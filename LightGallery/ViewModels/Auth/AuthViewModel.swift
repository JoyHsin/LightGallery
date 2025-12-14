//
//  AuthViewModel.swift
//  LightGallery
//
//  Created by Kiro on 2025-12-06.
//

import Foundation
import SwiftUI

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
}
