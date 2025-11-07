//
//  UserSettings.swift
//  FoodToru
//
//  Created by Christine Chen on 9/14/25.
//

import Foundation

enum UnitSystem: String, CaseIterable {
    case imperial = "Imperial"
    case metric = "Metric"
    
    var heightUnit: String {
        switch self {
        case .imperial: return "inches"
        case .metric: return "cm"
        }
    }
    
    var weightUnit: String {
        switch self {
        case .imperial: return "lbs"
        case .metric: return "kg"
        }
    }
}

enum Gender: String, CaseIterable {
    case male = "Male"
    case female = "Female"
}

enum ExerciseType: String, CaseIterable {
    case walking = "Walking (3 mph)"
    case briskWalking = "Brisk Walking (4 mph)"
    case jogging = "Jogging (5 mph)"
    case running = "Running (6 mph)"
    case cycling = "Cycling (12 mph)"
    case swimming = "Swimming (moderate)"
    case weightlifting = "Weightlifting"
    case yoga = "Yoga"
    case dancing = "Dancing"
    case hiking = "Hiking"
    case basketball = "Basketball"
    case tennis = "Tennis"
    case soccer = "Soccer"
    case elliptical = "Elliptical"
    case stairClimbing = "Stair Climbing"
    case boxing = "Boxing"
    case rockClimbing = "Rock Climbing"
    case crossFit = "CrossFit"
    case pilates = "Pilates"
    
    var metValue: Double {
        switch self {
        case .walking: return 3.5
        case .briskWalking: return 4.3
        case .jogging: return 6.0
        case .running: return 8.0
        case .cycling: return 8.0
        case .swimming: return 6.0
        case .weightlifting: return 3.0
        case .yoga: return 2.5
        case .dancing: return 4.8
        case .hiking: return 6.0
        case .basketball: return 6.5
        case .tennis: return 7.3
        case .soccer: return 7.0
        case .elliptical: return 5.0
        case .stairClimbing: return 8.0
        case .boxing: return 8.0
        case .rockClimbing: return 8.0
        case .crossFit: return 8.0
        case .pilates: return 3.0
        }
    }
}

class UserSettings: ObservableObject {
    @Published var height: Double = 0
    @Published var weight: Double = 0
    @Published var age: Int = 0
    @Published var gender: Gender = .male
    @Published var unitSystem: UnitSystem = .imperial
    @Published var preferredExercise: ExerciseType = .walking
    
    var hasCompleteBiometrics: Bool {
        return height > 0 && weight > 0 && age > 0
    }
    
    // Convert height to meters
    var heightInMeters: Double {
        switch unitSystem {
        case .imperial:
            return height * 0.0254 // inches to meters
        case .metric:
            return height / 100 // cm to meters
        }
    }
    
    // Convert weight to kg
    var weightInKg: Double {
        switch unitSystem {
        case .imperial:
            return weight * 0.453592 // lbs to kg
        case .metric:
            return weight
        }
    }
    
    // Calculate BMR (Basal Metabolic Rate) using Mifflin-St Jeor Equation
    var bmr: Double {
        guard hasCompleteBiometrics else { return 0 }
        
        let heightCm = heightInMeters * 100
        let weightKg = weightInKg
        
        // Mifflin-St Jeor Equation
        // Male: BMR = (10 × weight in kg) + (6.25 × height in cm) - (5 × age in years) + 5
        // Female: BMR = (10 × weight in kg) + (6.25 × height in cm) - (5 × age in years) - 161
        let baseBMR = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age))
        let genderConstant = gender == .male ? 5.0 : -161.0
        return baseBMR + genderConstant
    }
    
    // Calculate BMI (Body Mass Index)
    var bmi: Double {
        guard hasCompleteBiometrics else { return 0 }
        
        let heightM = heightInMeters
        let weightKg = weightInKg
        
        guard heightM > 0 else { return 0 }
        
        // BMI = weight (kg) / height (m)²
        return weightKg / (heightM * heightM)
    }
    
    // Calculate calories burned per minute for preferred exercise
    func caloriesBurnedPerMinute() -> Double {
        guard hasCompleteBiometrics else {
            // Default for average person (70kg, 30 years old, 170cm)
            return 3.5 * 3.5 * 70 / 200 // MET * 3.5 * weight(kg) / 200
        }
        
        let met = preferredExercise.metValue
        let weightKg = weightInKg
        return met * 3.5 * weightKg / 200
    }
    
    // Calculate time to burn off calories
    func timeToBurnCalories(_ calories: Int) -> TimeInterval {
        let caloriesPerMinute = caloriesBurnedPerMinute()
        guard caloriesPerMinute > 0 else { return 0 }
        
        let minutes = Double(calories) / caloriesPerMinute
        return minutes * 60 // Convert to seconds
    }
}
