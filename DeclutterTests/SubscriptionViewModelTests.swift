//
//  SubscriptionViewModelTests.swift
//  DeclutterTests
//
//  Created by Kiro on 2025-12-06.
//

import XCTest
@testable import Declutter

@MainActor
final class SubscriptionViewModelTests: XCTestCase {
    
    var viewModel: SubscriptionViewModel!
    var mockSubscriptionService: MockSubscriptionService!
    
    override func setUp() {
        super.setUp()
        mockSubscriptionService = MockSubscriptionService()
        viewModel = SubscriptionViewModel(subscriptionService: mockSubscriptionService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockSubscriptionService = nil
        super.tearDown()
    }
    
    // MARK: - Product Display Logic Tests
    
    func testLoadProductsSuccessfullyPopulatesAvailableProducts() async {
        // Given
        mockSubscriptionService.shouldSucceed = true
        XCTAssertTrue(viewModel.availableProducts.isEmpty, "Initial products should be empty")
        
        // When
        await viewModel.loadProducts()
        
        // Then
        XCTAssertFalse(viewModel.availableProducts.isEmpty, "Products should be populated after loading")
        XCTAssertEqual(viewModel.availableProducts.count, 4, "Should have 4 products (Pro monthly, Pro yearly, Max monthly, Max yearly)")
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil on success")
    }
    
    func testLoadProductsDisplaysErrorOnFailure() async {
        // Given
        mockSubscriptionService.shouldSucceed = false
        
        // When
        await viewModel.loadProducts()
        
        // Then
        XCTAssertTrue(viewModel.availableProducts.isEmpty, "Products should remain empty on failure")
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set on failure")
        XCTAssertTrue(viewModel.errorMessage?.contains("加载产品失败") ?? false, "Error message should indicate product loading failure")
    }
    
    func testLoadProductsSetsLoadingState() async {
        // Given
        mockSubscriptionService.shouldSucceed = true
        XCTAssertFalse(viewModel.isLoading, "Initial loading state should be false")
        
        // When
        await viewModel.loadProducts()
        
        // Then
        XCTAssertFalse(viewModel.isLoading, "Loading state should be false after completion")
    }
    
    func testAvailableProductsContainCorrectTiers() async {
        // Given
        mockSubscriptionService.shouldSucceed = true
        
        // When
        await viewModel.loadProducts()
        
        // Then
        let proProducts = viewModel.availableProducts.filter { $0.tier == .pro }
        let maxProducts = viewModel.availableProducts.filter { $0.tier == .max }
        
        XCTAssertEqual(proProducts.count, 2, "Should have 2 Pro products (monthly and yearly)")
        XCTAssertEqual(maxProducts.count, 2, "Should have 2 Max products (monthly and yearly)")
    }
    
    func testAvailableProductsContainCorrectBillingPeriods() async {
        // Given
        mockSubscriptionService.shouldSucceed = true
        
        // When
        await viewModel.loadProducts()
        
        // Then
        let monthlyProducts = viewModel.availableProducts.filter { $0.billingPeriod == .monthly }
        let yearlyProducts = viewModel.availableProducts.filter { $0.billingPeriod == .yearly }
        
        XCTAssertEqual(monthlyProducts.count, 2, "Should have 2 monthly products (Pro and Max)")
        XCTAssertEqual(yearlyProducts.count, 2, "Should have 2 yearly products (Pro and Max)")
    }
    
    // MARK: - Tier Highlighting Tests
    
    func testCurrentSubscriptionHighlightingForProMonthly() async {
        // Given
        mockSubscriptionService.shouldSucceed = true
        mockSubscriptionService.mockSubscription = Subscription(
            userId: "test-user",
            tier: .pro,
            billingPeriod: .monthly,
            status: .active,
            startDate: Date(),
            expiryDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
            paymentMethod: .appleIAP
        )
        
        // When
        await viewModel.checkSubscriptionStatus()
        
        // Then
        XCTAssertNotNil(viewModel.currentSubscription, "Current subscription should be set")
        XCTAssertEqual(viewModel.currentSubscription?.tier, .pro, "Current tier should be Pro")
        XCTAssertEqual(viewModel.currentSubscription?.billingPeriod, .monthly, "Billing period should be monthly")
    }
    
    func testCurrentSubscriptionHighlightingForMaxYearly() async {
        // Given
        mockSubscriptionService.shouldSucceed = true
        mockSubscriptionService.mockSubscription = Subscription(
            userId: "test-user",
            tier: .max,
            billingPeriod: .yearly,
            status: .active,
            startDate: Date(),
            expiryDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
            paymentMethod: .appleIAP
        )
        
        // When
        await viewModel.checkSubscriptionStatus()
        
        // Then
        XCTAssertNotNil(viewModel.currentSubscription, "Current subscription should be set")
        XCTAssertEqual(viewModel.currentSubscription?.tier, .max, "Current tier should be Max")
        XCTAssertEqual(viewModel.currentSubscription?.billingPeriod, .yearly, "Billing period should be yearly")
    }
    
    func testNoCurrentSubscriptionForFreeUser() async {
        // Given
        mockSubscriptionService.shouldSucceed = true
        mockSubscriptionService.mockSubscription = nil
        
        // When
        await viewModel.checkSubscriptionStatus()
        
        // Then
        XCTAssertNil(viewModel.currentSubscription, "Current subscription should be nil for free user")
    }
    
    func testExpiryDateDisplayedForActiveSubscription() async {
        // Given
        let expiryDate = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days from now
        mockSubscriptionService.shouldSucceed = true
        mockSubscriptionService.mockSubscription = Subscription(
            userId: "test-user",
            tier: .pro,
            billingPeriod: .monthly,
            status: .active,
            startDate: Date(),
            expiryDate: expiryDate,
            paymentMethod: .appleIAP
        )
        
        // When
        await viewModel.checkSubscriptionStatus()
        
        // Then
        XCTAssertNotNil(viewModel.currentSubscription, "Current subscription should be set")
        XCTAssertEqual(viewModel.currentSubscription?.expiryDate, expiryDate, "Expiry date should match")
        XCTAssertTrue(viewModel.currentSubscription?.isActive ?? false, "Subscription should be active")
    }
    
    // MARK: - Paywall Trigger Tests
    
    func testCanAccessFeatureReturnsFalseForFreeUser() async {
        // Given
        mockSubscriptionService.shouldSucceed = true
        mockSubscriptionService.mockSubscription = nil
        await viewModel.checkSubscriptionStatus()
        
        // When
        let canAccess = viewModel.canAccessFeature(.smartClean)
        
        // Then
        XCTAssertFalse(canAccess, "Free user should not be able to access premium features")
    }
    
    func testCanAccessFeatureReturnsTrueForProUser() async {
        // Given
        mockSubscriptionService.shouldSucceed = true
        mockSubscriptionService.mockSubscription = Subscription(
            userId: "test-user",
            tier: .pro,
            billingPeriod: .monthly,
            status: .active,
            startDate: Date(),
            expiryDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
            paymentMethod: .appleIAP
        )
        await viewModel.checkSubscriptionStatus()
        
        // When
        let canAccess = viewModel.canAccessFeature(.smartClean)
        
        // Then
        XCTAssertTrue(canAccess, "Pro user should be able to access premium features")
    }
    
    func testCanAccessFeatureReturnsTrueForMaxUser() async {
        // Given
        mockSubscriptionService.shouldSucceed = true
        mockSubscriptionService.mockSubscription = Subscription(
            userId: "test-user",
            tier: .max,
            billingPeriod: .yearly,
            status: .active,
            startDate: Date(),
            expiryDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
            paymentMethod: .appleIAP
        )
        await viewModel.checkSubscriptionStatus()
        
        // When
        let canAccess = viewModel.canAccessFeature(.photoEnhancer)
        
        // Then
        XCTAssertTrue(canAccess, "Max user should be able to access premium features")
    }
    
    func testCanAccessFeatureReturnsFalseForExpiredSubscription() async {
        // Given
        mockSubscriptionService.shouldSucceed = true
        mockSubscriptionService.mockSubscription = Subscription(
            userId: "test-user",
            tier: .pro,
            billingPeriod: .monthly,
            status: .expired,
            startDate: Date().addingTimeInterval(-60 * 24 * 60 * 60),
            expiryDate: Date().addingTimeInterval(-1 * 24 * 60 * 60), // Expired yesterday
            paymentMethod: .appleIAP
        )
        await viewModel.checkSubscriptionStatus()
        
        // When
        let canAccess = viewModel.canAccessFeature(.smartClean)
        
        // Then
        XCTAssertFalse(canAccess, "User with expired subscription should not be able to access premium features")
    }
    
    func testRequiredTierForPremiumFeatures() {
        // When
        let requiredTier = viewModel.requiredTier(for: .smartClean)
        
        // Then
        XCTAssertEqual(requiredTier, .pro, "Premium features should require at least Pro tier")
    }
    
    // MARK: - Purchase Flow Tests
    
    func testPurchaseSuccessUpdatesCurrentSubscription() async {
        // Given
        mockSubscriptionService.shouldSucceed = true
        await viewModel.loadProducts()
        let product = viewModel.availableProducts.first!
        
        // When
        await viewModel.purchase(product)
        
        // Then
        XCTAssertNotNil(viewModel.currentSubscription, "Current subscription should be set after successful purchase")
        XCTAssertEqual(viewModel.currentSubscription?.tier, product.tier, "Subscription tier should match purchased product")
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil after successful purchase")
    }
    
    func testPurchaseFailureDisplaysError() async {
        // Given
        // First load products successfully
        mockSubscriptionService.shouldSucceed = true
        await viewModel.loadProducts()
        let product = viewModel.availableProducts.first!
        
        // Then set shouldSucceed to false for the purchase
        mockSubscriptionService.shouldSucceed = false
        
        // When
        await viewModel.purchase(product)
        
        // Then
        XCTAssertNil(viewModel.currentSubscription, "Current subscription should remain nil after failed purchase")
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set after failed purchase")
        XCTAssertTrue(viewModel.errorMessage?.contains("购买失败") ?? false, "Error message should indicate purchase failure")
    }
    
    func testRestorePurchasesSuccessRestoresSubscription() async {
        // Given
        mockSubscriptionService.shouldSucceed = true
        mockSubscriptionService.mockSubscription = Subscription(
            userId: "test-user",
            tier: .pro,
            billingPeriod: .yearly,
            status: .active,
            startDate: Date(),
            expiryDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
            paymentMethod: .appleIAP
        )
        
        // When
        await viewModel.restorePurchases()
        
        // Then
        XCTAssertNotNil(viewModel.currentSubscription, "Current subscription should be restored")
        XCTAssertEqual(viewModel.currentSubscription?.tier, .pro, "Restored subscription tier should be Pro")
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil after successful restore")
    }
    
    func testRestorePurchasesWithNoSubscriptionsDisplaysError() async {
        // Given
        mockSubscriptionService.shouldSucceed = true
        mockSubscriptionService.mockSubscription = nil
        
        // When
        await viewModel.restorePurchases()
        
        // Then
        XCTAssertNil(viewModel.currentSubscription, "Current subscription should remain nil")
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set")
        XCTAssertTrue(viewModel.errorMessage?.contains("未找到有效的订阅") ?? false, "Error message should indicate no valid subscription found")
    }
    
    func testUpgradeSubscriptionSuccess() async {
        // Given
        mockSubscriptionService.shouldSucceed = true
        mockSubscriptionService.mockSubscription = Subscription(
            userId: "test-user",
            tier: .pro,
            billingPeriod: .monthly,
            status: .active,
            startDate: Date(),
            expiryDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
            paymentMethod: .appleIAP
        )
        await viewModel.checkSubscriptionStatus()
        
        // When
        await viewModel.upgradeSubscription(to: .max)
        
        // Then
        XCTAssertNotNil(viewModel.currentSubscription, "Current subscription should be updated")
        XCTAssertEqual(viewModel.currentSubscription?.tier, .max, "Subscription tier should be upgraded to Max")
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil after successful upgrade")
    }
}

// MARK: - Mock Subscription Service

class MockSubscriptionService: SubscriptionServiceProtocol {
    var shouldSucceed = true
    var errorToThrow: Error = SubscriptionError.unknownError(NSError(domain: "test", code: -1))
    var mockSubscription: Subscription?
    
    func fetchAvailableProducts() async throws -> [SubscriptionProduct] {
        if shouldSucceed {
            return [
                SubscriptionProduct(
                    id: "joyhisn.Declutter.pro.monthly",
                    tier: .pro,
                    billingPeriod: .monthly,
                    price: 10,
                    localizedPrice: "¥10",
                    localizedDescription: "专业版月付"
                ),
                SubscriptionProduct(
                    id: "joyhisn.Declutter.pro.yearly",
                    tier: .pro,
                    billingPeriod: .yearly,
                    price: 100,
                    localizedPrice: "¥100",
                    localizedDescription: "专业版年付"
                ),
                SubscriptionProduct(
                    id: "joyhisn.Declutter.max.monthly",
                    tier: .max,
                    billingPeriod: .monthly,
                    price: 20,
                    localizedPrice: "¥20",
                    localizedDescription: "旗舰版月付"
                ),
                SubscriptionProduct(
                    id: "joyhisn.Declutter.max.yearly",
                    tier: .max,
                    billingPeriod: .yearly,
                    price: 200,
                    localizedPrice: "¥200",
                    localizedDescription: "旗舰版年付"
                )
            ]
        } else {
            throw errorToThrow
        }
    }
    
    func purchase(_ product: SubscriptionProduct) async throws -> PurchaseResult {
        if shouldSucceed {
            let subscription = Subscription(
                userId: "test-user",
                tier: product.tier,
                billingPeriod: product.billingPeriod,
                status: .active,
                startDate: Date(),
                expiryDate: Date().addingTimeInterval(product.billingPeriod == .monthly ? 30 * 24 * 60 * 60 : 365 * 24 * 60 * 60),
                paymentMethod: .appleIAP
            )
            mockSubscription = subscription
            return PurchaseResult(success: true, subscription: subscription, transaction: nil, error: nil)
        } else {
            return PurchaseResult(success: false, subscription: nil, transaction: nil, error: errorToThrow)
        }
    }
    
    func restorePurchases() async throws -> [Subscription] {
        if shouldSucceed {
            if let subscription = mockSubscription {
                return [subscription]
            } else {
                return []
            }
        } else {
            throw errorToThrow
        }
    }
    
    func getCurrentSubscription() async throws -> Subscription? {
        if shouldSucceed {
            return mockSubscription
        } else {
            throw errorToThrow
        }
    }
    
    func validateSubscription() async throws -> Bool {
        if shouldSucceed {
            return mockSubscription?.isActive ?? false
        } else {
            throw errorToThrow
        }
    }
    
    func cancelSubscription() async throws {
        if shouldSucceed {
            // Simulate cancellation
            if var subscription = mockSubscription {
                subscription.status = .cancelled
                mockSubscription = subscription
            }
        } else {
            throw errorToThrow
        }
    }
    
    func upgradeSubscription(to tier: SubscriptionTier) async throws -> PurchaseResult {
        if shouldSucceed {
            let subscription = Subscription(
                userId: "test-user",
                tier: tier,
                billingPeriod: mockSubscription?.billingPeriod ?? .monthly,
                status: .active,
                startDate: Date(),
                expiryDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                paymentMethod: .appleIAP
            )
            mockSubscription = subscription
            return PurchaseResult(success: true, subscription: subscription, transaction: nil, error: nil)
        } else {
            return PurchaseResult(success: false, subscription: nil, transaction: nil, error: errorToThrow)
        }
    }
    
    func checkAndHandleExpiration() async throws -> Bool {
        if shouldSucceed {
            guard let subscription = mockSubscription else {
                return false
            }
            
            if subscription.isExpired {
                // Update status to expired
                var expiredSubscription = subscription
                expiredSubscription.status = .expired
                mockSubscription = expiredSubscription
                return true
            }
            
            return false
        } else {
            throw errorToThrow
        }
    }
    
    func getCurrentSubscriptionOffline() async -> Subscription? {
        // Return cached subscription if available
        return mockSubscription
    }
    
    func syncSubscriptionOnNetworkRestore() async throws {
        if !shouldSucceed {
            throw errorToThrow
        }
        // Simulate sync - in mock, this is a no-op
    }
}
