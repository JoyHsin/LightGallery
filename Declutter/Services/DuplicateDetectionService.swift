//
//  DuplicateDetectionService.swift
//  Declutter
//
//  Created by Antigravity on 2025/12/05.
//

import Photos
import SwiftUI

struct DuplicateGroup: Identifiable {
    let id = UUID()
    let assets: [PhotoAsset]
    var totalSize: Int64 // Estimated size in bytes
    
    var dateString: String {
        guard let first = assets.first else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: first.creationDate)
    }
}

class DuplicateDetectionService {
    static let shared = DuplicateDetectionService()
    
    private init() {}
    
    /// Scans the library for duplicate photos based on creation date and dimensions
    func scanForDuplicates() async -> [DuplicateGroup] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        // Fetching all images might be slow, for demo we might limit or optimize
        // For a real app, we'd fetch properties only.
        let allAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var groups: [DuplicateGroup] = []
        var tempGrouping: [String: [PhotoAsset]] = [:]
        
        // Grouping Key: CreationDate (to second) + PixelWidth + PixelHeight
        // This is a strong heuristic for exact duplicates
        
        allAssets.enumerateObjects { asset, _, _ in
            if let date = asset.creationDate {
                // Use integer timestamp to group by second.
                // Also include pixel dimensions.
                // This is stricter than just "looks similar".
                let timestamp = Int(date.timeIntervalSince1970)
                let key = "\(timestamp)-\(asset.pixelWidth)x\(asset.pixelHeight)"
                let photoAsset = PhotoAsset(phAsset: asset)
                tempGrouping[key, default: []].append(photoAsset)
            }
        }
        
        // Filter for groups with > 1 asset
        for (_, assets) in tempGrouping {
            if assets.count > 1 {
                // Calculate estimated size (rough estimate if file size not available)
                // In a real app we would fetch PHAssetResource to get exact size
                let estimatedSize = Int64(assets.count * 2 * 1024 * 1024) // Assume 2MB per photo roughly
                
                let group = DuplicateGroup(assets: assets, totalSize: estimatedSize)
                groups.append(group)
            }
        }
        
        // Sort groups by date (newest first)
        return groups.sorted {
            ($0.assets.first?.creationDate ?? Date()) > ($1.assets.first?.creationDate ?? Date())
        }
    }
}
