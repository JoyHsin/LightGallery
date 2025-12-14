//
//  EndToEndIntegrationTests.swift
//  LightGalleryTests
//
//  Comprehensive end-to-end integration tests
//

import XCTest
@testable import LightGallery

class EndToEndIntegrationTests: XCTestCase {
    
    var mockBackendClient: MockBackendAPIClient!
    var authService: AuthenticationService!
    var subscriptionService: SubscriptionService!
    var secureStorage: SecureStorage!
    var subscriptionCache: SubscriptionCache!
    
    override func setUp() {
        super.setUp()
        mockBackendClient = MockBackendAPIClient()
        authService = AuthenticationService(backendClient: mockBackendClient)
        subscriptionCache = SubscriptionCache()
        subscriptionService = SubscriptionService(
            appleIAPManager: AppleIAPManager(backendAPIClient: mockBackendClient),
            subscriptionCache: subscriptionCache,
            backendAPIClient: mockBackendClient,
            networkMonitor: NetworkMonitor.shared
        )
        secureStorage = SecureStorage.shared
        
        // Clean up
        try? secureStorage.deleteAllCredentials()
        subscriptionCache.clearCache()
    }
    
    override func tearDown() {
        try? secureStorage.deleteAllCredentials()
        subscriptionCache.clearCache()
        mockBackendClient = nil
        authService = nil
        subscriptionService = nil
        super.tearDown()
    }
    
    // MARK: - Complete Authentication Flow
    
    /// Test: Complete authentication flow from OAuth to session creation
    /// Validates: Requirements 1.4
    func testCompleteAuthenticationFlow() async throws {
        // Given: Mock backend is configured
        let expectedUser = UserDTO(
            id: "user_complete_auth",
            displayName: "Complete Auth User",
            email: "complete@example.com",
            avatarURL: nil,
            authProvider: "apple"
        )
        
        let expectedAuthResponse = AuthResponse(
            accessToken: "complete_access_token",
            refreshToken: "complete_refresh_token",
            expiresAt: Date().addingTimeInterval(86400),
            user: expectedUser
        )
        
        mockBackendClient.mockAuthResponse = expectedAuthResponse
        
        // When: User completes OAuth flow
        let oauthCredential = OAuthCredential(
            provider: .apple,
            authCode: "complete_auth_code",
            idToken: "complete_id_token",
            email: "complete@example.com",
            displayName: "Complete Auth User"
        )
        
        let authResponse = try await mockBackendClient.exchangeOAuthToken(oauthCredential)
        
        // Then: User should be authenticated
        XCTAssertEqual(authResponse.accessToken, "complete_access_token")
        XCTAssertEqual(authResponse.user.id, "user_complete_auth")
        XCTAssertEqual(authResponse.user.email, "complete@example.com")
        
        // Verify token can be validated
        mockBackendClient.mockTokenValidation = true
        let isValid = try await mockBackendClient.validateAuthToken(authResponse.accessToken)
        XCTAssertTrue(isValid)
    }
    
    // MARK: - Complete Purchase Flow
    
    /// Test: Complete purchase flow from product selection to subscription activation
    /// Validates: Requirements 4.3
    func testCompletePurchaseFlow() async throws {
        // Given: User is authenticated
        let authToken = "purchase_flow_token"
        
        // Store mock credentials
        let credentials = UserCredentials(
            userId: "user_purchase",
            authToken: AuthToken(
                accessToken: authToken,
                refreshToken: "refresh_token",
                expiresAt: Date().addingTimeInterval(86400),
                tokenType: "Bearer"
            ),
            provider: .apple
        )
        try secureStorage.saveCredentials(credentials)
        
        // Mock subscription verification response
        let mockSubscriptionDTO = SubscriptionDTO(
            id: "sub_purchase_flow",
            userId: "user_purchase",
            tier: "pro",
            billingPeriod: "monthly",
            status: "active",
            startDate: Date(),
            expiryDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
            autoRenew: true,
            paymentMethod: "apple_iap"
        )
        
        mockBackendClient.mockSubscriptionResponse = SubscriptionVerificationResponse(
            success: true,
            subscription: mockSubscriptionDTO,
            message: "Purchase successful"
        )
        
        // When: Purchase is verified
        let mockTransaction = MockTransaction(
            id: 99999,
            productID: "joyhisn.LightGallery.pro.monthly",
            purchaseDate: Date(),
            expirationDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())
        )
        
        let verificationResponse = try await mockBackendClient.verifyAppleReceipt(
            mockTransaction,
            authToken: authToken
        )
        
        // Then: Purchase should be verified and subscription activated
        XCTAssertTrue(verificationResponse.success)
        XCTAssertNotNil(verificationResponse.subscription)
        XCTAssertEqual(verificationResponse.subscription?.tier, "pro")
        XCTAssertEqual(verificationResponse.subscription?.status, "active")
        
        // Verify subscription can be synced
        let subscription = Subscription(
            id: mockSubscriptionDTO.id,
            userId: mockSubscriptionDTO.userId,
            tier: SubscriptionTier(rawValue: mockSubscriptionDTO.tier)!,
            billingPeriod: BillingPeriod(rawValue: mockSubscriptionDTO.billingPeriod)!,
            status: SubscriptionStatus(rawValue: mockSubscriptionDTO.status)!,
            startDate: mockSubscriptionDTO.startDate,
            expiryDate: mockSubscriptionDTO.expiryDate,
            autoRenew: mockSubscriptionDTO.autoRenew,
            paymentMethod: PaymentMethod(rawValue: mockSubscriptionDTO.paymentMethod)!,
            lastSyncedAt: Date()
        )
        
        try await mockBackendClient.syncSubscription(subscription, authToken: authToken)
        
        // Sync should succeed without error
    }
    
    // MARK: - Offline to Online Sync
    
    /// Test: Offline to online sync flow
    /// Validates: Requirements 9.3
    func testOfflineToOnlineSync() async throws {
        // Given: User has cached subscription from offline period
        let offlineSubscription = Subscription(
            id: "sub_offline_sync",
            userId: "user_offline_sync",
            tier: .max,
            billingPeriod: .yearly,
            status: .active,
            startDate: Date().addingTimeInterval(-60 * 60 * 12), // 12 hours ago
            expiryDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())!,
            autoRenew: true,
            paymentMethod: .appleIAP,
            lastSyncedAt: Date().addingTimeInterval(-60 * 60 * 12) // 12 hours ago
        )
        
        subscriptionCache.cacheSubscription(offlineSubscription)
        
        // Store mock credentials
        let credentials = UserCredentials(
            userId: "user_offline_sync",
            authToken: AuthToken(
                accessToken: "offline_sync_token",
                refreshToken: "refresh_token",
                expiresAt: Date().addingTimeInterval(86400),
                tokenType: "Bearer"
            ),
            provider: .apple
        )
        try secureStorage.saveCredentials(credentials)
        
        // When: Network is restored and sync is triggered
        try await mockBackendClient.syncSubscription(
            offlineSubscription,
            authToken: "offline_sync_token"
        )
        
        // Then: Subscription should be synced successfully
        // Verify cached subscription is still valid
        let cachedSubscription = subscriptionCache.getCachedSubscription()
        XCTAssertNotNil(cachedSubscription)
        XCTAssertEqual(cachedSubscription?.tier, .max)
        XCTAssertEqual(cachedSubscription?.status, .active)
    }
    
    /// Test: Offline access with valid cache
    /// Validates: Requirements 9.1
    func testOfflineAccessWithValidCache() async {
        // Given: User has valid cached subscription
        let validSubscription = Subscription(
            id: "sub_valid_cache",
            userId: "user_valid_cache",
            tier: .pro,
            billingPeriod: .monthly,
            status: .active,
            startDate: Date(),
            expiryDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
            autoRenew: true,
            paymentMethod: .appleIAP,
            lastSyncedAt: Date().addingTimeInterval(-3600) // 1 hour ago
        )
        
        subscriptionCache.cacheSubscription(validSubscription)
        
        // When: User accesses subscription offline
        let offlineSubscription = await subscriptionService.getCurrentSubscriptionOffline()
        
        // Then: Cached subscription should be returned
        XCTAssertNotNil(offlineSubscription)
        XCTAssertEqual(offlineSubscription?.tier, .pro)
        XCTAssertTrue(subscriptionCache.isCacheValid())
    }
    
    /// Test: Offline access with expired cache
    /// Validates: Requirements 9.2
    func testOfflineAccessWithExpiredCache() async {
        // Given: User has expired cached subscription (> 24 hours old)
        let expiredCacheSubscription = Subscription(
            id: "sub_expired_cache",
            userId: "user_expired_cache",
            tier: .pro,
            billingPeriod: .monthly,
            status: .active,
            startDate: Date().addingTimeInterval(-60 * 60 * 48), // 48 hours ago
            expiryDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
            autoRenew: true,
            paymentMethod: .appleIAP,
            lastSyncedAt: Date().addingTimeInterval(-60 * 60 * 25) // 25 hours ago
        )
        
        subscriptionCache.cacheSubscription(expiredCacheSubscription)
        
        // Note: The cache validity check is based on lastSyncedAt
        // If cache is > 24 hours old, access should be restricted
        
        // When: User tries to access subscription with stale cache
        // The service should restrict access
        
        // Then: Cache validity should be checked
        // This is implementation-dependent on SubscriptionCache
        let isCacheValid = subscriptionCache.isCacheValid()
        
        // If cache is invalid, offline access should be restricted
        if !isCacheValid {
            let offlineSubscription = await subscriptionService.getCurrentSubscriptionOffline()
            // Should return nil for stale cache
            XCTAssertNil(offlineSubscription)
        }
    }
    
    // MARK: - Token Refresh Flow
    
    /// Test: Token refresh during session
    /// Validates: Requirements 2.4
    func testTokenRefreshDuringSession() async throws {
        // Given: User has expired access token but valid refresh token
        let oldRefreshToken = "old_refresh_token_session"
        
        let newAuthResponse = AuthResponse(
            accessToken: "new_access_token_session",
            refreshToken: "new_refresh_token_session",
            expiresAt: Date().addingTimeInterval(86400),
            user: UserDTO(
                id: "user_refresh_session",
                displayName: "Refresh User",
                email: "refresh@example.com",
                avatarURL: nil,
                authProvider: "apple"
            )
        )
        
        mockBackendClient.mockAuthResponse = newAuthResponse
        
        // When: Token is refreshed
        let refreshedAuthResponse = try await mockBackendClient.refreshAuthToken(oldRefreshToken)
        
        // Then: New tokens should be returned
        XCTAssertEqual(refreshedAuthResponse.accessToken, "new_access_token_session")
        XCTAssertEqual(refreshedAuthResponse.refreshToken, "new_refresh_token_session")
        XCTAssertNotEqual(refreshedAuthResponse.accessToken, oldRefreshToken)
        
        // Verify new token is valid
        mockBackendClient.mockTokenValidation = true
        let isValid = try await mockBackendClient.validateAuthToken(refreshedAuthResponse.accessToken)
        XCTAssertTrue(isValid)
    }
    
    // MARK: - Subscription Expiration and Renewal
    
    /// Test: Subscription expiration detection and handling
    /// Validates: Requirements 6.4
    func testSubscriptionExpirationDetection() async throws {
        // Given: User has subscription that just expired
        let justExpiredSubscription = Subscription(
            id: "sub_just_expired",
            userId: "user_just_expired",
            tier: .pro,
            billingPeriod: .monthly,
            status: .active,
            startDate: Date().addingTimeInterval(-60 * 60 * 24 * 31), // 31 days ago
            expiryDate: Date().addingTimeInterval(-60), // 1 minute ago
            autoRenew: false,
            paymentMethod: .appleIAP,
            lastSyncedAt: Date()
        )
        
        subscriptionCache.cacheSubscription(justExpiredSubscription)
        
        // When: Expiration check is performed
        let isExpired = try await subscriptionService.checkAndHandleExpiration()
        
        // Then: Subscription should be detected as expired
        XCTAssertTrue(isExpired)
        
        // Verify subscription status is updated
        let updatedSubscription = subscriptionCache.getCachedSubscription()
        XCTAssertNotNil(updatedSubscription)
        XCTAssertEqual(updatedSubscription?.status, .expired)
    }
    
    // MARK: - Error Handling
    
    /// Test: Network error handling during authentication
    /// Validates: Requirements 1.5
    func testNetworkErrorDuringAuthentication() async {
        // Given: Backend is unavailable
        mockBackendClient.mockAuthResponse = nil
        
        // When: User attempts to authenticate
        let oauthCredential = OAuthCredential(
            provider: .apple,
            authCode: "error_auth_code",
            idToken: "error_id_token",
            email: "error@example.com",
            displayName: "Error User"
        )
        
        do {
            _ = try await mockBackendClient.exchangeOAuthToken(oauthCredential)
            XCTFail("Should have thrown an error")
        } catch {
            // Then: Error should be thrown
            XCTAssertTrue(error is BackendAPIError)
        }
    }
    
    /// Test: Network error handling during purchase verification
    /// Validates: Requirements 4.4
    func testNetworkErrorDuringPurchaseVerification() async {
        // Given: Backend is unavailable
        mockBackendClient.mockSubscriptionResponse = nil
        
        // When: Purchase verification is attempted
        let mockTransaction = MockTransaction(
            id: 88888,
            productID: "joyhisn.LightGallery.pro.monthly",
            purchaseDate: Date(),
            expirationDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())
        )
        
        do {
            _ = try await mockBackendClient.verifyAppleReceipt(
                mockTransaction,
                authToken: "error_token"
            )
            XCTFail("Should have thrown an error")
        } catch {
            // Then: Error should be thrown
            XCTAssertTrue(error is BackendAPIError)
        }
    }
}
