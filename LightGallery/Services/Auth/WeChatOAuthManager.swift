//
//  WeChatOAuthManager.swift
//  LightGallery
//
//  Created by Kiro on 2025-12-06.
//

import Foundation

/// WeChat OAuth credential data
struct WeChatCredential {
    let code: String
    let state: String?
}

/// WeChat user information after token exchange
struct WeChatUserInfo {
    let openId: String
    let unionId: String?
    let nickname: String
    let avatarUrl: String?
    let accessToken: String
    let refreshToken: String
    let expiresIn: TimeInterval
}

/// Manager for handling WeChat OAuth authentication
/// 
/// Note: This implementation requires the WeChat SDK to be installed.
/// To integrate WeChat SDK:
/// 1. Add WeChat SDK via CocoaPods or SPM:
///    - CocoaPods: pod 'WechatOpenSDK'
///    - Or download from: https://developers.weixin.qq.com/doc/oplatform/Mobile_App/Access_Guide/iOS.html
/// 2. Configure Info.plist with:
///    - LSApplicationQueriesSchemes: ["weixin", "weixinULAPI"]
///    - CFBundleURLTypes with URL scheme: "wx{YOUR_APP_ID}"
/// 3. Register WeChat App ID in AppDelegate or App struct
class WeChatOAuthManager {
    
    // WeChat App ID - should be configured from environment or config file
    private let appId: String
    private let appSecret: String
    
    // Continuation to bridge callback-based API to async/await
    private var authContinuation: CheckedContinuation<WeChatCredential, Error>?
    
    init(appId: String = "YOUR_WECHAT_APP_ID", appSecret: String = "YOUR_WECHAT_APP_SECRET") {
        self.appId = appId
        self.appSecret = appSecret
    }
    
    /// Initiates the WeChat OAuth flow
    /// - Returns: WeChatCredential containing authorization code
    /// - Throws: AuthError if OAuth fails
    func initiateSignIn() async throws -> WeChatCredential {
        return try await withCheckedThrowingContinuation { continuation in
            self.authContinuation = continuation
            
            // In production, this would use the WeChat SDK:
            // let req = SendAuthReq()
            // req.scope = "snsapi_userinfo"
            // req.state = generateState()
            // WXApi.send(req)
            
            // For now, simulate the OAuth flow
            // In production, the actual callback will come from WeChat app
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // This is a placeholder - actual implementation requires WeChat SDK
                let error = AuthError.oauthFailed(
                    provider: .wechat,
                    reason: "WeChat SDK not integrated. Please install WeChat SDK and configure App ID."
                )
                self.authContinuation?.resume(throwing: error)
                self.authContinuation = nil
            }
        }
    }
    
    /// Handles the OAuth callback from WeChat app
    /// This should be called from the app's URL scheme handler
    /// - Parameters:
    ///   - code: Authorization code from WeChat
    ///   - state: State parameter for CSRF protection
    func handleCallback(code: String, state: String?) {
        let credential = WeChatCredential(code: code, state: state)
        authContinuation?.resume(returning: credential)
        authContinuation = nil
    }
    
    /// Handles OAuth error callback from WeChat app
    /// - Parameter error: Error from WeChat OAuth flow
    func handleError(_ error: Error) {
        let authError = AuthError.oauthFailed(provider: .wechat, reason: error.localizedDescription)
        authContinuation?.resume(throwing: authError)
        authContinuation = nil
    }
    
    /// Exchanges authorization code for access token via backend
    /// - Parameter code: Authorization code from WeChat
    /// - Returns: WeChatUserInfo with user details and tokens
    /// - Throws: AuthError if exchange fails
    func exchangeCodeForToken(code: String) async throws -> WeChatUserInfo {
        // In production, this should call your backend API
        // The backend will exchange the code with WeChat servers
        
        guard let url = URL(string: "https://api.weixin.qq.com/sns/oauth2/access_token") else {
            throw AuthError.networkError
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "appid", value: appId),
            URLQueryItem(name: "secret", value: appSecret),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        
        guard let requestUrl = components?.url else {
            throw AuthError.networkError
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw AuthError.oauthFailed(provider: .wechat, reason: "Token exchange failed")
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let accessToken = json?["access_token"] as? String,
                  let openId = json?["openid"] as? String,
                  let refreshToken = json?["refresh_token"] as? String,
                  let expiresIn = json?["expires_in"] as? TimeInterval else {
                throw AuthError.oauthFailed(provider: .wechat, reason: "Invalid token response")
            }
            
            // Fetch user info with access token
            let userInfo = try await fetchUserInfo(accessToken: accessToken, openId: openId)
            
            return WeChatUserInfo(
                openId: openId,
                unionId: json?["unionid"] as? String,
                nickname: userInfo.nickname,
                avatarUrl: userInfo.avatarUrl,
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresIn: expiresIn
            )
            
        } catch {
            throw AuthError.networkError
        }
    }
    
    /// Fetches user information from WeChat API
    /// - Parameters:
    ///   - accessToken: Access token from WeChat
    ///   - openId: User's OpenID
    /// - Returns: Tuple with nickname and avatar URL
    private func fetchUserInfo(accessToken: String, openId: String) async throws -> (nickname: String, avatarUrl: String?) {
        guard let url = URL(string: "https://api.weixin.qq.com/sns/userinfo") else {
            throw AuthError.networkError
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "openid", value: openId)
        ]
        
        guard let requestUrl = components?.url else {
            throw AuthError.networkError
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw AuthError.oauthFailed(provider: .wechat, reason: "Failed to fetch user info")
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            let nickname = json?["nickname"] as? String ?? "WeChat User"
            let avatarUrl = json?["headimgurl"] as? String
            
            return (nickname, avatarUrl)
            
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
extension WeChatOAuthManager {
    
    /// Handles incoming URL from WeChat app
    /// This should be called from your app's URL scheme handler
    /// - Parameter url: The URL received from WeChat
    /// - Returns: true if the URL was handled, false otherwise
    func handleOpenURL(_ url: URL) -> Bool {
        // Parse WeChat callback URL
        // Format: wx{appid}://oauth?code=xxx&state=xxx
        
        guard url.scheme?.hasPrefix("wx") == true else {
            return false
        }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            handleError(AuthError.oauthFailed(provider: .wechat, reason: "Invalid callback URL"))
            return true
        }
        
        // Extract code and state from query parameters
        let code = queryItems.first(where: { $0.name == "code" })?.value
        let state = queryItems.first(where: { $0.name == "state" })?.value
        
        if let code = code {
            handleCallback(code: code, state: state)
        } else {
            handleError(AuthError.oauthFailed(provider: .wechat, reason: "No authorization code received"))
        }
        
        return true
    }
}
