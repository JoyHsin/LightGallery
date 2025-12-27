//
//  FeatureAccessManager.swift
//  LightGallery
//
//  Lite version - All features unlocked, no subscription required
//

import Foundation
import SwiftUI

/// Manages feature access control - Lite version with all features unlocked
class FeatureAccessManager: ObservableObject {
    static let shared = FeatureAccessManager()

    init() {
        // Lite version: No subscription service needed
    }

    /// Check if user can access a specific premium feature
    /// Lite version: Always returns true - all features are free
    func canAccessFeature(_ feature: PremiumFeature) -> Bool {
        return true
    }

    /// Check if user can access a feature with offline support
    /// Lite version: Always returns true
    func canAccessFeatureOffline(_ feature: PremiumFeature) async -> Bool {
        return true
    }

    /// Get the minimum subscription tier required for a feature
    /// Lite version: Returns max tier (all features available)
    func requiredTier(for feature: PremiumFeature) -> SubscriptionTier {
        return .free
    }

    /// Show paywall for a specific feature
    /// Lite version: Does nothing - no paywall needed
    func showPaywall(for feature: PremiumFeature) {
        // Lite version: No paywall
    }

    /// Get the current subscription tier
    /// Lite version: Returns max tier to unlock all features
    func getCurrentTier() -> SubscriptionTier {
        return .max
    }

    /// Check if a feature is locked for the current user
    /// Lite version: Always returns false - nothing is locked
    func isFeatureLocked(_ feature: PremiumFeature) -> Bool {
        return false
    }

    /// Check if the current subscription is expired
    /// Lite version: Always returns false
    func isSubscriptionExpired() -> Bool {
        return false
    }

    /// Check subscription expiration on app launch
    /// Lite version: Does nothing
    func checkExpirationOnLaunch() async {
        // Lite version: No subscription to check
    }

    /// Refresh subscription status
    /// Lite version: Does nothing
    func refreshSubscriptionStatus() async {
        // Lite version: No subscription to refresh
    }
}
