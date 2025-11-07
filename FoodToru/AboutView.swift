//
//  AboutView.swift
//  FoodToru
//
//  Created by Christine Chen on 11/7/25.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingDisclaimer = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // App Icon and Name
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)
                        
                        Text("FoodToru")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("AI-Powered Meal Analysis")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    
                    // App Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("FoodToru is an AI-powered meal analysis app that helps you understand the nutritional content of your meals. Simply take a photo of your meal, and our advanced AI will identify the dish, estimate calories, list ingredients, and provide nutritional insights.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Features")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureItem(icon: "camera.fill", text: "Smart meal photo analysis")
                            FeatureItem(icon: "brain.head.profile", text: "AI-powered by Claude Opus 4.1")
                            FeatureItem(icon: "flame.fill", text: "Calorie estimation")
                            FeatureItem(icon: "chart.bar.fill", text: "Nutritional analysis")
                            FeatureItem(icon: "figure.walk", text: "Personalized exercise recommendations")
                            FeatureItem(icon: "clock.fill", text: "Meal history tracking")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Version Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Version")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                            Text("Version \(version) (Build \(build))")
                                .font(.body)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Version 1.0")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Disclaimer Link
                    Button(action: {
                        showingDisclaimer = true
                    }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("View Disclaimer")
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .foregroundColor(.primary)
                    
                    // Copyright
                    VStack(spacing: 4) {
                        Text("© 2025 FoodToru")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("All rights reserved")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingDisclaimer) {
            DisclaimerView(hasSeenDisclaimer: .constant(true))
        }
    }
}

// MARK: - Feature Item
struct FeatureItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 20)
            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    AboutView()
}

