//
//  AuthError.swift
//  Declutter
//
//  Authentication error definitions
//

import Foundation

/// Authentication errors
enum AuthError: LocalizedError {
    case invalidCredentials
    case oauthFailed(provider: AuthProvider, reason: String)
    case tokenExpired
    case tokenInvalid
    case networkError
    case serverError
    case userCancelled
    case notImplemented
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "无效的登录凭证"
        case .oauthFailed(let provider, let reason):
            return "登录失败：\(provider.displayName) - \(reason)"
        case .tokenExpired:
            return "登录已过期，请重新登录"
        case .tokenInvalid:
            return "登录信息无效，请重新登录"
        case .networkError:
            return "网络连接失败，请检查网络设置"
        case .serverError:
            return "服务器错误，请稍后重试"
        case .userCancelled:
            return "用户取消登录"
        case .notImplemented:
            return "功能尚未实现"
        case .unknownError(let error):
            return "登录失败：\(error.localizedDescription)"
        }
    }
}