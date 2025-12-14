//
//  AuthConfig.swift
//  LightGallery
//
//  Created by Kiro on 2025-12-14.
//

import Foundation

/// Authentication configuration for different environments
struct AuthConfig {
    
    /// Authentication mode
    enum Mode {
        case production  // Use real authentication services
        case mock       // Use mock authentication for testing
    }
    
    /// Current authentication mode
    /// Change this to .production when you have configured all OAuth providers
    static let currentMode: Mode = .mock
    
    /// Get the appropriate authentication service based on current mode
    static func getAuthenticationService() -> AuthenticationServiceProtocol {
        switch currentMode {
        case .production:
            return AuthenticationService.shared
        case .mock:
            return MockAuthenticationService()
        }
    }
    
    /// OAuth Provider Configuration
    struct OAuthProviders {
        
        /// Apple Sign In Configuration
        struct Apple {
            static let isEnabled = true
            // Apple Sign In is automatically configured through entitlements
        }
        
        /// WeChat OAuth Configuration
        struct WeChat {
            static let isEnabled = false // Set to true when configured
            static let appId = "YOUR_WECHAT_APP_ID" // Replace with your WeChat App ID
            static let universalLink = "https://your-domain.com/wechat/" // Replace with your universal link
        }
        
        /// Alipay OAuth Configuration
        struct Alipay {
            static let isEnabled = false // Set to true when configured
            static let appId = "YOUR_ALIPAY_APP_ID" // Replace with your Alipay App ID
            static let scheme = "alipay\(appId)" // URL scheme for Alipay
        }
    }
    
    /// Backend API Configuration
    struct Backend {
        enum Environment {
            case development
            case staging
            case production
        }
        
        static let currentEnvironment: Environment = .development
        
        static var baseURL: String {
            switch currentEnvironment {
            case .development:
                return "http://localhost:8080" // Change to your backend URL
            case .staging:
                return "https://staging-api.lightgallery.com"
            case .production:
                return "https://api.lightgallery.com"
            }
        }
    }
}