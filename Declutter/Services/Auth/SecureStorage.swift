//
//  SecureStorage.swift
//  Declutter
//
//  Created by Kiro on 2025-12-06.
//

import Foundation
import Security

/// Secure storage for authentication tokens using Keychain
class SecureStorage {
    static let shared = SecureStorage()
    
    private let service = "com.lightgallery.auth"
    
    private init() {}
    
    /// Saves an auth token to Keychain
    /// - Parameters:
    ///   - token: The auth token to store
    ///   - userId: The user ID associated with the token
    /// - Throws: SecureStorageError if save fails
    func saveAuthToken(_ token: String, for userId: String) throws {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: userId,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Delete any existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw SecureStorageError.saveFailed(status: status)
        }
    }
    
    /// Retrieves an auth token from Keychain
    /// - Parameter userId: The user ID associated with the token
    /// - Returns: The auth token if found, nil otherwise
    /// - Throws: SecureStorageError if retrieval fails
    func getAuthToken(for userId: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: userId,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw SecureStorageError.retrievalFailed(status: status)
        }
        
        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw SecureStorageError.invalidData
        }
        
        return token
    }
    
    /// Deletes an auth token from Keychain
    /// - Parameter userId: The user ID associated with the token
    /// - Throws: SecureStorageError if deletion fails
    func deleteAuthToken(for userId: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: userId
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // Success if item was deleted or didn't exist
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureStorageError.deletionFailed(status: status)
        }
    }
    
    /// Saves user credentials to Keychain
    /// - Parameter credentials: The user credentials to store
    /// - Throws: SecureStorageError if save fails
    func saveCredentials(_ credentials: UserCredentials) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(credentials)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "user_credentials",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Delete any existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw SecureStorageError.saveFailed(status: status)
        }
    }
    
    /// Retrieves user credentials from Keychain
    /// - Returns: The user credentials if found, nil otherwise
    /// - Throws: SecureStorageError if retrieval fails
    func getCredentials() throws -> UserCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "user_credentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw SecureStorageError.retrievalFailed(status: status)
        }
        
        guard let data = result as? Data else {
            throw SecureStorageError.invalidData
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(UserCredentials.self, from: data)
    }
    
    /// Deletes all stored credentials
    /// - Throws: SecureStorageError if deletion fails
    func deleteAllCredentials() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // Success if items were deleted or didn't exist
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureStorageError.deletionFailed(status: status)
        }
    }
}

/// User credentials stored in Keychain
struct UserCredentials: Codable {
    let userId: String
    var authToken: AuthToken
    let provider: AuthProvider
}

/// Errors that can occur during secure storage operations
enum SecureStorageError: LocalizedError {
    case saveFailed(status: OSStatus)
    case retrievalFailed(status: OSStatus)
    case deletionFailed(status: OSStatus)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "保存到 Keychain 失败: \(status)"
        case .retrievalFailed(let status):
            return "从 Keychain 读取失败: \(status)"
        case .deletionFailed(let status):
            return "从 Keychain 删除失败: \(status)"
        case .invalidData:
            return "无效的数据格式"
        }
    }
}
