//
//  FeatureAccessManager.swift
//  LightGallery
//
//  Created for user-auth-subscription feature
//

import Foundation
import SwiftUI

/// Manages feature access control based on subscription status
class FeatureAccessManager: ObservableObject {
    static let shared = FeatureAccessManager()
    
    private let subscriptionService: SubscriptionServiceProtocol
    @Published private var currentSubscription: Subscription?
    
    init(subscriptionService: SubscriptionServiceProtocol = SubscriptionService()) {
        self.subscriptionService = subscriptionService
        
        // Don't initialize with any subscription - let loadCurrentSubscription handle it
        self.currentSubscription = nil
        
        // Load actual subscription asynchronously
        Task {
            await loadCurrentSubscription()
        }
        
        // Listen for login/logout events
        setupAuthNotifications()
    }
    
    private func setupAuthNotifications() {
        NotificationCenter.default.addObserver(
            forName: .userDidLogin,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.loadCurrentSubscription()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .userDidLogout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await MainActor.run {
                    self?.currentSubscription = nil
                }
            }
        }
    }
    
    /// Check if user can access a specific premium feature
    /// - Parameter feature: The premium feature to check
    /// - Returns: True if user has access, false otherwise
    func canAccessFeature(_ feature: PremiumFeature) -> Bool {
        // Check if user is logged in first
        let authService = AuthenticationService.shared
        guard authService.getCurrentUser() != nil else {
            // User not logged in, no access to premium features
            return false
        }
        
        // Get current subscription tier (uses cache-first approach)
        let tier = getCurrentTier()
        
        // Check if subscription is expired
        if let subscription = currentSubscription {
            if subscription.isExpired {
                // Expired subscriptions cannot access premium features
                return false
            }
            
            // Cancelled subscriptions maintain access until expiry
            // Requirement: 7.4
            if subscription.status == .cancelled && !subscription.isExpired {
                // Still has access until expiry date
                return tier.features.contains(feature)
            }
        }
        
        // Check if the tier includes this feature
        return tier.features.contains(feature)
    }
    
    /// Check if user can access a feature with offline support
    /// - Parameter feature: The premium feature to check
    /// - Returns: True if user has access based on cached subscription (if valid)
    func canAccessFeatureOffline(_ feature: PremiumFeature) async -> Bool {
        // Try to get subscription with offline support
        if let subscription = await subscriptionService.getCurrentSubscriptionOffline() {
            // Check if subscription is expired
            if subscription.isExpired {
                return false
            }
            
            // Check if the tier includes this feature
            return subscription.tier.features.contains(feature)
        }
        
        // No valid subscription (either no subscription or cache expired)
        return false
    }
    
    /// Get the minimum subscription tier required for a feature
    /// - Parameter feature: The premium feature
    /// - Returns: The minimum subscription tier required
    func requiredTier(for feature: PremiumFeature) -> SubscriptionTier {
        // All premium features require at least Pro tier
        return .pro
    }
    
    /// Show paywall for a specific feature
    /// - Parameters:
    ///   - feature: The premium feature that triggered the paywall
    ///   - presentingView: The view to present the paywall from
    func showPaywall(for feature: PremiumFeature) {
        // Check if user is logged in first
        let authService = AuthenticationService.shared
        guard authService.getCurrentUser() != nil else {
            // User not logged in, show login required for feature access
            NotificationCenter.default.post(
                name: .loginRequiredForFeature,
                object: nil,
                userInfo: ["feature": feature]
            )
            return
        }
        
        // User is logged in, show normal paywall
        NotificationCenter.default.post(
            name: .showPaywall,
            object: nil,
            userInfo: ["feature": feature]
        )
    }
    
    /// Get the current subscription tier
    /// - Returns: Current subscription tier (defaults to free if no subscription or expired)
    func getCurrentTier() -> SubscriptionTier {
        // Check if user is logged in first
        let authService = AuthenticationService.shared
        guard authService.getCurrentUser() != nil else {
            // User not logged in, always return free tier
            return .free
        }
        
        // Try to get cached subscription first
        if let subscription = currentSubscription {
            // Check if subscription is expired
            if subscription.isExpired {
                return .free
            }
            
            if subscription.isActive {
                return subscription.tier
            }
        }
        
        // For development/testing, let's check if we have a cached subscription
        // This is a temporary solution until proper initialization is implemented
        Task {
            await loadCurrentSubscription()
        }
        
        // Try to fetch from service synchronously (using cached value)
        // In production, this should be kept up-to-date by the subscription service
        return .free
    }
    
    /// Load current subscription asynchronously
    @MainActor
    private func loadCurrentSubscription() async {
        // Check if user is logged in first
        let authService = AuthenticationService.shared
        guard authService.getCurrentUser() != nil else {
            // User not logged in, clear any subscription
            self.currentSubscription = nil
            return
        }
        
        do {
            let subscription = try await subscriptionService.getCurrentSubscription()
            self.currentSubscription = subscription
        } catch {
            print("Failed to load current subscription: \(error)")
            // Clear subscription on error for logged in users
            self.currentSubscription = nil
        }
    }
    

    
    /// Update the current subscription (called by SubscriptionService)
    /// - Parameter subscription: The updated subscription
    func updateSubscription(_ subscription: Subscription?) {
        Task { @MainActor in
            self.currentSubscription = subscription
            // Trigger UI update
            self.objectWillChange.send()
        }
    }
    
    /// Check if a feature is locked for the current user
    /// - Parameter feature: The premium feature to check
    /// - Returns: True if the feature is locked (requires upgrade)
    func isFeatureLocked(_ feature: PremiumFeature) -> Bool {
        return !canAccessFeature(feature)
    }
    
    /// Check if the current subscription is expired
    /// - Returns: True if subscription exists and is expired
    func isSubscriptionExpired() -> Bool {
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
                // Post notification to show renewal prompt
                NotificationCenter.default.post(
                    name: .subscriptionExpired,
                    object: nil
                )
            }
        } catch {
            print("Failed to check subscription expiration: \(error)")
        }
    }
    
    /// Refresh subscription status (called when network is restored)
    func refreshSubscriptionStatus() async {
        do {
            let subscription = try await subscriptionService.getCurrentSubscription()
            updateSubscription(subscription)
        } catch {
            print("Failed to refresh subscription status: \(error)")
        }
    }
}


