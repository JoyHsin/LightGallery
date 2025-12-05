//
//  CompletionFunctionalityTests.swift
//  LightGalleryTests
//
//  Created by Kiro on 2025/9/7.
//

import XCTest
import SwiftUI
import Photos
@testable import LightGallery

@MainActor
final class CompletionFunctionalityTests: XCTestCase {
    
    var viewModel: PhotoViewModel!
    var mockPhotoService: MockPhotoServiceForCompletion!
    
    override func setUp() {
        super.setUp()
        mockPhotoService = MockPhotoServiceForCompletion()
        viewModel = PhotoViewModel(photoService: mockPhotoService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockPhotoService = nil
        super.tearDown()
    }
    
    // MARK: - 完成状态检测测试
    
    func testCompletionDetectionWithAllPhotosProcessed() async {
        // 准备测试数据
        let testPhotos = createTestPhotos(count: 3)
        mockPhotoService.mockPhotos = testPhotos
        mockPhotoService.mockPermissionGranted = true
        await viewModel.loadPhotos()
        
        // 初始状态应该未完成
        XCTAssertFalse(viewModel.isCompleted)
        XCTAssertEqual(viewModel.progressPercentage, 0)
        
        // 处理第一张照片（删除）
        await viewModel.swipeLeft()
        XCTAssertFalse(viewModel.isCompleted)
        XCTAssertEqual(viewModel.progressPercentage, 33.33, accuracy: 0.01)
        
        // 处理第二张照片（保留）
        viewModel.swipeRight()
        XCTAssertFalse(viewModel.isCompleted)
        XCTAssertEqual(viewModel.progressPercentage, 66.67, accuracy: 0.01)
        
        // 处理最后一张照片（删除）
        await viewModel.swipeLeft()
        XCTAssertTrue(viewModel.isCompleted)
        XCTAssertEqual(viewModel.progressPercentage, 100)
        
        // 验证统计信息
        XCTAssertEqual(viewModel.deletedCount, 2)
        XCTAssertEqual(viewModel.keptCount, 1)
        XCTAssertEqual(viewModel.totalCount, 3)
    }
    
    func testCompletionDetectionWithEmptyPhotoList() {
        // 空照片列表应该不被认为是完成状态
        XCTAssertFalse(viewModel.isCompleted)
        XCTAssertEqual(viewModel.progressPercentage, 0)
        XCTAssertEqual(viewModel.totalCount, 0)
    }
    
    func testCompletionDetectionWithSinglePhoto() async {
        // 准备单张照片
        let testPhotos = createTestPhotos(count: 1)
        mockPhotoService.mockPhotos = testPhotos
        mockPhotoService.mockPermissionGranted = true
        await viewModel.loadPhotos()
        
        XCTAssertFalse(viewModel.isCompleted)
        
        // 处理唯一的照片
        viewModel.swipeRight()
        
        XCTAssertTrue(viewModel.isCompleted)
        XCTAssertEqual(viewModel.progressPercentage, 100)
        XCTAssertEqual(viewModel.deletedCount, 0)
        XCTAssertEqual(viewModel.keptCount, 1)
    }
    
    // MARK: - 完成后重新开始测试
    
    func testRestartAfterCompletion() async {
        // 完成所有照片处理
        let testPhotos = createTestPhotos(count: 2)
        mockPhotoService.mockPhotos = testPhotos
        mockPhotoService.mockPermissionGranted = true
        await viewModel.loadPhotos()
        
        await viewModel.swipeLeft()
        viewModel.swipeRight()
        XCTAssertTrue(viewModel.isCompleted)
        
        // 重新开始（清除筛选会重新加载照片）
        let newTestPhotos = createTestPhotos(count: 3)
        mockPhotoService.mockPhotos = newTestPhotos
        await viewModel.clearFilter()
        
        // 验证状态重置
        XCTAssertFalse(viewModel.isCompleted)
        XCTAssertEqual(viewModel.deletedCount, 0)
        XCTAssertEqual(viewModel.keptCount, 0)
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertEqual(viewModel.totalCount, 3)
    }
    
    // MARK: - 筛选状态下的完成检测测试
    
    func testCompletionDetectionWithFilter() async {
        // 应用筛选后的完成检测
        let filteredPhotos = createTestPhotos(count: 2)
        mockPhotoService.mockFilteredPhotos = filteredPhotos
        
        let startDate = Date().addingTimeInterval(-86400 * 30)
        let endDate = Date()
        await viewModel.applyDateFilter(startDate, endDate)
        
        XCTAssertFalse(viewModel.isCompleted)
        XCTAssertEqual(viewModel.totalCount, 2)
        
        // 处理筛选后的所有照片
        await viewModel.swipeLeft()
        viewModel.swipeRight()
        
        XCTAssertTrue(viewModel.isCompleted)
        XCTAssertEqual(viewModel.progressPercentage, 100)
    }
    
    // MARK: - 完成状态的边界情况测试
    
    func testCompletionWithMixedOperations() async {
        // 测试混合操作（删除和保留）的完成检测
        let testPhotos = createTestPhotos(count: 4)
        mockPhotoService.mockPhotos = testPhotos
        mockPhotoService.mockPermissionGranted = true
        await viewModel.loadPhotos()
        
        // 执行混合操作
        await viewModel.swipeLeft()    // 删除
        viewModel.swipeRight()         // 保留
        await viewModel.swipeLeft()    // 删除
        viewModel.swipeRight()         // 保留
        
        XCTAssertTrue(viewModel.isCompleted)
        XCTAssertEqual(viewModel.deletedCount, 2)
        XCTAssertEqual(viewModel.keptCount, 2)
        XCTAssertEqual(viewModel.progressPercentage, 100)
    }
    
    // MARK: - 辅助方法
    
    private func createTestPhotos(count: Int) -> [PhotoAsset] {
        var photos: [PhotoAsset] = []
        for i in 0..<count {
            let mockPHAsset = MockPHAssetForCompletion(
                creationDate: Date().addingTimeInterval(TimeInterval(i * 3600)),
                localIdentifier: "completion-test-\(i)"
            )
            let photoAsset = PhotoAsset(phAsset: mockPHAsset)
            photos.append(photoAsset)
        }
        return photos
    }
}

// MARK: - Mock Classes for Completion Tests

class MockPhotoServiceForCompletion: PhotoServiceProtocol {
    var mockPermissionGranted = false
    var mockPhotos: [PhotoAsset] = []
    var mockFilteredPhotos: [PhotoAsset] = []
    var shouldThrowError = false
    
    var currentAuthorizationStatus: PHAuthorizationStatus {
        return mockPermissionGranted ? .authorized : .denied
    }
    
    var hasPhotoLibraryAccess: Bool {
        return mockPermissionGranted
    }
    
    func requestPhotoLibraryAccess() async -> Bool {
        return mockPermissionGranted
    }
    
    func ensurePhotoLibraryAccess() async throws {
        if !mockPermissionGranted {
            throw PhotoError.permissionDenied
        }
    }
    
    func fetchAllPhotos() async throws -> [PhotoAsset] {
        try await ensurePhotoLibraryAccess()
        return mockPhotos
    }
    
    func fetchPhotosInDateRange(_ startDate: Date, _ endDate: Date) async throws -> [PhotoAsset] {
        try await ensurePhotoLibraryAccess()
        return mockFilteredPhotos
    }
    
    func movePhotoToTrash(_ asset: PhotoAsset) async throws {
        if shouldThrowError {
            throw PhotoError.deletionFailed("Test error")
        }
    }
    
    func getPhotoCreationDate(_ asset: PhotoAsset) -> Date? {
        return asset.creationDate
    }
}

class MockPHAssetForCompletion: PHAsset, @unchecked Sendable {
    private let mockIdentifier: String
    private let mockCreationDate: Date
    
    init(creationDate: Date, localIdentifier: String) {
        self.mockIdentifier = localIdentifier
        self.mockCreationDate = creationDate
        super.init()
    }
    
    override var localIdentifier: String {
        return mockIdentifier
    }
    
    override var creationDate: Date? {
        return mockCreationDate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}