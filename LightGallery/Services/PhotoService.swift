//
//  PhotoService.swift
//  LightGallery
//
//  Created by Kiro on 2025/9/7.
//

import Foundation
import Photos

/// 照片服务的基础实现
class PhotoService: PhotoServiceProtocol {
    
    // MARK: - Permission Management
    
    /// 当前照片库权限状态
    var currentAuthorizationStatus: PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    /// 检查是否有照片库访问权限
    var hasPhotoLibraryAccess: Bool {
        let status = currentAuthorizationStatus
        return status == .authorized || status == .limited
    }
    
    func requestPhotoLibraryAccess() async -> Bool {
        let status = currentAuthorizationStatus
        
        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return newStatus == .authorized || newStatus == .limited
        case .denied, .restricted:
            // 权限被拒绝，抛出相应错误
            return false
        @unknown default:
            return false
        }
    }
    
    /// 检查权限状态并在必要时请求权限
    func ensurePhotoLibraryAccess() async throws {
        let hasAccess = await requestPhotoLibraryAccess()
        if !hasAccess {
            throw PhotoError.permissionDenied
        }
    }
    
    func fetchAllPhotos() async throws -> [PhotoAsset] {
        try await ensurePhotoLibraryAccess()
        
        return await withCheckedContinuation { continuation in
            let fetchOptions = PHFetchOptions()
            // 按拍摄时间从最早到最新排序，符合需求1.1
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            // 只获取图片类型的资源
            fetchOptions.includeHiddenAssets = false
            
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            var photoAssets: [PhotoAsset] = []
            
            fetchResult.enumerateObjects { (asset, _, _) in
                // 确保照片有创建时间，过滤掉异常数据
                if asset.creationDate != nil {
                    let photoAsset = PhotoAsset(phAsset: asset)
                    photoAssets.append(photoAsset)
                }
            }
            
            continuation.resume(returning: photoAssets)
        }
    }
    
    func fetchPhotosInDateRange(_ startDate: Date, _ endDate: Date) async throws -> [PhotoAsset] {
        try await ensurePhotoLibraryAccess()
        
        return await withCheckedContinuation { continuation in
            let fetchOptions = PHFetchOptions()
            // 按时间范围筛选照片
            fetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate <= %@", startDate as NSDate, endDate as NSDate)
            // 按拍摄时间从最早到最新排序
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            fetchOptions.includeHiddenAssets = false
            
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            var photoAssets: [PhotoAsset] = []
            
            fetchResult.enumerateObjects { (asset, _, _) in
                // 确保照片有创建时间，过滤掉异常数据
                if asset.creationDate != nil {
                    let photoAsset = PhotoAsset(phAsset: asset)
                    photoAssets.append(photoAsset)
                }
            }
            
            continuation.resume(returning: photoAssets)
        }
    }
    
    func movePhotoToTrash(_ asset: PhotoAsset) async throws {
        try await ensurePhotoLibraryAccess()
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets([asset.phAsset] as NSArray)
            }
        } catch {
            throw PhotoError.deletionFailed(error.localizedDescription)
        }
    }
    
    func deletePhotos(_ assets: [PhotoAsset]) async throws {
        try await ensurePhotoLibraryAccess()
        guard !assets.isEmpty else { return }
        do {
            let nsArray = assets.map { $0.phAsset } as NSArray
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(nsArray)
            }
        } catch {
            throw PhotoError.deletionFailed(error.localizedDescription)
        }
    }
    
    func getPhotoCreationDate(_ asset: PhotoAsset) -> Date? {
        return asset.phAsset.creationDate
    }
    
    /// 获取所有截图
    func fetchScreenshots() async throws -> [PhotoAsset] {
        try await ensurePhotoLibraryAccess()
        
        return await withCheckedContinuation { continuation in
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)] // 最新截图在前
            fetchOptions.includeHiddenAssets = false
            // 筛选截图类型
            fetchOptions.predicate = NSPredicate(format: "mediaSubtype == %d", PHAssetMediaSubtype.photoScreenshot.rawValue)
            
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            var photoAssets: [PhotoAsset] = []
            
            fetchResult.enumerateObjects { (asset, _, _) in
                if asset.creationDate != nil {
                    photoAssets.append(PhotoAsset(phAsset: asset))
                }
            }
            
            continuation.resume(returning: photoAssets)
        }
    }
    
    // MARK: - Album Management
    
    /// 获取用户创建的相簿
    func fetchUserAlbums() -> [PHAssetCollection] {
        var albums: [PHAssetCollection] = []
        let fetchOptions = PHFetchOptions()
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions)
        
        userAlbums.enumerateObjects { collection, _, _ in
            albums.append(collection)
        }
        return albums
    }
    
    /// 将照片添加到指定相簿
    func addAssetToAlbum(asset: PHAsset, album: PHAssetCollection) async throws {
        try await ensurePhotoLibraryAccess()
        
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest(for: album)
            request?.addAssets([asset] as NSArray)
        }
    }
}