//
//  BlurryPhotosViewModel.swift
//  LightGallery
//
//  Created by Claude on 2025/12/27.
//

import SwiftUI
import Photos

@MainActor
class BlurryPhotosViewModel: ObservableObject {
    @Published var photos: [BlurryPhoto] = []
    @Published var selectedPhotos: Set<String> = []
    @Published var isLoading = false
    @Published var showDeleteConfirmation = false
    @Published var scanProgress: Double = 0

    var selectedCount: Int {
        selectedPhotos.count
    }

    var totalSize: Int64 {
        photos.reduce(0) { $0 + $1.fileSize }
    }

    var selectedSize: Int64 {
        photos.filter { selectedPhotos.contains($0.id) }
            .reduce(0) { $0 + $1.fileSize }
    }

    var formattedTotalSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }

    var formattedSelectedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: selectedSize)
    }

    func scan() {
        isLoading = true
        scanProgress = 0

        Task {
            let foundPhotos = await BlurDetectionService.shared.scanForBlurryPhotos()
            self.photos = foundPhotos
            // 默认全选
            self.selectedPhotos = Set(foundPhotos.map { $0.id })
            self.isLoading = false
        }
    }

    func toggleSelection(_ photo: BlurryPhoto) {
        if selectedPhotos.contains(photo.id) {
            selectedPhotos.remove(photo.id)
        } else {
            selectedPhotos.insert(photo.id)
        }
    }

    func selectAll() {
        selectedPhotos = Set(photos.map { $0.id })
    }

    func deselectAll() {
        selectedPhotos.removeAll()
    }

    func deleteSelected() {
        let photosToDelete = photos.filter { selectedPhotos.contains($0.id) }
        guard !photosToDelete.isEmpty else { return }

        Task {
            let success = await BlurDetectionService.shared.deletePhotos(photosToDelete)
            if success {
                // 从列表中移除已删除的照片
                photos.removeAll { selectedPhotos.contains($0.id) }
                selectedPhotos.removeAll()
            }
        }
    }

    func deletePhoto(_ photo: BlurryPhoto) {
        Task {
            let success = await BlurDetectionService.shared.deletePhotos([photo])
            if success {
                photos.removeAll { $0.id == photo.id }
                selectedPhotos.remove(photo.id)
            }
        }
    }
}
