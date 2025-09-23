//
//  KeychainServiceTests.swift
//  FoodToru
//
//  Created by Christine Chen on 9/14/25.
//

import Foundation

#if DEBUG
class KeychainServiceTests {
    static func runTests() {
        let logger = Logger.shared
        logger.debug("Running KeychainService Tests", context: "Tests")
        
        let keychain = KeychainService.shared
        let testKey = "sk-ant-test123456789012345678901234567890"
        
        // Test 1: Save API key
        logger.debug("Test 1: Saving API key", context: "Tests")
        let saveResult = keychain.saveAPIKey(testKey)
        logger.debug("Save result: \(saveResult ? "Success" : "Failed")", context: "Tests")
        
        // Test 2: Retrieve API key
        logger.debug("Test 2: Retrieving API key", context: "Tests")
        if let retrievedKey = keychain.getAPIKey() {
            logger.debug("Keys match: \(retrievedKey == testKey ? "Yes" : "No")", context: "Tests")
        } else {
            logger.debug("Failed to retrieve key", context: "Tests")
        }
        
        // Test 3: Check if key exists
        logger.debug("Test 3: Checking if key exists", context: "Tests")
        let hasKey = keychain.hasAPIKey()
        logger.debug("Has key: \(hasKey ? "Yes" : "No")", context: "Tests")
        
        // Test 4: Validate key format
        logger.debug("Test 4: Validating key format", context: "Tests")
        let isValid = keychain.isValidAPIKey(testKey)
        logger.debug("Is valid: \(isValid ? "Yes" : "No")", context: "Tests")
        
        // Test 5: Delete API key
        logger.debug("Test 5: Deleting API key", context: "Tests")
        let deleteResult = keychain.deleteAPIKey()
        logger.debug("Delete result: \(deleteResult ? "Success" : "Failed")", context: "Tests")
        
        // Test 6: Verify deletion
        logger.debug("Test 6: Verifying deletion", context: "Tests")
        let hasKeyAfterDelete = keychain.hasAPIKey()
        logger.debug("Has key after delete: \(hasKeyAfterDelete ? "Yes (should be No)" : "No")", context: "Tests")
        
        logger.debug("KeychainService Tests Complete", context: "Tests")
    }
}
#endif
