//
//  LightGalleryApp.swift
//  LightGallery
//
//  Created by Joy Hsin on 2025/9/7.
//

import SwiftUI
import Photos

@main
struct LightGalleryApp: App {
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()
    
    // OAuth managers for handling callbacks
    private let wechatManager = WeChatOAuthManager()
    private let alipayManager = AlipayOAuthManager()
    
    init() {
        // Register WeChat SDK when it's installed
        // Uncomment the following line after installing WeChat SDK:
        // WXApi.registerApp("YOUR_WECHAT_APP_ID", universalLink: "https://yourdomain.com/")
        
        // Register Alipay SDK when it's installed
        // Uncomment the following line after installing Alipay SDK:
        // Note: Alipay SDK registration is handled in AlipayOAuthManager
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(localizationManager)
                .environmentObject(subscriptionViewModel)
                .onOpenURL { url in
                    handleOpenURL(url)
                }
                .task {
                    // Check subscription expiration on app launch (non-blocking)
                    Task.detached {
                        await subscriptionViewModel.checkExpirationOnLaunch()
                    }
                }
        }
    }
    
    /// Handles incoming URLs from OAuth providers
    /// - Parameter url: The URL received from external apps (WeChat, Alipay, etc.)
    private func handleOpenURL(_ url: URL) {
        // Handle WeChat OAuth callback
        if url.scheme?.hasPrefix("wx") == true {
            // When WeChat SDK is installed, use:
            // WXApi.handleOpen(url, delegate: wechatDelegate)
            
            // For now, handle directly with our manager
            _ = wechatManager.handleOpenURL(url)
        }
        
        // Handle Alipay OAuth callback
        if url.scheme?.hasPrefix("ap") == true {
            _ = alipayManager.handleOpenURL(url)
        }
    }
}
