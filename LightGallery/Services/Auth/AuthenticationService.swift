//
//  AuthenticationService.swift
//  LightGallery
//
//  Created by Kiro on 2025-12-06.
//

import Foundation
import Contacts

protocol AuthenticationServiceProtocol {
    /// 使用 Apple ID 登录 (legacy method)
    func signInWithApple() async throws -> User
    
    /// 使用 Apple ID 登录 (with credentials from SignInWithAppleButton)
    /// App Store Guideline 4.8 Compliance
    func signInWithApple(
        userIdentifier: String,
        identityToken: String,
        authorizationCode: String,
        fullName: PersonNameComponents?,
        email: String?
    ) async throws -> User
    
    /// 使用微信登录
    func signInWithWeChat() async throws -> User
    
    /// 使用支付宝登录
    func signInWithAlipay() async throws -> User
    
    /// 验证当前会话
    func validateSession() async throws -> Bool
    
    /// 登出
    func signOut() async throws
    
    /// 获取当前用户
    func getCurrentUser() -> User?
    
    /// 刷新认证令牌
    func refreshAuthToken() async throws -> String
}

class AuthenticationService: AuthenticationServiceProtocol {
    static let shared = AuthenticationService()
    
    private var currentUser: User?
    private let appleSignInManager = AppleSignInManager()
    private let wechatManager = WeChatOAuthManager()
    private let alipayManager = AlipayOAuthManager()
    private let secureStorage = SecureStorage.shared
    private let backendClient: BackendAPIClient
    
    init(backendClient: BackendAPIClient = .shared) {
        self.backendClient = backendClient
    }
    
    private convenience init() {
        self.init(backendClient: .shared)
    }
    
    func signInWithApple() async throws -> User {
        // Initiate Apple Sign In flow
        let credential = try await appleSignInManager.initiateSignIn()
        
        // Exchange OAuth credential with backend
        let oauthCredential = OAuthCredential(
            provider: .apple,
            authCode: credential.authorizationCode,
            idToken: credential.identityToken,
            email: credential.email,
            displayName: formatDisplayName(from: credential.fullName)
        )
        
        let authResponse = try await backendClient.exchangeOAuthToken(oauthCredential)
        
        // Create user from backend response
        let user = User(
            id: authResponse.user.id,
            displayName: authResponse.user.displayName,
            email: authResponse.user.email,
            avatarURL: authResponse.user.avatarURL.flatMap { URL(string: $0) },
            authProvider: .apple
        )
        
        // Create auth token from backend response
        let authToken = AuthToken(
            accessToken: authResponse.accessToken,
            refreshToken: authResponse.refreshToken,
            expiresAt: authResponse.expiresAt,
            tokenType: "Bearer"
        )
        
        // Store token securely in Keychain
        try secureStorage.saveAuthToken(authToken.accessToken, for: user.id)
        
        // Store user credentials
        let credentials = UserCredentials(
            userId: user.id,
            authToken: authToken,
            provider: .apple
        )
        try secureStorage.saveCredentials(credentials)
        
        // Update current user
        currentUser = user
        
        // 发送登录成功通知
        NotificationCenter.default.post(name: .userDidLogin, object: user)
        
        return user
    }
    
    /// Formats a display name from PersonNameComponents
    private func formatDisplayName(from nameComponents: PersonNameComponents?) -> String? {
        guard let nameComponents = nameComponents else { return nil }
        
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .default
        let formattedName = formatter.string(from: nameComponents)
        
        return formattedName.isEmpty ? nil : formattedName
    }
    
    // MARK: - Apple Sign In with Credentials (App Store Guideline 4.8 Compliance)
    
    /// Sign in with Apple using credentials from SignInWithAppleButton
    /// This method is used when the official Apple Sign In button is used
    func signInWithApple(
        userIdentifier: String,
        identityToken: String,
        authorizationCode: String,
        fullName: PersonNameComponents?,
        email: String?
    ) async throws -> User {
        // Exchange OAuth credential with backend
        let oauthCredential = OAuthCredential(
            provider: .apple,
            authCode: authorizationCode,
            idToken: identityToken,
            email: email,
            displayName: formatDisplayName(from: fullName)
        )
        
        let authResponse = try await backendClient.exchangeOAuthToken(oauthCredential)
        
        // Create user from backend response
        let user = User(
            id: authResponse.user.id,
            displayName: authResponse.user.displayName,
            email: authResponse.user.email,
            avatarURL: authResponse.user.avatarURL.flatMap { URL(string: $0) },
            authProvider: .apple
        )
        
        // Create auth token from backend response
        let authToken = AuthToken(
            accessToken: authResponse.accessToken,
            refreshToken: authResponse.refreshToken,
            expiresAt: authResponse.expiresAt,
            tokenType: "Bearer"
        )
        
        // Store token securely in Keychain
        try secureStorage.saveAuthToken(authToken.accessToken, for: user.id)
        
        // Store user credentials
        let credentials = UserCredentials(
            userId: user.id,
            authToken: authToken,
            provider: .apple
        )
        try secureStorage.saveCredentials(credentials)
        
        // Update current user
        currentUser = user
        
        // 发送登录成功通知
        NotificationCenter.default.post(name: .userDidLogin, object: user)
        
        return user
    }
    
    func signInWithWeChat() async throws -> User {
        // Initiate WeChat OAuth flow
        let credential = try await wechatManager.initiateSignIn()
        
        // Exchange OAuth credential with backend
        let oauthCredential = OAuthCredential(
            provider: .wechat,
            authCode: credential.code,
            idToken: nil,
            email: nil,
            displayName: nil
        )
        
        let authResponse = try await backendClient.exchangeOAuthToken(oauthCredential)
        
        // Create user from backend response
        let user = User(
            id: authResponse.user.id,
            displayName: authResponse.user.displayName,
            email: authResponse.user.email,
            avatarURL: authResponse.user.avatarURL.flatMap { URL(string: $0) },
            authProvider: .wechat
        )
        
        // Create auth token from backend response
        let authToken = AuthToken(
            accessToken: authResponse.accessToken,
            refreshToken: authResponse.refreshToken,
            expiresAt: authResponse.expiresAt,
            tokenType: "Bearer"
        )
        
        // Store token securely in Keychain
        try secureStorage.saveAuthToken(authToken.accessToken, for: user.id)
        
        // Store user credentials
        let credentials = UserCredentials(
            userId: user.id,
            authToken: authToken,
            provider: .wechat
        )
        try secureStorage.saveCredentials(credentials)
        
        // Update current user
        currentUser = user
        
        // 发送登录成功通知
        NotificationCenter.default.post(name: .userDidLogin, object: user)
        
        return user
    }
    
    func signInWithAlipay() async throws -> User {
        // Initiate Alipay OAuth flow
        let credential = try await alipayManager.initiateSignIn()
        
        // Exchange OAuth credential with backend
        let oauthCredential = OAuthCredential(
            provider: .alipay,
            authCode: credential.code,
            idToken: nil,
            email: nil,
            displayName: nil
        )
        
        let authResponse = try await backendClient.exchangeOAuthToken(oauthCredential)
        
        // Create user from backend response
        let user = User(
            id: authResponse.user.id,
            displayName: authResponse.user.displayName,
            email: authResponse.user.email,
            avatarURL: authResponse.user.avatarURL.flatMap { URL(string: $0) },
            authProvider: .alipay
        )
        
        // Create auth token from backend response
        let authToken = AuthToken(
            accessToken: authResponse.accessToken,
            refreshToken: authResponse.refreshToken,
            expiresAt: authResponse.expiresAt,
            tokenType: "Bearer"
        )
        
        // Store token securely in Keychain
        try secureStorage.saveAuthToken(authToken.accessToken, for: user.id)
        
        // Store user credentials
        let credentials = UserCredentials(
            userId: user.id,
            authToken: authToken,
            provider: .alipay
        )
        try secureStorage.saveCredentials(credentials)
        
        // Update current user
        currentUser = user
        
        // 发送登录成功通知
        NotificationCenter.default.post(name: .userDidLogin, object: user)
        
        return user
    }
    
    func validateSession() async throws -> Bool {
        // Try to retrieve stored credentials
        guard let credentials = try? secureStorage.getCredentials() else {
            // No credentials found, session is invalid
            return false
        }
        
        // Check if token is expired
        if credentials.authToken.isExpired {
            // Token is expired, try to refresh it
            do {
                let newToken = try await refreshAuthToken()
                // If refresh succeeds, update stored credentials
                var updatedCredentials = credentials
                updatedCredentials.authToken = AuthToken(
                    accessToken: newToken,
                    refreshToken: credentials.authToken.refreshToken,
                    expiresAt: Date().addingTimeInterval(86400), // 24 hours
                    tokenType: credentials.authToken.tokenType
                )
                try secureStorage.saveCredentials(updatedCredentials)
                
                // Restore user session
                currentUser = User(
                    id: credentials.userId,
                    displayName: "", // Will be populated from backend in production
                    authProvider: credentials.provider
                )
                return true
            } catch {
                // Refresh failed, clear session data
                try? secureStorage.deleteAllCredentials()
                currentUser = nil
                throw AuthError.tokenExpired
            }
        }
        
        // Token is valid, restore user session
        currentUser = User(
            id: credentials.userId,
            displayName: "", // Will be populated from backend in production
            authProvider: credentials.provider
        )
        return true
    }
    
    func signOut() async throws {
        // Get current user ID before clearing
        guard let userId = currentUser?.id else {
            // No user logged in, nothing to do
            return
        }
        
        // Delete auth token from Keychain
        try secureStorage.deleteAuthToken(for: userId)
        
        // Delete all credentials from Keychain
        try secureStorage.deleteAllCredentials()
        
        // Clear current user
        currentUser = nil
        
        // 发送登出通知
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }
    
    func getCurrentUser() -> User? {
        return currentUser
    }
    
    func refreshAuthToken() async throws -> String {
        // Retrieve stored credentials
        guard let credentials = try? secureStorage.getCredentials() else {
            throw AuthError.tokenInvalid
        }
        
        // Call backend API to refresh the token
        let authResponse = try await backendClient.refreshAuthToken(credentials.authToken.refreshToken)
        
        // Update stored credentials with new token
        let newAuthToken = AuthToken(
            accessToken: authResponse.accessToken,
            refreshToken: authResponse.refreshToken,
            expiresAt: authResponse.expiresAt,
            tokenType: "Bearer"
        )
        
        var updatedCredentials = credentials
        updatedCredentials.authToken = newAuthToken
        try secureStorage.saveCredentials(updatedCredentials)
        
        // Update stored auth token
        try secureStorage.saveAuthToken(newAuthToken.accessToken, for: credentials.userId)
        
        return newAuthToken.accessToken
    }
}
