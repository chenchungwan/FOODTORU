//
//  SubscriptionView.swift
//  FoodToru
//
//  Created by Christine Chen on 9/22/25.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingPurchaseAlert = false
    @State private var purchaseResult: PurchaseResult?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("Unlock Unlimited Analysis")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Get unlimited meal analysis and nutritional insights")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Current Status
                    if subscriptionService.subscriptionInfo.isSubscribed {
                        subscribedStatusView
                    } else {
                        freeTrialStatusView
                    }
                    
                    // Features
                    featuresView
                    
                    // Pricing
                    if !subscriptionService.availableProducts.isEmpty {
                        pricingView
                    }
                    
                    // Purchase Button
                    purchaseButton
                    
                    // Restore Button
                    restoreButton
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Purchase Result", isPresented: $showingPurchaseAlert) {
            Button("OK") { }
        } message: {
            if let result = purchaseResult {
                Text(result.message)
            }
        }
    }
    
    // MARK: - Subscribed Status View
    private var subscribedStatusView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Subscribed")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            if let expirationDate = subscriptionService.subscriptionInfo.expirationDate {
                Text("Expires: \(expirationDate, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Free Trial Status View
    private var freeTrialStatusView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                Text("Free Trial")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text("\(subscriptionService.subscriptionInfo.freeMealsUsed)/\(subscriptionService.subscriptionInfo.freeMealsLimit) free analyses used")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ProgressView(value: Double(subscriptionService.subscriptionInfo.freeMealsUsed), 
                        total: Double(subscriptionService.subscriptionInfo.freeMealsLimit))
                .progressViewStyle(LinearProgressViewStyle(tint: .orange))
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Features View
    private var featuresView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Premium Features")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                FeatureRow(icon: "camera.fill", title: "Unlimited Meal Analysis", description: "Analyze as many meals as you want")
                FeatureRow(icon: "chart.bar.fill", title: "Detailed Nutrition Insights", description: "Get comprehensive nutritional breakdowns")
                FeatureRow(icon: "leaf.fill", title: "Healthier Alternatives", description: "Discover better ingredient substitutions")
                FeatureRow(icon: "heart.fill", title: "Health Tracking", description: "Track your nutritional progress over time")
            }
        }
    }
    
    // MARK: - Pricing View
    private var pricingView: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(subscriptionService.availableProducts, id: \.id) { product in
                PricingCard(product: product) {
                    Task {
                        let success = await subscriptionService.purchaseSubscription(product)
                        purchaseResult = success ? .success : .failed
                        showingPurchaseAlert = true
                    }
                }
            }
        }
    }
    
    // MARK: - Purchase Button
    private var purchaseButton: some View {
        Button(action: {
            if let product = subscriptionService.availableProducts.first {
                Task {
                    let success = await subscriptionService.purchaseSubscription(product)
                    purchaseResult = success ? .success : .failed
                    showingPurchaseAlert = true
                }
            }
        }) {
            HStack {
                if subscriptionService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                Text(subscriptionService.isLoading ? "Processing..." : "Start Free Trial")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(subscriptionService.isLoading || subscriptionService.availableProducts.isEmpty)
    }
    
    // MARK: - Restore Button
    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task {
                let success = await subscriptionService.restorePurchases()
                purchaseResult = success ? .restored : .restoreFailed
                showingPurchaseAlert = true
            }
        }
        .foregroundColor(.blue)
        .disabled(subscriptionService.isLoading)
    }
    
    // MARK: - Date Formatter
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Pricing Card
struct PricingCard: View {
    let product: Product
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Unlimited access")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("per month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("Subscribe") {
                onPurchase()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Purchase Result
enum PurchaseResult {
    case success
    case failed
    case restored
    case restoreFailed
    
    var message: String {
        switch self {
        case .success:
            return "Subscription activated successfully!"
        case .failed:
            return "Purchase failed. Please try again."
        case .restored:
            return "Purchases restored successfully!"
        case .restoreFailed:
            return "No purchases found to restore."
        }
    }
}

#Preview {
    SubscriptionView()
}
