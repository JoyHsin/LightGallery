//
//  PhotoAsset.swift
//  LightGallery
//
//  Created by Kiro on 2025/9/7.
//

import Foundation
import Photos

/// 照片资源的数据模型，封装PHAsset和相关元数据
struct PhotoAsset: Identifiable, Equatable {
    let id: String
    let phAsset: PHAsset
    let creationDate: Date
    let localIdentifier: String
    
    init(phAsset: PHAsset) {
        self.phAsset = phAsset
        self.id = phAsset.localIdentifier
        self.localIdentifier = phAsset.localIdentifier
        self.creationDate = phAsset.creationDate ?? Date()
    }
    
    /// 格式化显示日期
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: creationDate)
    }
    
    /// 格式化显示时间
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: creationDate)
    }
    
    /// 获取年份
    var year: Int {
        Calendar.current.component(.year, from: creationDate)
    }
    
    /// 获取月份
    var month: Int {
        Calendar.current.component(.month, from: creationDate)
    }
    
    static func == (lhs: PhotoAsset, rhs: PhotoAsset) -> Bool {
        lhs.localIdentifier == rhs.localIdentifier
    }
    
    // MARK: - Test/Preview Initializer
    
    /// 用于测试和预览的初始化方法
    init(id: String, creationDate: Date, localIdentifier: String) {
        self.id = id
        self.phAsset = PHAsset() // 空的PHAsset，仅用于测试/预览
        self.creationDate = creationDate
        self.localIdentifier = localIdentifier
    }
}