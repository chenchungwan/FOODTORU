//
//  SubscriptionService.swift
//  FoodToru
//
//  Created by Christine Chen on 9/22/25.
//

import Foundation
import StoreKit
import SwiftUI

// MARK: - Subscription Models
struct SubscriptionInfo {
    let isSubscribed: Bool
    let subscriptionType: SubscriptionType?
    let expirationDate: Date?
    let freeMealsUsed: Int
    let freeMealsLimit: Int
}

enum SubscriptionType: String, CaseIterable {
    case monthly = "com.foodtoru.subscription.monthly"
    
    var displayName: String {
        switch self {
        case .monthly:
            return "Monthly Subscription"
        }
    }
    
    var price: String {
        switch self {
        case .monthly:
            return "$0.99/month"
        }
    }
}

// MARK: - Subscription Service
@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    @Published var subscriptionInfo: SubscriptionInfo
    @Published var availableProducts: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let logger = Logger.shared
    private let userDefaults = UserDefaults.standard
    private let keychainService = KeychainService.shared
    
    // Constants
    private let freeMealsLimit = 3
    private let freeMealsUsedKey = "freeMealsUsed"
    private let subscriptionStatusKey = "subscriptionStatus"
    private let subscriptionExpirationKey = "subscriptionExpiration"
    
    private init() {
        self.subscriptionInfo = SubscriptionInfo(
            isSubscribed: false,
            subscriptionType: nil,
            expirationDate: nil,
            freeMealsUsed: userDefaults.integer(forKey: freeMealsUsedKey),
            freeMealsLimit: freeMealsLimit
        )
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    // MARK: - Public Methods
    
    func canAnalyzeMeal() -> Bool {
        return subscriptionInfo.isSubscribed || subscriptionInfo.freeMealsUsed < subscriptionInfo.freeMealsLimit
    }
    
    func recordMealAnalysis() {
        guard !subscriptionInfo.isSubscribed else { return }
        
        let newCount = subscriptionInfo.freeMealsUsed + 1
        userDefaults.set(newCount, forKey: freeMealsUsedKey)
        
        subscriptionInfo = SubscriptionInfo(
            isSubscribed: subscriptionInfo.isSubscribed,
            subscriptionType: subscriptionInfo.subscriptionType,
            expirationDate: subscriptionInfo.expirationDate,
            freeMealsUsed: newCount,
            freeMealsLimit: subscriptionInfo.freeMealsLimit
        )
        
        logger.debug("Meal analysis recorded. Free meals used: \(newCount)/\(freeMealsLimit)", context: "Subscription")
    }
    
    func purchaseSubscription(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus()
                await transaction.finish()
                
                logger.subscriptionEvent("Subscription purchased successfully", context: "Subscription")
                return true
                
            case .userCancelled:
                logger.debug("User cancelled subscription purchase", context: "Subscription")
                return false
                
            case .pending:
                logger.debug("Subscription purchase pending", context: "Subscription")
                return false
                
            @unknown default:
                logger.warning("Unknown purchase result", context: "Subscription")
                return false
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            logger.subscriptionError("Purchase failed: \(error.localizedDescription)", context: "Subscription")
            return false
        }
    }
    
    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            
            logger.subscriptionEvent("Purchases restored successfully", context: "Subscription")
            return true
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
            logger.subscriptionError("Restore failed: \(error.localizedDescription)", context: "Subscription")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func loadProducts() async {
        do {
            let productIdentifiers = SubscriptionType.allCases.map { $0.rawValue }
            let products = try await Product.products(for: productIdentifiers)
            
            await MainActor.run {
                self.availableProducts = products
                self.logger.debug("Loaded \(products.count) subscription products", context: "Subscription")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load products: \(error.localizedDescription)"
                self.logger.subscriptionError("Failed to load products: \(error.localizedDescription)", context: "Subscription")
            }
        }
    }
    
    private func updateSubscriptionStatus() async {
        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if let subscriptionType = SubscriptionType(rawValue: transaction.productID) {
                    let isActive = transaction.revocationDate == nil && 
                                 transaction.expirationDate != nil && 
                                 transaction.expirationDate! > Date()
                    
                    if isActive {
                        await MainActor.run {
                            self.subscriptionInfo = SubscriptionInfo(
                                isSubscribed: true,
                                subscriptionType: subscriptionType,
                                expirationDate: transaction.expirationDate,
                                freeMealsUsed: self.subscriptionInfo.freeMealsUsed,
                                freeMealsLimit: self.subscriptionInfo.freeMealsLimit
                            )
                        }
                        
                        logger.subscriptionEvent("Active subscription found: \(subscriptionType.displayName)", context: "Subscription")
                        return
                    }
                }
            } catch {
                logger.subscriptionError("Failed to verify transaction: \(error.localizedDescription)", context: "Subscription")
            }
        }
        
        // No active subscription found
        await MainActor.run {
            self.subscriptionInfo = SubscriptionInfo(
                isSubscribed: false,
                subscriptionType: nil,
                expirationDate: nil,
                freeMealsUsed: self.subscriptionInfo.freeMealsUsed,
                freeMealsLimit: self.subscriptionInfo.freeMealsLimit
            )
        }
        
        logger.debug("No active subscription found", context: "Subscription")
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.unverifiedTransaction
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Errors
enum SubscriptionError: LocalizedError {
    case unverifiedTransaction
    case productNotFound
    case purchaseFailed
    
    var errorDescription: String? {
        switch self {
        case .unverifiedTransaction:
            return "Transaction could not be verified"
        case .productNotFound:
            return "Subscription product not found"
        case .purchaseFailed:
            return "Purchase failed"
        }
    }
}

// MARK: - Logger Extensions
extension Logger {
    func subscriptionEvent(_ message: String, context: String = "Subscription") {
        log(.info, message, context: context, category: "Subscription")
    }
    
    func subscriptionError(_ message: String, context: String = "Subscription") {
        log(.error, message, context: context, category: "Subscription")
    }
}
