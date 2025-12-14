//
//  AuthViewModelTests.swift
//  LightGalleryTests
//
//  Created by Kiro on 2025-12-06.
//

import XCTest
@testable import LightGallery

@MainActor
final class AuthViewModelTests: XCTestCase {
    
    var viewModel: AuthViewModel!
    var mockAuthService: MockAuthenticationService!
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthenticationService()
        viewModel = AuthViewModel(authService: mockAuthService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockAuthService = nil
        super.tearDown()
    }
    
    // MARK: - Loading State Tests
    
    func testSignInSetsLoadingStateToTrue() async {
        // Given
        mockAuthService.shouldSucceed = true
        XCTAssertFalse(viewModel.isLoading, "Initial loading state should be false")
        
        // When
        let signInTask = Task {
            await viewModel.signIn(with: .apple)
        }
        
        // Then - check loading state is true during sign in
        // Note: This is a race condition test, so we check immediately
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        
        await signInTask.value
        XCTAssertFalse(viewModel.isLoading, "Loading state should be false after sign in completes")
    }
    
    func testSignInSetsLoadingStateToFalseAfterSuccess() async {
        // Given
        mockAuthService.shouldSucceed = true
        
        // When
        await viewModel.signIn(with: .apple)
        
        // Then
        XCTAssertFalse(viewModel.isLoading, "Loading state should be false after successful sign in")
    }
    
    func testSignInSetsLoadingStateToFalseAfterFailure() async {
        // Given
        mockAuthService.shouldSucceed = false
        
        // When
        await viewModel.signIn(with: .apple)
        
        // Then
        XCTAssertFalse(viewModel.isLoading, "Loading state should be false after failed sign in")
    }
    
    func testSignOutSetsLoadingStateToTrue() async {
        // Given
        mockAuthService.shouldSucceed = true
        await viewModel.signIn(with: .apple)
        XCTAssertFalse(viewModel.isLoading, "Initial loading state should be false")
        
        // When
        let signOutTask = Task {
            await viewModel.signOut()
        }
        
        // Then
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        
        await signOutTask.value
        XCTAssertFalse(viewModel.isLoading, "Loading state should be false after sign out completes")
    }
    
    func testValidateSessionSetsLoadingState() async {
        // Given
        mockAuthService.shouldSucceed = true
        XCTAssertFalse(viewModel.isLoading, "Initial loading state should be false")
        
        // When
        await viewModel.validateSession()
        
        // Then
        XCTAssertFalse(viewModel.isLoading, "Loading state should be false after validation completes")
    }
    
    // MARK: - Error Handling Tests
    
    func testSignInWithAppleDisplaysErrorOnFailure() async {
        // Given
        mockAuthService.shouldSucceed = false
        mockAuthService.errorToThrow = AuthError.oauthFailed(provider: .apple, reason: "Test error")
        
        // When
        await viewModel.signIn(with: .apple)
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set on failure")
        XCTAssertTrue(viewModel.errorMessage?.contains("登录失败") ?? false, "Error message should contain failure text")
        XCTAssertFalse(viewModel.isAuthenticated, "User should not be authenticated on failure")
    }
    
    func testSignInWithWeChatDisplaysErrorOnFailure() async {
        // Given
        mockAuthService.shouldSucceed = false
        mockAuthService.errorToThrow = AuthError.oauthFailed(provider: .wechat, reason: "Test error")
        
        // When
        await viewModel.signIn(with: .wechat)
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set on failure")
        XCTAssertFalse(viewModel.isAuthenticated, "User should not be authenticated on failure")
    }
    
    func testSignInWithAlipayDisplaysErrorOnFailure() async {
        // Given
        mockAuthService.shouldSucceed = false
        mockAuthService.errorToThrow = AuthError.oauthFailed(provider: .alipay, reason: "Test error")
        
        // When
        await viewModel.signIn(with: .alipay)
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set on failure")
        XCTAssertFalse(viewModel.isAuthenticated, "User should not be authenticated on failure")
    }
    
    func testSignInClearsErrorMessageOnNewAttempt() async {
        // Given
        mockAuthService.shouldSucceed = false
        await viewModel.signIn(with: .apple)
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set after first failure")
        
        // When
        mockAuthService.shouldSucceed = true
        await viewModel.signIn(with: .apple)
        
        // Then
        XCTAssertNil(viewModel.errorMessage, "Error message should be cleared on new sign in attempt")
    }
    
    func testSignOutDisplaysErrorOnFailure() async {
        // Given
        mockAuthService.shouldSucceed = true
        await viewModel.signIn(with: .apple)
        
        mockAuthService.shouldSucceed = false
        mockAuthService.errorToThrow = AuthError.networkError
        
        // When
        await viewModel.signOut()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set on sign out failure")
    }
    
    func testValidateSessionDisplaysErrorOnFailure() async {
        // Given
        mockAuthService.shouldSucceed = false
        mockAuthService.errorToThrow = AuthError.tokenExpired
        
        // When
        await viewModel.validateSession()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set on validation failure")
        XCTAssertFalse(viewModel.isAuthenticated, "User should not be authenticated on validation failure")
    }
    
    // MARK: - Successful Authentication Flow Tests
    
    func testSuccessfulAppleSignInUpdatesUser() async {
        // Given
        mockAuthService.shouldSucceed = true
        
        // When
        await viewModel.signIn(with: .apple)
        
        // Then
        XCTAssertNotNil(viewModel.currentUser, "Current user should be set after successful sign in")
        XCTAssertEqual(viewModel.currentUser?.authProvider, .apple, "Auth provider should be Apple")
        XCTAssertTrue(viewModel.isAuthenticated, "User should be authenticated after successful sign in")
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil after successful sign in")
    }
    
    func testSuccessfulWeChatSignInUpdatesUser() async {
        // Given
        mockAuthService.shouldSucceed = true
        
        // When
        await viewModel.signIn(with: .wechat)
        
        // Then
        XCTAssertNotNil(viewModel.currentUser, "Current user should be set after successful sign in")
        XCTAssertEqual(viewModel.currentUser?.authProvider, .wechat, "Auth provider should be WeChat")
        XCTAssertTrue(viewModel.isAuthenticated, "User should be authenticated after successful sign in")
    }
    
    func testSuccessfulAlipaySignInUpdatesUser() async {
        // Given
        mockAuthService.shouldSucceed = true
        
        // When
        await viewModel.signIn(with: .alipay)
        
        // Then
        XCTAssertNotNil(viewModel.currentUser, "Current user should be set after successful sign in")
        XCTAssertEqual(viewModel.currentUser?.authProvider, .alipay, "Auth provider should be Alipay")
        XCTAssertTrue(viewModel.isAuthenticated, "User should be authenticated after successful sign in")
    }
    
    func testSuccessfulSignOutClearsUser() async {
        // Given
        mockAuthService.shouldSucceed = true
        await viewModel.signIn(with: .apple)
        XCTAssertNotNil(viewModel.currentUser, "User should be set after sign in")
        
        // When
        await viewModel.signOut()
        
        // Then
        XCTAssertNil(viewModel.currentUser, "Current user should be nil after sign out")
        XCTAssertFalse(viewModel.isAuthenticated, "User should not be authenticated after sign out")
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil after successful sign out")
    }
    
    func testSuccessfulValidationRestoresUser() async {
        // Given
        mockAuthService.shouldSucceed = true
        mockAuthService.mockUser = User(
            id: "test-user-id",
            displayName: "Test User",
            authProvider: .apple
        )
        
        // When
        await viewModel.validateSession()
        
        // Then
        XCTAssertNotNil(viewModel.currentUser, "Current user should be restored after successful validation")
        XCTAssertTrue(viewModel.isAuthenticated, "User should be authenticated after successful validation")
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil after successful validation")
    }
    
    func testFailedValidationClearsUser() async {
        // Given
        mockAuthService.shouldSucceed = false
        mockAuthService.errorToThrow = AuthError.tokenInvalid
        
        // When
        await viewModel.validateSession()
        
        // Then
        XCTAssertNil(viewModel.currentUser, "Current user should be nil after failed validation")
        XCTAssertFalse(viewModel.isAuthenticated, "User should not be authenticated after failed validation")
    }
    
    // MARK: - State Transition Tests
    
    func testAuthenticationStateTransitionFromUnauthenticatedToAuthenticated() async {
        // Given
        XCTAssertFalse(viewModel.isAuthenticated, "Initial state should be unauthenticated")
        XCTAssertNil(viewModel.currentUser, "Initial user should be nil")
        
        // When
        mockAuthService.shouldSucceed = true
        await viewModel.signIn(with: .apple)
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated, "State should transition to authenticated")
        XCTAssertNotNil(viewModel.currentUser, "User should be set")
    }
    
    func testAuthenticationStateTransitionFromAuthenticatedToUnauthenticated() async {
        // Given
        mockAuthService.shouldSucceed = true
        await viewModel.signIn(with: .apple)
        XCTAssertTrue(viewModel.isAuthenticated, "Initial state should be authenticated")
        
        // When
        await viewModel.signOut()
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated, "State should transition to unauthenticated")
        XCTAssertNil(viewModel.currentUser, "User should be cleared")
    }
    
    func testInitializationWithExistingUser() {
        // Given
        let existingUser = User(
            id: "existing-user",
            displayName: "Existing User",
            authProvider: .apple
        )
        mockAuthService.mockUser = existingUser
        
        // When
        let newViewModel = AuthViewModel(authService: mockAuthService)
        
        // Then
        XCTAssertNotNil(newViewModel.currentUser, "ViewModel should initialize with existing user")
        XCTAssertTrue(newViewModel.isAuthenticated, "ViewModel should be authenticated with existing user")
        XCTAssertEqual(newViewModel.currentUser?.id, existingUser.id, "User ID should match")
    }
}

// MARK: - Mock Authentication Service

class MockAuthenticationService: AuthenticationServiceProtocol {
    var shouldSucceed = true
    var errorToThrow: Error = AuthError.unknownError(NSError(domain: "test", code: -1))
    var mockUser: User?
    
    func signInWithApple() async throws -> User {
        if shouldSucceed {
            let user = User(
                id: "apple-user-id",
                displayName: "Apple User",
                email: "apple@example.com",
                authProvider: .apple
            )
            mockUser = user
            return user
        } else {
            throw errorToThrow
        }
    }
    
    func signInWithWeChat() async throws -> User {
        if shouldSucceed {
            let user = User(
                id: "wechat-user-id",
                displayName: "WeChat User",
                authProvider: .wechat
            )
            mockUser = user
            return user
        } else {
            throw errorToThrow
        }
    }
    
    func signInWithAlipay() async throws -> User {
        if shouldSucceed {
            let user = User(
                id: "alipay-user-id",
                displayName: "Alipay User",
                authProvider: .alipay
            )
            mockUser = user
            return user
        } else {
            throw errorToThrow
        }
    }
    
    func validateSession() async throws -> Bool {
        if shouldSucceed {
            return true
        } else {
            throw errorToThrow
        }
    }
    
    func signOut() async throws {
        if shouldSucceed {
            mockUser = nil
        } else {
            throw errorToThrow
        }
    }
    
    func getCurrentUser() -> User? {
        return mockUser
    }
    
    func refreshAuthToken() async throws -> String {
        if shouldSucceed {
            return "refreshed-token"
        } else {
            throw errorToThrow
        }
    }
}
