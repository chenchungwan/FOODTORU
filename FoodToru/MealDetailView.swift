//
//  MealDetailView.swift
//  FoodToru
//
//  Created by Christine Chen on 9/14/25.
//

import SwiftUI
import CoreData

struct MealDetailView: View {
    let item: Item
    @StateObject private var userSettings = UserSettings()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Photo
                if let photoData = item.photoData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                }
                
                // Meal Information
                VStack(alignment: .leading, spacing: 12) {
                    Text(item.mealName ?? "Unknown Meal")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(item.calories) calories")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    // BMR Percentage
                    if userSettings.hasCompleteBiometrics {
                        HStack {
                            Image(systemName: "percent")
                                .foregroundColor(.blue)
                            Text("\(bmrPercentage, specifier: "%.1f")% of daily BMR")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Calorie burn time - Highlighted
                    HStack {
                        Image(systemName: "figure.walk")
                            .foregroundColor(.white)
                            .font(.title2)
                        Text(CalorieBurnCalculator.shared.getBurnTimeDescription(for: Int(item.calories), userSettings: userSettings))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    if let timestamp = item.timestamp {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.gray)
                            Text(timestamp, formatter: itemFormatter)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Ingredients
                if let ingredients = item.ingredients, !ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ingredients")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(ingredients)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                
                // Analysis
                if let analysis = item.analysis, !analysis.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nutritional Analysis")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text(analysis)
                            .font(.body)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }

                // Reference Sources
                if let referenceSources = item.referenceSources, !referenceSources.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reference Sources")
                            .font(.headline)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(referenceSources.components(separatedBy: "\n"), id: \.self) { source in
                                if !source.isEmpty, let url = URL(string: source) {
                                    Link(destination: url) {
                                        HStack {
                                            Image(systemName: "link")
                                                .foregroundColor(.blue)
                                                .font(.caption)
                                            Text(source)
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                                .underline()
                                                .lineLimit(2)
                                            Spacer()
                                            Image(systemName: "arrow.up.right.square")
                                                .foregroundColor(.blue)
                                                .font(.caption)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }

                // Alternative Exercises
                VStack(alignment: .leading, spacing: 12) {
                    Text("Alternative Exercises")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Time to burn off \(item.calories) calories with different activities:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(AlternativeExerciseCalculator.shared.calculateBurnTimes(for: Int(item.calories), userSettings: userSettings).prefix(15), id: \.exercise.name) { burnTime in
                            HStack {
                                Image(systemName: burnTime.exercise.icon)
                                    .foregroundColor(.blue)
                                    .frame(width: 20)
                                
                                Text(burnTime.exercise.name)
                                    .font(.body)
                                
                                Spacer()
                                
                                Text(burnTime.formattedTime)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Meal Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUserSettings()
        }
    }
    
    // MARK: - Computed Properties
    
    /// Calculate meal calories as percentage of daily BMR
    private var bmrPercentage: Double {
        guard userSettings.hasCompleteBiometrics else { return 0 }
        let bmr = userSettings.bmr
        guard bmr > 0 else { return 0 }
        return (Double(item.calories) / bmr) * 100
    }
    
    private func loadUserSettings() {
        if let height = UserDefaults.standard.object(forKey: "height") as? Double {
            userSettings.height = height
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
        }
        if let exerciseRaw = UserDefaults.standard.string(forKey: "preferredExercise"),
           let exercise = ExerciseType(rawValue: exerciseRaw) {
            userSettings.preferredExercise = exercise
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()
