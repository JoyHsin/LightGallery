//
//  AuthProvider.swift
//  Declutter
//
//  Created by Kiro on 2025-12-06.
//

import Foundation

enum AuthProvider: String, Codable {
    case apple = "apple"
    case wechat = "wechat"
    case alipay = "alipay"
    
    var displayName: String {
        switch self {
        case .apple:
            return "Apple ID"
        case .wechat:
            return "微信"
        case .alipay:
            return "支付宝"
        }
    }
}
