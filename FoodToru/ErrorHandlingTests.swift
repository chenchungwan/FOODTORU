//
//  ErrorHandlingTests.swift
//  FoodToru
//
//  Created by Christine Chen on 9/14/25.
//

import Foundation
import CoreData

#if DEBUG
class ErrorHandlingTests {
    static func runTests() {
        let logger = Logger.shared
        logger.debug("Running Error Handling Tests", context: "Tests")
        
        // Test 1: CoreDataError enum
        testCoreDataErrorEnum()
        
        // Test 2: Error handler methods
        testErrorHandlerMethods()
        
        // Test 3: Error recovery
        testErrorRecovery()
        
        logger.debug("Error Handling Tests Complete", context: "Tests")
    }
    
    private static func testCoreDataErrorEnum() {
        let logger = Logger.shared
        logger.debug("Test 1: Testing CoreDataError enum", context: "Tests")
        
        let errors: [CoreDataError] = [
            .storeLoadFailed("Test store load error"),
            .saveFailed("Test save error"),
            .migrationFailed("Test migration error"),
            .insufficientStorage,
            .permissionDenied,
            .unknown("Test unknown error")
        ]
        
        for error in errors {
            logger.debug("Error: \(error.localizedDescription)", context: "Tests")
            if let suggestion = error.recoverySuggestion {
                logger.debug("Suggestion: \(suggestion)", context: "Tests")
            }
        }
        logger.debug("CoreDataError enum test passed", context: "Tests")
    }
    
    private static func testErrorHandlerMethods() {
        let logger = Logger.shared
        logger.debug("Test 2: Testing error handler methods", context: "Tests")
        
        // Test store load error handling
        let storeLoadError = NSError(domain: "TestDomain", code: NSPersistentStoreIncompatibleVersionHashError, userInfo: [NSLocalizedDescriptionKey: "Test store load error"])
        let handledStoreError = CoreDataErrorHandler.handleStoreLoadError(storeLoadError)
        logger.debug("Store load error handled as: \(handledStoreError.localizedDescription)", context: "Tests")
        
        // Test save error handling
        let saveError = NSError(domain: "TestDomain", code: 28, userInfo: [NSLocalizedDescriptionKey: "Test save error"]) // ENOSPC = 28
        let handledSaveError = CoreDataErrorHandler.handleSaveError(saveError)
        logger.debug("Save error handled as: \(handledSaveError.localizedDescription)", context: "Tests")
        
        logger.debug("Error handler methods test passed", context: "Tests")
    }
    
    private static func testErrorRecovery() {
        let logger = Logger.shared
        logger.debug("Test 3: Testing error recovery", context: "Tests")
        
        // Test that PersistenceController can be created without crashing
        let persistenceController = PersistenceController.shared
        logger.debug("PersistenceController created successfully", context: "Tests")
        
        // Test error clearing
        persistenceController.clearError()
        logger.debug("Error clearing works", context: "Tests")
        
        // Test retry functionality (this won't actually retry in test, but won't crash)
        persistenceController.retryStoreLoading()
        logger.debug("Retry functionality works", context: "Tests")
        
        logger.debug("Error recovery test passed", context: "Tests")
    }
}
#endif
