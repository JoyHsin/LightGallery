//
//  SubscriptionProduct.swift
//  LightGallery
//
//  Created for user-auth-subscription feature
//

import Foundation
import StoreKit

struct SubscriptionProduct: Identifiable {
    let id: String
    let tier: SubscriptionTier
    let billingPeriod: BillingPeriod
    let price: Decimal
    let currency: String
    let localizedPrice: String
    let localizedDescription: String
    
    // Apple IAP Product (iOS)
    var storeKitProduct: Product?
    
    init(
        id: String,
        tier: SubscriptionTier,
        billingPeriod: BillingPeriod,
        price: Decimal,
        currency: String = "CNY",
        localizedPrice: String,
        localizedDescription: String,
        storeKitProduct: Product? = nil
    ) {
        self.id = id
        self.tier = tier
        self.billingPeriod = billingPeriod
        self.price = price
        self.currency = currency
        self.localizedPrice = localizedPrice
        self.localizedDescription = localizedDescription
        self.storeKitProduct = storeKitProduct
    }
    
    var displayPrice: String {
        switch (tier, billingPeriod) {
        case (.pro, .monthly): return "¥10/月"
        case (.pro, .yearly): return "¥100/年"
        case (.max, .monthly): return "¥20/月"
        case (.max, .yearly): return "¥200/年"
        default: return "免费"
        }
    }
    
    var displayTitle: String {
        return "\(tier.displayName) - \(billingPeriod.displayName)"
    }
}

struct PurchaseResult {
    let success: Bool
    let subscription: Subscription?
    let transaction: StoreKit.Transaction?
    let error: Error?
}
