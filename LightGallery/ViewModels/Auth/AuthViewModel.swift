//
//  AuthViewModel.swift
//  LightGallery
//
//  Created by Kiro on 2025-12-06.
//

import Foundation
import SwiftUI
import AuthenticationServices

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let authService: AuthenticationServiceProtocol
    
    init(authService: AuthenticationServiceProtocol = AuthenticationService.shared) {
        self.authService = authService
        self.currentUser = authService.getCurrentUser()
        self.isAuthenticated = currentUser != nil
    }
    
    func signIn(with provider: AuthProvider) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user: User
            switch provider {
            case .apple:
                user = try await authService.signInWithApple()
            case .wechat:
                user = try await authService.signInWithWeChat()
            case .alipay:
                user = try await authService.signInWithAlipay()
            }
            
            currentUser = user
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    func signOut() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func validateSession() async {
        isLoading = true
        
        do {
            let isValid = try await authService.validateSession()
            if isValid {
                currentUser = authService.getCurrentUser()
                isAuthenticated = true
            } else {
                currentUser = nil
                isAuthenticated = false
            }
        } catch {
            errorMessage = error.localizedDescription
            currentUser = nil
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    // MARK: - Apple Sign In Handler (App Store Guideline 4.8 Compliance)
    
    /// Handle the result from SignInWithAppleButton
    /// This method processes the authorization result from the official Apple Sign In button
    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .success(let authorization):
            do {
                // Extract credentials from authorization
                guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                    throw AuthError.invalidCredentials
                }
                
                // Get user identifier
                let userIdentifier = appleIDCredential.user
                
                // Get identity token
                guard let identityTokenData = appleIDCredential.identityToken,
                      let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                    throw AuthError.invalidCredentials
                }
                
                // Get authorization code
                guard let authorizationCodeData = appleIDCredential.authorizationCode,
                      let authorizationCode = String(data: authorizationCodeData, encoding: .utf8) else {
                    throw AuthError.invalidCredentials
                }
                
                // Get user info (only available on first sign in)
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email
                
                // Sign in with the extracted credentials
                let user = try await authService.signInWithApple(
                    userIdentifier: userIdentifier,
                    identityToken: identityToken,
                    authorizationCode: authorizationCode,
                    fullName: fullName,
                    email: email
                )
                
                currentUser = user
                isAuthenticated = true
                
            } catch {
                errorMessage = "Apple 登录失败: \(error.localizedDescription)"
                isAuthenticated = false
            }
            
        case .failure(let error):
            // Handle user cancellation gracefully
            if let authError = error as? ASAuthorizationError,
               authError.code == .canceled {
                // User cancelled, don't show error
                errorMessage = nil
            } else {
                errorMessage = "Apple 登录失败: \(error.localizedDescription)"
            }
            isAuthenticated = false
        }
        
        isLoading = false
    }
}
