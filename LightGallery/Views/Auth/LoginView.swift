//
//  LoginView.swift
//  LightGallery
//
//  Created by Kiro on 2025-12-06.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // App Logo and Title
            VStack(spacing: 16) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("LightGallery")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("轻松管理您的照片")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Login Buttons
            VStack(spacing: 16) {
                // Apple Sign In Button (App Store Guideline 4.8 Compliance)
                // Using official SignInWithAppleButton for HIG compliance
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    Task {
                        await viewModel.handleAppleSignInResult(result)
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .cornerRadius(12)
                
                // WeChat Login Button
                Button(action: {
                    Task {
                        await viewModel.signIn(with: .wechat)
                    }
                }) {
                    HStack {
                        Image(systemName: "message.fill")
                            .font(.title3)
                        Text("使用微信登录")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // Alipay Login Button
                Button(action: {
                    Task {
                        await viewModel.signIn(with: .alipay)
                    }
                }) {
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .font(.title3)
                        Text("使用支付宝登录")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)
            
            // Error Message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Terms and Privacy (App Store Guideline 5.1.1 Compliance)
            VStack(spacing: 8) {
                Text("登录即表示您同意我们的")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Button("服务条款") {
                        openURL(AppConstants.termsOfServiceURL)
                    }
                    .font(.caption)
                    
                    Text("和")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("隐私政策") {
                        openURL(AppConstants.privacyPolicyURL)
                    }
                    .font(.caption)
                }
            }
            .padding(.bottom, 32)
        }
        .overlay {
            if viewModel.isLoading {
                AuthLoadingView()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }
}

#Preview {
    LoginView()
}
