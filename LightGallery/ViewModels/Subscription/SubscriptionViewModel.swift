//
//  SubscriptionViewModel.swift
//  LightGallery
//
//  Created for user-auth-subscription feature
//

import Foundation
import SwiftUI

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var currentSubscription: Subscription?
    @Published var availableProducts: [SubscriptionProduct] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let subscriptionService: SubscriptionServiceProtocol
    
    init(subscriptionService: SubscriptionServiceProtocol = SubscriptionService()) {
        self.subscriptionService = subscriptionService
    }
    
    /// Load available subscription products
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            availableProducts = try await subscriptionService.fetchAvailableProducts()
        } catch {
            errorMessage = "加载产品失败: \(error.localizedDescription)"
            print("Failed to load products: \(error)")
        }
        
        isLoading = false
    }
    
    /// Purchase a subscription product
    func purchase(_ product: SubscriptionProduct) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await subscriptionService.purchase(product)
            
            if result.success, let subscription = result.subscription {
                currentSubscription = subscription
                // Update FeatureAccessManager with new subscription
                FeatureAccessManager.shared.updateSubscription(subscription)
            } else if let error = result.error {
                errorMessage = "购买失败: \(error.localizedDescription)"
            }
        } catch {
            if let subscriptionError = error as? SubscriptionError {
                errorMessage = subscriptionError.errorDescription
            } else {
                errorMessage = "购买失败: \(error.localizedDescription)"
            }
            print("Purchase failed: \(error)")
        }
        
        isLoading = false
    }
    
    /// Restore previous purchases
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let subscriptions = try await subscriptionService.restorePurchases()
            
            if let activeSubscription = subscriptions.first(where: { $0.isActive }) {
                currentSubscription = activeSubscription
            } else {
                errorMessage = "未找到有效的订阅"
            }
        } catch {
            errorMessage = "恢复购买失败: \(error.localizedDescription)"
            print("Restore purchases failed: \(error)")
        }
        
        isLoading = false
    }
    
    /// Check current subscription status
    func checkSubscriptionStatus() async {
        isLoading = true
        errorMessage = nil
        
        do {
            currentSubscription = try await subscriptionService.getCurrentSubscription()
        } catch {
            errorMessage = "检查订阅状态失败: \(error.localizedDescription)"
            print("Check subscription status failed: \(error)")
        }
        
        isLoading = false
    }
    
    /// Upgrade to a higher tier
    func upgradeSubscription(to tier: SubscriptionTier) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await subscriptionService.upgradeSubscription(to: tier)
            
            if result.success, let subscription = result.subscription {
                currentSubscription = subscription
            } else if let error = result.error {
                errorMessage = "升级失败: \(error.localizedDescription)"
            }
        } catch {
            errorMessage = "升级失败: \(error.localizedDescription)"
            print("Upgrade failed: \(error)")
        }
        
        isLoading = false
    }
    
    /// Check if user can access a premium feature
    func canAccessFeature(_ feature: PremiumFeature) -> Bool {
        guard let subscription = currentSubscription else {
            return false
        }
        
        // Check if subscription is expired
        if subscription.isExpired {
            return false
        }
        
        return subscription.isActive && subscription.tier.features.contains(feature)
    }
    
    /// Get the required tier for a feature
    func requiredTier(for feature: PremiumFeature) -> SubscriptionTier {
        // All premium features require at least Pro tier
        return .pro
    }
    
    /// Check if subscription is expired
    var isSubscriptionExpired: Bool {
        guard let subscription = currentSubscription else {
            return false
        }
        return subscription.isExpired
    }
    
    /// Check subscription expiration on app launch
    func checkExpirationOnLaunch() async {
        do {
            let isExpired = try await subscriptionService.checkAndHandleExpiration()
            
            if isExpired {
                // Refresh current subscription to get updated status
                await checkSubscriptionStatus()
            }
        } catch {
            print("Failed to check subscription expiration: \(error)")
        }
    }
    
    /// Cancel subscription (guides user to App Store)
    func cancelSubscription() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await subscriptionService.cancelSubscription()
            // Subscription will remain active until expiry
            // Refresh status to show cancelled state
            await checkSubscriptionStatus()
        } catch {
            errorMessage = "取消订阅失败: \(error.localizedDescription)"
            print("Cancel subscription failed: \(error)")
        }
        
        isLoading = false
    }
    
    /// Check if cancelled subscription still has access
    var cancelledSubscriptionHasAccess: Bool {
        guard let subscription = currentSubscription else {
            return false
        }
        return subscriptionService.cancelledSubscriptionHasAccess(subscription)
    }
}
