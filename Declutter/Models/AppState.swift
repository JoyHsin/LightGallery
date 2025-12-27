//
//  AppState.swift
//  Declutter
//
//  Created by Kiro on 2025/9/7.
//

import Foundation

/// 应用程序状态
struct AppState {
    var photos: [PhotoAsset] = []
    var currentIndex: Int = 0
    var deletedPhotos: Set<String> = []
    var keptPhotos: Set<String> = []
    var filter: FilterCriteria = .none
    var hasPhotoPermission: Bool = false
}