//
//  LoginView.swift
//  LightGallery
//
//  Created by Kiro on 2025-12-06.
//

import SwiftUI

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
                // Apple Sign In Button
                Button(action: {
                    Task {
                        await viewModel.signIn(with: .apple)
                    }
                }) {
                    HStack {
                        Image(systemName: "apple.logo")
                            .font(.title3)
                        Text("使用 Apple ID 登录")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
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
            
            // Terms and Privacy
            VStack(spacing: 8) {
                Text("登录即表示您同意我们的")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Button("服务条款") {
                        // Open terms of service
                    }
                    .font(.caption)
                    
                    Text("和")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("隐私政策") {
                        // Open privacy policy
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
}

#Preview {
    LoginView()
}
