//
//  SettingsView.swift
//  FoodToru
//
//  Created by Christine Chen on 9/14/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var userSettings = UserSettings()
    @StateObject private var claudeService = ClaudeService()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var apiKey = ""
    @State private var showingAPIKeyAlert = false
    @State private var apiKeyStatus = "Not configured"
    @State private var showingAbout = false
    @State private var heightFeet: Int = 0
    @State private var heightInches: Int = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Unit System")) {
                    Picker("Unit System", selection: $userSettings.unitSystem) {
                        ForEach(UnitSystem.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: userSettings.unitSystem) { oldSystem, newSystem in
                        // Convert height when switching unit systems
                        if userSettings.height > 0 {
                            if oldSystem == .metric && newSystem == .imperial {
                                // Convert cm to inches
                                userSettings.height = userSettings.height / 2.54
                                // Update feet/inches display
                                updateFeetInchesFromHeight(userSettings.height)
                            } else if oldSystem == .imperial && newSystem == .metric {
                                // Convert inches to cm
                                userSettings.height = userSettings.height * 2.54
                            }
                        }
                        
                        // Convert weight when switching unit systems
                        if userSettings.weight > 0 {
                            if oldSystem == .metric && newSystem == .imperial {
                                // Convert kg to lbs
                                userSettings.weight = userSettings.weight / 0.453592
                            } else if oldSystem == .imperial && newSystem == .metric {
                                // Convert lbs to kg
                                userSettings.weight = userSettings.weight * 0.453592
                            }
                        }
                    }
                }
                
                Section(header: Text("Biometrics")) {
                    if userSettings.unitSystem == .imperial {
                        // Imperial: Feet and Inches
                        HStack {
                            Text("Height")
                            Spacer()
                            HStack(spacing: 4) {
                                TextField("Feet", value: $heightFeet, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 50)
                                Text("ft")
                                    .foregroundColor(.secondary)
                                
                                TextField("Inches", value: $heightInches, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 50)
                                Text("in")
                                    .foregroundColor(.secondary)
                            }
                            .onChange(of: heightFeet) { _, _ in
                                updateHeightFromFeetInches()
                            }
                            .onChange(of: heightInches) { _, _ in
                                updateHeightFromFeetInches()
                            }
                        }
                    } else {
                        // Metric: Centimeters
                        HStack {
                            Text("Height")
                            Spacer()
                            TextField("Enter height", value: $userSettings.height, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text(userSettings.unitSystem.heightUnit)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("Enter weight", value: $userSettings.weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(userSettings.unitSystem.weightUnit)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Age")
                        Spacer()
                        TextField("Enter age", value: $userSettings.age, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("years")
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Gender", selection: $userSettings.gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                }
                
                Section(header: Text("Exercise Preference")) {
                    Picker("Preferred Exercise", selection: $userSettings.preferredExercise) {
                        ForEach(ExerciseType.allCases, id: \.self) { exercise in
                            Text(exercise.rawValue).tag(exercise)
                        }
                    }
                }
                
                Section(header: Text("Profile Status")) {
                    HStack {
                        Image(systemName: userSettings.hasCompleteBiometrics ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(userSettings.hasCompleteBiometrics ? .green : .orange)
                        Text(userSettings.hasCompleteBiometrics ? "Complete Profile" : "Incomplete Profile")
                            .foregroundColor(userSettings.hasCompleteBiometrics ? .green : .orange)
                    }
                    
                    if userSettings.hasCompleteBiometrics {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BMR: \(Int(userSettings.bmr)) calories/day")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("BMI: \(String(format: "%.1f", userSettings.bmi))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Calories burned per minute: \(String(format: "%.1f", userSettings.caloriesBurnedPerMinute()))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Complete your biometrics to get personalized calorie burn estimates")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(footer: Text("Your biometric data is stored locally on your device and is not shared with any external services.")) {
                    EmptyView()
                }
                
                Section(header: Text("API Configuration")) {
                    HStack {
                        Text("Claude API Key")
                        Spacer()
                        Text(apiKeyStatus)
                            .foregroundColor(apiKeyStatus == "Configured" ? .green : .orange)
                    }
                    
                    Button(action: {
                        showingAPIKeyAlert = true
                    }) {
                        Text(apiKeyStatus == "Configured" ? "Update API Key" : "Set API Key")
                            .foregroundColor(.blue)
                    }
                    
                    if apiKeyStatus == "Configured" {
                        Button(action: {
                            deleteAPIKey()
                        }) {
                            Text("Remove API Key")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    Button(action: {
                        showingAbout = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("About FoodToru")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadSettings()
            updateAPIKeyStatus()
        }
        .onDisappear {
            saveSettings()
        }
        .alert("Claude API Key", isPresented: $showingAPIKeyAlert) {
            TextField("Enter your Claude API key", text: $apiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button("Save") {
                saveAPIKey()
            }
            Button("Cancel", role: .cancel) {
                apiKey = ""
            }
        } message: {
            Text("Enter your Claude API key from Anthropic Console. The key will be stored securely on your device.")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    private func loadSettings() {
        // Load from UserDefaults
        if let height = UserDefaults.standard.object(forKey: "height") as? Double {
            userSettings.height = height
            // Convert height to feet and inches if imperial
            if userSettings.unitSystem == .imperial {
                updateFeetInchesFromHeight(height)
            }
        }
        if let weight = UserDefaults.standard.object(forKey: "weight") as? Double {
            userSettings.weight = weight
        }
        if let age = UserDefaults.standard.object(forKey: "age") as? Int {
            userSettings.age = age
        }
        if let unitSystemRaw = UserDefaults.standard.string(forKey: "unitSystem"),
           let unitSystem = UnitSystem(rawValue: unitSystemRaw) {
            userSettings.unitSystem = unitSystem
            // Update feet/inches if switching to imperial
            if unitSystem == .imperial && userSettings.height > 0 {
                updateFeetInchesFromHeight(userSettings.height)
            }
        }
        if let exerciseRaw = UserDefaults.standard.string(forKey: "preferredExercise"),
           let exercise = ExerciseType(rawValue: exerciseRaw) {
            userSettings.preferredExercise = exercise
        }
        if let genderRaw = UserDefaults.standard.string(forKey: "gender"),
           let gender = Gender(rawValue: genderRaw) {
            userSettings.gender = gender
        }
    }
    
    private func saveSettings() {
        // Update height from feet/inches if imperial
        if userSettings.unitSystem == .imperial {
            updateHeightFromFeetInches()
        }
        
        // Save to UserDefaults
        UserDefaults.standard.set(userSettings.height, forKey: "height")
        UserDefaults.standard.set(userSettings.weight, forKey: "weight")
        UserDefaults.standard.set(userSettings.age, forKey: "age")
        UserDefaults.standard.set(userSettings.gender.rawValue, forKey: "gender")
        UserDefaults.standard.set(userSettings.unitSystem.rawValue, forKey: "unitSystem")
        UserDefaults.standard.set(userSettings.preferredExercise.rawValue, forKey: "preferredExercise")
    }
    
    // MARK: - Height Conversion Helpers
    
    /// Update height (in inches) from feet and inches
    private func updateHeightFromFeetInches() {
        let totalInches = Double(heightFeet * 12 + heightInches)
        userSettings.height = totalInches
    }
    
    /// Update feet and inches from total height (in inches)
    private func updateFeetInchesFromHeight(_ heightInInches: Double) {
        let totalInches = Int(heightInInches)
        heightFeet = totalInches / 12
        heightInches = totalInches % 12
    }
    
    // MARK: - API Key Management
    
    private func updateAPIKeyStatus() {
        if claudeService.isAPIKeyConfigured() {
            apiKeyStatus = "Configured"
        } else {
            apiKeyStatus = "Not configured"
        }
    }
    
    private func saveAPIKey() {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if KeychainService.shared.isValidAPIKey(trimmedKey) {
            if KeychainService.shared.saveAPIKey(trimmedKey) {
                apiKeyStatus = "Configured"
                apiKey = ""
                
                // Test the API connection
                Task {
                    let isConnected = await claudeService.testAPIConnection()
                    if !isConnected {
                        await MainActor.run {
                            apiKeyStatus = "Invalid key"
                        }
                    }
                }
            } else {
                apiKeyStatus = "Save failed"
            }
        } else {
            apiKeyStatus = "Invalid format"
        }
    }
    
    private func deleteAPIKey() {
        if KeychainService.shared.deleteAPIKey() {
            apiKeyStatus = "Not configured"
        }
    }
}
