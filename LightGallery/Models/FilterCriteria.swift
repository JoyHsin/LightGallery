//
//  FilterCriteria.swift
//  LightGallery
//
//  Created by Kiro on 2025/9/7.
//

import Foundation

/// 筛选条件
struct FilterCriteria {
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    
    /// 无筛选条件的默认值
    static let none = FilterCriteria(
        startDate: Date.distantPast,
        endDate: Date.distantFuture,
        isActive: false
    )
}