//
//  ContentView.swift
//  FoodToru
//
//  Created by Christine Chen on 9/14/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var claudeService = ClaudeService()
    @StateObject private var persistenceController = PersistenceController.shared
    @StateObject private var dailyLimitService = DailyLimitService.shared
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var showingSettings = false
    @State private var showingLimitAlert = false
    @State private var showingDisclaimer = false
    
    private let logger = Logger.shared
    private let hasSeenDisclaimerKey = "hasSeenDisclaimer"

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        NavigationView {
            VStack {
                // Daily Limit Banner
                dailyLimitBanner
                
                if items.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No meals recorded yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Tap the camera button to take a photo of your meal")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(items) { item in
                            NavigationLink {
                                MealDetailView(item: item)
                            } label: {
                                MealRowView(item: item)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Label("Settings", systemImage: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !items.isEmpty {
                        EditButton()
                    }
                }
                ToolbarItem {
                    Button(action: {
                        if dailyLimitService.canAnalyzeMeal() {
                            showingCamera = true
                        } else {
                            showingLimitAlert = true
                        }
                    }) {
                        Label("Take Photo", systemImage: "camera")
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingDisclaimer) {
                DisclaimerView(hasSeenDisclaimer: $showingDisclaimer)
            }
            .onChange(of: selectedImage) { _, newImage in
                if let image = newImage {
                    analyzeMeal(image: image)
                }
            }
            .alert("Daily Limit Reached", isPresented: $showingLimitAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(dailyLimitAlertMessage)
            }
            .alert("Error", isPresented: .constant(claudeService.errorMessage != nil || persistenceController.lastError != nil)) {
                if persistenceController.lastError != nil {
                    Button("Retry") {
                        persistenceController.retryStoreLoading()
                    }
                    Button("OK") {
                        persistenceController.clearError()
                    }
                } else {
                    Button("OK") {
                        claudeService.errorMessage = nil
                    }
                }
            } message: {
                Text(errorAlertMessage)
            }
            .overlay(
                Group {
                    if claudeService.isLoading {
                        MealAnalysisLoadingView()
                    }
                }
            )
        }
        .onAppear {
            #if DEBUG
            KeychainServiceTests.runTests()
            ErrorHandlingTests.runTests()
            #endif
            // Ensure pre-configured API key is initialized (backup in case app init timing is off)
            KeychainService.shared.initializePreconfiguredKeyIfNeeded()
            testAPIConnection()
            
            // Show disclaimer on first launch - check Core Data first, then UserDefaults as fallback
            let hasAcknowledged = UserPreferencesService.shared.hasAcknowledgedDisclaimer(context: viewContext)
            let hasAcknowledgedFallback = UserDefaults.standard.bool(forKey: hasSeenDisclaimerKey)
            
            if !hasAcknowledged && !hasAcknowledgedFallback {
                showingDisclaimer = true
            } else if hasAcknowledgedFallback && !hasAcknowledged {
                // Migrate from UserDefaults to Core Data
                _ = UserPreferencesService.shared.acknowledgeDisclaimer(context: viewContext)
            }
        }
    }

    // MARK: - Alert Messages
    private var dailyLimitAlertMessage: String {
        let limit = dailyLimitService.limit
        return "You've reached your daily limit of \(limit) meal analyses. Your limit will reset tomorrow at midnight."
    }
    
    private var errorAlertMessage: String {
        if let claudeError = claudeService.errorMessage {
            return claudeError
        } else if let coreDataError = persistenceController.lastError {
            var message = coreDataError.localizedDescription
            if let suggestion = coreDataError.recoverySuggestion {
                message += "\n\n\(suggestion)"
            }
            return message
        }
        return ""
    }
    
    // MARK: - Daily Limit Banner
    private var dailyLimitBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text("Daily Limit")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text("\(dailyLimitService.remainingCount) of \(dailyLimitService.limit) analyses remaining today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ProgressView(value: Double(dailyLimitService.currentCount), 
                            total: Double(dailyLimitService.limit))
                    .progressViewStyle(LinearProgressViewStyle(tint: dailyLimitService.remainingCount > 0 ? .blue : .red))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func testAPIConnection() {
        Task {
            if !claudeService.isAPIKeyConfigured() {
                await MainActor.run {
                    claudeService.errorMessage = "No API key configured. Please set your Claude API key in Settings."
                }
                return
            }
            
            let isConnected = await claudeService.testAPIConnection()
            if !isConnected {
                await MainActor.run {
                    claudeService.errorMessage = "API connection test failed. Please check your internet connection and API key."
                }
            }
        }
    }
    
    private func analyzeMeal(image: UIImage) {
        Task {
            if let analysis = await claudeService.analyzeMeal(image: image) {
                await MainActor.run {
                    let newItem = Item(context: viewContext)
                    newItem.timestamp = Date()
                    newItem.mealName = analysis.mealName
                    newItem.calories = Int32(analysis.calories)
                    newItem.ingredients = analysis.ingredients.joined(separator: ", ")
                    newItem.replacementIngredients = analysis.replacementIngredients.joined(separator: ", ")
                    
                    logger.debug("Saving meal data", context: "Meal Save")
                    newItem.analysis = analysis.analysis
                    newItem.photoData = image.jpegData(compressionQuality: 0.8)
                    
                    do {
                        try viewContext.save()
                        // Record successful analysis only after successful save
                        dailyLimitService.recordSuccessfulAnalysis()
                    } catch {
                        let nsError = error as NSError
                        let coreDataError = CoreDataErrorHandler.handleSaveError(nsError)
                        CoreDataErrorHandler.logError(coreDataError, context: "Meal Save")
                        
                        // Show user-friendly error message
                        DispatchQueue.main.async {
                            self.persistenceController.lastError = coreDataError
                        }
                    }
                }
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Handle Core Data save error gracefully
                let nsError = error as NSError
                let coreDataError = CoreDataErrorHandler.handleSaveError(nsError)
                CoreDataErrorHandler.logError(coreDataError, context: "Delete Operation")
                
                // Show user-friendly error message
                DispatchQueue.main.async {
                    self.persistenceController.lastError = coreDataError
                }
                
                // Attempt to rollback the changes
                viewContext.rollback()
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
