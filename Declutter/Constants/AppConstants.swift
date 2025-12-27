//
//  AppConstants.swift
//  Declutter
//
//  App-wide constants for URLs and configuration
//

import Foundation

/// App-wide constants
/// Contains URLs and configuration values used throughout the app
enum AppConstants {
    // MARK: - Legal URLs (Required for App Store Guideline 5.1.1 & 3.1.2)
    
    /// Privacy Policy URL - Must be accessible and match App Store Connect
    static let privacyPolicyURL = "https://lightgallery.app/privacy"
    
    /// Terms of Service URL - Must be accessible and match App Store Connect
    static let termsOfServiceURL = "https://lightgallery.app/terms"
    
    /// Support URL
    static let supportURL = "https://lightgallery.app/support"
    
    // MARK: - App Store URLs
    
    /// App Store subscription management URL
    static let subscriptionManagementURL = "https://apps.apple.com/account/subscriptions"
    
    /// App Store review URL (for requesting reviews)
    static let appStoreReviewURL = "https://apps.apple.com/app/idYOUR_APP_ID?action=write-review"
    
    // MARK: - App Information
    
    /// App Bundle ID
    static let bundleID = "joyhisn.Declutter"
    
    /// App Name
    static let appName = "Declutter"
    
    // MARK: - Subscription Product IDs
    
    /// Pro Monthly subscription product ID
    static let proMonthlyProductID = "joyhisn.Declutter.pro.monthly"
    
    /// Pro Yearly subscription product ID
    static let proYearlyProductID = "joyhisn.Declutter.pro.yearly"
    
    /// Max Monthly subscription product ID
    static let maxMonthlyProductID = "joyhisn.Declutter.max.monthly"
    
    /// Max Yearly subscription product ID
    static let maxYearlyProductID = "joyhisn.Declutter.max.yearly"
}
