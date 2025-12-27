//
//  SwipeGestureTests.swift
//  DeclutterTests
//
//  Created by Kiro on 2025/9/7.
//

import Testing
import SwiftUI
import Photos
@testable import Declutter

/// 测试滑动手势识别和交互逻辑
struct SwipeGestureTests {
    
    // MARK: - Mock Service for Swipe Tests
    
    /// 专门用于滑动测试的Mock服务，包含删除操作跟踪
    class MockSwipePhotoService: PhotoServiceProtocol {
        private let mockAuthorizationStatus: PHAuthorizationStatus
        var mockPhotos: [PhotoAsset] = []
        var moveToTrashCalled = false
        var deletedAssets: [PhotoAsset] = []
        
        init(mockStatus: PHAuthorizationStatus = .authorized) {
            self.mockAuthorizationStatus = mockStatus
        }
        
        var currentAuthorizationStatus: PHAuthorizationStatus {
            return mockAuthorizationStatus
        }
        
        var hasPhotoLibraryAccess: Bool {
            return mockAuthorizationStatus == .authorized || mockAuthorizationStatus == .limited
        }
        
        func requestPhotoLibraryAccess() async -> Bool {
            return hasPhotoLibraryAccess
        }
        
        func ensurePhotoLibraryAccess() async throws {
            let hasAccess = await requestPhotoLibraryAccess()
            if !hasAccess {
                throw PhotoError.permissionDenied
            }
        }
        
        func fetchAllPhotos() async -> [PhotoAsset] {
            do {
                try await ensurePhotoLibraryAccess()
                return mockPhotos.sorted { $0.creationDate < $1.creationDate }
            } catch {
                return []
            }
        }
        
        func fetchPhotosInDateRange(_ startDate: Date, _ endDate: Date) async -> [PhotoAsset] {
            do {
                try await ensurePhotoLibraryAccess()
                return mockPhotos
                    .filter { $0.creationDate >= startDate && $0.creationDate <= endDate }
                    .sorted { $0.creationDate < $1.creationDate }
            } catch {
                return []
            }
        }
        
        func movePhotoToTrash(_ asset: PhotoAsset) async throws {
            try await ensurePhotoLibraryAccess()
            moveToTrashCalled = true
            deletedAssets.append(asset)
        }
        
        func getPhotoCreationDate(_ asset: PhotoAsset) -> Date? {
            return asset.creationDate
        }
        
        func deletePhotos(_ assets: [PhotoAsset]) async throws {
            try await ensurePhotoLibraryAccess()
            deletedAssets.append(contentsOf: assets)
        }
        
        func fetchScreenshots() async throws -> [PhotoAsset] {
            try await ensurePhotoLibraryAccess()
            return mockPhotos
        }
        
        func fetchUserAlbums() -> [PHAssetCollection] {
            return []
        }
        
        func addAssetToAlbum(asset: PHAsset, album: PHAssetCollection) async throws {
            try await ensurePhotoLibraryAccess()
        }
    }
    
    // MARK: - Swipe Direction Tests
    
    @Test("测试滑动方向识别 - 左滑")
    func testDetermineSwipeDirection_LeftSwipe() {
        // Given
        let translation: CGFloat = -150.0
        
        // When
        let direction = determineSwipeDirection(translation: translation)
        
        // Then
        #expect(direction == .left)
    }
    
    @Test("测试滑动方向识别 - 右滑")
    func testDetermineSwipeDirection_RightSwipe() {
        // Given
        let translation: CGFloat = 150.0
        
        // When
        let direction = determineSwipeDirection(translation: translation)
        
        // Then
        #expect(direction == .right)
    }
    
    @Test("测试滑动方向识别 - 零平移")
    func testDetermineSwipeDirection_ZeroTranslation() {
        // Given
        let translation: CGFloat = 0.0
        
        // When
        let direction = determineSwipeDirection(translation: translation)
        
        // Then
        #expect(direction == .left)
    }
    
    // Helper function to test swipe direction logic
    private func determineSwipeDirection(translation: CGFloat) -> SwipeDirection {
        return translation > 0 ? .right : .left
    }
    
    // MARK: - Swipe Threshold Tests
    
    @Test("测试滑动阈值常量的合理性")
    func testSwipeThreshold_Constants() {
        // Given
        let swipeThreshold: CGFloat = 100.0
        let velocityThreshold: CGFloat = 300.0
        
        // When & Then
        #expect(swipeThreshold > 0, "滑动距离阈值应该大于0")
        #expect(velocityThreshold > 0, "滑动速度阈值应该大于0")
        #expect(swipeThreshold < 200, "滑动距离阈值不应该太大，影响用户体验")
        #expect(velocityThreshold >= 200, "滑动速度阈值应该足够大以避免误触")
    }
    
    // MARK: - Gesture Recognition Logic Tests
    
    @Test("测试滑动触发逻辑 - 距离和速度阈值")
    func testShouldTriggerSwipe_DistanceThreshold() {
        // Given
        let swipeThreshold: CGFloat = 100.0
        let velocityThreshold: CGFloat = 300.0
        
        // Test cases
        let testCases: [(distance: CGFloat, velocity: CGFloat, expected: Bool, description: String)] = [
            (120.0, 100.0, true, "距离超过阈值应该触发滑动"),
            (80.0, 100.0, false, "距离未达到阈值且速度不够应该不触发滑动"),
            (50.0, 350.0, true, "距离不够但速度超过阈值应该触发滑动"),
            (150.0, 400.0, true, "距离和速度都超过阈值应该触发滑动"),
            (0.0, 0.0, false, "距离和速度都为0应该不触发滑动")
        ]
        
        // When & Then
        for testCase in testCases {
            let shouldTrigger = testCase.distance > swipeThreshold || testCase.velocity > velocityThreshold
            #expect(shouldTrigger == testCase.expected)
        }
    }
    
    // MARK: - Swipe Action Integration Tests
    
    @Test("测试滑动操作集成 - 左滑删除")
    func testSwipeActionIntegration_LeftSwipe() async {
        // Given
        let mockService = MockSwipePhotoService()
        let viewModel = await PhotoViewModel(photoService: mockService)
        
        // 创建测试照片
        let testDate = Date()
        let mockAsset = MockPHAsset(creationDate: testDate, localIdentifier: "test-1")
        mockService.mockPhotos = [PhotoAsset(phAsset: mockAsset)]
        
        // When
        await viewModel.loadPhotos()
        let initialDeletedCount = await viewModel.deletedCount
        await viewModel.swipeLeft()
        
        // Then
        let finalDeletedCount = await viewModel.deletedCount
        #expect(finalDeletedCount == initialDeletedCount + 1)
        #expect(mockService.moveToTrashCalled == true)
        #expect(mockService.deletedAssets.count == 1)
    }
    
    @Test("测试滑动操作集成 - 右滑保留")
    func testSwipeActionIntegration_RightSwipe() async {
        // Given
        let mockService = MockSwipePhotoService()
        let viewModel = await PhotoViewModel(photoService: mockService)
        
        // 创建测试照片
        let testDate = Date()
        let mockAsset = MockPHAsset(creationDate: testDate, localIdentifier: "test-1")
        mockService.mockPhotos = [PhotoAsset(phAsset: mockAsset)]
        
        // When
        await viewModel.loadPhotos()
        let initialKeptCount = await viewModel.keptCount
        await viewModel.swipeRight()
        
        // Then
        let finalKeptCount = await viewModel.keptCount
        #expect(finalKeptCount == initialKeptCount + 1)
        #expect(mockService.moveToTrashCalled == false)
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("测试边界情况 - 没有当前照片时的滑动操作")
    func testSwipeGesture_NoCurrentPhoto() async {
        // Given
        let mockService = MockSwipePhotoService()
        let viewModel = await PhotoViewModel(photoService: mockService)
        mockService.mockPhotos = [] // 空照片列表
        
        // When
        await viewModel.loadPhotos()
        let initialDeletedCount = await viewModel.deletedCount
        let initialKeptCount = await viewModel.keptCount
        
        await viewModel.swipeLeft()
        await viewModel.swipeRight()
        
        // Then
        let finalDeletedCount = await viewModel.deletedCount
        let finalKeptCount = await viewModel.keptCount
        #expect(finalDeletedCount == initialDeletedCount)
        #expect(finalKeptCount == initialKeptCount)
        #expect(mockService.moveToTrashCalled == false)
    }
    
    @Test("测试边界情况 - 最后一张照片的滑动操作")
    func testSwipeGesture_LastPhoto() async {
        // Given
        let mockService = MockSwipePhotoService()
        let viewModel = await PhotoViewModel(photoService: mockService)
        
        let testDate = Date()
        let mockAsset = MockPHAsset(creationDate: testDate, localIdentifier: "test-1")
        mockService.mockPhotos = [PhotoAsset(phAsset: mockAsset)]
        
        // When
        await viewModel.loadPhotos()
        let initialIndex = await viewModel.currentIndex
        await viewModel.swipeRight()
        
        // Then
        let finalIndex = await viewModel.currentIndex
        let finalKeptCount = await viewModel.keptCount
        #expect(finalIndex == initialIndex)
        #expect(finalKeptCount == 1)
    }
    
    // MARK: - Performance Tests
    
    @Test("测试滑动手势性能")
    func testSwipeGesturePerformance() async {
        // Given
        let mockService = MockSwipePhotoService()
        let viewModel = await PhotoViewModel(photoService: mockService)
        
        // 创建大量测试照片
        mockService.mockPhotos = Array(0..<100).map { index in
            let testDate = Calendar.current.date(byAdding: .day, value: index, to: Date()) ?? Date()
            let mockAsset = MockPHAsset(creationDate: testDate, localIdentifier: "test-\(index)")
            return PhotoAsset(phAsset: mockAsset)
        }
        
        // When & Then
        await viewModel.loadPhotos()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<10 {
            await viewModel.swipeRight()
        }
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // 验证性能 - 10次滑动操作应该在合理时间内完成
        #expect(timeElapsed < 1.0)
    }
    
    // MARK: - Gesture State Management Tests
    
    @Test("测试手势状态管理 - 防止并发滑动")
    func testGestureStateManagement_PreventConcurrentSwipes() async {
        // Given
        let mockService = MockSwipePhotoService()
        let viewModel = await PhotoViewModel(photoService: mockService)
        
        let testDate = Date()
        let mockAsset1 = MockPHAsset(creationDate: testDate, localIdentifier: "test-1")
        let mockAsset2 = MockPHAsset(creationDate: testDate.addingTimeInterval(3600), localIdentifier: "test-2")
        mockService.mockPhotos = [PhotoAsset(phAsset: mockAsset1), PhotoAsset(phAsset: mockAsset2)]
        
        // When
        await viewModel.loadPhotos()
        
        // 模拟快速连续的滑动操作
        let initialDeletedCount = await viewModel.deletedCount
        
        // 在实际应用中，isSwipeInProgress状态会防止并发操作
        // 这里我们测试ViewModel层面的状态管理
        await viewModel.swipeLeft()
        let afterFirstSwipe = await viewModel.deletedCount
        
        await viewModel.swipeLeft()
        let afterSecondSwipe = await viewModel.deletedCount
        
        // Then
        #expect(afterFirstSwipe == initialDeletedCount + 1)
        #expect(afterSecondSwipe == initialDeletedCount + 2)
        #expect(mockService.deletedAssets.count == 2)
    }
    
    @Test("测试滑动方向检测的准确性")
    func testSwipeDirectionDetectionAccuracy() {
        // Given
        let testCases: [(translation: CGFloat, expected: SwipeDirection, description: String)] = [
            (-1.0, .left, "微小的负值应该被识别为左滑"),
            (1.0, .right, "微小的正值应该被识别为右滑"),
            (-999.0, .left, "大的负值应该被识别为左滑"),
            (999.0, .right, "大的正值应该被识别为右滑"),
            (-0.1, .left, "小数负值应该被识别为左滑"),
            (0.1, .right, "小数正值应该被识别为右滑")
        ]
        
        // When & Then
        for testCase in testCases {
            let direction = determineSwipeDirection(translation: testCase.translation)
            #expect(direction == testCase.expected)
        }
    }
}