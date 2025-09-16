//
//  AlternativeExerciseCalculator.swift
//  FoodToru
//
//  Created by Christine Chen on 9/14/25.
//

import Foundation

struct ExerciseOption {
    let name: String
    let metValue: Double
    let icon: String
}

class AlternativeExerciseCalculator {
    static let shared = AlternativeExerciseCalculator()
    
    private init() {}
    
    let allExercises: [ExerciseOption] = [
        ExerciseOption(name: "Walking (3 mph)", metValue: 3.5, icon: "figure.walk"),
        ExerciseOption(name: "Brisk Walking (4 mph)", metValue: 4.3, icon: "figure.walk"),
        ExerciseOption(name: "Jogging (5 mph)", metValue: 6.0, icon: "figure.run"),
        ExerciseOption(name: "Running (6 mph)", metValue: 8.0, icon: "figure.run"),
        ExerciseOption(name: "Cycling (12 mph)", metValue: 8.0, icon: "bicycle"),
        ExerciseOption(name: "Swimming (moderate)", metValue: 6.0, icon: "figure.pool.swim"),
        ExerciseOption(name: "Weightlifting", metValue: 3.0, icon: "dumbbell"),
        ExerciseOption(name: "Yoga", metValue: 2.5, icon: "figure.yoga"),
        ExerciseOption(name: "Dancing", metValue: 4.8, icon: "figure.dance"),
        ExerciseOption(name: "Hiking", metValue: 6.0, icon: "figure.hiking"),
        ExerciseOption(name: "Basketball", metValue: 6.5, icon: "basketball"),
        ExerciseOption(name: "Tennis", metValue: 7.3, icon: "tennis.racket"),
        ExerciseOption(name: "Soccer", metValue: 7.0, icon: "soccerball"),
        ExerciseOption(name: "Elliptical", metValue: 5.0, icon: "figure.elliptical"),
        ExerciseOption(name: "Stair Climbing", metValue: 8.0, icon: "figure.stairs"),
        ExerciseOption(name: "Boxing", metValue: 8.0, icon: "figure.boxing"),
        ExerciseOption(name: "Rock Climbing", metValue: 8.0, icon: "figure.climbing"),
        ExerciseOption(name: "CrossFit", metValue: 8.0, icon: "figure.strengthtraining.traditional"),
        ExerciseOption(name: "Pilates", metValue: 3.0, icon: "figure.pilates")
    ]
    
    func calculateBurnTimes(for calories: Int, userSettings: UserSettings) -> [ExerciseBurnTime] {
        return allExercises.map { exercise in
            let timeInterval = calculateBurnTime(calories: calories, metValue: exercise.metValue, userSettings: userSettings)
            return ExerciseBurnTime(
                exercise: exercise,
                timeInterval: timeInterval,
                formattedTime: formatTimeInterval(timeInterval)
            )
        }.sorted { $0.timeInterval < $1.timeInterval } // Sort by shortest time first
    }
    
    private func calculateBurnTime(calories: Int, metValue: Double, userSettings: UserSettings) -> TimeInterval {
        let caloriesPerMinute: Double
        
        if userSettings.hasCompleteBiometrics {
            let weightKg = userSettings.weightInKg
            caloriesPerMinute = metValue * 3.5 * weightKg / 200
        } else {
            // Default for average person (70kg, 30 years old)
            caloriesPerMinute = metValue * 3.5 * 70 / 200
        }
        
        guard caloriesPerMinute > 0 else { return 0 }
        
        let minutes = Double(calories) / caloriesPerMinute
        return minutes * 60 // Convert to seconds
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
}

struct ExerciseBurnTime {
    let exercise: ExerciseOption
    let timeInterval: TimeInterval
    let formattedTime: String
}
