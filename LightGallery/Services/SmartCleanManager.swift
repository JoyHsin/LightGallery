//
//  SmartCleanManager.swift
//  LightGallery
//
//  Created by Antigravity on 2025/12/05.
//

import Photos
import SwiftUI

enum SmartCleanCategoryType: String, CaseIterable {
    case duplicates = "Duplicates"
    case expiredScreenshots = "Expired Screenshots"
    case lowQuality = "Low Quality"
    
    var iconName: String {
        switch self {
        case .duplicates: return "doc.on.doc.fill"
        case .expiredScreenshots: return "clock.arrow.circlepath"
        case .lowQuality: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .duplicates: return .red
        case .expiredScreenshots: return .orange
        case .lowQuality: return .yellow
        }
    }
}

struct SmartCleanCategory: Identifiable {
    let id = UUID()
    let type: SmartCleanCategoryType
    var assets: [PhotoAsset]
    var totalSize: Int64
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }
}

class SmartCleanManager {
    static let shared = SmartCleanManager()
    private let featureAccessManager: FeatureAccessManager
    
    private init(featureAccessManager: FeatureAccessManager = .shared) {
        self.featureAccessManager = featureAccessManager
    }
    
    func scan() async -> [SmartCleanCategory] {
        // Check if user has access to smart clean feature
        guard featureAccessManager.canAccessFeature(.smartClean) else {
            // Show paywall
            featureAccessManager.showPaywall(for: .smartClean)
            return []
        }
        var categories: [SmartCleanCategory] = []
        
        // 1. Duplicates
        let duplicates = await scanDuplicates()
        if !duplicates.isEmpty {
            let size = calculateSize(for: duplicates)
            categories.append(SmartCleanCategory(type: .duplicates, assets: duplicates, totalSize: size))
        }
        
        // 2. Expired Screenshots
        let screenshots = await scanExpiredScreenshots()
        if !screenshots.isEmpty {
            let size = calculateSize(for: screenshots)
            categories.append(SmartCleanCategory(type: .expiredScreenshots, assets: screenshots, totalSize: size))
        }
        
        // 3. Low Quality
        let lowQuality = await scanLowQuality()
        if !lowQuality.isEmpty {
            let size = calculateSize(for: lowQuality)
            categories.append(SmartCleanCategory(type: .lowQuality, assets: lowQuality, totalSize: size))
        }
        
        return categories
    }
    
    private func calculateSize(for assets: [PhotoAsset]) -> Int64 {
        // Estimate 2MB per photo for demo purposes
        // In production, fetch PHAssetResource
        return Int64(assets.count * 2 * 1024 * 1024)
    }
    
    // Logic: Identify photos that look identical (CreationDate + Dimensions)
    private func scanDuplicates() async -> [PhotoAsset] {
        // We can reuse the logic from DuplicateDetectionService, but here we just want a flat list of "extra" copies
        let groups = await DuplicateDetectionService.shared.scanForDuplicates()
        var duplicates: [PhotoAsset] = []
        for group in groups {
            // Keep the first one, mark the rest as duplicates
            let extras = group.assets.dropFirst()
            duplicates.append(contentsOf: extras)
        }
        return duplicates
    }
    
    // Logic: Oldest 1% of screenshots
    private func scanExpiredScreenshots() async -> [PhotoAsset] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaSubtype == %d", PHAssetMediaSubtype.photoScreenshot.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)] // Oldest first
        
        let result = PHAsset.fetchAssets(with: .image, options: options)
        let count = result.count
        guard count > 0 else { return [] }
        
        // Select oldest 1%, minimum 1
        let limit = max(1, Int(Double(count) * 0.01))
        
        var assets: [PhotoAsset] = []
        result.enumerateObjects { asset, index, stop in
            if index < limit {
                assets.append(PhotoAsset(phAsset: asset))
            } else {
                stop.pointee = true
            }
        }
        return assets
    }
    
    // Logic: Pixel width or height < 1000px
    private func scanLowQuality() async -> [PhotoAsset] {
        let options = PHFetchOptions()
        // We can't easily predicate pixel dimensions in all cases, so we fetch and filter
        let result = PHAsset.fetchAssets(with: .image, options: options)
        
        var assets: [PhotoAsset] = []
        result.enumerateObjects { asset, _, _ in
            if asset.pixelWidth < 1000 || asset.pixelHeight < 1000 {
                assets.append(PhotoAsset(phAsset: asset))
            }
        }
        return assets
    }
}
