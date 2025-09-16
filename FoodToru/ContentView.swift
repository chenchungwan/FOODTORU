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
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var showingSettings = false

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
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    analyzeMeal(image: image)
                }
            }
            .alert("Error", isPresented: .constant(claudeService.errorMessage != nil)) {
                Button("OK") {
                    claudeService.errorMessage = nil
                }
            } message: {
                Text(claudeService.errorMessage ?? "")
            }
            .overlay(
                Group {
                    if claudeService.isLoading {
                        VStack {
                            ProgressView("Analyzing meal...")
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(10)
                        }
                    }
                }
            )
        }
        .onAppear {
            testAPIConnection()
        }
    }

    private func testAPIConnection() {
        Task {
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
                    
                    print("💾 Saving meal data:")
                    print("  Ingredients: \(newItem.ingredients ?? "None")")
                    print("  Replacement Ingredients: \(newItem.replacementIngredients ?? "None")")
                    newItem.analysis = analysis.analysis
                    newItem.photoData = image.jpegData(compressionQuality: 0.8)
                    
                    do {
                        try viewContext.save()
                    } catch {
                        print("Failed to save meal: \(error)")
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
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
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
