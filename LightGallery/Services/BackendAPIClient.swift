//
//  BackendAPIClient.swift
//  LightGallery
//
//  Created for user-auth-subscription feature
//

import Foundation
import StoreKit

class BackendAPIClient {
    static let shared = BackendAPIClient()
    
    private let baseURL: String
    private let session: URLSession
    private let enableLogging: Bool
    
    // MARK: - Environment Configuration
    
    enum Environment {
        case development
        case staging
        case production
        
        var baseURL: String {
            switch self {
            case .development:
                return "http://192.168.1.56:8080"  // 你的电脑局域网IP
            case .staging:
                return "https://staging-api.lightgallery.com"
            case .production:
                return "https://api.lightgallery.com"
            }
        }
    }
    
    init(environment: Environment = .development, session: URLSession = .shared, enableLogging: Bool = true) {
        self.baseURL = environment.baseURL
        self.session = session
        self.enableLogging = enableLogging
    }
    
    // For testing with custom base URL
    init(baseURL: String, session: URLSession = .shared, enableLogging: Bool = true) {
        self.baseURL = baseURL
        self.session = session
        self.enableLogging = enableLogging
    }
    
    // MARK: - Authentication Endpoints
    
    /// Exchange OAuth token for app token
    func exchangeOAuthToken(_ credential: OAuthCredential) async throws -> AuthResponse {
        let endpoint = "\(baseURL)/api/v1/auth/oauth/exchange"
        
        guard let url = URL(string: endpoint) else {
            throw BackendAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = OAuthExchangeRequest(
            provider: credential.provider.rawValue,
            authCode: credential.authCode,
            idToken: credential.idToken,
            email: credential.email,
            displayName: credential.displayName
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)
        
        logRequest(request, body: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        logResponse(response, data: data)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let authResponse = try decoder.decode(AuthResponse.self, from: data)
        
        return authResponse
    }
    
    /// Validate auth token with backend
    func validateAuthToken(_ token: String) async throws -> Bool {
        let endpoint = "\(baseURL)/api/v1/auth/validate"
        
        guard let url = URL(string: endpoint) else {
            throw BackendAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        logRequest(request, body: nil)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendAPIError.invalidResponse
        }
        
        logResponse(response, data: data)
        
        return (200...299).contains(httpResponse.statusCode)
    }
    
    /// Refresh auth token
    func refreshAuthToken(_ refreshToken: String) async throws -> AuthResponse {
        let endpoint = "\(baseURL)/api/v1/auth/token/refresh"
        
        guard let url = URL(string: endpoint) else {
            throw BackendAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = RefreshTokenRequest(refreshToken: refreshToken)
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)
        
        logRequest(request, body: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        logResponse(response, data: data)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let authResponse = try decoder.decode(AuthResponse.self, from: data)
        
        return authResponse
    }
    
    /// Logout user
    func logout(authToken: String) async throws {
        let endpoint = "\(baseURL)/api/v1/auth/logout"
        
        guard let url = URL(string: endpoint) else {
            throw BackendAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        logRequest(request, body: nil)
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        logResponse(response, data: data)
    }
    
    /// Delete user account
    func deleteUserAccount(authToken: String) async throws {
        let endpoint = "\(baseURL)/api/v1/auth/account"
        
        guard let url = URL(string: endpoint) else {
            throw BackendAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        logRequest(request, body: nil)
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        logResponse(response, data: data)
    }
    
    // MARK: - Subscription Endpoints
    
    /// Get available subscription products
    func getSubscriptionProducts() async throws -> [SubscriptionProductDTO] {
        let endpoint = "\(baseURL)/api/v1/subscription/products"
        
        guard let url = URL(string: endpoint) else {
            throw BackendAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        logRequest(request, body: nil)
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        logResponse(response, data: data)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let apiResponse = try decoder.decode(ApiResponse<[SubscriptionProductDTO]>.self, from: data)
        
        return apiResponse.data
    }
    
    /// Get current subscription status
    func getSubscriptionStatus(authToken: String) async throws -> SubscriptionDTO {
        let endpoint = "\(baseURL)/api/v1/subscription/status"
        
        guard let url = URL(string: endpoint) else {
            throw BackendAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        logRequest(request, body: nil)
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        logResponse(response, data: data)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let apiResponse = try decoder.decode(ApiResponse<SubscriptionDTO>.self, from: data)
        
        return apiResponse.data
    }
    
    /// Verify Apple IAP receipt with backend
    func verifyAppleReceipt(_ transaction: Transaction, authToken: String) async throws -> SubscriptionVerificationResponse {
        let endpoint = "\(baseURL)/api/v1/subscription/verify"
        
        guard let url = URL(string: endpoint) else {
            throw BackendAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        // Prepare request body
        let requestBody = ReceiptVerificationRequest(
            transactionId: String(transaction.id),
            productId: transaction.productID,
            purchaseDate: transaction.purchaseDate,
            expirationDate: transaction.expirationDate
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(requestBody)
        
        logRequest(request, body: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        logResponse(response, data: data)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let apiResponse = try decoder.decode(ApiResponse<SubscriptionVerificationResponse>.self, from: data)
        
        return apiResponse.data
    }
    
    /// Sync subscription status with backend
    func syncSubscription(_ subscription: Subscription, authToken: String) async throws {
        let endpoint = "\(baseURL)/api/v1/subscription/sync"
        
        guard let url = URL(string: endpoint) else {
            throw BackendAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(subscription)
        
        logRequest(request, body: subscription)
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        logResponse(response, data: data)
    }
    
    // MARK: - User Profile Endpoints
    
    /// Get user profile
    func getUserProfile(userId: String, authToken: String) async throws -> UserProfile {
        let endpoint = "\(baseURL)/api/v1/user/profile"
        
        guard let url = URL(string: endpoint) else {
            throw BackendAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        logRequest(request, body: nil)
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        logResponse(response, data: data)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let apiResponse = try decoder.decode(ApiResponse<UserProfile>.self, from: data)
        
        return apiResponse.data
    }
    
    /// Update user profile
    func updateUserProfile(_ profile: UserProfile, authToken: String) async throws {
        let endpoint = "\(baseURL)/api/v1/user/profile"
        
        guard let url = URL(string: endpoint) else {
            throw BackendAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(profile)
        
        logRequest(request, body: profile)
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        logResponse(response, data: data)
    }
    
    /// Upload user avatar
    func uploadAvatar(_ imageData: Data, authToken: String) async throws -> AvatarUploadResponse {
        let endpoint = "\(baseURL)/api/v1/user/avatar"
        
        guard let url = URL(string: endpoint) else {
            throw BackendAPIError.invalidURL
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        logRequest(request, body: nil)
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        logResponse(response, data: data)
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(ApiResponse<AvatarUploadResponse>.self, from: data)
        
        return apiResponse.data
    }
    
    // MARK: - Private Helpers
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendAPIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw BackendAPIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
    
    private func logRequest(_ request: URLRequest, body: Encodable?) {
        guard enableLogging else { return }
        
        print("🌐 [BackendAPI] Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        
        if let headers = request.allHTTPHeaderFields {
            print("📋 [BackendAPI] Headers: \(headers)")
        }
        
        if let body = body {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(body),
               let jsonString = String(data: data, encoding: .utf8) {
                print("📦 [BackendAPI] Body: \(jsonString)")
            }
        }
    }
    
    private func logResponse(_ response: URLResponse, data: Data) {
        guard enableLogging else { return }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("✅ [BackendAPI] Response: \(httpResponse.statusCode)")
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📥 [BackendAPI] Data: \(jsonString)")
            }
        }
    }
}

// MARK: - Request/Response Models

// API Response Wrapper
struct ApiResponse<T: Codable>: Codable {
    let code: Int
    let message: String
    let data: T
}

// Authentication
struct OAuthExchangeRequest: Codable {
    let provider: String
    let authCode: String?
    let idToken: String?
    let email: String?
    let displayName: String?
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let user: UserDTO
}

struct UserDTO: Codable {
    let id: String
    let displayName: String
    let email: String?
    let avatarURL: String?
    let authProvider: String
}

// Subscription
struct ReceiptVerificationRequest: Codable {
    let transactionId: String
    let productId: String
    let purchaseDate: Date
    let expirationDate: Date?
}

struct SubscriptionVerificationResponse: Codable {
    let success: Bool
    let subscription: SubscriptionDTO?
    let message: String?
}

struct SubscriptionDTO: Codable {
    let id: String
    let userId: String
    let tier: String
    let billingPeriod: String
    let status: String
    let startDate: Date
    let expiryDate: Date
    let autoRenew: Bool
    let paymentMethod: String
}

struct SubscriptionProductDTO: Codable {
    let id: String
    let tier: String
    let billingPeriod: String
    let price: Decimal
    let currency: String
    let localizedPrice: String
    let localizedDescription: String
    
    // Map backend field names to iOS field names
    enum CodingKeys: String, CodingKey {
        case id = "productId"
        case tier
        case billingPeriod
        case price
        case currency
        case localizedPrice
        case localizedDescription = "description"
    }
}

// User Profile
struct UserProfile: Codable {
    let id: String
    var displayName: String
    var email: String?
    var avatarURL: String?
}

struct AvatarUploadResponse: Codable {
    let avatarURL: String
    let message: String?
}

// OAuth Credential
struct OAuthCredential {
    let provider: AuthProvider
    let authCode: String?
    let idToken: String?
    let email: String?
    let displayName: String?
}

// MARK: - Errors

enum BackendAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 API URL"
        case .invalidResponse:
            return "无效的服务器响应"
        case .httpError(let statusCode):
            return "服务器错误：HTTP \(statusCode)"
        case .decodingError(let error):
            return "数据解析失败：\(error.localizedDescription)"
        case .networkError(let error):
            return "网络错误：\(error.localizedDescription)"
        }
    }
}
