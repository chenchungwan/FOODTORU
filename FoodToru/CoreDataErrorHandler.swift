//
//  CoreDataErrorHandler.swift
//  FoodToru
//
//  Created by Christine Chen on 9/14/25.
//

import Foundation
import CoreData

enum CoreDataError: LocalizedError {
    case storeLoadFailed(String)
    case saveFailed(String)
    case migrationFailed(String)
    case insufficientStorage
    case permissionDenied
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .storeLoadFailed(let message):
            return "Failed to load data store: \(message)"
        case .saveFailed(let message):
            return "Failed to save data: \(message)"
        case .migrationFailed(let message):
            return "Failed to migrate data: \(message)"
        case .insufficientStorage:
            return "Insufficient storage space. Please free up some space and try again."
        case .permissionDenied:
            return "Permission denied. Please check your device settings."
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .storeLoadFailed:
            return "Try restarting the app. If the problem persists, contact support."
        case .saveFailed:
            return "Try again in a moment. If the problem continues, restart the app."
        case .migrationFailed:
            return "Your data may need to be migrated. Please contact support."
        case .insufficientStorage:
            return "Delete some photos or apps to free up space, then try again."
        case .permissionDenied:
            return "Check that the app has permission to access your device storage."
        case .unknown:
            return "Try restarting the app. If the problem persists, contact support."
        }
    }
}

class CoreDataErrorHandler {
    static func handleStoreLoadError(_ error: NSError) -> CoreDataError {
        let errorCode = error.code
        let errorMessage = error.localizedDescription
        
        switch errorCode {
        case NSPersistentStoreIncompatibleVersionHashError:
            return .migrationFailed(errorMessage)
        case NSFileReadNoSuchFileError, NSFileReadNoPermissionError:
            return .permissionDenied
        case 28: // ENOSPC - No space left on device
            return .insufficientStorage
        default:
            return .storeLoadFailed(errorMessage)
        }
    }
    
    static func handleSaveError(_ error: NSError) -> CoreDataError {
        let errorCode = error.code
        let errorMessage = error.localizedDescription
        
        switch errorCode {
        case 28: // ENOSPC - No space left on device
            return .insufficientStorage
        case NSFileReadNoPermissionError, NSFileWriteNoPermissionError:
            return .permissionDenied
        default:
            return .saveFailed(errorMessage)
        }
    }
    
    static func logError(_ error: CoreDataError, context: String) {
        Logger.shared.coreDataError(error.localizedDescription, context: context)
        if let suggestion = error.recoverySuggestion {
            Logger.shared.debug("Suggestion: \(suggestion)", context: context)
        }
    }
}
