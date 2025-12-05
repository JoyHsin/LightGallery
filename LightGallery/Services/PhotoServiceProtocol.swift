//
//  PhotoServiceProtocol.swift
//  LightGallery
//
//  Created by Kiro on 2025/9/7.
//

import Foundation
import Photos

/// 照片服务协议，定义照片相关操作的接口
protocol PhotoServiceProtocol {
    /// 当前照片库权限状态
    var currentAuthorizationStatus: PHAuthorizationStatus { get }
    
    /// 检查是否有照片库访问权限
    var hasPhotoLibraryAccess: Bool { get }
    
    /// 请求照片库访问权限
    func requestPhotoLibraryAccess() async -> Bool
    
    /// 检查权限状态并在必要时请求权限，权限被拒绝时抛出错误
    func ensurePhotoLibraryAccess() async throws
    
    /// 获取所有照片，按拍摄时间排序
    func fetchAllPhotos() async throws -> [PhotoAsset]
    
    /// 获取指定时间范围内的照片
    func fetchPhotosInDateRange(_ startDate: Date, _ endDate: Date) async throws -> [PhotoAsset]
    
    /// 将照片移动到垃圾箱（最近删除）
    func movePhotoToTrash(_ asset: PhotoAsset) async throws
    
    /// 批量将照片移动到垃圾箱（最近删除）
    func deletePhotos(_ assets: [PhotoAsset]) async throws
    
    /// 获取照片的创建日期
    func getPhotoCreationDate(_ asset: PhotoAsset) -> Date?
    
    /// 获取所有截图
    func fetchScreenshots() async throws -> [PhotoAsset]
    
    /// 获取用户创建的相簿
    func fetchUserAlbums() -> [PHAssetCollection]
    
    /// 将照片添加到指定相簿
    func addAssetToAlbum(asset: PHAsset, album: PHAssetCollection) async throws
}