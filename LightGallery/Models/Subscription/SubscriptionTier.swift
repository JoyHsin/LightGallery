//
//  SubscriptionTier.swift
//  LightGallery
//
//  Created for user-auth-subscription feature
//

import Foundation

enum SubscriptionTier: String, Codable, Comparable, CaseIterable {
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
    
    // Comparable conformance
    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        let order: [SubscriptionTier] = [.free, .pro, .max]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

enum PremiumFeature: String, CaseIterable {
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
    
    var displayName: String {
        switch self {
        case .toolbox: return "工具箱"
        case .smartClean: return "智能清理"
        case .duplicateDetection: return "重复照片检测"
        case .similarPhotoCleanup: return "相似照片清理"
        case .screenshotCleanup: return "截图清理"
        case .photoEnhancer: return "照片增强"
        case .formatConverter: return "格式转换"
        case .livePhotoConverter: return "Live Photo 转换"
        case .idPhotoEditor: return "证件照编辑"
        case .privacyWiper: return "隐私擦除"
        case .screenshotStitcher: return "长截图拼接"
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
