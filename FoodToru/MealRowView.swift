//
//  MealRowView.swift
//  FoodToru
//
//  Created by Christine Chen on 9/14/25.
//

import SwiftUI
import CoreData

struct MealRowView: View {
    let item: Item
    @StateObject private var userSettings = UserSettings()
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let photoData = item.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            // Meal Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.mealName ?? "Unknown Meal")
                    .font(.headline)
                    .lineLimit(1)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("\(item.calories) cal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "figure.walk")
                            .foregroundColor(.blue)
                            .font(.caption2)
                        Text(CalorieBurnCalculator.shared.getBurnTimeDescription(for: Int(item.calories), userSettings: userSettings))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                if let timestamp = item.timestamp {
                    Text(timestamp, formatter: timeFormatter)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(.vertical, 4)
        .onAppear {
            loadUserSettings()
        }
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

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()
