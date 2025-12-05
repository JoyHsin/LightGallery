//
//  SwipeAction.swift
//  LightGallery
//
//  Created by Kiro on 2025/9/7.
//

import Foundation

/// 滑动操作类型
enum SwipeAction {
    case delete  // 删除照片
    case keep    // 保留照片
    case none    // 无操作
}

/// 滑动方向
enum SwipeDirection {
    case left   // 左滑
    case right  // 右滑
}