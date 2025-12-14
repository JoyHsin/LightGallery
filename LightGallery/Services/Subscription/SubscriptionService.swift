//
//  SubscriptionService.swift
//  LightGallery
//
//  Created for user-auth-subscription feature
//

import Foundation
import StoreKit

protocol SubscriptionServiceProtocol {
    /// 获取可用的订阅产品
    func fetchAvailableProducts() async throws -> [SubscriptionProduct]
    
    /// 购买订阅
    func purchase(_ product: SubscriptionProduct) async throws -> PurchaseResult
    
    /// 恢复购买
    func restorePurchases() async throws -> [Subscription]
    
    /// 获取当前订阅状态
    func getCurrentSubscription() async throws -> Subscription?
    
    /// 获取当前订阅状态（离线支持）
    func getCurrentSubscriptionOffline() async -> Subscription?
    
    /// 验证订阅状态
    func validateSubscription() async throws -> Bool
    
    /// 取消订阅（引导用户到系统设置）
    func cancelSubscription() async throws
    
    /// 升级订阅
    func upgradeSubscription(to tier: SubscriptionTier) async throws -> PurchaseResult
    
    /// 检查并处理订阅过期
    func checkAndHandleExpiration() async throws -> Bool
    
    /// 网络恢复时同步订阅
    func syncSubscriptionOnNetworkRestore() async throws
    
    /// 检查已取消的订阅是否仍有访问权限
    func cancelledSubscriptionHasAccess(_ subscription: Subscription) -> Bool
}

class SubscriptionService: SubscriptionServiceProtocol {
    private let appleIAPManager: AppleIAPManager
    private let subscriptionCache: SubscriptionCache
    private let backendAPIClient: BackendAPIClient
    private let networkMonitor: NetworkMonitor
    
    init(
        appleIAPManager: AppleIAPManager = AppleIAPManager(),
        subscriptionCache: SubscriptionCache = SubscriptionCache(),
        backendAPIClient: BackendAPIClient = .shared,
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.appleIAPManager = appleIAPManager
        self.subscriptionCache = subscriptionCache
        self.backendAPIClient = backendAPIClient
        self.networkMonitor = networkMonitor
        
        // Set up network restoration handler
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.onConnectionRestored { [weak self] in
            guard let self = self else { return }
            try? await self.syncSubscriptionOnNetworkRestore()
        }
    }
    
    func fetchAvailableProducts() async throws -> [SubscriptionProduct] {
        // Always return mock products for development/testing
        // This allows UI testing without App Store Connect configuration
        
        print("Using mock products for development/testing")
        return createMockProducts()
        
        // TODO: Enable real StoreKit integration when App Store Connect is configured
        /*
        do {
            // Try to fetch products from Apple IAP
            let productIds = [
                "joyhisn.LightGallery.pro.monthly",
                "joyhisn.LightGallery.pro.yearly",
                "joyhisn.LightGallery.max.monthly",
                "joyhisn.LightGallery.max.yearly"
            ]
            
            let storeKitProducts = try await appleIAPManager.fetchProducts(productIds: productIds)
            
            // If we got products from StoreKit, use them
            if !storeKitProducts.isEmpty {
                return storeKitProducts.compactMap { product in
                    guard let (tier, period) = parseProductId(product.id) else {
                        return nil
                    }
                    
                    return SubscriptionProduct(
                        id: product.id,
                        tier: tier,
                        billingPeriod: period,
                        price: product.price as Decimal,
                        currency: product.priceFormatStyle.currencyCode,
                        localizedPrice: product.displayPrice,
                        localizedDescription: product.description,
                        storeKitProduct: product
                    )
                }
            }
        } catch {
            print("Failed to fetch StoreKit products: \(error)")
        }
        
        // Fallback to mock products for development/testing
        print("Using mock products as fallback")
        return createMockProducts()
        */
    }
    
    /// Create mock products for development/testing
    private func createMockProducts() -> [SubscriptionProduct] {
        return [
            SubscriptionProduct(
                id: "joyhisn.LightGallery.pro.monthly",
                tier: .pro,
                billingPeriod: .monthly,
                price: 10.00,
                currency: "CNY",
                localizedPrice: "¥10",
                localizedDescription: "专业版月付订阅",
                storeKitProduct: nil
            ),
            SubscriptionProduct(
                id: "joyhisn.LightGallery.pro.yearly",
                tier: .pro,
                billingPeriod: .yearly,
                price: 100.00,
                currency: "CNY",
                localizedPrice: "¥100",
                localizedDescription: "专业版年付订阅",
                storeKitProduct: nil
            ),
            SubscriptionProduct(
                id: "joyhisn.LightGallery.max.monthly",
                tier: .max,
                billingPeriod: .monthly,
                price: 20.00,
                currency: "CNY",
                localizedPrice: "¥20",
                localizedDescription: "旗舰版月付订阅",
                storeKitProduct: nil
            ),
            SubscriptionProduct(
                id: "joyhisn.LightGallery.max.yearly",
                tier: .max,
                billingPeriod: .yearly,
                price: 200.00,
                currency: "CNY",
                localizedPrice: "¥200",
                localizedDescription: "旗舰版年付订阅",
                storeKitProduct: nil
            )
        ]
    }
    
    func purchase(_ product: SubscriptionProduct) async throws -> PurchaseResult {
        // Always simulate successful purchase for development/testing
        print("Simulating successful purchase for product: \(product.id)")
        
        let mockSubscription = Subscription(
            id: UUID().uuidString,
            userId: "debug_user",
            tier: product.tier,
            billingPeriod: product.billingPeriod,
            status: .active,
            startDate: Date(),
            expiryDate: Calendar.current.date(byAdding: product.billingPeriod == .monthly ? .month : .year, value: 1, to: Date()) ?? Date(),
            autoRenew: true,
            paymentMethod: .appleIAP,
            lastSyncedAt: Date()
        )
        
        // Cache the mock subscription
        subscriptionCache.cacheSubscription(mockSubscription)
        
        return PurchaseResult(
            success: true,
            subscription: mockSubscription,
            transaction: nil,
            error: nil
        )
        
        // TODO: Enable real IAP when App Store Connect is configured
        /*
        guard let storeKitProduct = product.storeKitProduct else {
            throw SubscriptionError.productNotFound
        }
        
        do {
            // Purchase through Apple IAP
            let transaction = try await appleIAPManager.purchase(storeKitProduct)
            
            // Get auth token for backend verification
            guard let authToken = try? SecureStorage.shared.getCredentials()?.authToken.accessToken else {
                throw SubscriptionError.verificationFailed
            }
            
            // Verify with backend
            let verificationResponse = try await backendAPIClient.verifyAppleReceipt(transaction, authToken: authToken)
            
            guard verificationResponse.success else {
                throw SubscriptionError.verificationFailed
            }
            
            // Create subscription from backend response or transaction
            let subscription: Subscription
            if let subscriptionDTO = verificationResponse.subscription {
                subscription = try convertDTOToSubscription(subscriptionDTO)
            } else {
                subscription = try await createSubscriptionFromTransaction(transaction, product: product)
            }
            
            // Cache the subscription
            subscriptionCache.cacheSubscription(subscription)
            
            // Sync with backend
            try? await backendAPIClient.syncSubscription(subscription, authToken: authToken)
            
            return PurchaseResult(
                success: true,
                subscription: subscription,
                transaction: transaction,
                error: nil
            )
        } catch let error as SubscriptionError {
            return PurchaseResult(
                success: false,
                subscription: nil,
                transaction: nil,
                error: error
            )
        } catch {
            return PurchaseResult(
                success: false,
                subscription: nil,
                transaction: nil,
                error: SubscriptionError.unknownError(error)
            )
        }
        */
    }
    
    func restorePurchases() async throws -> [Subscription] {
        // Restore purchases from Apple
        var subscriptions: [Subscription] = []
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if let subscription = try? await createSubscriptionFromTransaction(transaction) {
                    subscriptions.append(subscription)
                }
            }
        }
        
        // Cache the most recent active subscription
        if let activeSubscription = subscriptions.first(where: { $0.isActive }) {
            subscriptionCache.cacheSubscription(activeSubscription)
        }
        
        return subscriptions
    }
    
    func getCurrentSubscription() async throws -> Subscription? {
        // Check cache first
        if let cachedSubscription = subscriptionCache.getCachedSubscription(),
           subscriptionCache.isCacheValid() {
            return cachedSubscription
        }
        
        // Try to fetch from Apple if cache is stale
        do {
            let subscriptions = try await restorePurchases()
            let activeSubscription = subscriptions.first(where: { $0.isActive })
            
            // Update cache with fresh data
            if let subscription = activeSubscription {
                subscriptionCache.cacheSubscription(subscription)
            }
            
            return activeSubscription
        } catch {
            // If network fails and we have stale cache, use it if < 24 hours old
            if let cachedSubscription = subscriptionCache.getCachedSubscription(),
               subscriptionCache.isCacheValid() {
                return cachedSubscription
            }
            
            // If cache is too old (> 24 hours), throw network error
            throw SubscriptionError.networkError
        }
    }
    
    /// Get current subscription with offline support
    /// - Returns: Subscription if available, nil if no subscription or cache expired
    /// - Note: This method uses cached data when network is unavailable
    func getCurrentSubscriptionOffline() async -> Subscription? {
        // Always check cache first
        if let cachedSubscription = subscriptionCache.getCachedSubscription() {
            // If cache is valid (< 24 hours), use it
            if subscriptionCache.isCacheValid() {
                return cachedSubscription
            }
            
            // Cache is stale but we're offline - restrict access
            // Return nil to indicate no valid subscription
            return nil
        }
        
        // Try to fetch from network
        do {
            return try await getCurrentSubscription()
        } catch {
            // Network failed and no cache available
            return nil
        }
    }
    
    /// Sync subscription with backend when network is restored
    func syncSubscriptionOnNetworkRestore() async throws {
        // Get auth token
        guard let authToken = try? SecureStorage.shared.getCredentials()?.authToken.accessToken else {
            return
        }
        
        // Fetch latest subscription from Apple
        let subscriptions = try await restorePurchases()
        
        guard let activeSubscription = subscriptions.first(where: { $0.isActive }) else {
            // No active subscription, clear cache
            subscriptionCache.clearCache()
            return
        }
        
        // Update cache
        subscriptionCache.cacheSubscription(activeSubscription)
        
        // Sync with backend
        try await backendAPIClient.syncSubscription(activeSubscription, authToken: authToken)
    }
    
    func validateSubscription() async throws -> Bool {
        guard let subscription = try await getCurrentSubscription() else {
            return false
        }
        
        return subscription.isActive
    }
    
    /// Check if subscription is expired and handle accordingly
    /// - Returns: True if subscription is expired, false otherwise
    func checkAndHandleExpiration() async throws -> Bool {
        guard let subscription = try await getCurrentSubscription() else {
            // No subscription means user is on free tier
            return false
        }
        
        // Check if subscription is expired
        if subscription.isExpired {
            // Update subscription status to expired
            var expiredSubscription = subscription
            expiredSubscription.status = .expired
            
            // Update cache with expired status
            subscriptionCache.cacheSubscription(expiredSubscription)
            
            // Sync with backend
            if let authToken = try? SecureStorage.shared.getCredentials()?.authToken.accessToken {
                try? await backendAPIClient.syncSubscription(expiredSubscription, authToken: authToken)
            }
            
            return true
        }
        
        return false
    }
    
    /// Cancel subscription by guiding user to App Store settings
    /// Note: On iOS, subscriptions can only be cancelled through App Store settings
    /// This method opens the subscription management page
    func cancelSubscription() async throws {
        // On iOS, we need to guide users to App Store settings
        // We can open the subscription management URL
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else {
            throw SubscriptionError.insufficientPermissions
        }
        
        #if os(iOS)
        await MainActor.run {
            UIApplication.shared.open(url)
        }
        #elseif os(macOS)
        await MainActor.run {
            NSWorkspace.shared.open(url)
        }
        #endif
        
        // Note: The subscription will remain active until the current billing period ends
        // We don't update the status here - it will be updated when we sync with Apple
    }
    
    /// Handle cancelled subscription status
    /// Updates local cache to reflect cancelled status while maintaining access until expiry
    func handleCancelledSubscription(_ subscription: Subscription) async throws {
        var cancelledSubscription = subscription
        cancelledSubscription.status = .cancelled
        cancelledSubscription.autoRenew = false
        
        // Update cache
        subscriptionCache.cacheSubscription(cancelledSubscription)
        
        // Sync with backend
        if let authToken = try? SecureStorage.shared.getCredentials()?.authToken.accessToken {
            try? await backendAPIClient.syncSubscription(cancelledSubscription, authToken: authToken)
        }
    }
    
    /// Check if a cancelled subscription still has access
    /// Cancelled subscriptions maintain access until the current billing period ends
    /// - Parameter subscription: The subscription to check
    /// - Returns: True if subscription is cancelled but still has access
    func cancelledSubscriptionHasAccess(_ subscription: Subscription) -> Bool {
        return subscription.status == .cancelled && !subscription.isExpired
    }
    
    func upgradeSubscription(to tier: SubscriptionTier) async throws -> PurchaseResult {
        // Get current subscription
        guard let currentSubscription = try await getCurrentSubscription() else {
            throw SubscriptionError.productNotFound
        }
        
        // Validate upgrade is to a higher tier
        guard tier > currentSubscription.tier else {
            throw SubscriptionError.purchaseFailed(reason: "只能升级到更高的订阅层级")
        }
        
        // Fetch available products
        let products = try await fetchAvailableProducts()
        
        // Find the upgrade product (same billing period as current subscription)
        guard let upgradeProduct = products.first(where: {
            $0.tier == tier && $0.billingPeriod == currentSubscription.billingPeriod
        }) else {
            throw SubscriptionError.productNotFound
        }
        
        // Calculate prorated pricing
        let proratedAmount = calculateProratedUpgrade(
            currentSubscription: currentSubscription,
            upgradeProduct: upgradeProduct
        )
        
        print("Upgrade from \(currentSubscription.tier.displayName) to \(tier.displayName)")
        print("Prorated amount: ¥\(proratedAmount)")
        print("Days remaining: \(currentSubscription.daysRemaining)")
        
        // Purchase the upgrade
        // Note: Apple IAP handles prorated pricing automatically for subscription upgrades
        return try await purchase(upgradeProduct)
    }
    
    /// Calculate prorated pricing for subscription upgrade
    /// - Parameters:
    ///   - currentSubscription: Current active subscription
    ///   - upgradeProduct: Product to upgrade to
    /// - Returns: Prorated amount to charge
    func calculateProratedUpgrade(
        currentSubscription: Subscription,
        upgradeProduct: SubscriptionProduct
    ) -> Decimal {
        // Get the price difference between tiers
        let currentPrice = getPriceForTier(currentSubscription.tier, period: currentSubscription.billingPeriod)
        let upgradePrice = upgradeProduct.price
        let priceDifference = upgradePrice - currentPrice
        
        // Calculate remaining days in current billing period
        let totalDays = getTotalDaysInPeriod(currentSubscription.billingPeriod)
        let remainingDays = Decimal(currentSubscription.daysRemaining)
        
        // Calculate prorated amount: (price difference) * (remaining days / total days)
        let proratedAmount = priceDifference * (remainingDays / Decimal(totalDays))
        
        // Round to 2 decimal places
        let rounded = ((proratedAmount * Decimal(100)) as NSDecimalNumber).doubleValue.rounded() / 100
        
        return max(0, Decimal(rounded))
    }
    
    /// Get price for a specific tier and billing period
    private func getPriceForTier(_ tier: SubscriptionTier, period: BillingPeriod) -> Decimal {
        switch (tier, period) {
        case (.free, _):
            return 0
        case (.pro, .monthly):
            return 10
        case (.pro, .yearly):
            return 100
        case (.max, .monthly):
            return 20
        case (.max, .yearly):
            return 200
        }
    }
    
    /// Get total days in a billing period
    private func getTotalDaysInPeriod(_ period: BillingPeriod) -> Int {
        switch period {
        case .monthly:
            return 30
        case .yearly:
            return 365
        }
    }
    
    // MARK: - Private Helpers
    
    private func parseProductId(_ productId: String) -> (SubscriptionTier, BillingPeriod)? {
        let components = productId.split(separator: ".")
        guard components.count >= 3 else { return nil }
        
        let tierString = String(components[components.count - 2])
        let periodString = String(components[components.count - 1])
        
        guard let tier = SubscriptionTier(rawValue: tierString),
              let period = BillingPeriod(rawValue: periodString) else {
            return nil
        }
        
        return (tier, period)
    }
    
    private func createSubscriptionFromTransaction(
        _ transaction: Transaction,
        product: SubscriptionProduct? = nil
    ) async throws -> Subscription {
        // Parse product info from transaction
        let (tier, period) = parseProductId(transaction.productID) ?? (.free, .monthly)
        
        // Get user ID from auth service
        let userId = "current_user_id" // TODO: Get from AuthenticationService
        
        let startDate = transaction.purchaseDate
        let expiryDate = transaction.expirationDate ?? Calendar.current.date(
            byAdding: period == .monthly ? .month : .year,
            value: 1,
            to: startDate
        ) ?? startDate
        
        return Subscription(
            id: String(transaction.id),
            userId: userId,
            tier: tier,
            billingPeriod: period,
            status: .active,
            startDate: startDate,
            expiryDate: expiryDate,
            autoRenew: true,
            paymentMethod: .appleIAP,
            lastSyncedAt: Date()
        )
    }
    
    private func convertDTOToSubscription(_ dto: SubscriptionDTO) throws -> Subscription {
        guard let tier = SubscriptionTier(rawValue: dto.tier),
              let period = BillingPeriod(rawValue: dto.billingPeriod),
              let status = SubscriptionStatus(rawValue: dto.status),
              let paymentMethod = PaymentMethod(rawValue: dto.paymentMethod) else {
            throw SubscriptionError.unknownError(NSError(domain: "SubscriptionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid subscription data from backend"]))
        }
        
        return Subscription(
            id: dto.id,
            userId: dto.userId,
            tier: tier,
            billingPeriod: period,
            status: status,
            startDate: dto.startDate,
            expiryDate: dto.expiryDate,
            autoRenew: dto.autoRenew,
            paymentMethod: paymentMethod,
            lastSyncedAt: Date()
        )
    }
}

enum SubscriptionError: LocalizedError {
    case productNotFound
    case purchaseFailed(reason: String)
    case verificationFailed
    case networkError
    case userCancelled
    case alreadySubscribed
    case insufficientPermissions
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "未找到订阅产品，请稍后重试"
        case .purchaseFailed:
            // 统一使用中文错误提示，避免混合语言
            return "购买失败，请稍后重试"
        case .verificationFailed:
            return "支付验证失败，请联系客服"
        case .networkError:
            return "网络连接失败，请检查网络设置后重试"
        case .userCancelled:
            return "已取消购买"
        case .alreadySubscribed:
            return "您已经订阅了此服务"
        case .insufficientPermissions:
            return "权限不足，无法完成购买"
        case .unknownError:
            // 统一使用中文错误提示，避免显示英文系统错误
            return "购买失败，请稍后重试或联系客服"
        }
    }
}
