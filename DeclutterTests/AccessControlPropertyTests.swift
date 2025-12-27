//
//  AccessControlPropertyTests.swift
//  DeclutterTests
//
//  Created by Kiro on 2025-12-06.
//

import XCTest
@testable import Declutter

/// Property-based tests for feature access control functionality
final class AccessControlPropertyTests: XCTestCase {
    
    var featureAccessManager: FeatureAccessManager!
    var mockSubscriptionService: MockSubscriptionService!
    
    override func setUp() {
        super.setUp()
        mockSubscriptionService = MockSubscriptionService()
        featureAccessManager = FeatureAccessManager(subscriptionService: mockSubscriptionService)
    }
    
    override func tearDown() {
        featureAccessManager = nil
        mockSubscriptionService = nil
        super.tearDown()
    }
    
    // MARK: - Property 17: Free Tier Access Restriction
    
    /// **Feature: user-auth-subscription, Property 17: Free Tier Access Restriction**
    /// **Validates: Requirements 6.1**
    ///
    /// Property: For any premium feature, when a free tier user attempts access,
    /// the system should block access and show an upgrade prompt.
    ///
    /// This test verifies that:
    /// 1. Free tier users cannot access any premium features
    /// 2. Access checks return false for all premium features
    /// 3. Features are correctly marked as locked
    func testFreeTierAccessRestriction() {
        // Set up free tier subscription
        let freeSubscription = Subscription(
            userId: "test_user",
            tier: .free,
            billingPeriod: .monthly,
            status: .active,
            startDate: Date(),
            expiryDate: Date().addingTimeInterval(86400 * 30),
            paymentMethod: .appleIAP
        )
        mockSubscriptionService.mockSubscription = freeSubscription
        featureAccessManager.updateSubscription(freeSubscription)
        
        // Run 100 iterations as specified in the design document
        for iteration in 1...100 {
            // Test all premium features
            for feature in PremiumFeature.allCases {
                // Verify access is denied
                let canAccess = featureAccessManager.canAccessFeature(feature)
                XCTAssertFalse(
                    canAccess,
                    "Iteration \(iteration): Free tier should not access \(feature.rawValue)"
                )
                
                // Verify feature is marked as locked
                let isLocked = featureAccessManager.isFeatureLocked(feature)
                XCTAssertTrue(
                    isLocked,
                    "Iteration \(iteration): Feature \(feature.rawValue) should be locked for free tier"
                )
                
                // Verify required tier is Pro or higher
                let requiredTier = featureAccessManager.requiredTier(for: feature)
                XCTAssertGreaterThanOrEqual(
                    requiredTier,
                    .pro,
                    "Iteration \(iteration): Required tier for \(feature.rawValue) should be at least Pro"
                )
            }
        }
    }
    
    /// Test free tier access restriction with random feature selection
    /// **Feature: user-auth-subscription, Property 17: Free Tier Access Restriction**
    /// **Validates: Requirements 6.1**
    func testFreeTierRandomFeatureRestriction() {
        // Set up free tier
        let freeSubscription = Subscription(
            userId: "test_user",
            tier: .free,
            billingPeriod: .monthly,
            status: .active,
            startDate: Date(),
            expiryDate: Date().addingTimeInterval(86400 * 30),
            paymentMethod: .appleIAP
        )
        mockSubscriptionService.mockSubscription = freeSubscription
        featureAccessManager.updateSubscription(freeSubscription)
        
        // Run 100 iterations with random feature selection
        for iteration in 1...100 {
            let randomFeature = PremiumFeature.allCases.randomElement()!
            
            // Verify access is denied
            XCTAssertFalse(
                featureAccessManager.canAccessFeature(randomFeature),
                "Iteration \(iteration): Free tier should not access \(randomFeature.rawValue)"
            )
            
            // Verify feature is locked
            XCTAssertTrue(
                featureAccessManager.isFeatureLocked(randomFeature),
                "Iteration \(iteration): \(randomFeature.rawValue) should be locked"
            )
        }
    }
    
    // MARK: - Property 18: Paid Tier Access Grant
    
    /// **Feature: user-auth-subscription, Property 18: Paid Tier Access Grant**
    /// **Validates: Requirements 6.2**
    ///
    /// Property: For any premium feature, when a Pro or Max tier user attempts access,
    /// the system should grant access immediately.
    ///
    /// This test verifies that:
    /// 1. Pro tier users can access all premium features
    /// 2. Max tier users can access all premium features
    /// 3. Access checks return true for all premium features
    /// 4. Features are not marked as locked
    func testPaidTierAccessGrant() {
        let tiers: [SubscriptionTier] = [.pro, .max]
        
        // Run 100 iterations as specified in the design document
        for iteration in 1...100 {
            // Test both Pro and Max tiers
            for tier in tiers {
                // Set up paid tier subscription
                let paidSubscription = Subscription(
                    userId: "test_user_\(iteration)",
                    tier: tier,
                    billingPeriod: [.monthly, .yearly].randomElement()!,
                    status: .active,
                    startDate: Date(),
                    expiryDate: Date().addingTimeInterval(86400 * 30),
                    paymentMethod: .appleIAP
                )
                mockSubscriptionService.mockSubscription = paidSubscription
                featureAccessManager.updateSubscription(paidSubscription)
                
                // Test all premium features
                for feature in PremiumFeature.allCases {
                    // Verify access is granted
                    let canAccess = featureAccessManager.canAccessFeature(feature)
                    XCTAssertTrue(
                        canAccess,
                        "Iteration \(iteration): \(tier.rawValue) tier should access \(feature.rawValue)"
                    )
                    
                    // Verify feature is not locked
                    let isLocked = featureAccessManager.isFeatureLocked(feature)
                    XCTAssertFalse(
                        isLocked,
                        "Iteration \(iteration): Feature \(feature.rawValue) should not be locked for \(tier.rawValue) tier"
                    )
                }
            }
        }
    }
    
    /// Test paid tier access with random feature and tier selection
    /// **Feature: user-auth-subscription, Property 18: Paid Tier Access Grant**
    /// **Validates: Requirements 6.2**
    func testPaidTierRandomAccessGrant() {
        // Run 100 iterations with random selections
        for iteration in 1...100 {
            // Random paid tier
            let tier = [SubscriptionTier.pro, .max].randomElement()!
            
            // Random billing period
            let billingPeriod = [BillingPeriod.monthly, .yearly].randomElement()!
            
            // Set up subscription
            let subscription = Subscription(
                userId: "random_user_\(iteration)",
                tier: tier,
                billingPeriod: billingPeriod,
                status: .active,
                startDate: Date(),
                expiryDate: Date().addingTimeInterval(86400 * 30),
                paymentMethod: .appleIAP
            )
            mockSubscriptionService.mockSubscription = subscription
            featureAccessManager.updateSubscription(subscription)
            
            // Random feature
            let randomFeature = PremiumFeature.allCases.randomElement()!
            
            // Verify access is granted
            XCTAssertTrue(
                featureAccessManager.canAccessFeature(randomFeature),
                "Iteration \(iteration): \(tier.rawValue) should access \(randomFeature.rawValue)"
            )
            
            // Verify feature is not locked
            XCTAssertFalse(
                featureAccessManager.isFeatureLocked(randomFeature),
                "Iteration \(iteration): \(randomFeature.rawValue) should not be locked for \(tier.rawValue)"
            )
        }
    }
    
    /// Test that Pro and Max tiers have identical feature access
    /// **Feature: user-auth-subscription, Property 18: Paid Tier Access Grant**
    /// **Validates: Requirements 6.2**
    func testProAndMaxTierFeatureParity() {
        // Run 100 iterations
        for iteration in 1...100 {
            // Set up Pro subscription
            let proSubscription = Subscription(
                userId: "pro_user_\(iteration)",
                tier: .pro,
                billingPeriod: .monthly,
                status: .active,
                startDate: Date(),
                expiryDate: Date().addingTimeInterval(86400 * 30),
                paymentMethod: .appleIAP
            )
            mockSubscriptionService.mockSubscription = proSubscription
            featureAccessManager.updateSubscription(proSubscription)
            
            // Get Pro tier accessible features
            let proFeatures = PremiumFeature.allCases.filter { feature in
                featureAccessManager.canAccessFeature(feature)
            }
            
            // Set up Max subscription
            let maxSubscription = Subscription(
                userId: "max_user_\(iteration)",
                tier: .max,
                billingPeriod: .monthly,
                status: .active,
                startDate: Date(),
                expiryDate: Date().addingTimeInterval(86400 * 30),
                paymentMethod: .appleIAP
            )
            mockSubscriptionService.mockSubscription = maxSubscription
            featureAccessManager.updateSubscription(maxSubscription)
            
            // Get Max tier accessible features
            let maxFeatures = PremiumFeature.allCases.filter { feature in
                featureAccessManager.canAccessFeature(feature)
            }
            
            // Verify both tiers have same feature access
            XCTAssertEqual(
                Set(proFeatures),
                Set(maxFeatures),
                "Iteration \(iteration): Pro and Max should have identical feature access"
            )
            
            // Verify both have all features
            XCTAssertEqual(
                proFeatures.count,
                PremiumFeature.allCases.count,
                "Iteration \(iteration): Pro should have all features"
            )
            XCTAssertEqual(
                maxFeatures.count,
                PremiumFeature.allCases.count,
                "Iteration \(iteration): Max should have all features"
            )
        }
    }
    
    // MARK: - Property 21: Feature Lock Display
    
    /// **Feature: user-auth-subscription, Property 21: Feature Lock Display**
    /// **Validates: Requirements 6.5**
    ///
    /// Property: For any premium feature, when displayed to a user without
    /// appropriate subscription, the system should mark it as locked in the view model.
    ///
    /// This test verifies that:
    /// 1. Features are correctly marked as locked for free tier users
    /// 2. Features are correctly marked as unlocked for paid tier users
    /// 3. Lock status is consistent across multiple checks
    func testFeatureLockDisplay() {
        // Run 100 iterations as specified in the design document
        for iteration in 1...100 {
            // Test with free tier
            let freeSubscription = Subscription(
                userId: "free_user_\(iteration)",
                tier: .free,
                billingPeriod: .monthly,
                status: .active,
                startDate: Date(),
                expiryDate: Date().addingTimeInterval(86400 * 30),
                paymentMethod: .appleIAP
            )
            mockSubscriptionService.mockSubscription = freeSubscription
            featureAccessManager.updateSubscription(freeSubscription)
            
            // Verify all features are locked for free tier
            for feature in PremiumFeature.allCases {
                let isLocked = featureAccessManager.isFeatureLocked(feature)
                XCTAssertTrue(
                    isLocked,
                    "Iteration \(iteration): \(feature.rawValue) should be locked for free tier"
                )
                
                // Verify consistency with canAccessFeature
                let canAccess = featureAccessManager.canAccessFeature(feature)
                XCTAssertEqual(
                    isLocked,
                    !canAccess,
                    "Iteration \(iteration): Lock status should be inverse of access status"
                )
            }
            
            // Test with paid tier
            let paidTier = [SubscriptionTier.pro, .max].randomElement()!
            let paidSubscription = Subscription(
                userId: "paid_user_\(iteration)",
                tier: paidTier,
                billingPeriod: [.monthly, .yearly].randomElement()!,
                status: .active,
                startDate: Date(),
                expiryDate: Date().addingTimeInterval(86400 * 30),
                paymentMethod: .appleIAP
            )
            mockSubscriptionService.mockSubscription = paidSubscription
            featureAccessManager.updateSubscription(paidSubscription)
            
            // Verify all features are unlocked for paid tier
            for feature in PremiumFeature.allCases {
                let isLocked = featureAccessManager.isFeatureLocked(feature)
                XCTAssertFalse(
                    isLocked,
                    "Iteration \(iteration): \(feature.rawValue) should not be locked for \(paidTier.rawValue) tier"
                )
                
                // Verify consistency with canAccessFeature
                let canAccess = featureAccessManager.canAccessFeature(feature)
                XCTAssertEqual(
                    isLocked,
                    !canAccess,
                    "Iteration \(iteration): Lock status should be inverse of access status"
                )
            }
        }
    }
    
    /// Test feature lock display consistency across multiple checks
    /// **Feature: user-auth-subscription, Property 21: Feature Lock Display**
    /// **Validates: Requirements 6.5**
    func testFeatureLockDisplayConsistency() {
        // Run 100 iterations
        for iteration in 1...100 {
            // Random tier
            let tier = [SubscriptionTier.free, .pro, .max].randomElement()!
            
            let subscription = Subscription(
                userId: "consistency_user_\(iteration)",
                tier: tier,
                billingPeriod: .monthly,
                status: .active,
                startDate: Date(),
                expiryDate: Date().addingTimeInterval(86400 * 30),
                paymentMethod: .appleIAP
            )
            mockSubscriptionService.mockSubscription = subscription
            featureAccessManager.updateSubscription(subscription)
            
            // Random feature
            let feature = PremiumFeature.allCases.randomElement()!
            
            // Check lock status multiple times
            let checks = 10
            var lockStatuses: [Bool] = []
            
            for _ in 1...checks {
                let isLocked = featureAccessManager.isFeatureLocked(feature)
                lockStatuses.append(isLocked)
            }
            
            // Verify all checks return the same result
            let firstStatus = lockStatuses.first!
            XCTAssertTrue(
                lockStatuses.allSatisfy { $0 == firstStatus },
                "Iteration \(iteration): Lock status should be consistent across multiple checks"
            )
            
            // Verify lock status matches tier expectations
            if tier == .free {
                XCTAssertTrue(
                    firstStatus,
                    "Iteration \(iteration): Feature should be locked for free tier"
                )
            } else {
                XCTAssertFalse(
                    firstStatus,
                    "Iteration \(iteration): Feature should not be locked for \(tier.rawValue) tier"
                )
            }
        }
    }
    
    /// Test feature lock display with expired subscription
    /// **Feature: user-auth-subscription, Property 21: Feature Lock Display**
    /// **Validates: Requirements 6.5**
    func testFeatureLockDisplayWithExpiredSubscription() {
        // Run 100 iterations
        for iteration in 1...100 {
            // Create expired subscription
            let expiredSubscription = Subscription(
                userId: "expired_user_\(iteration)",
                tier: [.pro, .max].randomElement()!,
                billingPeriod: .monthly,
                status: .expired,
                startDate: Date().addingTimeInterval(-86400 * 60), // 60 days ago
                expiryDate: Date().addingTimeInterval(-86400 * 30), // Expired 30 days ago
                paymentMethod: .appleIAP
            )
            mockSubscriptionService.mockSubscription = expiredSubscription
            featureAccessManager.updateSubscription(expiredSubscription)
            
            // Random feature
            let feature = PremiumFeature.allCases.randomElement()!
            
            // Verify feature is locked for expired subscription
            let isLocked = featureAccessManager.isFeatureLocked(feature)
            XCTAssertTrue(
                isLocked,
                "Iteration \(iteration): \(feature.rawValue) should be locked for expired subscription"
            )
            
            // Verify access is denied
            let canAccess = featureAccessManager.canAccessFeature(feature)
            XCTAssertFalse(
                canAccess,
                "Iteration \(iteration): Access should be denied for expired subscription"
            )
        }
    }
    
    /// Test feature lock display with no subscription
    /// **Feature: user-auth-subscription, Property 21: Feature Lock Display**
    /// **Validates: Requirements 6.5**
    func testFeatureLockDisplayWithNoSubscription() {
        // Run 100 iterations
        for iteration in 1...100 {
            // Clear subscription
            mockSubscriptionService.mockSubscription = nil
            featureAccessManager.updateSubscription(nil)
            
            // Random feature
            let feature = PremiumFeature.allCases.randomElement()!
            
            // Verify feature is locked with no subscription
            let isLocked = featureAccessManager.isFeatureLocked(feature)
            XCTAssertTrue(
                isLocked,
                "Iteration \(iteration): \(feature.rawValue) should be locked with no subscription"
            )
            
            // Verify access is denied
            let canAccess = featureAccessManager.canAccessFeature(feature)
            XCTAssertFalse(
                canAccess,
                "Iteration \(iteration): Access should be denied with no subscription"
            )
            
            // Verify current tier defaults to free
            let currentTier = featureAccessManager.getCurrentTier()
            XCTAssertEqual(
                currentTier,
                .free,
                "Iteration \(iteration): Current tier should default to free with no subscription"
            )
        }
    }
    
    // MARK: - Property 20: Expired Subscription Restriction
    
    /// **Feature: user-auth-subscription, Property 20: Expired Subscription Restriction**
    /// **Validates: Requirements 6.4**
    ///
    /// Property: For any expired subscription, the system should immediately restrict
    /// access to all premium features.
    ///
    /// This test verifies that:
    /// 1. Expired subscriptions cannot access premium features
    /// 2. Access is restricted regardless of the original subscription tier
    /// 3. Features are marked as locked for expired subscriptions
    /// 4. Current tier defaults to free for expired subscriptions
    func testExpiredSubscriptionRestriction() {
        // Run 100 iterations as specified in the design document
        for iteration in 1...100 {
            // Random paid tier (Pro or Max)
            let originalTier = [SubscriptionTier.pro, .max].randomElement()!
            
            // Random billing period
            let billingPeriod = [BillingPeriod.monthly, .yearly].randomElement()!
            
            // Random payment method
            let paymentMethod = [PaymentMethod.appleIAP, .wechatPay, .alipay].randomElement()!
            
            // Create expired subscription with random past dates
            let daysExpired = Int.random(in: 1...365) // Expired 1 to 365 days ago
            let subscriptionDuration = billingPeriod == .monthly ? 30 : 365
            
            let expiryDate = Date().addingTimeInterval(-Double(daysExpired * 86400))
            let startDate = expiryDate.addingTimeInterval(-Double(subscriptionDuration * 86400))
            
            let expiredSubscription = Subscription(
                userId: "expired_user_\(iteration)",
                tier: originalTier,
                billingPeriod: billingPeriod,
                status: .expired,
                startDate: startDate,
                expiryDate: expiryDate,
                autoRenew: false,
                paymentMethod: paymentMethod
            )
            
            mockSubscriptionService.mockSubscription = expiredSubscription
            featureAccessManager.updateSubscription(expiredSubscription)
            
            // Test all premium features
            for feature in PremiumFeature.allCases {
                // Verify access is denied for expired subscription
                let canAccess = featureAccessManager.canAccessFeature(feature)
                XCTAssertFalse(
                    canAccess,
                    "Iteration \(iteration): Expired \(originalTier.rawValue) subscription should not access \(feature.rawValue)"
                )
                
                // Verify feature is locked
                let isLocked = featureAccessManager.isFeatureLocked(feature)
                XCTAssertTrue(
                    isLocked,
                    "Iteration \(iteration): \(feature.rawValue) should be locked for expired subscription"
                )
            }
            
            // Verify current tier defaults to free for expired subscription
            let currentTier = featureAccessManager.getCurrentTier()
            XCTAssertEqual(
                currentTier,
                .free,
                "Iteration \(iteration): Current tier should be free for expired \(originalTier.rawValue) subscription"
            )
            
            // Verify subscription is recognized as expired
            XCTAssertTrue(
                expiredSubscription.isExpired,
                "Iteration \(iteration): Subscription should be recognized as expired"
            )
            
            // Verify subscription is not active
            XCTAssertFalse(
                expiredSubscription.isActive,
                "Iteration \(iteration): Expired subscription should not be active"
            )
        }
    }
    
    /// Test expired subscription restriction with random feature selection
    /// **Feature: user-auth-subscription, Property 20: Expired Subscription Restriction**
    /// **Validates: Requirements 6.4**
    func testExpiredSubscriptionRandomFeatureRestriction() {
        // Run 100 iterations with random feature selection
        for iteration in 1...100 {
            // Random expired subscription
            let tier = [SubscriptionTier.pro, .max].randomElement()!
            let daysExpired = Int.random(in: 1...1000)
            
            let expiredSubscription = Subscription(
                userId: "random_expired_\(iteration)",
                tier: tier,
                billingPeriod: .monthly,
                status: .expired,
                startDate: Date().addingTimeInterval(-Double((daysExpired + 30) * 86400)),
                expiryDate: Date().addingTimeInterval(-Double(daysExpired * 86400)),
                paymentMethod: .appleIAP
            )
            
            mockSubscriptionService.mockSubscription = expiredSubscription
            featureAccessManager.updateSubscription(expiredSubscription)
            
            // Random feature
            let randomFeature = PremiumFeature.allCases.randomElement()!
            
            // Verify access is denied
            XCTAssertFalse(
                featureAccessManager.canAccessFeature(randomFeature),
                "Iteration \(iteration): Expired subscription should not access \(randomFeature.rawValue)"
            )
            
            // Verify feature is locked
            XCTAssertTrue(
                featureAccessManager.isFeatureLocked(randomFeature),
                "Iteration \(iteration): \(randomFeature.rawValue) should be locked for expired subscription"
            )
        }
    }
    
    /// Test that expiration check properly updates subscription status
    /// **Feature: user-auth-subscription, Property 20: Expired Subscription Restriction**
    /// **Validates: Requirements 6.4**
    func testExpirationCheckUpdatesStatus() async {
        // Run 100 iterations
        for iteration in 1...100 {
            // Create subscription that just expired
            let tier = [SubscriptionTier.pro, .max].randomElement()!
            let minutesExpired = Int.random(in: 1...60)
            
            let expiredSubscription = Subscription(
                userId: "check_expired_\(iteration)",
                tier: tier,
                billingPeriod: .monthly,
                status: .active, // Status is still active but expiry date has passed
                startDate: Date().addingTimeInterval(-86400 * 30),
                expiryDate: Date().addingTimeInterval(-Double(minutesExpired * 60)),
                paymentMethod: .appleIAP
            )
            
            mockSubscriptionService.mockSubscription = expiredSubscription
            featureAccessManager.updateSubscription(expiredSubscription)
            
            // Check expiration
            let isExpired = try? await mockSubscriptionService.checkAndHandleExpiration()
            
            // Verify expiration was detected
            XCTAssertEqual(
                isExpired,
                true,
                "Iteration \(iteration): Expiration check should detect expired subscription"
            )
            
            // Verify status was updated to expired
            let updatedSubscription = mockSubscriptionService.mockSubscription
            XCTAssertEqual(
                updatedSubscription?.status,
                .expired,
                "Iteration \(iteration): Status should be updated to expired"
            )
            
            // Verify access is now denied
            featureAccessManager.updateSubscription(updatedSubscription)
            let randomFeature = PremiumFeature.allCases.randomElement()!
            XCTAssertFalse(
                featureAccessManager.canAccessFeature(randomFeature),
                "Iteration \(iteration): Access should be denied after expiration check"
            )
        }
    }
    
    /// Test expiration boundary conditions
    /// **Feature: user-auth-subscription, Property 20: Expired Subscription Restriction**
    /// **Validates: Requirements 6.4**
    func testExpirationBoundaryConditions() {
        // Run 100 iterations
        for iteration in 1...100 {
            let tier = [SubscriptionTier.pro, .max].randomElement()!
            
            // Test 1: Subscription expires in 1 second (still active)
            let almostExpiredSubscription = Subscription(
                userId: "almost_expired_\(iteration)",
                tier: tier,
                billingPeriod: .monthly,
                status: .active,
                startDate: Date().addingTimeInterval(-86400 * 30),
                expiryDate: Date().addingTimeInterval(1), // Expires in 1 second
                paymentMethod: .appleIAP
            )
            
            mockSubscriptionService.mockSubscription = almostExpiredSubscription
            featureAccessManager.updateSubscription(almostExpiredSubscription)
            
            // Should still have access
            let randomFeature = PremiumFeature.allCases.randomElement()!
            XCTAssertTrue(
                featureAccessManager.canAccessFeature(randomFeature),
                "Iteration \(iteration): Should have access when subscription expires in 1 second"
            )
            
            // Test 2: Subscription expired 1 second ago
            let justExpiredSubscription = Subscription(
                userId: "just_expired_\(iteration)",
                tier: tier,
                billingPeriod: .monthly,
                status: .expired,
                startDate: Date().addingTimeInterval(-86400 * 30),
                expiryDate: Date().addingTimeInterval(-1), // Expired 1 second ago
                paymentMethod: .appleIAP
            )
            
            mockSubscriptionService.mockSubscription = justExpiredSubscription
            featureAccessManager.updateSubscription(justExpiredSubscription)
            
            // Should not have access
            XCTAssertFalse(
                featureAccessManager.canAccessFeature(randomFeature),
                "Iteration \(iteration): Should not have access when subscription expired 1 second ago"
            )
        }
    }
    
    /// Test that expired subscriptions are treated the same as free tier
    /// **Feature: user-auth-subscription, Property 20: Expired Subscription Restriction**
    /// **Validates: Requirements 6.4**
    func testExpiredSubscriptionEquivalentToFreeTier() {
        // Run 100 iterations
        for iteration in 1...100 {
            // Create expired subscription
            let expiredTier = [SubscriptionTier.pro, .max].randomElement()!
            let expiredSubscription = Subscription(
                userId: "expired_\(iteration)",
                tier: expiredTier,
                billingPeriod: .monthly,
                status: .expired,
                startDate: Date().addingTimeInterval(-86400 * 60),
                expiryDate: Date().addingTimeInterval(-86400 * 30),
                paymentMethod: .appleIAP
            )
            
            mockSubscriptionService.mockSubscription = expiredSubscription
            featureAccessManager.updateSubscription(expiredSubscription)
            
            // Get access status for all features with expired subscription
            let expiredAccess = PremiumFeature.allCases.map { feature in
                featureAccessManager.canAccessFeature(feature)
            }
            
            // Create free tier subscription
            let freeSubscription = Subscription(
                userId: "free_\(iteration)",
                tier: .free,
                billingPeriod: .monthly,
                status: .active,
                startDate: Date(),
                expiryDate: Date().addingTimeInterval(86400 * 30),
                paymentMethod: .appleIAP
            )
            
            mockSubscriptionService.mockSubscription = freeSubscription
            featureAccessManager.updateSubscription(freeSubscription)
            
            // Get access status for all features with free tier
            let freeAccess = PremiumFeature.allCases.map { feature in
                featureAccessManager.canAccessFeature(feature)
            }
            
            // Verify expired subscription has same access as free tier
            XCTAssertEqual(
                expiredAccess,
                freeAccess,
                "Iteration \(iteration): Expired \(expiredTier.rawValue) should have same access as free tier"
            )
            
            // Verify both have no access to premium features
            XCTAssertTrue(
                expiredAccess.allSatisfy { !$0 },
                "Iteration \(iteration): Expired subscription should have no premium access"
            )
            XCTAssertTrue(
                freeAccess.allSatisfy { !$0 },
                "Iteration \(iteration): Free tier should have no premium access"
            )
        }
    }
}


