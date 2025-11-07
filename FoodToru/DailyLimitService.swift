//
//  DailyLimitService.swift
//  FoodToru
//
//  Created by Christine Chen on 11/7/25.
//

import Foundation
import SwiftUI

class DailyLimitService: ObservableObject {
    static let shared = DailyLimitService()
    
    private let userDefaults = UserDefaults.standard
    private let logger = Logger.shared
    
    // Constants
    private let dailyLimit = 5
    private let countKey = "dailyMealAnalysisCount"
    private let dateKey = "lastAnalysisDate"
    
    @Published private(set) var currentCount: Int = 0
    
    private init() {
        // Initialize current count
        updateCount()
    }
    
    // MARK: - Public Methods
    
    /// Get the daily limit
    var limit: Int {
        return dailyLimit
    }
    
    /// Update the current count (internal method)
    private func updateCount() {
        // Check if we need to reset (new day)
        if shouldResetCount() {
            resetCount()
        }
        currentCount = userDefaults.integer(forKey: countKey)
    }
    
    /// Check if user can analyze a meal today
    func canAnalyzeMeal() -> Bool {
        updateCount()
        return currentCount < dailyLimit
    }
    
    /// Get remaining analyses for today
    var remainingCount: Int {
        return max(0, dailyLimit - currentCount)
    }
    
    /// Record a successful meal analysis
    func recordSuccessfulAnalysis() {
        updateCount()
        
        let newCount = currentCount + 1
        userDefaults.set(newCount, forKey: countKey)
        userDefaults.set(Date(), forKey: dateKey)
        currentCount = newCount
        
        logger.debug("Meal analysis recorded. Count: \(newCount)/\(dailyLimit)", context: "Daily Limit")
    }
    
    /// Get the date when the limit will reset
    var resetDate: Date? {
        guard let lastDate = userDefaults.object(forKey: dateKey) as? Date else {
            return nil
        }
        return Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: lastDate) ?? Date())
    }
    
    // MARK: - Private Methods
    
    /// Check if we should reset the count (new day)
    private func shouldResetCount() -> Bool {
        guard let lastDate = userDefaults.object(forKey: dateKey) as? Date else {
            // No previous date, so we should initialize
            return true
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastDate)
        
        return !calendar.isDate(today, inSameDayAs: lastDay)
    }
    
    /// Reset the count for a new day
    private func resetCount() {
        userDefaults.set(0, forKey: countKey)
        userDefaults.set(Date(), forKey: dateKey)
        currentCount = 0
        logger.debug("Daily limit reset for new day", context: "Daily Limit")
    }
    
    /// Force reset (for testing/debugging)
    func forceReset() {
        resetCount()
        logger.debug("Daily limit force reset", context: "Daily Limit")
    }
}

