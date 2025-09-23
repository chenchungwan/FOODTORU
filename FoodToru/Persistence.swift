//
//  Persistence.swift
//  FoodToru
//
//  Created by Christine Chen on 9/14/25.
//

import CoreData
import SwiftUI

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    // Error handling for Core Data operations
    @Published var lastError: CoreDataError?
    private let logger = Logger.shared

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            // Handle Core Data save error in preview
            let nsError = error as NSError
            let coreDataError = CoreDataErrorHandler.handleSaveError(nsError)
            CoreDataErrorHandler.logError(coreDataError, context: "Preview Data Setup")
            
            // For preview, we'll just log the error and continue
            // In a real app, you might want to show an error state
            Logger.shared.warning("Preview data setup failed, but continuing", context: "Preview")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "FoodToru")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { [weak self] (storeDescription, error) in
            if let error = error as NSError? {
                // Handle Core Data store loading error gracefully
                let coreDataError = CoreDataErrorHandler.handleStoreLoadError(error)
                CoreDataErrorHandler.logError(coreDataError, context: "Store Loading")
                
                // Store the error for UI to display
                DispatchQueue.main.async {
                    self?.lastError = coreDataError
                }
                
                // Attempt to create a new store as fallback
                self?.createFallbackStore()
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Error Recovery Methods
    
    private func createFallbackStore() {
        logger.debug("Attempting to create fallback store", context: "Core Data")
        
        // Check if we already have a working store
        if !container.persistentStoreCoordinator.persistentStores.isEmpty {
            logger.debug("Store already exists, clearing error", context: "Core Data")
            DispatchQueue.main.async {
                self.lastError = nil
            }
            return
        }
        
        // Create a new store description with a different name
        let fallbackStoreDescription = NSPersistentStoreDescription()
        fallbackStoreDescription.url = getFallbackStoreURL()
        fallbackStoreDescription.type = NSSQLiteStoreType
        
        container.persistentStoreDescriptions = [fallbackStoreDescription]
        
        container.loadPersistentStores { [weak self] (storeDescription, error) in
            if let error = error {
                self?.logger.coreDataError("Fallback store creation failed: \(error.localizedDescription)", context: "Core Data")
                DispatchQueue.main.async {
                    self?.lastError = .storeLoadFailed("Unable to create data store. The app may not function properly.")
                }
            } else {
                self?.logger.coreDataSuccess("Fallback store created", context: "Core Data")
                DispatchQueue.main.async {
                    self?.lastError = nil
                }
            }
        }
    }
    
    private func getFallbackStoreURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("FoodToru_Fallback.sqlite")
    }
    
    // MARK: - Public Error Handling Methods
    
    func clearError() {
        lastError = nil
    }
    
    func retryStoreLoading() {
        logger.debug("Retrying store loading", context: "Core Data")
        lastError = nil
        
        // Clear any existing error and attempt to create a new fallback store
        // This is safer than trying to reload an existing store
        createFallbackStore()
    }
}
