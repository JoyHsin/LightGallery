//
//  SmartCleanViewModel.swift
//  Declutter
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI
import Photos

@MainActor
class SmartCleanViewModel: ObservableObject {
    @Published var categories: [SmartCleanCategory] = []
    @Published var isLoading = false
    @Published var totalSizeToClean: String = "0 MB"

    /// 是否已经扫描过（用于缓存）
    private var hasScanned = false

    func scan(forceRescan: Bool = false) {
        // 如果已经扫描过且不强制重新扫描，直接返回
        if hasScanned && !forceRescan && !categories.isEmpty {
            return
        }

        isLoading = true
        Task {
            let results = await SmartCleanManager.shared.scan()
            self.categories = results
            self.calculateTotalSize()
            self.isLoading = false
            self.hasScanned = true
        }
    }

    /// 强制重新扫描
    func rescan() {
        scan(forceRescan: true)
    }

    private func calculateTotalSize() {
        let totalBytes = categories.reduce(0) { $0 + $1.totalSize }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        self.totalSizeToClean = formatter.string(fromByteCount: totalBytes)
    }

    func deleteCategory(_ category: SmartCleanCategory) {
        let assetsToDelete = category.assets.map { $0.phAsset }

        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSArray)
        } completionHandler: { success, error in
            if success {
                DispatchQueue.main.async {
                    self.categories.removeAll { $0.id == category.id }
                    self.calculateTotalSize()
                }
            }
        }
    }

    func deleteAssets(_ assets: [PhotoAsset], from categoryType: SmartCleanCategoryType) {
        let phAssets = assets.map { $0.phAsset }

        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(phAssets as NSArray)
        } completionHandler: { success, error in
            if success {
                DispatchQueue.main.async {
                    // Update local state
                    if let index = self.categories.firstIndex(where: { $0.type == categoryType }) {
                        var updatedCategory = self.categories[index]
                        let deletedIds = Set(assets.map { $0.id })
                        updatedCategory.assets.removeAll { deletedIds.contains($0.id) }

                        // Recalculate size
                        updatedCategory.totalSize = Int64(updatedCategory.assets.count * 2 * 1024 * 1024)

                        if updatedCategory.assets.isEmpty {
                            self.categories.remove(at: index)
                        } else {
                            self.categories[index] = updatedCategory
                        }
                        self.calculateTotalSize()
                    }
                }
            }
        }
    }
}
