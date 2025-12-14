//
//  LoginPromptManager.swift
//  LightGallery
//
//  Created for login prompt management
//

import Foundation
import SwiftUI

/// 管理登录提示的全局服务
class LoginPromptManager: ObservableObject {
    static let shared = LoginPromptManager()
    
    @Published var showLoginAlert = false
    @Published var showLoginView = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var pendingFeature: PremiumFeature?
    @Published var pendingProduct: SubscriptionProduct?
    
    private init() {
        setupNotificationListeners()
    }
    
    private func setupNotificationListeners() {
        // 监听功能访问需要登录的通知
        NotificationCenter.default.addObserver(
            forName: .loginRequiredForFeature,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            if let feature = notification.userInfo?["feature"] as? PremiumFeature {
                self.pendingFeature = feature
                self.alertTitle = "需要登录"
                self.alertMessage = "使用\(feature.displayName)功能需要登录账户，请先登录后再试"
                self.showLoginAlert = true
            }
        }
        
        // 监听订阅需要登录的通知
        NotificationCenter.default.addObserver(
            forName: .loginRequiredForSubscription,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            if let product = notification.object as? SubscriptionProduct {
                self.pendingProduct = product
                self.alertTitle = "需要登录"
                self.alertMessage = "订阅功能需要登录账户，请先登录后再进行订阅"
                self.showLoginAlert = true
            }
        }
    }
    
    /// 显示登录界面
    func showLogin() {
        showLoginView = true
    }
    
    /// 取消登录提示
    func cancelLogin() {
        showLoginAlert = false
        pendingFeature = nil
        pendingProduct = nil
    }
    
    /// 处理登录成功后的操作
    func handleLoginSuccess() {
        showLoginView = false
        
        // 如果有待处理的订阅产品，继续购买流程
        if let product = pendingProduct {
            Task { @MainActor in
                let subscriptionViewModel = SubscriptionViewModel()
                await subscriptionViewModel.purchase(product)
            }
            pendingProduct = nil
        }
        
        // 如果有待处理的功能，显示付费墙
        if let feature = pendingFeature {
            FeatureAccessManager.shared.showPaywall(for: feature)
            pendingFeature = nil
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}