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
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var showingSettings = false
    
    private let logger = Logger.shared

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        NavigationView {
            VStack {
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
                        showingCamera = true
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
            .onChange(of: selectedImage) { _, newImage in
                if let image = newImage {
                    analyzeMeal(image: image)
                }
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
                if let claudeError = claudeService.errorMessage {
                    Text(claudeError)
                } else if let coreDataError = persistenceController.lastError {
                    VStack {
                        Text(coreDataError.localizedDescription)
                        if let suggestion = coreDataError.recoverySuggestion {
                            Text(suggestion)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
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
            testAPIConnection()
        }
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
