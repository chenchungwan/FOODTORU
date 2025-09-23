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
    }
    #endif
}
