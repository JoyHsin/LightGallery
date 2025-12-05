//
//  PhotoViewModelTests.swift
//  LightGalleryTests
//
//  Created by Kiro on 2025/9/7.
//

import XCTest
import Photos
@testable import LightGallery

@MainActor
final class PhotoViewModelTests: XCTestCase {
    
    var viewModel: PhotoViewModel!
    var mockPhotoService: MockPhotoServiceForViewModel!
    
    override func setUp() {
        super.setUp()
        mockPhotoService = MockPhotoServiceForViewModel(mockStatus: .authorized)
        viewModel = PhotoViewModel(photoService: mockPhotoService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockPhotoService = nil
        super.tearDown()
    }
    
    // MARK: - 初始状态测试
    
    func testInitialState() {
        XCTAssertEqual(viewModel.photos.count, 0)
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.hasPermission)
        XCTAssertEqual(viewModel.deletedCount, 0)
        XCTAssertEqual(viewModel.keptCount, 0)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.currentPhoto)
        XCTAssertEqual(viewModel.totalCount, 0)
        XCTAssertEqual(viewModel.progressPercentage, 0)
        XCTAssertFalse(viewModel.isCompleted)
    }
    
    // MARK: - 照片加载测试
    
    func testLoadPhotosWithPermissionGranted() async {
        // 准备测试数据
        let testPhotos = createTestPhotos(count: 3)
        mockPhotoService.mockPhotos = testPhotos
        mockPhotoService.mockPermissionGranted = true
        
        // 执行测试
        await viewModel.loadPhotos()
        
        // 验证结果
        XCTAssertTrue(viewModel.hasPermission)
        XCTAssertEqual(viewModel.photos.count, 3)
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.deletedCount, 0)
        XCTAssertEqual(viewModel.keptCount, 0)
        XCTAssertNotNil(viewModel.currentPhoto)
    }
    
    func testLoadPhotosWithPermissionDenied() async {
        mockPhotoService = MockPhotoServiceForViewModel(mockStatus: .denied)
        viewModel = PhotoViewModel(photoService: mockPhotoService)
        
        await viewModel.loadPhotos()
        
        XCTAssertFalse(viewModel.hasPermission)
        XCTAssertEqual(viewModel.photos.count, 0)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - 滑动操作测试
    
    func testSwipeLeft() async {
        // 准备测试数据
        let testPhotos = createTestPhotos(count: 3)
        mockPhotoService.mockPhotos = testPhotos
        mockPhotoService.mockPermissionGranted = true
        await viewModel.loadPhotos()
        
        let initialIndex = viewModel.currentIndex
        
        // 执行左滑删除
        await viewModel.swipeLeft()
        
        // 验证结果
        XCTAssertEqual(viewModel.deletedCount, 1)
        XCTAssertEqual(viewModel.keptCount, 0)
        XCTAssertEqual(viewModel.currentIndex, initialIndex + 1)
        XCTAssertTrue(mockPhotoService.moveToTrashCalled)
    }
    
    func testSwipeLeftWithError() async {
        // 准备测试数据
        let testPhotos = createTestPhotos(count: 3)
        mockPhotoService.mockPhotos = testPhotos
        mockPhotoService.mockPermissionGranted = true
        mockPhotoService.shouldThrowError = true
        await viewModel.loadPhotos()
        
        // 执行左滑删除
        await viewModel.swipeLeft()
        
        // 验证错误处理
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.deletedCount, 0)
    }
    
    func testSwipeRight() async {
        // 准备测试数据
        let testPhotos = createTestPhotos(count: 3)
        mockPhotoService.mockPhotos = testPhotos
        mockPhotoService.mockPermissionGranted = true
        await viewModel.loadPhotos()
        
        let initialIndex = viewModel.currentIndex
        
        // 执行右滑保留
        viewModel.swipeRight()
        
        // 验证结果
        XCTAssertEqual(viewModel.deletedCount, 0)
        XCTAssertEqual(viewModel.keptCount, 1)
        XCTAssertEqual(viewModel.currentIndex, initialIndex + 1)
    }
    
    // MARK: - 进度计算测试
    
    func testProgressPercentage() async {
        let testPhotos = createTestPhotos(count: 4)
        mockPhotoService.mockPhotos = testPhotos
        mockPhotoService.mockPermissionGranted = true
        await viewModel.loadPhotos()
        
        // 初始进度应为0
        XCTAssertEqual(viewModel.progressPercentage, 0)
        
        // 处理一张照片
        viewModel.swipeRight()
        XCTAssertEqual(viewModel.progressPercentage, 25)
        
        // 处理第二张照片
        await viewModel.swipeLeft()
        XCTAssertEqual(viewModel.progressPercentage, 50)
    }
    
    func testIsCompleted() async {
        let testPhotos = createTestPhotos(count: 2)
        mockPhotoService.mockPhotos = testPhotos
        mockPhotoService.mockPermissionGranted = true
        await viewModel.loadPhotos()
        
        XCTAssertFalse(viewModel.isCompleted)
        
        // 处理所有照片
        viewModel.swipeRight()
        await viewModel.swipeLeft()
        
        XCTAssertTrue(viewModel.isCompleted)
    }
    
    // MARK: - 筛选功能测试
    
    func testApplyDateFilter() async {
        let startDate = Date().addingTimeInterval(-86400 * 30) // 30天前
        let endDate = Date()
        let filteredPhotos = createTestPhotos(count: 2)
        
        mockPhotoService.mockFilteredPhotos = filteredPhotos
        
        await viewModel.applyDateFilter(startDate, endDate)
        
        XCTAssertEqual(viewModel.photos.count, 2)
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertEqual(viewModel.deletedCount, 0)
        XCTAssertEqual(viewModel.keptCount, 0)
        XCTAssertFalse(viewModel.isLoading)
        
        // 验证筛选状态
        XCTAssertTrue(viewModel.currentFilter.isActive)
        XCTAssertEqual(viewModel.currentFilter.startDate, startDate)
        XCTAssertEqual(viewModel.currentFilter.endDate, endDate)
    }
    
    func testClearFilter() async {
        // 先应用筛选
        let startDate = Date().addingTimeInterval(-86400 * 30)
        let endDate = Date()
        await viewModel.applyDateFilter(startDate, endDate)
        XCTAssertTrue(viewModel.currentFilter.isActive)
        
        // 清除筛选
        let allPhotos = createTestPhotos(count: 5)
        mockPhotoService.mockPhotos = allPhotos
        mockPhotoService.mockPermissionGranted = true
        
        await viewModel.clearFilter()
        
        XCTAssertEqual(viewModel.photos.count, 5)
        XCTAssertTrue(viewModel.hasPermission)
        
        // 验证筛选状态被重置
        XCTAssertFalse(viewModel.currentFilter.isActive)
        XCTAssertEqual(viewModel.currentFilter.startDate, FilterCriteria.none.startDate)
        XCTAssertEqual(viewModel.currentFilter.endDate, FilterCriteria.none.endDate)
    }
    
    func testInitialFilterState() {
        // 验证初始筛选状态
        XCTAssertFalse(viewModel.currentFilter.isActive)
        XCTAssertEqual(viewModel.currentFilter.startDate, FilterCriteria.none.startDate)
        XCTAssertEqual(viewModel.currentFilter.endDate, FilterCriteria.none.endDate)
    }
    
    // MARK: - 错误处理测试
    
    func testLoadPhotosWithError() async {
        mockPhotoService = MockPhotoServiceForViewModel(mockStatus: .denied)
        viewModel = PhotoViewModel(photoService: mockPhotoService)
        
        await viewModel.loadPhotos()
        
        XCTAssertFalse(viewModel.hasPermission)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showRetryOption) // 权限错误不显示重试
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testApplyDateFilterWithError() async {
        mockPhotoService = MockPhotoServiceForViewModel(mockStatus: .denied)
        viewModel = PhotoViewModel(photoService: mockPhotoService)
        
        let startDate = Date().addingTimeInterval(-86400 * 30)
        let endDate = Date()
        
        await viewModel.applyDateFilter(startDate, endDate)
        
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showRetryOption) // 权限错误不显示重试
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testRetryLastOperation() async {
        // 准备测试数据
        let testPhotos = createTestPhotos(count: 3)
        mockPhotoService.mockPhotos = testPhotos
        mockPhotoService.mockPermissionGranted = true
        mockPhotoService.shouldThrowError = true
        await viewModel.loadPhotos()
        
        // 执行会失败的操作
        await viewModel.swipeLeft()
        
        // 验证错误状态
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.showRetryOption)
        XCTAssertNotNil(viewModel.lastFailedOperation)
        
        // 修复错误条件并重试
        mockPhotoService.shouldThrowError = false
        viewModel.retryLastOperation()
        
        // 验证错误状态被清除
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showRetryOption)
        XCTAssertNil(viewModel.lastFailedOperation)
    }
    
    func testClearError() async {
        // 设置错误状态
        mockPhotoService = MockPhotoServiceForViewModel(mockStatus: .denied)
        viewModel = PhotoViewModel(photoService: mockPhotoService)
        await viewModel.loadPhotos()
        
        XCTAssertNotNil(viewModel.errorMessage)
        
        // 清除错误
        viewModel.clearError()
        
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showRetryOption)
        XCTAssertNil(viewModel.lastFailedOperation)
    }
    
    // MARK: - 边界情况测试
    
    func testSwipeWithNoPhotos() async {
        // 没有照片时的滑动操作
        await viewModel.swipeLeft()
        viewModel.swipeRight()
        
        XCTAssertEqual(viewModel.deletedCount, 0)
        XCTAssertEqual(viewModel.keptCount, 0)
    }
    
    func testSwipeAtLastPhoto() async {
        let testPhotos = createTestPhotos(count: 1)
        mockPhotoService.mockPhotos = testPhotos
        mockPhotoService.mockPermissionGranted = true
        await viewModel.loadPhotos()
        
        let initialIndex = viewModel.currentIndex
        
        // 在最后一张照片上滑动
        viewModel.swipeRight()
        
        // 索引不应该超出范围
        XCTAssertEqual(viewModel.currentIndex, initialIndex)
        XCTAssertEqual(viewModel.keptCount, 1)
    }
    
    // MARK: - 辅助方法
    
    private func createTestPhotos(count: Int) -> [PhotoAsset] {
        var photos: [PhotoAsset] = []
        for i in 0..<count {
            let mockPHAsset = MockPHAssetForViewModel(creationDate: Date().addingTimeInterval(TimeInterval(i * 3600)), localIdentifier: "test-\(i)")
            let photoAsset = PhotoAsset(phAsset: mockPHAsset)
            photos.append(photoAsset)
        }
        return photos
    }
}

// MARK: - Mock Classes for ViewModel Tests

class MockPhotoServiceForViewModel: PhotoServiceProtocol {
    private let mockAuthorizationStatus: PHAuthorizationStatus
    var mockPermissionGranted = false
    var mockPhotos: [PhotoAsset] = []
    var mockFilteredPhotos: [PhotoAsset] = []
    var shouldThrowError = false
    var moveToTrashCalled = false
    
    init(mockStatus: PHAuthorizationStatus) {
        self.mockAuthorizationStatus = mockStatus
        self.mockPermissionGranted = (mockStatus == .authorized || mockStatus == .limited)
    }
    
    var currentAuthorizationStatus: PHAuthorizationStatus {
        return mockAuthorizationStatus
    }
    
    var hasPhotoLibraryAccess: Bool {
        return mockAuthorizationStatus == .authorized || mockAuthorizationStatus == .limited
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
        moveToTrashCalled = true
        if shouldThrowError {
            throw PhotoError.deletionFailed("Test error")
        }
    }
    
    func getPhotoCreationDate(_ asset: PhotoAsset) -> Date? {
        return asset.creationDate
    }
}

class MockPHAssetForViewModel: PHAsset, @unchecked Sendable {
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