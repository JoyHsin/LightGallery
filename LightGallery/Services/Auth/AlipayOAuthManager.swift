//
//  AlipayOAuthManager.swift
//  LightGallery
//
//  Created by Kiro on 2025-12-06.
//

import Foundation

/// Alipay OAuth credential data
struct AlipayCredential {
    let code: String
    let state: String?
}

/// Alipay user information after token exchange
struct AlipayUserInfo {
    let userId: String
    let nickname: String
    let avatar: String?
    let accessToken: String
    let refreshToken: String
    let expiresIn: TimeInterval
}

/// Manager for handling Alipay OAuth authentication
/// 
/// Note: This implementation requires the Alipay SDK to be installed.
/// To integrate Alipay SDK:
/// 1. Add Alipay SDK via CocoaPods:
///    - CocoaPods: pod 'AlipaySDK-iOS'
///    - Or download from: https://opendocs.alipay.com/open/54/00y8k9
/// 2. Configure Info.plist with:
///    - LSApplicationQueriesSchemes: ["alipay", "alipayshare"]
///    - CFBundleURLTypes with URL scheme: "ap{YOUR_APP_ID}"
/// 3. Register Alipay App ID in AppDelegate or App struct
class AlipayOAuthManager {
    
    // Alipay App ID - should be configured from environment or config file
    private let appId: String
    private let appSecret: String
    
    // Continuation to bridge callback-based API to async/await
    private var authContinuation: CheckedContinuation<AlipayCredential, Error>?
    
    init(appId: String = "YOUR_ALIPAY_APP_ID", appSecret: String = "YOUR_ALIPAY_APP_SECRET") {
        self.appId = appId
        self.appSecret = appSecret
    }
    
    /// Initiates the Alipay OAuth flow
    /// - Returns: AlipayCredential containing authorization code
    /// - Throws: AuthError if OAuth fails
    func initiateSignIn() async throws -> AlipayCredential {
        return try await withCheckedThrowingContinuation { continuation in
            self.authContinuation = continuation
            
            // In production, this would use the Alipay SDK:
            // let authInfo = "apiname=com.alipay.account.auth&app_id=\(appId)&app_name=mc&auth_type=AUTHACCOUNT&biz_type=openservice&pid=\(partnerId)&product_id=APP_FAST_LOGIN&scope=kuaijie&sign_type=RSA2&target_id=\(targetId)"
            // AlipaySDK.defaultService().auth_V2(withInfo: authInfo, fromScheme: "ap\(appId)") { result in
            //     self.handleAuthResult(result)
            // }
            
            // For now, simulate the OAuth flow
            // In production, the actual callback will come from Alipay app
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // This is a placeholder - actual implementation requires Alipay SDK
                let error = AuthError.oauthFailed(
                    provider: .alipay,
                    reason: "Alipay SDK not integrated. Please install Alipay SDK and configure App ID."
                )
                self.authContinuation?.resume(throwing: error)
                self.authContinuation = nil
            }
        }
    }
    
    /// Handles the OAuth callback from Alipay app
    /// This should be called from the app's URL scheme handler
    /// - Parameters:
    ///   - code: Authorization code from Alipay
    ///   - state: State parameter for CSRF protection
    func handleCallback(code: String, state: String?) {
        let credential = AlipayCredential(code: code, state: state)
        authContinuation?.resume(returning: credential)
        authContinuation = nil
    }
    
    /// Handles OAuth error callback from Alipay app
    /// - Parameter error: Error from Alipay OAuth flow
    func handleError(_ error: Error) {
        let authError = AuthError.oauthFailed(provider: .alipay, reason: error.localizedDescription)
        authContinuation?.resume(throwing: authError)
        authContinuation = nil
    }
    
    /// Exchanges authorization code for access token via backend
    /// - Parameter code: Authorization code from Alipay
    /// - Returns: AlipayUserInfo with user details and tokens
    /// - Throws: AuthError if exchange fails
    func exchangeCodeForToken(code: String) async throws -> AlipayUserInfo {
        // In production, this should call your backend API
        // The backend will exchange the code with Alipay servers
        // Backend endpoint example: POST /api/v1/auth/oauth/exchange
        // Body: { "provider": "alipay", "code": "...", "state": "..." }
        
        // For now, we'll simulate a direct call to Alipay API
        // Note: In production, NEVER expose your app secret in the client app
        // This should be done on your backend server
        
        guard let url = URL(string: "https://openapi.alipay.com/gateway.do") else {
            throw AuthError.networkError
        }
        
        // Build Alipay API request parameters
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let params: [String: String] = [
            "app_id": appId,
            "method": "alipay.system.oauth.token",
            "format": "JSON",
            "charset": "utf-8",
            "sign_type": "RSA2",
            "timestamp": timestamp,
            "version": "1.0",
            "grant_type": "authorization_code",
            "code": code
        ]
        
        // In production, you would:
        // 1. Sort parameters
        // 2. Generate sign string
        // 3. Sign with RSA2 private key
        // 4. Add sign to parameters
        // This MUST be done on backend for security
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Build query string
        let queryString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = queryString.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw AuthError.oauthFailed(provider: .alipay, reason: "Token exchange failed")
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let responseData = json?["alipay_system_oauth_token_response"] as? [String: Any]
            
            guard let accessToken = responseData?["access_token"] as? String,
                  let userId = responseData?["user_id"] as? String,
                  let refreshToken = responseData?["refresh_token"] as? String,
                  let expiresIn = responseData?["expires_in"] as? TimeInterval else {
                throw AuthError.oauthFailed(provider: .alipay, reason: "Invalid token response")
            }
            
            // Fetch user info with access token
            let userInfo = try await fetchUserInfo(accessToken: accessToken, userId: userId)
            
            return AlipayUserInfo(
                userId: userId,
                nickname: userInfo.nickname,
                avatar: userInfo.avatar,
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresIn: expiresIn
            )
            
        } catch {
            throw AuthError.networkError
        }
    }
    
    /// Fetches user information from Alipay API
    /// - Parameters:
    ///   - accessToken: Access token from Alipay
    ///   - userId: User's Alipay user ID
    /// - Returns: Tuple with nickname and avatar URL
    private func fetchUserInfo(accessToken: String, userId: String) async throws -> (nickname: String, avatar: String?) {
        guard let url = URL(string: "https://openapi.alipay.com/gateway.do") else {
            throw AuthError.networkError
        }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let params: [String: String] = [
            "app_id": appId,
            "method": "alipay.user.info.share",
            "format": "JSON",
            "charset": "utf-8",
            "sign_type": "RSA2",
            "timestamp": timestamp,
            "version": "1.0",
            "auth_token": accessToken
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let queryString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = queryString.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw AuthError.oauthFailed(provider: .alipay, reason: "Failed to fetch user info")
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let responseData = json?["alipay_user_info_share_response"] as? [String: Any]
            
            let nickname = responseData?["nick_name"] as? String ?? "Alipay User"
            let avatar = responseData?["avatar"] as? String
            
            return (nickname, avatar)
            
        } catch {
            throw AuthError.networkError
        }
    }
    
    /// Generates a random state parameter for CSRF protection
    private func generateState() -> String {
        return UUID().uuidString
    }
}

// MARK: - URL Scheme Handling
extension AlipayOAuthManager {
    
    /// Handles incoming URL from Alipay app
    /// This should be called from your app's URL scheme handler
    /// - Parameter url: The URL received from Alipay
    /// - Returns: true if the URL was handled, false otherwise
    func handleOpenURL(_ url: URL) -> Bool {
        // Parse Alipay callback URL
        // Format: ap{appid}://oauth?result=...
        
        guard url.scheme?.hasPrefix("ap") == true else {
            return false
        }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            handleError(AuthError.oauthFailed(provider: .alipay, reason: "Invalid callback URL"))
            return true
        }
        
        // Alipay returns result as a URL-encoded string
        if let resultString = queryItems.first(where: { $0.name == "result" })?.value {
            // Parse the result string which contains auth_code and other parameters
            let resultParams = parseResultString(resultString)
            
            if let authCode = resultParams["auth_code"] {
                let state = resultParams["state"]
                handleCallback(code: authCode, state: state)
            } else if let memo = resultParams["memo"] {
                // Error case
                handleError(AuthError.oauthFailed(provider: .alipay, reason: memo))
            } else {
                handleError(AuthError.oauthFailed(provider: .alipay, reason: "No authorization code received"))
            }
        } else {
            handleError(AuthError.oauthFailed(provider: .alipay, reason: "Invalid result format"))
        }
        
        return true
    }
    
    /// Parses the result string from Alipay callback
    /// - Parameter resultString: URL-encoded result string
    /// - Returns: Dictionary of parsed parameters
    private func parseResultString(_ resultString: String) -> [String: String] {
        var params: [String: String] = [:]
        
        let pairs = resultString.components(separatedBy: "&")
        for pair in pairs {
            let keyValue = pair.components(separatedBy: "=")
            if keyValue.count == 2 {
                let key = keyValue[0]
                let value = keyValue[1].removingPercentEncoding ?? keyValue[1]
                params[key] = value
            }
        }
        
        return params
    }
}
