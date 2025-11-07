//
//  UserPreferencesService.swift
//  FoodToru
//
//  Created by Christine Chen on 11/7/25.
//

import Foundation
import CoreData
import SwiftUI

class UserPreferencesService {
    static let shared = UserPreferencesService()
    
    private let persistenceController = PersistenceController.shared
    private let logger = Logger.shared
    
    private init() {}
    
    // MARK: - Disclaimer Acknowledgment
    
    /// Check if user has acknowledged the disclaimer
    func hasAcknowledgedDisclaimer(context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<UserPreferences> = UserPreferences.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            if let preferences = results.first {
                return preferences.hasAcknowledgedDisclaimer
            }
        } catch {
            logger.coreDataError("Failed to fetch user preferences: \(error.localizedDescription)", context: "User Preferences")
        }
        
        return false
    }
    
    /// Save disclaimer acknowledgment to Core Data
    func acknowledgeDisclaimer(context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<UserPreferences> = UserPreferences.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            let preferences: UserPreferences
            
            if let existing = results.first {
                preferences = existing
            } else {
                preferences = UserPreferences(context: context)
            }
            
            preferences.hasAcknowledgedDisclaimer = true
            preferences.disclaimerAcknowledgmentDate = Date()
            
            try context.save()
            logger.debug("Disclaimer acknowledgment saved to Core Data", context: "User Preferences")
            return true
        } catch {
            let nsError = error as NSError
            let coreDataError = CoreDataErrorHandler.handleSaveError(nsError)
            CoreDataErrorHandler.logError(coreDataError, context: "Disclaimer Acknowledgment")
            logger.coreDataError("Failed to save disclaimer acknowledgment: \(error.localizedDescription)", context: "User Preferences")
            return false
        }
    }
    
    /// Get disclaimer acknowledgment date
    func getDisclaimerAcknowledgmentDate(context: NSManagedObjectContext) -> Date? {
        let request: NSFetchRequest<UserPreferences> = UserPreferences.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            return results.first?.disclaimerAcknowledgmentDate
        } catch {
            logger.coreDataError("Failed to fetch disclaimer date: \(error.localizedDescription)", context: "User Preferences")
            return nil
        }
    }
}

