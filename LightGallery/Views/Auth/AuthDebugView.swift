//
//  AuthDebugView.swift
//  LightGallery
//
//  Created by Kiro on 2025-12-14.
//

import SwiftUI

struct AuthDebugView: View {
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                Section("认证模式") {
                    HStack {
                        Text("当前模式")
                        Spacer()
                        Text(AuthConfig.currentMode == .mock ? "模拟模式" : "生产模式")
                            .foregroundColor(AuthConfig.currentMode == .mock ? .orange : .green)
                    }
                    
                    if AuthConfig.currentMode == .mock {
                        Text("当前使用模拟认证服务，所有登录都会成功")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("OAuth 提供商状态") {
                    HStack {
                        Image(systemName: "applelogo")
                        Text("Apple 登录")
                        Spacer()
                        Text(AuthConfig.OAuthProviders.Apple.isEnabled ? "已启用" : "未启用")
                            .foregroundColor(AuthConfig.OAuthProviders.Apple.isEnabled ? .green : .red)
                    }
                    
                    HStack {
                        Image(systemName: "message.fill")
                            .foregroundColor(.green)
                        Text("微信登录")
                        Spacer()
                        Text(AuthConfig.OAuthProviders.WeChat.isEnabled ? "已配置" : "未配置")
                            .foregroundColor(AuthConfig.OAuthProviders.WeChat.isEnabled ? .green : .red)
                    }
                    
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.blue)
                        Text("支付宝登录")
                        Spacer()
                        Text(AuthConfig.OAuthProviders.Alipay.isEnabled ? "已配置" : "未配置")
                            .foregroundColor(AuthConfig.OAuthProviders.Alipay.isEnabled ? .green : .red)
                    }
                }
                
                Section("后端配置") {
                    HStack {
                        Text("环境")
                        Spacer()
                        Text("\(AuthConfig.Backend.currentEnvironment)")
                    }
                    
                    HStack {
                        Text("API 地址")
                        Spacer()
                        Text(AuthConfig.Backend.baseURL)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("配置说明") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("要启用真实的登录功能，请完成以下步骤：")
                            .font(.headline)
                        
                        Text("1. Apple 登录")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("• 在 Apple Developer 中心启用 Sign in with Apple")
                        Text("• 确保 Bundle ID 和 Team ID 配置正确")
                        
                        Text("2. 微信登录")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("• 在微信开放平台注册应用")
                        Text("• 获取 App ID 并配置到 AuthConfig.swift")
                        Text("• 配置 URL Scheme 和 Universal Link")
                        
                        Text("3. 支付宝登录")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("• 在支付宝开放平台注册应用")
                        Text("• 获取 App ID 并配置到 AuthConfig.swift")
                        Text("• 配置 URL Scheme")
                        
                        Text("4. 后端服务")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("• 启动后端服务")
                        Text("• 更新 AuthConfig.swift 中的 API 地址")
                        Text("• 将 AuthConfig.currentMode 改为 .production")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("认证调试")
            .alert("提示", isPresented: $showingAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
}