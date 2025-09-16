//
//  CalorieBurnCalculator.swift
//  FoodToru
//
//  Created by Christine Chen on 9/14/25.
//

import Foundation

class CalorieBurnCalculator {
    static let shared = CalorieBurnCalculator()
    
    private init() {}
    
    func calculateBurnTime(for calories: Int, userSettings: UserSettings) -> (timeInterval: TimeInterval, formattedString: String) {
        let timeInterval = userSettings.timeToBurnCalories(calories)
        let formattedString = formatTimeInterval(timeInterval)
        return (timeInterval, formattedString)
    }
    
    private func formatTimeInterval(_ timeInterval: TimeInterval) -> String {
        let totalMinutes = Int(timeInterval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(hours)h"
            }
        } else {
            return "\(minutes)m"
        }
    }
    
    func getBurnTimeDescription(for calories: Int, userSettings: UserSettings) -> String {
        let (_, formattedTime) = calculateBurnTime(for: calories, userSettings: userSettings)
        
        if userSettings.hasCompleteBiometrics {
            return "Burn off in \(formattedTime) of \(userSettings.preferredExercise.rawValue.lowercased())"
        } else {
            return "Burn off in \(formattedTime) of walking (average person)"
        }
    }
}
