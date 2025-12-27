//
//  PhotoError.swift
//  Declutter
//
//  Created by Kiro on 2025/9/7.
//

import Foundation

/// 照片操作相关错误类型
enum PhotoError: LocalizedError, Equatable {
    case permissionDenied
    case photoLibraryUnavailable
    case deletionFailed(String)
    case loadingFailed(String)
    case filteringFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "需要访问照片库的权限才能使用此功能"
        case .photoLibraryUnavailable:
            return "照片库当前不可用"
        case .deletionFailed(let reason):
            return "删除照片失败：\(reason)"
        case .loadingFailed(let reason):
            return "加载照片失败：\(reason)"
        case .filteringFailed(let reason):
            return "筛选照片失败：\(reason)"
        }
    }
}