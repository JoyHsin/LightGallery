# Design Document: User Authentication and Subscription System

## Overview

本设计文档描述了 LightGallery 应用的用户认证和订阅付费系统的技术架构和实现方案。该系统将实现：

- **多平台第三方登录**：支持微信、支付宝和 Apple ID 三种登录方式
- **分层订阅模型**：Free、Pro（10元/月或100元/年）、Max（20元/月或200元/年）三个层级
- **跨平台支付集成**：iOS 使用 Apple IAP，Android/Web 使用微信支付和支付宝
- **功能权限控制**：基于订阅状态的细粒度访问控制
- **离线优先架构**：支持网络不稳定情况下的正常使用

该系统将与现有的 SwiftUI 应用架构无缝集成，使用 MVVM 模式，并遵循 iOS 平台最佳实践。

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      LightGallery App                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Views      │  │  ViewModels  │  │   Models     │      │
│  │              │  │              │  │              │      │
│  │ - LoginView  │→ │ - AuthVM     │→ │ - User       │      │
│  │ - SubView    │  │ - SubVM      │  │ - Subscription│     │
│  │ - PaywallView│  │              │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         ↓                  ↓                                 │
│  ┌──────────────────────────────────────────────────┐      │
│  │              Service Layer                        │      │
│  │                                                    │      │
│  │  ┌──────────────┐  ┌──────────────┐             │      │
│  │  │ AuthService  │  │ SubService   │             │      │
│  │  └──────────────┘  └──────────────┘             │      │
│  │         ↓                  ↓                      │      │
│  │  ┌──────────────┐  ┌──────────────┐             │      │
│  │  │ OAuth        │  │ Payment      │             │      │
│  │  │ Providers    │  │ Gateways     │             │      │
│  │  └──────────────┘  └──────────────┘             │      │
│  └──────────────────────────────────────────────────┘      │
│         ↓                  ↓                                 │
│  ┌──────────────────────────────────────────────────┐      │
│  │         Local Storage & Cache                     │      │
│  │  - Keychain (Auth Tokens)                        │      │
│  │  - UserDefaults (Subscription Cache)             │      │
│  └──────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
                         ↓ HTTPS
┌─────────────────────────────────────────────────────────────┐
│                    Backend Service                           │
├─────────────────────────────────────────────────────────────┤
│  - User Account Management                                   │
│  - Subscription Status Sync                                  │
│  - Payment Verification (Apple, WeChat, Alipay)             │
│  - OAuth Token Exchange                                      │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              External Services                               │
├─────────────────────────────────────────────────────────────┤
│  - Apple Sign In & IAP                                       │
│  - WeChat OAuth & Payment                                    │
│  - Alipay OAuth & Payment                                    │
└─────────────────────────────────────────────────────────────┘
```

### Platform-Specific Considerations

**iOS (Primary Platform)**
- 使用 Apple In-App Purchase (StoreKit 2) 作为唯一支付方式
- 使用 AuthenticationServices 框架实现 Sign in with Apple
- 微信和支付宝仅用于登录，不用于支付（符合 App Store 政策）

**Android/Web (Future)**
- 支持微信支付和支付宝支付
- 使用各平台的 OAuth SDK

## Components and Interfaces

### 1. Authentication Module

#### AuthenticationService

```swift
protocol AuthenticationServiceProtocol {
    /// 使用 Apple ID 登录
    func signInWithApple() async throws -> User
    
    /// 使用微信登录
    func signInWithWeChat() async throws -> User
    
    /// 使用支付宝登录
    func signInWithAlipay() async throws -> User
    
    /// 验证当前会话
    func validateSession() async throws -> Bool
    
    /// 登出
    func signOut() async throws
    
    /// 获取当前用户
    func getCurrentUser() -> User?
    
    /// 刷新认证令牌
    func refreshAuthToken() async throws -> String
}
```

#### AuthViewModel

```swift
@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let authService: AuthenticationServiceProtocol
    
    func signIn(with provider: AuthProvider) async
    func signOut() async
    func validateSession() async
}
```

#### OAuth Provider Managers

```swift
// Apple Sign In Manager
class AppleSignInManager {
    func initiateSignIn() async throws -> AppleIDCredential
    func handleCallback(_ credential: ASAuthorization) throws -> AppleIDCredential
}

// WeChat OAuth Manager
class WeChatOAuthManager {
    func initiateSignIn() async throws -> WeChatCredential
    func handleCallback(_ code: String) async throws -> WeChatCredential
}

// Alipay OAuth Manager
class AlipayOAuthManager {
    func initiateSignIn() async throws -> AlipayCredential
    func handleCallback(_ code: String) async throws -> AlipayCredential
}
```

### 2. Subscription Module

#### SubscriptionService

```swift
protocol SubscriptionServiceProtocol {
    /// 获取可用的订阅产品
    func fetchAvailableProducts() async throws -> [SubscriptionProduct]
    
    /// 购买订阅
    func purchase(_ product: SubscriptionProduct) async throws -> PurchaseResult
    
    /// 恢复购买
    func restorePurchases() async throws -> [Subscription]
    
    /// 获取当前订阅状态
    func getCurrentSubscription() async throws -> Subscription?
    
    /// 验证订阅状态
    func validateSubscription() async throws -> Bool
    
    /// 取消订阅（引导用户到系统设置）
    func cancelSubscription() async throws
    
    /// 升级订阅
    func upgradeSubscription(to tier: SubscriptionTier) async throws -> PurchaseResult
}
```

#### SubscriptionViewModel

```swift
@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var currentSubscription: Subscription?
    @Published var availableProducts: [SubscriptionProduct] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let subscriptionService: SubscriptionServiceProtocol
    
    func loadProducts() async
    func purchase(_ product: SubscriptionProduct) async
    func restorePurchases() async
    func checkSubscriptionStatus() async
}
```

#### Payment Gateway Managers

```swift
// Apple IAP Manager (iOS)
class AppleIAPManager {
    func fetchProducts(productIds: [String]) async throws -> [Product]
    func purchase(_ product: Product) async throws -> Transaction
    func verifyReceipt(_ transaction: Transaction) async throws -> Bool
    func listenForTransactions() -> Task<Void, Never>
}

// WeChat Pay Manager (Android/Web)
class WeChatPayManager {
    func initiatePayment(orderId: String, amount: Decimal) async throws -> PaymentResult
    func verifyPayment(transactionId: String) async throws -> Bool
}

// Alipay Manager (Android/Web)
class AlipayManager {
    func initiatePayment(orderId: String, amount: Decimal) async throws -> PaymentResult
    func verifyPayment(transactionId: String) async throws -> Bool
}
```

### 3. Access Control Module

#### FeatureAccessManager

```swift
class FeatureAccessManager {
    /// 检查功能访问权限
    func canAccessFeature(_ feature: PremiumFeature) -> Bool
    
    /// 获取功能所需的最低订阅层级
    func requiredTier(for feature: PremiumFeature) -> SubscriptionTier
    
    /// 显示付费墙
    func showPaywall(for feature: PremiumFeature, from viewController: UIViewController)
}

enum PremiumFeature {
    case toolbox              // 工具箱所有功能
    case smartClean           // 智能清理
    case duplicateDetection   // 重复照片检测
    case similarPhotoCleanup  // 相似照片清理
    case screenshotCleanup    // 截图清理
    case photoEnhancer        // 照片增强
    case formatConverter      // 格式转换
    case livePhotoConverter   // Live Photo 转换
    case idPhotoEditor        // 证件照编辑
    case privacyWiper         // 隐私擦除
    case screenshotStitcher   // 长截图拼接
}
```

### 4. Storage and Cache Module

#### SecureStorage

```swift
class SecureStorage {
    /// 存储认证令牌（使用 Keychain）
    func saveAuthToken(_ token: String, for userId: String) throws
    
    /// 读取认证令牌
    func getAuthToken(for userId: String) throws -> String?
    
    /// 删除认证令牌
    func deleteAuthToken(for userId: String) throws
    
    /// 存储用户凭证
    func saveCredentials(_ credentials: UserCredentials) throws
    
    /// 读取用户凭证
    func getCredentials() throws -> UserCredentials?
}
```

#### SubscriptionCache

```swift
class SubscriptionCache {
    /// 缓存订阅状态
    func cacheSubscription(_ subscription: Subscription)
    
    /// 获取缓存的订阅状态
    func getCachedSubscription() -> Subscription?
    
    /// 检查缓存是否过期（24小时）
    func isCacheValid() -> Bool
    
    /// 清除缓存
    func clearCache()
}
```

### 5. Network Module

#### BackendAPIClient

```swift
class BackendAPIClient {
    /// 用户认证相关
    func exchangeOAuthToken(_ credential: OAuthCredential) async throws -> AuthResponse
    func validateAuthToken(_ token: String) async throws -> Bool
    func refreshAuthToken(_ refreshToken: String) async throws -> AuthResponse
    
    /// 订阅相关
    func syncSubscription(_ subscription: Subscription) async throws
    func verifyAppleReceipt(_ receiptData: Data) async throws -> SubscriptionStatus
    func verifyWeChatPayment(_ transactionId: String) async throws -> PaymentStatus
    func verifyAlipayPayment(_ transactionId: String) async throws -> PaymentStatus
    
    /// 用户管理
    func getUserProfile(_ userId: String) async throws -> UserProfile
    func updateUserProfile(_ profile: UserProfile) async throws
    func deleteUserAccount(_ userId: String) async throws
}
```

## Data Models

### User

```swift
struct User: Codable, Identifiable {
    let id: String
    var displayName: String
    var email: String?
    var avatarURL: URL?
    var authProvider: AuthProvider
    var createdAt: Date
    var lastLoginAt: Date
}

enum AuthProvider: String, Codable {
    case apple = "apple"
    case wechat = "wechat"
    case alipay = "alipay"
}
```

### Subscription

```swift
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
}

enum SubscriptionTier: String, Codable, Comparable {
    case free = "free"
    case pro = "pro"
    case max = "max"
    
    var displayName: String {
        switch self {
        case .free: return "免费版"
        case .pro: return "专业版"
        case .max: return "旗舰版"
        }
    }
    
    var features: [PremiumFeature] {
        switch self {
        case .free:
            return []
        case .pro, .max:
            return PremiumFeature.allCases
        }
    }
}

enum BillingPeriod: String, Codable {
    case monthly = "monthly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .monthly: return "月付"
        case .yearly: return "年付"
        }
    }
}

enum SubscriptionStatus: String, Codable {
    case active = "active"
    case expired = "expired"
    case cancelled = "cancelled"
    case pending = "pending"
}

enum PaymentMethod: String, Codable {
    case appleIAP = "apple_iap"
    case wechatPay = "wechat_pay"
    case alipay = "alipay"
}
```

### SubscriptionProduct

```swift
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
    
    var displayPrice: String {
        switch (tier, billingPeriod) {
        case (.pro, .monthly): return "¥10/月"
        case (.pro, .yearly): return "¥100/年"
        case (.max, .monthly): return "¥20/月"
        case (.max, .yearly): return "¥200/年"
        default: return "免费"
        }
    }
}
```

### AuthToken

```swift
struct AuthToken: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let tokenType: String
}
```

### PurchaseResult

```swift
struct PurchaseResult {
    let success: Bool
    let subscription: Subscription?
    let transaction: Transaction?
    let error: Error?
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property Reflection

After reviewing all testable properties from the prework, I've identified the following redundancies and consolidations:

**Redundant Properties:**
- Properties 1.1, 1.2, 1.3 can be combined into one property about OAuth provider routing
- Properties 5.2 and 5.3 can be combined into one property about payment gateway routing
- Property 5.5 is redundant with 4.3 (both about backend sync after payment verification)
- Properties 8.2 and 8.3 can be combined into one property about verification API routing

**Consolidated Properties:**
The following properties provide unique validation value and will be implemented:

### Authentication Properties

**Property 1: OAuth Provider Routing**
*For any* authentication provider (WeChat, Alipay, Apple), when a user initiates sign-in, the system should route to the correct OAuth manager and return either a valid credential or an error.
**Validates: Requirements 1.1, 1.2, 1.3**

**Property 2: Successful Authentication Storage**
*For any* successful OAuth authentication, the system should store the auth token in secure storage (Keychain) and create or retrieve the user account.
**Validates: Requirements 1.4, 2.1**

**Property 3: Authentication Error Handling**
*For any* failed OAuth authentication, the system should return an error state without storing any credentials.
**Validates: Requirements 1.5**

**Property 4: Session Restoration**
*For any* valid auth token, when the app launches, the system should restore the user session automatically.
**Validates: Requirements 2.3**

**Property 5: Invalid Token Cleanup**
*For any* invalid or expired auth token, the system should clear all local authentication data.
**Validates: Requirements 2.4**

**Property 6: Logout Data Removal**
*For any* logout action, all authentication data should be removed from secure storage.
**Validates: Requirements 2.5**

### Subscription Properties

**Property 7: Subscription Tier Features**
*For any* subscription tier, the features list should match the tier's defined feature set (Free: no premium features, Pro/Max: all premium features).
**Validates: Requirements 3.3**

**Property 8: Active Subscription Display**
*For any* user with an active subscription, the system should correctly identify their current tier and expiration date.
**Validates: Requirements 3.4**

**Property 9: Free Tier Upgrade Prompts**
*For any* free tier user attempting to access a premium feature, the system should display an upgrade prompt.
**Validates: Requirements 3.5**

### Payment Properties

**Property 10: iOS Payment Routing**
*For any* subscription purchase on iOS platform, the system should initiate Apple IAP flow.
**Validates: Requirements 4.1**

**Property 11: Receipt Verification**
*For any* successful IAP transaction, the system should verify the receipt with Apple servers before updating subscription status.
**Validates: Requirements 4.2**

**Property 12: Payment Success Sync**
*For any* verified payment (Apple IAP, WeChat Pay, or Alipay), the system should update the subscription status on the backend service.
**Validates: Requirements 4.3, 5.5**

**Property 13: Failed Purchase Invariant**
*For any* failed purchase attempt, the user's subscription status should remain unchanged.
**Validates: Requirements 4.4**

**Property 14: Auto-Renewal Handling**
*For any* auto-renewal transaction, the system should validate the new receipt and extend the subscription period.
**Validates: Requirements 4.5**

**Property 15: Payment Gateway Routing**
*For any* payment method selection (WeChat Pay or Alipay), the system should initiate the correct payment flow with the correct subscription amount.
**Validates: Requirements 5.2, 5.3**

**Property 16: Payment Verification**
*For any* completed payment, the system should verify the transaction with the payment gateway before updating subscription status.
**Validates: Requirements 5.4**

### Access Control Properties

**Property 17: Free Tier Access Restriction**
*For any* premium feature, when a free tier user attempts access, the system should block access and show an upgrade prompt.
**Validates: Requirements 6.1**

**Property 18: Paid Tier Access Grant**
*For any* premium feature, when a Pro or Max tier user attempts access, the system should grant access immediately.
**Validates: Requirements 6.2**

**Property 19: Cache-First Access Check**
*For any* feature access check, the system should verify subscription status from local cache first, then from backend service if cache is stale.
**Validates: Requirements 6.3**

**Property 20: Expired Subscription Restriction**
*For any* expired subscription, the system should immediately restrict access to all premium features.
**Validates: Requirements 6.4**

**Property 21: Feature Lock Display**
*For any* premium feature, when displayed to a user without appropriate subscription, the system should mark it as locked in the view model.
**Validates: Requirements 6.5**

### Subscription Management Properties

**Property 22: Prorated Upgrade Calculation**
*For any* subscription upgrade (e.g., Pro to Max), the system should calculate prorated pricing based on remaining billing period.
**Validates: Requirements 7.2**

**Property 23: Platform-Specific Cancellation**
*For any* cancellation request, the system should route to the correct platform-specific cancellation process (App Store, WeChat, or Alipay).
**Validates: Requirements 7.3**

**Property 24: Cancelled Subscription Access**
*For any* cancelled subscription, the system should maintain access until the current billing period expiry date.
**Validates: Requirements 7.4**

**Property 25: Subscription Sync**
*For any* subscription status change, the system should synchronize between backend service and local storage.
**Validates: Requirements 7.5**

### Security and Verification Properties

**Property 26: Payment Verification Routing**
*For any* subscription update request, the system should verify the payment using the correct verification API (Apple for IAP, WeChat/Alipay for their respective payments).
**Validates: Requirements 8.1, 8.2, 8.3**

**Property 27: Failed Verification Rejection**
*For any* failed payment verification, the system should reject the subscription update and not modify the user's subscription status.
**Validates: Requirements 8.4**

**Property 28: Audit Logging**
*For any* subscription status update, the system should create an audit log entry with timestamp and payment details.
**Validates: Requirements 8.5**

### Offline Support Properties

**Property 29: Offline Cache Usage**
*For any* network failure, when cached subscription data is less than 24 hours old, the system should use the cached status for feature access checks.
**Validates: Requirements 9.1**

**Property 30: Stale Cache Restriction**
*For any* cached subscription data older than 24 hours, when network is unavailable, the system should restrict access to premium features.
**Validates: Requirements 9.2**

**Property 31: Network Restoration Sync**
*For any* network connectivity restoration, the system should synchronize subscription status with the backend service.
**Validates: Requirements 9.3**

**Property 32: Offline Payment Queuing**
*For any* payment initiated while offline, the system should queue the transaction and complete it when connectivity is restored.
**Validates: Requirements 9.4**

**Property 33: Network Error Distinction**
*For any* subscription verification failure due to network error, the system should distinguish it from subscription-related errors in the error message.
**Validates: Requirements 9.5**

### Data Security Properties

**Property 34: Secure Token Storage**
*For any* auth token storage operation, the system should use platform-provided secure storage (Keychain on iOS).
**Validates: Requirements 10.1**

**Property 35: HTTPS Communication**
*For any* backend service communication, the system should use HTTPS with TLS 1.2 or higher.
**Validates: Requirements 10.2**

**Property 36: No Local Payment Credentials**
*For any* local storage check, the system should never contain credit card numbers or payment credentials.
**Validates: Requirements 10.3**

**Property 37: Account Deletion Cleanup**
*For any* account deletion request, the system should remove all personal data from local storage and request deletion from backend service.
**Validates: Requirements 10.4**

**Property 38: Log Sanitization**
*For any* log entry, the system should not include sensitive information such as passwords, tokens, or payment details.
**Validates: Requirements 10.5**

## Error Handling

### Authentication Errors

```swift
enum AuthError: LocalizedError {
    case oauthFailed(provider: AuthProvider, reason: String)
    case tokenExpired
    case tokenInvalid
    case networkError
    case userCancelled
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .oauthFailed(let provider, let reason):
            return "登录失败：\(provider.displayName) - \(reason)"
        case .tokenExpired:
            return "登录已过期，请重新登录"
        case .tokenInvalid:
            return "登录信息无效，请重新登录"
        case .networkError:
            return "网络连接失败，请检查网络设置"
        case .userCancelled:
            return "用户取消登录"
        case .unknownError(let error):
            return "登录失败：\(error.localizedDescription)"
        }
    }
}
```

### Subscription Errors

```swift
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
            return "未找到订阅产品"
        case .purchaseFailed(let reason):
            return "购买失败：\(reason)"
        case .verificationFailed:
            return "支付验证失败，请联系客服"
        case .networkError:
            return "网络连接失败，请检查网络设置"
        case .userCancelled:
            return "用户取消购买"
        case .alreadySubscribed:
            return "您已经订阅了此服务"
        case .insufficientPermissions:
            return "权限不足，无法完成购买"
        case .unknownError(let error):
            return "购买失败：\(error.localizedDescription)"
        }
    }
}
```

### Error Recovery Strategies

1. **Network Errors**: Retry with exponential backoff (1s, 2s, 4s, 8s)
2. **Token Expiration**: Automatically attempt token refresh, fallback to re-login
3. **Payment Verification Failures**: Queue for retry, notify user after 3 failed attempts
4. **OAuth Failures**: Allow user to retry or switch to different provider
5. **Cache Staleness**: Gracefully degrade to free tier after 24 hours offline

## Testing Strategy

### Unit Testing

**Authentication Module Tests:**
- Test OAuth provider routing logic
- Test token storage and retrieval from Keychain
- Test session validation logic
- Test logout cleanup

**Subscription Module Tests:**
- Test subscription tier feature mapping
- Test product loading and parsing
- Test subscription status evaluation
- Test cache validity checks

**Access Control Tests:**
- Test feature access logic for each tier
- Test paywall trigger conditions
- Test cache-first access check strategy

**Payment Module Tests:**
- Test payment gateway routing
- Test receipt/transaction parsing
- Test verification request formatting

### Property-Based Testing

We will use **swift-check** (Swift port of QuickCheck) for property-based testing. Each property-based test will:
- Run a minimum of 100 iterations
- Generate random test data (users, subscriptions, tokens, etc.)
- Verify the correctness property holds for all generated inputs
- Be tagged with a comment referencing the design document property

**Example Property Test Structure:**

```swift
import XCTest
import SwiftCheck
@testable import LightGallery

class AuthenticationPropertyTests: XCTestCase {
    
    /// **Feature: user-auth-subscription, Property 1: OAuth Provider Routing**
    func testOAuthProviderRouting() {
        property("For any auth provider, sign-in routes to correct OAuth manager") <- forAll { (provider: AuthProvider) in
            let authService = AuthenticationService()
            let result = try? await authService.signIn(with: provider)
            
            // Verify correct OAuth manager was used based on provider
            return result != nil || result?.error != nil
        }
    }
    
    /// **Feature: user-auth-subscription, Property 2: Successful Authentication Storage**
    func testSuccessfulAuthenticationStorage() {
        property("For any successful OAuth, token is stored in Keychain") <- forAll { (credential: OAuthCredential) in
            let authService = AuthenticationService()
            let user = try? await authService.processCredential(credential)
            
            guard let user = user else { return false }
            
            // Verify token was stored in Keychain
            let storedToken = try? SecureStorage.shared.getAuthToken(for: user.id)
            return storedToken != nil
        }
    }
}
```

### Integration Testing

- Test complete authentication flow from OAuth initiation to token storage
- Test complete purchase flow from product selection to subscription activation
- Test subscription sync between local cache and backend
- Test offline-to-online transition scenarios
- Test subscription expiration and renewal flows

### Manual Testing Scenarios

- Test each OAuth provider on actual devices
- Test IAP purchases in sandbox environment
- Test subscription management in App Store
- Test UI/UX of paywall and subscription screens
- Test accessibility features

## Performance Considerations

### Caching Strategy

- **Subscription Status**: Cache for 24 hours, refresh on app launch if stale
- **Product List**: Cache for 7 days, refresh on subscription page access
- **User Profile**: Cache indefinitely, refresh on explicit user action

### Network Optimization

- Batch subscription status checks with other API calls
- Use HTTP/2 for multiplexing
- Implement request deduplication for concurrent access checks
- Use CDN for static subscription product information

### Background Tasks

- Schedule background refresh of subscription status (iOS Background App Refresh)
- Listen for StoreKit transaction updates in background
- Sync pending transactions when app returns to foreground

## Security Considerations

### Token Security

- Store all auth tokens in Keychain with `kSecAttrAccessibleAfterFirstUnlock`
- Never log auth tokens or refresh tokens
- Implement token rotation every 7 days
- Clear tokens immediately on logout or account deletion

### Payment Security

- Never store payment credentials locally
- Use Apple's receipt validation for IAP
- Verify all payments server-side before granting access
- Implement fraud detection (unusual purchase patterns, rapid tier changes)

### API Security

- Use certificate pinning for backend API calls
- Implement request signing for sensitive operations
- Rate limit API calls to prevent abuse
- Validate all server responses before processing

### Privacy

- Request minimal user information from OAuth providers
- Provide clear privacy policy and terms of service
- Allow users to delete their account and all data
- Comply with GDPR, CCPA, and Chinese privacy regulations

## Localization

### Supported Languages

- Chinese (Simplified) - Primary
- English - Secondary

### Localized Content

- All subscription tier names and descriptions
- Payment method names
- Error messages
- Paywall copy and call-to-action buttons
- Subscription management UI

## Platform-Specific Implementation Notes

### iOS (SwiftUI + StoreKit 2)

**StoreKit 2 Integration:**
```swift
import StoreKit

class AppleIAPManager {
    private var updateListenerTask: Task<Void, Never>?
    
    func startTransactionListener() {
        updateListenerTask = Task.detached {
            for await result in Transaction.updates {
                await self.handleTransaction(result)
            }
        }
    }
    
    func fetchProducts() async throws -> [Product] {
        let productIds = [
            "com.lightgallery.pro.monthly",
            "com.lightgallery.pro.yearly",
            "com.lightgallery.max.monthly",
            "com.lightgallery.max.yearly"
        ]
        return try await Product.products(for: productIds)
    }
    
    func purchase(_ product: Product) async throws -> Transaction {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return transaction
        case .userCancelled:
            throw SubscriptionError.userCancelled
        case .pending:
            throw SubscriptionError.purchaseFailed(reason: "Purchase pending")
        @unknown default:
            throw SubscriptionError.unknownError(NSError(domain: "IAP", code: -1))
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}
```

**Sign in with Apple:**
```swift
import AuthenticationServices

class AppleSignInManager: NSObject, ASAuthorizationControllerDelegate {
    func initiateSignIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }
    
    func authorizationController(controller: ASAuthorizationController, 
                                didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            // Process credential
            Task {
                await processAppleCredential(credential)
            }
        }
    }
}
```

### Android (Future - Kotlin + Jetpack Compose)

**WeChat Pay Integration:**
- Use WeChat Open SDK for Android
- Implement WXPayEntryActivity for payment callbacks
- Handle payment results in BroadcastReceiver

**Alipay Integration:**
- Use Alipay SDK for Android
- Implement payment callback handling
- Support both app-based and H5-based payment flows

### Backend Service Requirements

**Technology Stack:**
- **Language**: Java 17+
- **Framework**: Spring Boot 3.x
- **Database**: MySQL 8.0+
- **ORM**: MyBatis-Plus 3.5+
- **Security**: Spring Security + JWT
- **API Documentation**: SpringDoc OpenAPI (Swagger)
- **Caching**: Redis (optional, for session management)

**Key Dependencies:**
```xml
<dependencies>
    <!-- Spring Boot Starters -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
    
    <!-- MyBatis-Plus -->
    <dependency>
        <groupId>com.baomidou</groupId>
        <artifactId>mybatis-plus-boot-starter</artifactId>
        <version>3.5.5</version>
    </dependency>
    
    <!-- MySQL Driver -->
    <dependency>
        <groupId>com.mysql</groupId>
        <artifactId>mysql-connector-j</artifactId>
    </dependency>
    
    <!-- JWT -->
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-api</artifactId>
        <version>0.12.3</version>
    </dependency>
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-impl</artifactId>
        <version>0.12.3</version>
        <scope>runtime</scope>
    </dependency>
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-jackson</artifactId>
        <version>0.12.3</version>
        <scope>runtime</scope>
    </dependency>
    
    <!-- Validation -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    
    <!-- Lombok -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
    </dependency>
    
    <!-- Hutool (optional, useful utilities) -->
    <dependency>
        <groupId>cn.hutool</groupId>
        <artifactId>hutool-all</artifactId>
        <version>5.8.25</version>
    </dependency>
</dependencies>
```

**API Endpoints:**
```
POST   /api/v1/auth/oauth/exchange       - Exchange OAuth token for app token
POST   /api/v1/auth/token/refresh        - Refresh auth token
POST   /api/v1/auth/logout               - Logout user
DELETE /api/v1/auth/account              - Delete user account

GET    /api/v1/subscription/products     - Get available products
GET    /api/v1/subscription/status       - Get current subscription
POST   /api/v1/subscription/verify       - Verify payment and update subscription
POST   /api/v1/subscription/sync         - Sync subscription status
POST   /api/v1/subscription/cancel       - Cancel subscription

GET    /api/v1/user/profile              - Get user profile
PUT    /api/v1/user/profile              - Update user profile
```

**Spring Boot Controller Example:**
```java
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {
    
    private final AuthService authService;
    
    @PostMapping("/oauth/exchange")
    public ResponseEntity<AuthResponse> exchangeOAuthToken(
            @Valid @RequestBody OAuthExchangeRequest request) {
        AuthResponse response = authService.exchangeOAuthToken(request);
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/token/refresh")
    public ResponseEntity<AuthResponse> refreshToken(
            @Valid @RequestBody RefreshTokenRequest request) {
        AuthResponse response = authService.refreshToken(request);
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/logout")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> logout(@AuthenticationPrincipal UserDetails userDetails) {
        authService.logout(userDetails.getUsername());
        return ResponseEntity.noContent().build();
    }
    
    @DeleteMapping("/account")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> deleteAccount(@AuthenticationPrincipal UserDetails userDetails) {
        authService.deleteAccount(userDetails.getUsername());
        return ResponseEntity.noContent().build();
    }
}

@RestController
@RequestMapping("/api/v1/subscription")
@RequiredArgsConstructor
public class SubscriptionController {
    
    private final SubscriptionService subscriptionService;
    
    @GetMapping("/products")
    public ResponseEntity<List<SubscriptionProductDTO>> getProducts() {
        List<SubscriptionProductDTO> products = subscriptionService.getAvailableProducts();
        return ResponseEntity.ok(products);
    }
    
    @GetMapping("/status")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<SubscriptionDTO> getStatus(@AuthenticationPrincipal UserDetails userDetails) {
        SubscriptionDTO subscription = subscriptionService.getCurrentSubscription(userDetails.getUsername());
        return ResponseEntity.ok(subscription);
    }
    
    @PostMapping("/verify")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<SubscriptionDTO> verifyPayment(
            @Valid @RequestBody PaymentVerificationRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        SubscriptionDTO subscription = subscriptionService.verifyAndUpdateSubscription(
                userDetails.getUsername(), request);
        return ResponseEntity.ok(subscription);
    }
}
```

**Database Schema (MySQL):**
```sql
-- Users table
CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY,
    display_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    avatar_url TEXT,
    auth_provider VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_email (email),
    INDEX idx_auth_provider (auth_provider),
    INDEX idx_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Subscriptions table
CREATE TABLE subscriptions (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    tier VARCHAR(50) NOT NULL,
    billing_period VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    start_date TIMESTAMP NOT NULL,
    expiry_date TIMESTAMP NOT NULL,
    auto_renew BOOLEAN DEFAULT TRUE,
    payment_method VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_expiry_date (expiry_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Transactions table (audit log)
CREATE TABLE transactions (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    subscription_id VARCHAR(36),
    payment_method VARCHAR(50) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'CNY',
    transaction_id VARCHAR(255) NOT NULL,
    receipt_data TEXT,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_transaction_id (transaction_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Auth tokens table
CREATE TABLE auth_tokens (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    access_token TEXT NOT NULL,
    refresh_token TEXT NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**MyBatis-Plus Entity Example:**
```java
@Data
@TableName("users")
public class User {
    
    @TableId(type = IdType.ASSIGN_UUID)
    private String id;
    
    @TableField("display_name")
    private String displayName;
    
    @TableField("email")
    private String email;
    
    @TableField("avatar_url")
    private String avatarUrl;
    
    @TableField("auth_provider")
    private String authProvider;
    
    @TableField(value = "created_at", fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
    
    @TableField(value = "last_login_at", fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime lastLoginAt;
    
    @TableField("deleted_at")
    @TableLogic
    private LocalDateTime deletedAt;
}

@Data
@TableName("subscriptions")
public class Subscription {
    
    @TableId(type = IdType.ASSIGN_UUID)
    private String id;
    
    @TableField("user_id")
    private String userId;
    
    @TableField("tier")
    private String tier;
    
    @TableField("billing_period")
    private String billingPeriod;
    
    @TableField("status")
    private String status;
    
    @TableField("start_date")
    private LocalDateTime startDate;
    
    @TableField("expiry_date")
    private LocalDateTime expiryDate;
    
    @TableField("auto_renew")
    private Boolean autoRenew;
    
    @TableField("payment_method")
    private String paymentMethod;
    
    @TableField(value = "created_at", fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
    
    @TableField(value = "updated_at", fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;
}

@Data
@TableName("transactions")
public class Transaction {
    
    @TableId(type = IdType.ASSIGN_UUID)
    private String id;
    
    @TableField("user_id")
    private String userId;
    
    @TableField("subscription_id")
    private String subscriptionId;
    
    @TableField("payment_method")
    private String paymentMethod;
    
    @TableField("amount")
    private BigDecimal amount;
    
    @TableField("currency")
    private String currency;
    
    @TableField("transaction_id")
    private String transactionId;
    
    @TableField("receipt_data")
    private String receiptData;
    
    @TableField("status")
    private String status;
    
    @TableField(value = "created_at", fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}
```

**MyBatis-Plus Mapper Example:**
```java
@Mapper
public interface UserMapper extends BaseMapper<User> {
    
    /**
     * 根据认证提供商和邮箱查询用户
     */
    @Select("SELECT * FROM users WHERE auth_provider = #{authProvider} AND email = #{email} AND deleted_at IS NULL")
    User findByAuthProviderAndEmail(@Param("authProvider") String authProvider, @Param("email") String email);
    
    /**
     * 更新最后登录时间
     */
    @Update("UPDATE users SET last_login_at = NOW() WHERE id = #{userId}")
    int updateLastLoginTime(@Param("userId") String userId);
}

@Mapper
public interface SubscriptionMapper extends BaseMapper<Subscription> {
    
    /**
     * 查询用户的活跃订阅
     */
    @Select("SELECT * FROM subscriptions WHERE user_id = #{userId} AND status = 'active' AND expiry_date > NOW() ORDER BY expiry_date DESC LIMIT 1")
    Subscription findActiveSubscriptionByUserId(@Param("userId") String userId);
    
    /**
     * 查询即将过期的订阅（用于自动续费检查）
     */
    @Select("SELECT * FROM subscriptions WHERE status = 'active' AND auto_renew = true AND expiry_date BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 3 DAY)")
    List<Subscription> findSubscriptionsNearExpiry();
}

@Mapper
public interface TransactionMapper extends BaseMapper<Transaction> {
    
    /**
     * 根据交易ID查询
     */
    @Select("SELECT * FROM transactions WHERE transaction_id = #{transactionId}")
    Transaction findByTransactionId(@Param("transactionId") String transactionId);
    
    /**
     * 查询用户的交易历史
     */
    @Select("SELECT * FROM transactions WHERE user_id = #{userId} ORDER BY created_at DESC")
    List<Transaction> findByUserId(@Param("userId") String userId);
}
```

**MyBatis-Plus Configuration:**
```java
@Configuration
@MapperScan("com.lightgallery.mapper")
public class MyBatisPlusConfig {
    
    /**
     * 分页插件
     */
    @Bean
    public MybatisPlusInterceptor mybatisPlusInterceptor() {
        MybatisPlusInterceptor interceptor = new MybatisPlusInterceptor();
        interceptor.addInnerInterceptor(new PaginationInnerInterceptor(DbType.MYSQL));
        return interceptor;
    }
    
    /**
     * 自动填充配置
     */
    @Bean
    public MetaObjectHandler metaObjectHandler() {
        return new MetaObjectHandler() {
            @Override
            public void insertFill(MetaObject metaObject) {
                this.strictInsertFill(metaObject, "createdAt", LocalDateTime.class, LocalDateTime.now());
                this.strictInsertFill(metaObject, "updatedAt", LocalDateTime.class, LocalDateTime.now());
                this.strictInsertFill(metaObject, "lastLoginAt", LocalDateTime.class, LocalDateTime.now());
            }
            
            @Override
            public void updateFill(MetaObject metaObject) {
                this.strictUpdateFill(metaObject, "updatedAt", LocalDateTime.class, LocalDateTime.now());
                this.strictUpdateFill(metaObject, "lastLoginAt", LocalDateTime.class, LocalDateTime.now());
            }
        };
    }
}
```

**Spring Security Configuration:**
```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(session -> 
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/auth/oauth/exchange", "/api/v1/auth/token/refresh").permitAll()
                .requestMatchers("/api/v1/subscription/products").permitAll()
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtAuthenticationFilter(), UsernamePasswordAuthenticationFilter.class);
        
        return http.build();
    }
    
    @Bean
    public JwtAuthenticationFilter jwtAuthenticationFilter() {
        return new JwtAuthenticationFilter();
    }
    
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(Arrays.asList("*"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(true);
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", configuration);
        return source;
    }
}
```

**Application Properties (application.yml):**
```yaml
spring:
  application:
    name: lightgallery-backend
  
  datasource:
    url: jdbc:mysql://localhost:3306/lightgallery?useSSL=true&serverTimezone=Asia/Shanghai&characterEncoding=utf8mb4
    username: ${DB_USERNAME:root}
    password: ${DB_PASSWORD:password}
    driver-class-name: com.mysql.cj.jdbc.Driver
    hikari:
      maximum-pool-size: 10
      minimum-idle: 5
      connection-timeout: 30000
  
  # MyBatis-Plus Configuration
mybatis-plus:
  mapper-locations: classpath*:/mapper/**/*.xml
  type-aliases-package: com.lightgallery.entity
  configuration:
    map-underscore-to-camel-case: true
    cache-enabled: false
    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl
  global-config:
    db-config:
      id-type: assign_uuid
      logic-delete-field: deletedAt
      logic-delete-value: NOW()
      logic-not-delete-value: 'NULL'
  
  security:
    jwt:
      secret: ${JWT_SECRET:your-secret-key-change-in-production}
      expiration: 86400000  # 24 hours
      refresh-expiration: 604800000  # 7 days

# Apple IAP Configuration
apple:
  iap:
    shared-secret: ${APPLE_IAP_SHARED_SECRET}
    sandbox-url: https://sandbox.itunes.apple.com/verifyReceipt
    production-url: https://buy.itunes.apple.com/verifyReceipt

# WeChat Configuration
wechat:
  app-id: ${WECHAT_APP_ID}
  app-secret: ${WECHAT_APP_SECRET}
  oauth-url: https://api.weixin.qq.com/sns/oauth2/access_token
  pay-url: https://api.mch.weixin.qq.com/v3/pay/transactions/native

# Alipay Configuration
alipay:
  app-id: ${ALIPAY_APP_ID}
  private-key: ${ALIPAY_PRIVATE_KEY}
  public-key: ${ALIPAY_PUBLIC_KEY}
  gateway-url: https://openapi.alipay.com/gateway.do

logging:
  level:
    root: INFO
    com.lightgallery: DEBUG
    org.hibernate.SQL: DEBUG
```

## Migration Strategy

### Existing Users

For users who already have the app installed:

1. **First Launch After Update**: Show onboarding screen explaining new subscription model
2. **Grace Period**: Provide 7-day free trial of Pro tier for existing users
3. **Feature Access**: Gradually restrict premium features after grace period
4. **Data Preservation**: All existing data and settings remain intact

### Rollout Plan

1. **Phase 1 (Week 1-2)**: Release authentication system, allow users to create accounts
2. **Phase 2 (Week 3-4)**: Enable subscription display and IAP integration (iOS)
3. **Phase 3 (Week 5-6)**: Implement feature access control with soft paywalls
4. **Phase 4 (Week 7-8)**: Enable hard paywalls and full enforcement
5. **Phase 5 (Week 9+)**: Monitor metrics, iterate based on user feedback

## Success Metrics

### Key Performance Indicators (KPIs)

- **Conversion Rate**: % of free users who upgrade to paid tiers
- **Retention Rate**: % of paid users who renew after first billing period
- **Churn Rate**: % of paid users who cancel subscription
- **Average Revenue Per User (ARPU)**
- **Lifetime Value (LTV)**

### Technical Metrics

- **Authentication Success Rate**: > 95%
- **Payment Success Rate**: > 90%
- **API Response Time**: < 500ms (p95)
- **Subscription Sync Latency**: < 60 seconds
- **Crash-Free Rate**: > 99.5%

### User Experience Metrics

- **Time to Complete Sign-In**: < 30 seconds
- **Time to Complete Purchase**: < 2 minutes
- **Feature Access Check Latency**: < 100ms
- **Paywall Conversion Rate**: > 5%

## Future Enhancements

### Planned Features

1. **Family Sharing**: Allow Pro/Max users to share subscription with family members
2. **Referral Program**: Reward users for referring friends
3. **Promotional Codes**: Support discount codes and promotional offers
4. **Subscription Gifting**: Allow users to gift subscriptions to others
5. **Enterprise Plans**: B2B subscriptions for organizations
6. **Lifetime Purchase**: One-time payment option for lifetime access

### Platform Expansion

1. **Android App**: Full feature parity with iOS
2. **Web App**: Browser-based access with subscription sync
3. **macOS App**: Native Mac application with Catalyst or SwiftUI
4. **iPad Optimization**: Enhanced UI for larger screens

### Payment Methods

1. **Credit/Debit Cards**: Direct card payments (non-iOS platforms)
2. **PayPal**: International payment option
3. **Cryptocurrency**: Bitcoin/Ethereum payments for privacy-conscious users
4. **Carrier Billing**: Mobile carrier-based payments

## Conclusion

This design document provides a comprehensive blueprint for implementing a robust, secure, and user-friendly authentication and subscription system for LightGallery. The system is designed to:

- Provide seamless multi-platform authentication
- Offer flexible subscription options with clear value propositions
- Ensure secure payment processing and data protection
- Support offline usage with intelligent caching
- Scale to support future growth and feature expansion

The implementation will follow iOS best practices, use modern frameworks (SwiftUI, StoreKit 2, AuthenticationServices), and prioritize user experience and security throughout.
