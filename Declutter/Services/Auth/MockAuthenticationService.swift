//
//  MockAuthenticationService.swift
//  Declutter
//
//  Created by Kiro on 2025-12-14.
//

import Foundation
import Contacts

/// Mock authentication service for testing when backend is not available
class MockAuthenticationService: AuthenticationServiceProtocol {
    private var currentUser: User?
    private let secureStorage = SecureStorage.shared
    
    func signInWithApple() async throws -> User {
        // Simulate Apple Sign In
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        let user = User(
            id: "mock_apple_user_\(UUID().uuidString)",
            displayName: "Apple 用户",
            email: "apple.user@example.com",
            avatarURL: nil,
            authProvider: .apple
        )
        
        // Create mock auth token
        let authToken = AuthToken(
            accessToken: "mock_access_token_\(UUID().uuidString)",
            refreshToken: "mock_refresh_token_\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(86400), // 24 hours
            tokenType: "Bearer"
        )
        
        // Store mock credentials
        try secureStorage.saveAuthToken(authToken.accessToken, for: user.id)
        let credentials = UserCredentials(
            userId: user.id,
            authToken: authToken,
            provider: .apple
        )
        try secureStorage.saveCredentials(credentials)
        
        currentUser = user
        
        // Send login notification
        NotificationCenter.default.post(name: .userDidLogin, object: user)
        
        return user
    }
    
    func signInWithApple(
        userIdentifier: String,
        identityToken: String,
        authorizationCode: String,
        fullName: PersonNameComponents?,
        email: String?
    ) async throws -> User {
        // Simulate Apple Sign In with credentials
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        let displayName: String
        if let fullName = fullName {
            let formatter = PersonNameComponentsFormatter()
            formatter.style = .default
            displayName = formatter.string(from: fullName)
        } else {
            displayName = "Apple 用户"
        }
        
        let user = User(
            id: userIdentifier,
            displayName: displayName,
            email: email ?? "apple.user@example.com",
            avatarURL: nil,
            authProvider: .apple
        )
        
        // Create mock auth token
        let authToken = AuthToken(
            accessToken: "mock_access_token_\(UUID().uuidString)",
            refreshToken: "mock_refresh_token_\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(86400), // 24 hours
            tokenType: "Bearer"
        )
        
        // Store mock credentials
        try secureStorage.saveAuthToken(authToken.accessToken, for: user.id)
        let credentials = UserCredentials(
            userId: user.id,
            authToken: authToken,
            provider: .apple
        )
        try secureStorage.saveCredentials(credentials)
        
        currentUser = user
        
        // Send login notification
        NotificationCenter.default.post(name: .userDidLogin, object: user)
        
        return user
    }
    
    func signInWithWeChat() async throws -> User {
        // Simulate WeChat Sign In
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 second delay
        
        let user = User(
            id: "mock_wechat_user_\(UUID().uuidString)",
            displayName: "微信用户",
            email: "wechat.user@example.com",
            avatarURL: nil,
            authProvider: .wechat
        )
        
        // Create mock auth token
        let authToken = AuthToken(
            accessToken: "mock_access_token_\(UUID().uuidString)",
            refreshToken: "mock_refresh_token_\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(86400), // 24 hours
            tokenType: "Bearer"
        )
        
        // Store mock credentials
        try secureStorage.saveAuthToken(authToken.accessToken, for: user.id)
        let credentials = UserCredentials(
            userId: user.id,
            authToken: authToken,
            provider: .wechat
        )
        try secureStorage.saveCredentials(credentials)
        
        currentUser = user
        
        // Send login notification
        NotificationCenter.default.post(name: .userDidLogin, object: user)
        
        return user
    }
    
    func signInWithAlipay() async throws -> User {
        // Simulate Alipay Sign In
        try await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 second delay
        
        let user = User(
            id: "mock_alipay_user_\(UUID().uuidString)",
            displayName: "支付宝用户",
            email: "alipay.user@example.com",
            avatarURL: nil,
            authProvider: .alipay
        )
        
        // Create mock auth token
        let authToken = AuthToken(
            accessToken: "mock_access_token_\(UUID().uuidString)",
            refreshToken: "mock_refresh_token_\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(86400), // 24 hours
            tokenType: "Bearer"
        )
        
        // Store mock credentials
        try secureStorage.saveAuthToken(authToken.accessToken, for: user.id)
        let credentials = UserCredentials(
            userId: user.id,
            authToken: authToken,
            provider: .alipay
        )
        try secureStorage.saveCredentials(credentials)
        
        currentUser = user
        
        // Send login notification
        NotificationCenter.default.post(name: .userDidLogin, object: user)
        
        return user
    }
    
    func validateSession() async throws -> Bool {
        // Check if we have stored credentials
        guard let credentials = try? secureStorage.getCredentials() else {
            return false
        }
        
        // Check if token is expired
        if credentials.authToken.isExpired {
            return false
        }
        
        // Restore user session
        currentUser = User(
            id: credentials.userId,
            displayName: "模拟用户",
            authProvider: credentials.provider
        )
        
        return true
    }
    
    func signOut() async throws {
        // Clear stored credentials
        if let userId = currentUser?.id {
            try secureStorage.deleteAuthToken(for: userId)
        }
        try secureStorage.deleteAllCredentials()
        
        currentUser = nil
        
        // Send logout notification
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }
    
    func getCurrentUser() -> User? {
        return currentUser
    }
    
    func refreshAuthToken() async throws -> String {
        // Simulate token refresh
        let newToken = "mock_refreshed_token_\(UUID().uuidString)"
        
        // Update stored credentials if available
        if let credentials = try? secureStorage.getCredentials() {
            let newAuthToken = AuthToken(
                accessToken: newToken,
                refreshToken: credentials.authToken.refreshToken,
                expiresAt: Date().addingTimeInterval(86400), // 24 hours
                tokenType: "Bearer"
            )
            
            var updatedCredentials = credentials
            updatedCredentials.authToken = newAuthToken
            try secureStorage.saveCredentials(updatedCredentials)
            try secureStorage.saveAuthToken(newToken, for: credentials.userId)
        }
        
        return newToken
    }
}