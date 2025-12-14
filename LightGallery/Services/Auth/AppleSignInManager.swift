//
//  AppleSignInManager.swift
//  LightGallery
//
//  Created by Kiro on 2025-12-06.
//

import Foundation
import AuthenticationServices
import Contacts
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Apple Sign In credential data
struct AppleIDCredential {
    let userID: String
    let email: String?
    let fullName: PersonNameComponents?
    let identityToken: String
    let authorizationCode: String
}

/// Manager for handling Apple Sign In authentication
class AppleSignInManager: NSObject {
    
    // Continuation to bridge callback-based API to async/await
    private var signInContinuation: CheckedContinuation<AppleIDCredential, Error>?
    
    /// Initiates the Apple Sign In flow
    /// - Returns: AppleIDCredential containing user information
    /// - Throws: AuthError if sign in fails
    func initiateSignIn() async throws -> AppleIDCredential {
        return try await withCheckedThrowingContinuation { continuation in
            self.signInContinuation = continuation
            
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            
            // Perform the authorization request
            controller.performRequests()
        }
    }
    
    /// Processes the Apple ID credential from the authorization callback
    /// - Parameter credential: The ASAuthorizationAppleIDCredential from Apple
    /// - Returns: AppleIDCredential with extracted user information
    /// - Throws: AuthError if credential processing fails
    private func processAppleCredential(_ credential: ASAuthorizationAppleIDCredential) throws -> AppleIDCredential {
        // Extract identity token
        guard let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            throw AuthError.oauthFailed(provider: .apple, reason: "无法获取身份令牌")
        }
        
        // Extract authorization code
        guard let authorizationCodeData = credential.authorizationCode,
              let authorizationCode = String(data: authorizationCodeData, encoding: .utf8) else {
            throw AuthError.oauthFailed(provider: .apple, reason: "无法获取授权码")
        }
        
        return AppleIDCredential(
            userID: credential.user,
            email: credential.email,
            fullName: credential.fullName,
            identityToken: identityToken,
            authorizationCode: authorizationCode
        )
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleSignInManager: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            signInContinuation?.resume(throwing: AuthError.oauthFailed(provider: .apple, reason: "无效的凭证类型"))
            signInContinuation = nil
            return
        }
        
        do {
            let appleCredential = try processAppleCredential(credential)
            signInContinuation?.resume(returning: appleCredential)
        } catch {
            signInContinuation?.resume(throwing: error)
        }
        
        signInContinuation = nil
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let authError: AuthError
        
        if let asError = error as? ASAuthorizationError {
            switch asError.code {
            case .canceled:
                authError = .userCancelled
            case .failed:
                authError = .oauthFailed(provider: .apple, reason: "认证失败")
            case .invalidResponse:
                authError = .oauthFailed(provider: .apple, reason: "无效的响应")
            case .notHandled:
                authError = .oauthFailed(provider: .apple, reason: "请求未处理")
            case .unknown:
                authError = .oauthFailed(provider: .apple, reason: "未知错误")
            case .notInteractive:
                authError = .oauthFailed(provider: .apple, reason: "非交互式认证失败")
            case .matchedExcludedCredential:
                authError = .oauthFailed(provider: .apple, reason: "匹配到排除的凭据")
            case .credentialImport:
                authError = .oauthFailed(provider: .apple, reason: "凭据导入失败")
            case .credentialExport:
                authError = .oauthFailed(provider: .apple, reason: "凭据导出失败")
            case .preferSignInWithApple:
                authError = .oauthFailed(provider: .apple, reason: "建议使用Apple登录")
            case .deviceNotConfiguredForPasskeyCreation:
                authError = .oauthFailed(provider: .apple, reason: "设备未配置通行密钥创建")
            @unknown default:
                authError = .unknownError(error)
            }
        } else {
            authError = .unknownError(error)
        }
        
        signInContinuation?.resume(throwing: authError)
        signInContinuation = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the key window for presenting the authorization UI
        #if os(iOS)
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
        #elseif os(macOS)
        return NSApplication.shared.windows.first ?? NSWindow()
        #endif
    }
}