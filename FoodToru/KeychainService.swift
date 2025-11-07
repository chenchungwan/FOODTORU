//
//  KeychainService.swift
//  FoodToru
//
//  Created by Christine Chen on 9/14/25.
//

import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    private let logger = Logger.shared
    
    private init() {}
    
    private let service = "com.foodtoru.api"
    private let account = "claude_api_key"
    
    // MARK: - API Key Management
    
    func saveAPIKey(_ apiKey: String) -> Bool {
        guard !apiKey.isEmpty else { return false }
        
        // Delete existing key first
        _ = deleteAPIKey()
        
        let data = apiKey.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return apiKey
    }
    
    func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    func hasAPIKey() -> Bool {
        return getAPIKey() != nil
    }
    
    // MARK: - Pre-configured API Key
    
    /// Gets the pre-configured API key from environment variables only
    /// This is more secure than storing in Info.plist which can be extracted
    /// Environment variables are only available at runtime and not embedded in the app bundle
    private func getPreconfiguredAPIKey() -> String? {
        // Get from environment variable (for development/testing)
        // This is more secure as it's not embedded in the app bundle
        if let envKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        return nil
    }
    
    /// Initializes the Keychain with a pre-configured API key if available
    /// This is called automatically on app launch if no key exists in Keychain
    func initializePreconfiguredKeyIfNeeded() {
        // Check if there's already a valid key in Keychain
        if let existingKey = getAPIKey(), isValidAPIKey(existingKey) {
            logger.debug("Valid API key already exists in Keychain, skipping pre-configured key", context: "Keychain")
            return
        }
        
        // If there's an invalid key, clear it first
        if hasAPIKey() {
            logger.debug("Invalid API key found in Keychain, clearing it", context: "Keychain")
            _ = deleteAPIKey()
        }
        
        // Try to get pre-configured key
        if let preconfiguredKey = getPreconfiguredAPIKey() {
            logger.debug("Found pre-configured API key from environment variable", context: "Keychain")
            if isValidAPIKey(preconfiguredKey) {
                if saveAPIKey(preconfiguredKey) {
                    logger.info("Pre-configured API key successfully stored in Keychain", context: "Keychain")
                } else {
                    logger.logError("Failed to save pre-configured API key to Keychain", context: "Keychain")
                }
            } else {
                logger.warning("Pre-configured API key format is invalid. Expected format: sk-ant-...", context: "Keychain")
            }
        } else {
            logger.debug("No pre-configured API key found in environment variable CLAUDE_API_KEY", context: "Keychain")
        }
    }
    
    /// Force re-initialization of pre-configured key (useful for debugging)
    func forceReinitializePreconfiguredKey() {
        logger.debug("Force re-initializing pre-configured API key", context: "Keychain")
        _ = deleteAPIKey()
        initializePreconfiguredKeyIfNeeded()
    }
    
    // MARK: - Validation
    
    func isValidAPIKey(_ apiKey: String) -> Bool {
        return apiKey.hasPrefix("sk-ant-") && apiKey.count > 20
    }
    
    // MARK: - Debug Helpers (only for development)
    
    #if DEBUG
    func debugPrintKeychainStatus() {
        if getAPIKey() != nil {
            logger.keychainOperation("Status Check", success: true, context: "Keychain")
        } else {
            logger.keychainOperation("Status Check", success: false, context: "Keychain")
        }
        
        // Check if environment variable is set
        if let envKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] {
            logger.debug("Environment variable CLAUDE_API_KEY is set (length: \(envKey.count))", context: "Keychain")
        } else {
            logger.debug("Environment variable CLAUDE_API_KEY is NOT set", context: "Keychain")
        }
    }
    #endif
}
