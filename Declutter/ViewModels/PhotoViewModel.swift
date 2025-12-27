//
//  PhotoViewModel.swift
//  Declutter
//
//  Created by Kiro on 2025/9/7.
//

import Foundation
import SwiftUI

/// 照片浏览的主要业务逻辑控制器
@MainActor
class PhotoViewModel: ObservableObject {
    @Published var photos: [PhotoAsset] = []
    @Published var currentIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var hasPermission: Bool = false
    @Published var deletedCount: Int = 0
    @Published var keptCount: Int = 0
    @Published var errorMessage: String?
    @Published var showRetryOption: Bool = false
    @Published var lastFailedOperation: (() -> Void)?
    @Published var currentFilter: FilterCriteria = .none
    @Published var pendingDeletion: [PhotoAsset] = []
    
    private let photoService: PhotoServiceProtocol
    
    init(photoService: PhotoServiceProtocol) {
        self.photoService = photoService
    }
    
    /// 当前显示的照片
    var currentPhoto: PhotoAsset? {
        guard currentIndex >= 0 && currentIndex < photos.count else { return nil }
        return photos[currentIndex]
    }
    
    /// 总照片数量
    var totalCount: Int {
        photos.count
    }
    
    /// 清理进度百分比
    var progressPercentage: Double {
        guard totalCount > 0 else { return 0 }
        let processedCount = deletedCount + keptCount
        return Double(processedCount) / Double(totalCount) * 100
    }
    
    /// 是否已完成所有照片的处理
    var isCompleted: Bool {
        (deletedCount + keptCount) >= totalCount && totalCount > 0
    }
    
    // MARK: - Public Methods
    
    /// 加载照片
    func loadPhotos() async {
        isLoading = true
        errorMessage = nil
        showRetryOption = false
        
        do {
            // 请求权限
            hasPermission = await photoService.requestPhotoLibraryAccess()
            
            if hasPermission {
                // 获取照片
                photos = try await photoService.fetchAllPhotos()
                currentIndex = 0
                resetCounts()
            }
        } catch let error as PhotoError {
            handlePhotoError(error)
            lastFailedOperation = { [weak self] in
                Task { await self?.loadPhotos() }
            }
        } catch {
            errorMessage = "加载照片时发生未知错误：\(error.localizedDescription)"
            showRetryOption = true
            lastFailedOperation = { [weak self] in
                Task { await self?.loadPhotos() }
            }
        }
        
        isLoading = false
    }
    
    /// 左滑删除当前照片
    func swipeLeft() async {
        guard let photo = currentPhoto else { return }
        // 改为加入待删除队列，不立即删除
        pendingDeletion.append(photo)
        deletedCount += 1
        moveToNextPhoto()
    }
    
    /// 右滑保留当前照片
    func swipeRight() {
        guard currentPhoto != nil else { return }
        keptCount += 1
        moveToNextPhoto()
    }
    
    /// 应用日期筛选
    func applyDateFilter(_ startDate: Date, _ endDate: Date) async {
        isLoading = true
        errorMessage = nil
        showRetryOption = false
        
        do {
            // 更新筛选条件状态
            currentFilter = FilterCriteria(
                startDate: startDate,
                endDate: endDate,
                isActive: true
            )
            
            photos = try await photoService.fetchPhotosInDateRange(startDate, endDate)
            currentIndex = 0
            resetCounts()
        } catch let error as PhotoError {
            handlePhotoError(error)
            lastFailedOperation = { [weak self] in
                Task { await self?.applyDateFilter(startDate, endDate) }
            }
        } catch {
            errorMessage = "筛选照片时发生未知错误：\(error.localizedDescription)"
            showRetryOption = true
            lastFailedOperation = { [weak self] in
                Task { await self?.applyDateFilter(startDate, endDate) }
            }
        }
        
        isLoading = false
    }
    
    /// 清除筛选条件
    func clearFilter() async {
        // 重置筛选条件状态
        currentFilter = .none
        await loadPhotos()
    }

    /// 提交批量删除（一次系统确认）
    func commitPendingDeletion() async {
        guard !pendingDeletion.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let assets = pendingDeletion
            pendingDeletion.removeAll()
            try await photoService.deletePhotos(assets)
            // 删除后需要从当前照片列表移除这些项
            let toRemoveIds = Set(assets.map { $0.localIdentifier })
            photos.removeAll { toRemoveIds.contains($0.localIdentifier) }
            // 校正当前索引
            if currentIndex >= photos.count {
                currentIndex = max(0, photos.count - 1)
            }
        } catch let error as PhotoError {
            handlePhotoError(error)
        } catch {
            errorMessage = "批量删除失败：\(error.localizedDescription)"
            showRetryOption = true
        }
    }

    /// 放弃待删除并将其计入保留统计
    func cancelPendingDeletionAndMarkKept() {
        let count = pendingDeletion.count
        guard count > 0 else { return }
        keptCount += count
        deletedCount = max(0, deletedCount - count)
        pendingDeletion.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func moveToNextPhoto() {
        if currentIndex < photos.count - 1 {
            currentIndex += 1
        }
    }
    
    private func resetCounts() {
        deletedCount = 0
        keptCount = 0
    }
    
    /// 处理PhotoError类型的错误
    private func handlePhotoError(_ error: PhotoError) {
        switch error {
        case .permissionDenied:
            errorMessage = error.errorDescription
            showRetryOption = false // 权限错误不显示重试，需要用户手动授权
        case .photoLibraryUnavailable:
            errorMessage = error.errorDescription
            showRetryOption = true
        case .deletionFailed(let reason):
            errorMessage = "删除照片失败：\(reason)"
            showRetryOption = true
        case .loadingFailed(let reason):
            errorMessage = "加载照片失败：\(reason)"
            showRetryOption = true
        case .filteringFailed(let reason):
            errorMessage = "筛选照片失败：\(reason)"
            showRetryOption = true
        }
    }
    
    /// 重试上次失败的操作
    func retryLastOperation() {
        errorMessage = nil
        showRetryOption = false
        lastFailedOperation?()
        lastFailedOperation = nil
    }
    
    /// 清除错误状态
    func clearError() {
        errorMessage = nil
        showRetryOption = false
        lastFailedOperation = nil
    }
}