//
//  SubscriptionViewModel.swift
//  Declutter
//
//  Lite version - Stub implementation, no subscription functionality
//

import Foundation
import SwiftUI

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var currentSubscription: Subscription?
    @Published var availableProducts: [SubscriptionProduct] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    init() {
        // Lite version: No subscription service needed
    }

    // Convenience init for compatibility
    init(subscriptionService: Any? = nil) {
        // Lite version: Ignore subscription service
    }

    /// Load available subscription products - Lite version: No-op
    func loadProducts() async {
        // Lite version: No products to load
    }

    /// Purchase a subscription product - Lite version: No-op
    func purchase(_ product: SubscriptionProduct) async {
        // Lite version: No purchase functionality
    }

    /// Restore previous purchases - Lite version: No-op
    func restorePurchases() async {
        // Lite version: No restore functionality
    }

    /// Check current subscription status - Lite version: No-op
    func checkSubscriptionStatus() async {
        // Lite version: No subscription to check
    }

    /// Upgrade to a higher tier - Lite version: No-op
    func upgradeSubscription(to tier: SubscriptionTier) async {
        // Lite version: No upgrade functionality
    }

    /// Check if user can access a premium feature - Lite version: Always true
    func canAccessFeature(_ feature: PremiumFeature) -> Bool {
        return true
    }

    /// Get the required tier for a feature
    func requiredTier(for feature: PremiumFeature) -> SubscriptionTier {
        return .free
    }

    /// Check if subscription is expired - Lite version: Always false
    var isSubscriptionExpired: Bool {
        return false
    }

    /// Check subscription expiration on app launch - Lite version: No-op
    func checkExpirationOnLaunch() async {
        // Lite version: No subscription to check
    }

    /// Cancel subscription - Lite version: No-op
    func cancelSubscription() async {
        // Lite version: No subscription to cancel
    }

    /// Check if cancelled subscription still has access - Lite version: Always false
    var cancelledSubscriptionHasAccess: Bool {
        return false
    }
}
