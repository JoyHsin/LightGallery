//
//  DuplicatesViewModel.swift
//  LightGallery
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI
import Photos

@MainActor
class DuplicatesViewModel: ObservableObject {
    @Published var groups: [DuplicateGroup] = []
    @Published var isLoading = false
    @Published var showMergeConfirmation = false
    
    func scan() {
        isLoading = true
        Task {
            let foundGroups = await DuplicateDetectionService.shared.scanForDuplicates()
            self.groups = foundGroups
            self.isLoading = false
        }
    }
    
    func mergeGroup(_ group: DuplicateGroup) {
        // Simple Merge: Keep the first one, delete the rest
        // In a real app, we might check for "Favorite" status or highest resolution
        guard let keepAsset = group.assets.first else { return }
        let deleteAssets = group.assets.dropFirst().map { $0.phAsset }
        
        performDelete(assets: Array(deleteAssets)) { success in
            if success {
                self.groups.removeAll { $0.id == group.id }
            }
        }
    }
    
    func mergeAll() {
        var allAssetsToDelete: [PHAsset] = []
        
        for group in groups {
            let deleteAssets = group.assets.dropFirst().map { $0.phAsset }
            allAssetsToDelete.append(contentsOf: deleteAssets)
        }
        
        guard !allAssetsToDelete.isEmpty else { return }
        
        performDelete(assets: allAssetsToDelete) { success in
            if success {
                self.groups.removeAll()
            }
        }
    }
    
    private func performDelete(assets: [PHAsset], completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
}
