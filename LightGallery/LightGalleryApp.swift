//
//  LightGalleryApp.swift
//  LightGallery
//
//  Created by Joy Hsin on 2025/9/7.
//  Lite version - No authentication or subscription required
//

import SwiftUI
import Photos

@main
struct LightGalleryApp: App {
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(localizationManager)
        }
    }
}
