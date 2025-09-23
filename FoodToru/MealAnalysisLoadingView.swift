//
//  MealAnalysisLoadingView.swift
//  FoodToru
//
//  Created by Christine Chen on 9/22/25.
//

import SwiftUI

struct MealAnalysisLoadingView: View {
    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0
    @State private var currentMessageIndex = 0
    
    private let messages = [
        "Analyzing your meal...",
        "Identifying ingredients...",
        "Calculating calories...",
        "Finding healthier alternatives...",
        "Almost done..."
    ]
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Main animation
                ZStack {
                    // Outer pulsing circle
                    Circle()
                        .stroke(Color.orange.opacity(0.3), lineWidth: 3)
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .opacity(0.6)
                    
                    // Rotating food icon
                    Image(systemName: "fork.knife")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.orange)
                        .rotationEffect(.degrees(rotationAngle))
                }
                
                // Loading text
                VStack(spacing: 12) {
                    Text(messages[currentMessageIndex])
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.5), value: currentMessageIndex)
                    
                    // Animated dots
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 6, height: 6)
                                .scaleEffect(isAnimating ? 1.2 : 0.8)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }
                }
                
                // Progress text
                Text("This may take a few moments")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(20)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Start pulsing animation
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            isAnimating = true
        }
        
        // Start rotation animation
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // Cycle through messages
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentMessageIndex = (currentMessageIndex + 1) % messages.count
            }
        }
    }
}

#Preview {
    MealAnalysisLoadingView()
        .background(Color.gray.opacity(0.3))
}