//
//  Subscription.swift
//  Declutter
//
//  Created for user-auth-subscription feature
//

import Foundation

struct Subscription: Codable {
    let id: String
    let userId: String
    var tier: SubscriptionTier
    var billingPeriod: BillingPeriod
    var status: SubscriptionStatus
    var startDate: Date
    var expiryDate: Date
    var autoRenew: Bool
    var paymentMethod: PaymentMethod
    var lastSyncedAt: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        tier: SubscriptionTier,
        billingPeriod: BillingPeriod,
        status: SubscriptionStatus,
        startDate: Date,
        expiryDate: Date,
        autoRenew: Bool = true,
        paymentMethod: PaymentMethod,
        lastSyncedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.tier = tier
        self.billingPeriod = billingPeriod
        self.status = status
        self.startDate = startDate
        self.expiryDate = expiryDate
        self.autoRenew = autoRenew
        self.paymentMethod = paymentMethod
        self.lastSyncedAt = lastSyncedAt
    }
    
    var isActive: Bool {
        return status == .active && expiryDate > Date()
    }
    
    var isExpired: Bool {
        return expiryDate <= Date()
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiryDate)
        return max(0, components.day ?? 0)
    }
}
