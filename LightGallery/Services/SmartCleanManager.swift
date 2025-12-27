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
    case largeFiles = "Large Files"

    var iconName: String {
        switch self {
        case .duplicates: return "doc.on.doc.fill"
        case .expiredScreenshots: return "clock.arrow.circlepath"
        case .lowQuality: return "exclamationmark.triangle.fill"
        case .largeFiles: return "externaldrive.fill"
        }
    }

    var color: Color {
        switch self {
        case .duplicates: return .red
        case .expiredScreenshots: return .orange
        case .lowQuality: return .yellow
        case .largeFiles: return .purple
        }
    }
}

struct SmartCleanCategory: Identifiable {
    let id = UUID()
    let type: SmartCleanCategoryType
    var assets: [PhotoAsset]
    var totalSize: Int64
    /// 用于大文件类别，存储每个资源的实际大小
    var assetSizes: [String: Int64] = [:]

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

        // 1. Large Files (优先显示，因为释放空间最多)
        let largeFilesResult = await scanLargeFiles()
        if !largeFilesResult.assets.isEmpty {
            categories.append(largeFilesResult)
        }

        // 2. Duplicates
        let duplicates = await scanDuplicates()
        if !duplicates.isEmpty {
            let size = calculateSize(for: duplicates)
            categories.append(SmartCleanCategory(type: .duplicates, assets: duplicates, totalSize: size))
        }

        // 3. Expired Screenshots
        let screenshots = await scanExpiredScreenshots()
        if !screenshots.isEmpty {
            let size = calculateSize(for: screenshots)
            categories.append(SmartCleanCategory(type: .expiredScreenshots, assets: screenshots, totalSize: size))
        }

        // 4. Low Quality
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

    // Logic: 扫描大文件（照片 > 5MB，视频 > 50MB）
    private func scanLargeFiles() async -> SmartCleanCategory {
        let largePhotoThreshold: Int64 = 5 * 1024 * 1024  // 5MB
        let largeVideoThreshold: Int64 = 50 * 1024 * 1024 // 50MB

        var assets: [PhotoAsset] = []
        var assetSizes: [String: Int64] = [:]
        var totalSize: Int64 = 0

        // 扫描大照片
        let photoOptions = PHFetchOptions()
        photoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let photos = PHAsset.fetchAssets(with: .image, options: photoOptions)

        photos.enumerateObjects { asset, _, _ in
            let size = self.getAssetFileSize(asset)
            if size > largePhotoThreshold {
                let photoAsset = PhotoAsset(phAsset: asset)
                assets.append(photoAsset)
                assetSizes[photoAsset.id] = size
                totalSize += size
            }
        }

        // 扫描大视频
        let videoOptions = PHFetchOptions()
        videoOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let videos = PHAsset.fetchAssets(with: .video, options: videoOptions)

        videos.enumerateObjects { asset, _, _ in
            let size = self.getAssetFileSize(asset)
            if size > largeVideoThreshold {
                let videoAsset = PhotoAsset(phAsset: asset)
                assets.append(videoAsset)
                assetSizes[videoAsset.id] = size
                totalSize += size
            }
        }

        // 按文件大小排序（最大的在前）
        assets.sort { asset1, asset2 in
            (assetSizes[asset1.id] ?? 0) > (assetSizes[asset2.id] ?? 0)
        }

        // 限制返回数量，避免列表过长
        let limitedAssets = Array(assets.prefix(50))
        let limitedTotalSize = limitedAssets.reduce(Int64(0)) { $0 + (assetSizes[$1.id] ?? 0) }

        return SmartCleanCategory(
            type: .largeFiles,
            assets: limitedAssets,
            totalSize: limitedTotalSize,
            assetSizes: assetSizes
        )
    }

    /// 获取资源的实际文件大小
    private func getAssetFileSize(_ asset: PHAsset) -> Int64 {
        let resources = PHAssetResource.assetResources(for: asset)

        // 优先获取原始资源的大小
        if let resource = resources.first(where: { $0.type == .photo || $0.type == .video }) {
            if let fileSize = resource.value(forKey: "fileSize") as? Int64 {
                return fileSize
            }
        }

        // 如果无法获取实际大小，使用估算值
        if asset.mediaType == .video {
            // 视频：基于时长估算（假设 10MB/分钟）
            return Int64(asset.duration * 10 * 1024 * 1024 / 60)
        } else {
            // 照片：基于像素数量估算
            let pixelCount = Int64(asset.pixelWidth * asset.pixelHeight)
            return pixelCount / 2 // 假设 JPEG 压缩后每像素约 0.5 字节
        }
    }
}
