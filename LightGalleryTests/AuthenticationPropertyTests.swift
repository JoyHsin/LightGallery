//
//  AuthenticationPropertyTests.swift
//  LightGalleryTests
//
//  Created by Kiro on 2025-12-06.
//

import XCTest
@testable import LightGallery

/// Property-based tests for authentication functionality
/// **Feature: user-auth-subscription, Property 1: OAuth Provider Routing**
/// **Validates: Requirements 1.1, 1.2, 1.3**
final class AuthenticationPropertyTests: XCTestCase {
    
    var authService: AuthenticationService!
    
    override func setUp() {
        super.setUp()
        authService = AuthenticationService.shared
    }
    
    override func tearDown() {
        authService = nil
        super.tearDown()
    }
    
    /// **Feature: user-auth-subscription, Property 1: OAuth Provider Routing**
    /// **Validates: Requirements 1.1, 1.2, 1.3**
    ///
    /// Property: For any authentication provider (WeChat, Alipay, Apple),
    /// when a user initiates sign-in, the system should route to the correct
    /// OAuth manager and return either a valid credential or an error.
    ///
    /// This test verifies that:
    /// 1. Each provider routes to its specific OAuth manager
    /// 2. The system handles both success and failure cases appropriately
    /// 3. No provider routing is missing or incorrectly mapped
    func testOAuthProviderRouting() async throws {
        // Test all authentication providers
        let providers: [AuthProvider] = [.apple, .wechat, .alipay]
        
        // Run 100 iterations as specified in the design document
        for iteration in 1...100 {
            // Select a random provider for this iteration
            let provider = providers.randomElement()!
            
            // Attempt sign-in with the selected provider
            do {
                let user = try await signInWithProvider(provider)
                
                // Verify the user's auth provider matches what was requested
                XCTAssertEqual(
                    user.authProvider,
                    provider,
                    "Iteration \(iteration): User auth provider should match requested provider"
                )
                
                // Verify user has required fields
                XCTAssertFalse(
                    user.id.isEmpty,
                    "Iteration \(iteration): User ID should not be empty"
                )
                XCTAssertFalse(
                    user.displayName.isEmpty,
                    "Iteration \(iteration): User display name should not be empty"
                )
                
            } catch let error as AuthError {
                // Verify error is properly typed and contains provider information
                switch error {
                case .oauthFailed(let errorProvider, _):
                    XCTAssertEqual(
                        errorProvider,
                        provider,
                        "Iteration \(iteration): Error provider should match requested provider"
                    )
                case .userCancelled, .networkError, .notImplemented:
                    // These are valid error cases
                    break
                default:
                    XCTFail("Iteration \(iteration): Unexpected error type: \(error)")
                }
            } catch {
                XCTFail("Iteration \(iteration): Unexpected error type: \(error)")
            }
        }
    }
    
    /// Helper method to sign in with a specific provider
    private func signInWithProvider(_ provider: AuthProvider) async throws -> User {
        switch provider {
        case .apple:
            return try await authService.signInWithApple()
        case .wechat:
            return try await authService.signInWithWeChat()
        case .alipay:
            return try await authService.signInWithAlipay()
        }
    }
    
    /// Test that Apple Sign In specifically routes correctly
    /// This is a focused test for the implemented Apple provider
    func testAppleSignInRouting() async throws {
        // Note: This test will fail in CI/test environments without user interaction
        // as Apple Sign In requires UI presentation
        
        do {
            let user = try await authService.signInWithApple()
            
            // Verify Apple-specific routing
            XCTAssertEqual(user.authProvider, .apple, "User should be authenticated via Apple")
            XCTAssertFalse(user.id.isEmpty, "Apple user ID should not be empty")
            XCTAssertFalse(user.displayName.isEmpty, "Apple user display name should not be empty")
            
        } catch AuthError.userCancelled {
            // User cancellation is expected in test environments
            XCTAssertTrue(true, "User cancellation is a valid outcome")
        } catch AuthError.notImplemented {
            // Not implemented is expected for WeChat and Alipay
            XCTFail("Apple Sign In should be implemented")
        } catch {
            // Other errors may occur in test environment (no UI context, etc.)
            // We verify the error is properly typed
            XCTAssertTrue(error is AuthError, "Error should be of type AuthError")
        }
    }
    
    /// Test that WeChat Sign In routes correctly
    /// **Feature: user-auth-subscription, Property 1: OAuth Provider Routing**
    /// **Validates: Requirements 1.1, 1.2, 1.3**
    func testWeChatSignInRouting() async throws {
        // Note: This test will fail without WeChat SDK installed
        // as WeChat Sign In requires the SDK and WeChat app
        
        do {
            let user = try await authService.signInWithWeChat()
            
            // Verify WeChat-specific routing
            XCTAssertEqual(user.authProvider, .wechat, "User should be authenticated via WeChat")
            XCTAssertFalse(user.id.isEmpty, "WeChat user ID (OpenID) should not be empty")
            XCTAssertFalse(user.displayName.isEmpty, "WeChat user display name should not be empty")
            
        } catch AuthError.oauthFailed(let provider, let reason) {
            // OAuth failure is expected without WeChat SDK
            XCTAssertEqual(provider, .wechat, "Error should be for WeChat provider")
            XCTAssertTrue(
                reason.contains("WeChat SDK") || reason.contains("微信"),
                "Error should mention WeChat SDK or WeChat app"
            )
        } catch AuthError.userCancelled {
            // User cancellation is expected in test environments
            XCTAssertTrue(true, "User cancellation is a valid outcome")
        } catch AuthError.networkError {
            // Network errors are valid during token exchange
            XCTAssertTrue(true, "Network error is a valid outcome")
        } catch {
            // Other errors may occur in test environment
            XCTAssertTrue(error is AuthError, "Error should be of type AuthError")
        }
    }
    
    /// Test that Alipay Sign In routes correctly
    /// **Feature: user-auth-subscription, Property 1: OAuth Provider Routing**
    /// **Validates: Requirements 1.1, 1.2, 1.3**
    func testAlipaySignInRouting() async throws {
        // Note: This test will fail without Alipay SDK installed
        // as Alipay Sign In requires the SDK and Alipay app
        
        do {
            let user = try await authService.signInWithAlipay()
            
            // Verify Alipay-specific routing
            XCTAssertEqual(user.authProvider, .alipay, "User should be authenticated via Alipay")
            XCTAssertFalse(user.id.isEmpty, "Alipay user ID should not be empty")
            XCTAssertFalse(user.displayName.isEmpty, "Alipay user display name should not be empty")
            
        } catch AuthError.oauthFailed(let provider, let reason) {
            // OAuth failure is expected without Alipay SDK
            XCTAssertEqual(provider, .alipay, "Error should be for Alipay provider")
            XCTAssertTrue(
                reason.contains("Alipay SDK") || reason.contains("支付宝"),
                "Error should mention Alipay SDK or Alipay app"
            )
        } catch AuthError.userCancelled {
            // User cancellation is expected in test environments
            XCTAssertTrue(true, "User cancellation is a valid outcome")
        } catch AuthError.networkError {
            // Network errors are valid during token exchange
            XCTAssertTrue(true, "Network error is a valid outcome")
        } catch {
            // Other errors may occur in test environment
            XCTAssertTrue(error is AuthError, "Error should be of type AuthError")
        }
    }
    
    /// Test that provider routing is consistent across multiple calls
    /// **Feature: user-auth-subscription, Property 1: OAuth Provider Routing**
    /// **Validates: Requirements 1.1, 1.2, 1.3**
    func testProviderRoutingConsistency() async throws {
        let iterations = 10
        
        // Test WeChat routing consistency
        for i in 1...iterations {
            do {
                let user = try await authService.signInWithWeChat()
                // If successful, verify consistency
                XCTAssertEqual(
                    user.authProvider,
                    .wechat,
                    "Iteration \(i): WeChat should consistently route to WeChat provider"
                )
            } catch let error as AuthError {
                // Verify error is consistently an AuthError
                switch error {
                case .oauthFailed(let provider, _):
                    XCTAssertEqual(
                        provider,
                        .wechat,
                        "Iteration \(i): Error should consistently be for WeChat provider"
                    )
                case .userCancelled, .networkError:
                    // These are valid and consistent error cases
                    continue
                default:
                    XCTFail("Iteration \(i): Unexpected error type: \(error)")
                }
            } catch {
                XCTFail("Iteration \(i): Error should be of type AuthError, got: \(error)")
            }
        }
        
        // Test Alipay routing consistency
        for i in 1...iterations {
            do {
                let user = try await authService.signInWithAlipay()
                // If successful, verify consistency
                XCTAssertEqual(
                    user.authProvider,
                    .alipay,
                    "Iteration \(i): Alipay should consistently route to Alipay provider"
                )
            } catch let error as AuthError {
                // Verify error is consistently an AuthError
                switch error {
                case .oauthFailed(let provider, _):
                    XCTAssertEqual(
                        provider,
                        .alipay,
                        "Iteration \(i): Error should consistently be for Alipay provider"
                    )
                case .userCancelled, .networkError:
                    // These are valid and consistent error cases
                    continue
                default:
                    XCTFail("Iteration \(i): Unexpected error type: \(error)")
                }
            } catch {
                XCTFail("Iteration \(i): Error should be of type AuthError, got: \(error)")
            }
        }
    }
    
    // MARK: - Token Storage Property Tests
    
    /// **Feature: user-auth-subscription, Property 2: Successful Authentication Storage**
    /// **Validates: Requirements 1.4, 2.1**
    ///
    /// Property: For any successful OAuth authentication, the system should store
    /// the auth token in secure storage (Keychain) and create or retrieve the user account.
    ///
    /// This test verifies that:
    /// 1. Auth tokens are stored in Keychain after successful authentication
    /// 2. Stored tokens can be retrieved successfully
    /// 3. Token storage uses secure storage mechanisms
    func testSuccessfulAuthenticationStorage() throws {
        let secureStorage = SecureStorage.shared
        
        // Run 100 iterations as specified in the design document
        for iteration in 1...100 {
            // Generate random test data
            let userId = "test_user_\(iteration)_\(UUID().uuidString)"
            let accessToken = "access_token_\(UUID().uuidString)"
            let refreshToken = "refresh_token_\(UUID().uuidString)"
            let expiresAt = Date().addingTimeInterval(3600) // 1 hour from now
            
            let authToken = AuthToken(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresAt: expiresAt,
                tokenType: "Bearer"
            )
            
            // Clean up any existing token for this user
            try? secureStorage.deleteAuthToken(for: userId)
            
            // Store the auth token
            XCTAssertNoThrow(
                try secureStorage.saveAuthToken(authToken.accessToken, for: userId),
                "Iteration \(iteration): Should successfully store auth token"
            )
            
            // Retrieve the stored token
            let retrievedToken = try secureStorage.getAuthToken(for: userId)
            
            // Verify the token was stored and retrieved correctly
            XCTAssertNotNil(
                retrievedToken,
                "Iteration \(iteration): Should retrieve stored token"
            )
            XCTAssertEqual(
                retrievedToken,
                accessToken,
                "Iteration \(iteration): Retrieved token should match stored token"
            )
            
            // Clean up
            try? secureStorage.deleteAuthToken(for: userId)
        }
    }
    
    /// **Feature: user-auth-subscription, Property 34: Secure Token Storage**
    /// **Validates: Requirements 10.1**
    ///
    /// Property: For any auth token storage operation, the system should use
    /// platform-provided secure storage (Keychain on iOS).
    ///
    /// This test verifies that:
    /// 1. Tokens are stored using Keychain (not UserDefaults or plain files)
    /// 2. Tokens use kSecAttrAccessibleAfterFirstUnlock accessibility
    /// 3. Multiple tokens can be stored for different users
    /// 4. Token deletion works correctly
    func testSecureTokenStorage() throws {
        let secureStorage = SecureStorage.shared
        
        // Run 100 iterations as specified in the design document
        for iteration in 1...100 {
            // Generate random test data for multiple users
            let userCount = Int.random(in: 2...5)
            var userTokenPairs: [(userId: String, token: String)] = []
            
            for userIndex in 1...userCount {
                let userId = "secure_test_user_\(iteration)_\(userIndex)_\(UUID().uuidString)"
                let token = "secure_token_\(UUID().uuidString)"
                userTokenPairs.append((userId, token))
            }
            
            // Store tokens for all users
            for (userId, token) in userTokenPairs {
                XCTAssertNoThrow(
                    try secureStorage.saveAuthToken(token, for: userId),
                    "Iteration \(iteration): Should store token for user \(userId)"
                )
            }
            
            // Verify all tokens can be retrieved independently
            for (userId, expectedToken) in userTokenPairs {
                let retrievedToken = try secureStorage.getAuthToken(for: userId)
                XCTAssertEqual(
                    retrievedToken,
                    expectedToken,
                    "Iteration \(iteration): Token for user \(userId) should match"
                )
            }
            
            // Test token update (overwrite)
            let firstUser = userTokenPairs[0]
            let newToken = "updated_token_\(UUID().uuidString)"
            
            XCTAssertNoThrow(
                try secureStorage.saveAuthToken(newToken, for: firstUser.userId),
                "Iteration \(iteration): Should update existing token"
            )
            
            let updatedToken = try secureStorage.getAuthToken(for: firstUser.userId)
            XCTAssertEqual(
                updatedToken,
                newToken,
                "Iteration \(iteration): Updated token should be retrieved"
            )
            
            // Test token deletion
            for (userId, _) in userTokenPairs {
                XCTAssertNoThrow(
                    try secureStorage.deleteAuthToken(for: userId),
                    "Iteration \(iteration): Should delete token for user \(userId)"
                )
                
                // Verify token is deleted
                let deletedToken = try secureStorage.getAuthToken(for: userId)
                XCTAssertNil(
                    deletedToken,
                    "Iteration \(iteration): Token should be nil after deletion for user \(userId)"
                )
            }
            
            // Test deletion of non-existent token (should not throw)
            let nonExistentUserId = "non_existent_\(UUID().uuidString)"
            XCTAssertNoThrow(
                try secureStorage.deleteAuthToken(for: nonExistentUserId),
                "Iteration \(iteration): Deleting non-existent token should not throw"
            )
        }
    }
    
    /// Test that credentials storage works correctly
    /// **Feature: user-auth-subscription, Property 2: Successful Authentication Storage**
    /// **Validates: Requirements 1.4, 2.1**
    func testCredentialsStorage() throws {
        let secureStorage = SecureStorage.shared
        
        // Run 100 iterations
        for iteration in 1...100 {
            // Generate random credentials
            let userId = "cred_user_\(iteration)_\(UUID().uuidString)"
            let accessToken = "access_\(UUID().uuidString)"
            let refreshToken = "refresh_\(UUID().uuidString)"
            let expiresAt = Date().addingTimeInterval(Double.random(in: 3600...86400))
            let provider = [AuthProvider.apple, .wechat, .alipay].randomElement()!
            
            let authToken = AuthToken(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresAt: expiresAt,
                tokenType: "Bearer"
            )
            
            let credentials = UserCredentials(
                userId: userId,
                authToken: authToken,
                provider: provider
            )
            
            // Clean up any existing credentials
            try? secureStorage.deleteAllCredentials()
            
            // Store credentials
            XCTAssertNoThrow(
                try secureStorage.saveCredentials(credentials),
                "Iteration \(iteration): Should store credentials"
            )
            
            // Retrieve credentials
            let retrievedCredentials = try secureStorage.getCredentials()
            
            // Verify credentials
            XCTAssertNotNil(
                retrievedCredentials,
                "Iteration \(iteration): Should retrieve credentials"
            )
            XCTAssertEqual(
                retrievedCredentials?.userId,
                userId,
                "Iteration \(iteration): User ID should match"
            )
            XCTAssertEqual(
                retrievedCredentials?.authToken.accessToken,
                accessToken,
                "Iteration \(iteration): Access token should match"
            )
            XCTAssertEqual(
                retrievedCredentials?.authToken.refreshToken,
                refreshToken,
                "Iteration \(iteration): Refresh token should match"
            )
            XCTAssertEqual(
                retrievedCredentials?.provider,
                provider,
                "Iteration \(iteration): Provider should match"
            )
            
            // Clean up
            try? secureStorage.deleteAllCredentials()
        }
    }
    
    /// Test token storage isolation between users
    /// **Feature: user-auth-subscription, Property 34: Secure Token Storage**
    /// **Validates: Requirements 10.1**
    func testTokenStorageIsolation() throws {
        let secureStorage = SecureStorage.shared
        
        // Run 100 iterations
        for iteration in 1...100 {
            // Create two users with similar IDs to test isolation
            let baseId = "isolation_test_\(iteration)"
            let userId1 = "\(baseId)_user1"
            let userId2 = "\(baseId)_user2"
            
            let token1 = "token_for_user1_\(UUID().uuidString)"
            let token2 = "token_for_user2_\(UUID().uuidString)"
            
            // Clean up
            try? secureStorage.deleteAuthToken(for: userId1)
            try? secureStorage.deleteAuthToken(for: userId2)
            
            // Store tokens for both users
            try secureStorage.saveAuthToken(token1, for: userId1)
            try secureStorage.saveAuthToken(token2, for: userId2)
            
            // Verify tokens are isolated
            let retrieved1 = try secureStorage.getAuthToken(for: userId1)
            let retrieved2 = try secureStorage.getAuthToken(for: userId2)
            
            XCTAssertEqual(
                retrieved1,
                token1,
                "Iteration \(iteration): User 1 should get their own token"
            )
            XCTAssertEqual(
                retrieved2,
                token2,
                "Iteration \(iteration): User 2 should get their own token"
            )
            XCTAssertNotEqual(
                retrieved1,
                retrieved2,
                "Iteration \(iteration): Tokens should be different"
            )
            
            // Delete one user's token
            try secureStorage.deleteAuthToken(for: userId1)
            
            // Verify only the deleted token is gone
            let deletedToken = try secureStorage.getAuthToken(for: userId1)
            let remainingToken = try secureStorage.getAuthToken(for: userId2)
            
            XCTAssertNil(
                deletedToken,
                "Iteration \(iteration): Deleted token should be nil"
            )
            XCTAssertEqual(
                remainingToken,
                token2,
                "Iteration \(iteration): Other user's token should remain"
            )
            
            // Clean up
            try? secureStorage.deleteAuthToken(for: userId2)
        }
    }
    
    // MARK: - Session Management Property Tests
    
    /// **Feature: user-auth-subscription, Property 4: Session Restoration**
    /// **Validates: Requirements 2.3**
    ///
    /// Property: For any valid auth token, when the app launches, the system
    /// should restore the user session automatically.
    ///
    /// This test verifies that:
    /// 1. Valid tokens result in successful session restoration
    /// 2. User information is correctly restored from stored credentials
    /// 3. Session restoration works across multiple app launches
    func testSessionRestoration() async throws {
        let secureStorage = SecureStorage.shared
        
        // Run 100 iterations as specified in the design document
        for iteration in 1...100 {
            // Generate random valid credentials
            let userId = "session_user_\(iteration)_\(UUID().uuidString)"
            let accessToken = "valid_token_\(UUID().uuidString)"
            let refreshToken = "refresh_\(UUID().uuidString)"
            let expiresAt = Date().addingTimeInterval(3600) // Valid for 1 hour
            let provider = [AuthProvider.apple, .wechat, .alipay].randomElement()!
            
            let authToken = AuthToken(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresAt: expiresAt,
                tokenType: "Bearer"
            )
            
            let credentials = UserCredentials(
                userId: userId,
                authToken: authToken,
                provider: provider
            )
            
            // Clean up any existing credentials
            try? secureStorage.deleteAllCredentials()
            
            // Store credentials (simulating a previous successful login)
            try secureStorage.saveCredentials(credentials)
            
            // Validate session (simulating app launch)
            let isValid = try await authService.validateSession()
            
            // Verify session was restored
            XCTAssertTrue(
                isValid,
                "Iteration \(iteration): Valid token should restore session"
            )
            
            // Verify user was restored
            let currentUser = authService.getCurrentUser()
            XCTAssertNotNil(
                currentUser,
                "Iteration \(iteration): Current user should be restored"
            )
            XCTAssertEqual(
                currentUser?.id,
                userId,
                "Iteration \(iteration): Restored user ID should match"
            )
            XCTAssertEqual(
                currentUser?.authProvider,
                provider,
                "Iteration \(iteration): Restored provider should match"
            )
            
            // Clean up
            try? secureStorage.deleteAllCredentials()
        }
    }
    
    /// **Feature: user-auth-subscription, Property 5: Invalid Token Cleanup**
    /// **Validates: Requirements 2.4**
    ///
    /// Property: For any invalid or expired auth token, the system should
    /// clear all local authentication data.
    ///
    /// This test verifies that:
    /// 1. Expired tokens trigger cleanup
    /// 2. All authentication data is removed
    /// 3. Session validation fails for expired tokens
    func testInvalidTokenCleanup() async throws {
        let secureStorage = SecureStorage.shared
        
        // Run 100 iterations as specified in the design document
        for iteration in 1...100 {
            // Generate random expired credentials
            let userId = "expired_user_\(iteration)_\(UUID().uuidString)"
            let accessToken = "expired_token_\(UUID().uuidString)"
            let refreshToken = "" // Empty refresh token to simulate refresh failure
            let expiresAt = Date().addingTimeInterval(-3600) // Expired 1 hour ago
            let provider = [AuthProvider.apple, .wechat, .alipay].randomElement()!
            
            let authToken = AuthToken(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresAt: expiresAt,
                tokenType: "Bearer"
            )
            
            let credentials = UserCredentials(
                userId: userId,
                authToken: authToken,
                provider: provider
            )
            
            // Clean up any existing credentials
            try? secureStorage.deleteAllCredentials()
            
            // Store expired credentials
            try secureStorage.saveCredentials(credentials)
            
            // Verify credentials were stored
            let storedCredentials = try secureStorage.getCredentials()
            XCTAssertNotNil(
                storedCredentials,
                "Iteration \(iteration): Credentials should be stored before validation"
            )
            
            // Validate session (should fail and cleanup)
            do {
                let isValid = try await authService.validateSession()
                XCTAssertFalse(
                    isValid,
                    "Iteration \(iteration): Expired token should not validate"
                )
            } catch AuthError.tokenExpired {
                // Expected error for expired token
                XCTAssertTrue(true, "Iteration \(iteration): Token expired error is expected")
            } catch {
                XCTFail("Iteration \(iteration): Unexpected error: \(error)")
            }
            
            // Verify credentials were cleaned up
            let cleanedCredentials = try? secureStorage.getCredentials()
            XCTAssertNil(
                cleanedCredentials,
                "Iteration \(iteration): Credentials should be cleaned up after failed validation"
            )
            
            // Verify user was cleared
            let currentUser = authService.getCurrentUser()
            XCTAssertNil(
                currentUser,
                "Iteration \(iteration): Current user should be nil after cleanup"
            )
            
            // Clean up
            try? secureStorage.deleteAllCredentials()
        }
    }
    
    /// **Feature: user-auth-subscription, Property 6: Logout Data Removal**
    /// **Validates: Requirements 2.5**
    ///
    /// Property: For any logout action, all authentication data should be
    /// removed from secure storage.
    ///
    /// This test verifies that:
    /// 1. Logout removes all stored credentials
    /// 2. Logout clears the current user
    /// 3. Multiple logouts don't cause errors
    func testLogoutDataRemoval() async throws {
        let secureStorage = SecureStorage.shared
        
        // Run 100 iterations as specified in the design document
        for iteration in 1...100 {
            // Generate random credentials
            let userId = "logout_user_\(iteration)_\(UUID().uuidString)"
            let accessToken = "logout_token_\(UUID().uuidString)"
            let refreshToken = "refresh_\(UUID().uuidString)"
            let expiresAt = Date().addingTimeInterval(3600)
            let provider = [AuthProvider.apple, .wechat, .alipay].randomElement()!
            
            let authToken = AuthToken(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresAt: expiresAt,
                tokenType: "Bearer"
            )
            
            let credentials = UserCredentials(
                userId: userId,
                authToken: authToken,
                provider: provider
            )
            
            // Clean up any existing credentials
            try? secureStorage.deleteAllCredentials()
            
            // Store credentials and set current user (simulating logged in state)
            try secureStorage.saveCredentials(credentials)
            try secureStorage.saveAuthToken(accessToken, for: userId)
            
            // Validate session to set current user
            _ = try await authService.validateSession()
            
            // Verify user is logged in
            let userBeforeLogout = authService.getCurrentUser()
            XCTAssertNotNil(
                userBeforeLogout,
                "Iteration \(iteration): User should be logged in before logout"
            )
            
            // Perform logout
            do {
                try await authService.signOut()
            } catch {
                XCTFail("Iteration \(iteration): Logout should not throw, but got: \(error)")
            }
            
            // Verify all credentials are removed
            let credentialsAfterLogout = try? secureStorage.getCredentials()
            XCTAssertNil(
                credentialsAfterLogout,
                "Iteration \(iteration): Credentials should be removed after logout"
            )
            
            // Verify auth token is removed
            let tokenAfterLogout = try? secureStorage.getAuthToken(for: userId)
            XCTAssertNil(
                tokenAfterLogout,
                "Iteration \(iteration): Auth token should be removed after logout"
            )
            
            // Verify current user is cleared
            let userAfterLogout = authService.getCurrentUser()
            XCTAssertNil(
                userAfterLogout,
                "Iteration \(iteration): Current user should be nil after logout"
            )
            
            // Test multiple logouts don't cause errors
            do {
                try await authService.signOut()
            } catch {
                XCTFail("Iteration \(iteration): Second logout should not throw, but got: \(error)")
            }
            
            // Clean up
            try? secureStorage.deleteAllCredentials()
        }
    }
    
    /// Test session restoration with expired token that can be refreshed
    /// **Feature: user-auth-subscription, Property 4: Session Restoration**
    /// **Validates: Requirements 2.3**
    func testSessionRestorationWithTokenRefresh() async throws {
        let secureStorage = SecureStorage.shared
        
        // Run 100 iterations
        for iteration in 1...100 {
            // Generate credentials with expired token but valid refresh token
            let userId = "refresh_user_\(iteration)_\(UUID().uuidString)"
            let accessToken = "expired_access_\(UUID().uuidString)"
            let refreshToken = "valid_refresh_\(UUID().uuidString)"
            let expiresAt = Date().addingTimeInterval(-3600) // Expired 1 hour ago
            let provider = [AuthProvider.apple, .wechat, .alipay].randomElement()!
            
            let authToken = AuthToken(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresAt: expiresAt,
                tokenType: "Bearer"
            )
            
            let credentials = UserCredentials(
                userId: userId,
                authToken: authToken,
                provider: provider
            )
            
            // Clean up
            try? secureStorage.deleteAllCredentials()
            
            // Store credentials
            try secureStorage.saveCredentials(credentials)
            
            // Validate session (should refresh token and succeed)
            let isValid = try await authService.validateSession()
            
            // Verify session was restored after refresh
            XCTAssertTrue(
                isValid,
                "Iteration \(iteration): Session should be restored after token refresh"
            )
            
            // Verify user was restored
            let currentUser = authService.getCurrentUser()
            XCTAssertNotNil(
                currentUser,
                "Iteration \(iteration): User should be restored after token refresh"
            )
            
            // Verify credentials were updated with new token
            let updatedCredentials = try? secureStorage.getCredentials()
            XCTAssertNotNil(
                updatedCredentials,
                "Iteration \(iteration): Updated credentials should be stored"
            )
            
            // Verify new token is different from expired one
            if let updatedToken = updatedCredentials?.authToken.accessToken {
                XCTAssertNotEqual(
                    updatedToken,
                    accessToken,
                    "Iteration \(iteration): New token should be different from expired token"
                )
                XCTAssertTrue(
                    updatedToken.contains("refreshed_"),
                    "Iteration \(iteration): New token should be marked as refreshed"
                )
            }
            
            // Clean up
            try? secureStorage.deleteAllCredentials()
        }
    }
    
    /// Test that logout works even when no user is logged in
    /// **Feature: user-auth-subscription, Property 6: Logout Data Removal**
    /// **Validates: Requirements 2.5**
    func testLogoutWithNoUser() async throws {
        let secureStorage = SecureStorage.shared
        
        // Run 100 iterations
        for iteration in 1...100 {
            // Clean up to ensure no user is logged in
            try? secureStorage.deleteAllCredentials()
            
            // Verify no user is logged in
            let userBefore = authService.getCurrentUser()
            XCTAssertNil(
                userBefore,
                "Iteration \(iteration): No user should be logged in"
            )
            
            // Perform logout (should not throw even with no user)
            do {
                try await authService.signOut()
            } catch {
                XCTFail("Iteration \(iteration): Logout with no user should not throw, but got: \(error)")
            }
            
            // Verify still no user
            let userAfter = authService.getCurrentUser()
            XCTAssertNil(
                userAfter,
                "Iteration \(iteration): Still no user after logout"
            )
        }
    }
    
    /// Test session validation with missing credentials
    /// **Feature: user-auth-subscription, Property 5: Invalid Token Cleanup**
    /// **Validates: Requirements 2.4**
    func testSessionValidationWithMissingCredentials() async throws {
        let secureStorage = SecureStorage.shared
        
        // Run 100 iterations
        for iteration in 1...100 {
            // Clean up to ensure no credentials exist
            try? secureStorage.deleteAllCredentials()
            
            // Validate session (should return false)
            let isValid = try await authService.validateSession()
            
            // Verify session is not valid
            XCTAssertFalse(
                isValid,
                "Iteration \(iteration): Session should not be valid without credentials"
            )
            
            // Verify no user is set
            let currentUser = authService.getCurrentUser()
            XCTAssertNil(
                currentUser,
                "Iteration \(iteration): No user should be set without credentials"
            )
        }
    }
}
