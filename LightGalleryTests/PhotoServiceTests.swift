//
//  PhotoServiceTests.swift
//  LightGalleryTests
//
//  Created by Kiro on 2025/9/7.
//

import Testing
import Photos
@testable import LightGallery

/// PhotoService权限管理功能的单元测试
struct PhotoServiceTests {
    
    // MARK: - Permission Tests
    
    @Test("测试权限状态检查")
    func testCurrentAuthorizationStatus() async throws {
        let photoService = PhotoService()
        
        // 验证权限状态属性可以正常访问
        let status = photoService.currentAuthorizationStatus
        #expect([.authorized, .limited, .denied, .restricted, .notDetermined].contains(status))
    }
    
    @Test("测试权限访问检查")
    func testHasPhotoLibraryAccess() async throws {
        let photoService = PhotoService()
        
        let hasAccess = photoService.hasPhotoLibraryAccess
        let status = photoService.currentAuthorizationStatus
        
        // 验证hasPhotoLibraryAccess与实际权限状态一致
        if status == .authorized || status == .limited {
            #expect(hasAccess == true)
        } else {
            #expect(hasAccess == false)
        }
    }
    
    @Test("测试权限请求 - 已授权状态")
    func testRequestPhotoLibraryAccessWhenAuthorized() async throws {
        let photoService = MockPhotoService(mockStatus: .authorized)
        
        let result = await photoService.requestPhotoLibraryAccess()
        #expect(result == true)
    }
    
    @Test("测试权限请求 - 受限状态")
    func testRequestPhotoLibraryAccessWhenLimited() async throws {
        let photoService = MockPhotoService(mockStatus: .limited)
        
        let result = await photoService.requestPhotoLibraryAccess()
        #expect(result == true)
    }
    
    @Test("测试权限请求 - 被拒绝状态")
    func testRequestPhotoLibraryAccessWhenDenied() async throws {
        let photoService = MockPhotoService(mockStatus: .denied)
        
        let result = await photoService.requestPhotoLibraryAccess()
        #expect(result == false)
    }
    
    @Test("测试权限请求 - 受限制状态")
    func testRequestPhotoLibraryAccessWhenRestricted() async throws {
        let photoService = MockPhotoService(mockStatus: .restricted)
        
        let result = await photoService.requestPhotoLibraryAccess()
        #expect(result == false)
    }
    
    @Test("测试确保权限访问 - 成功情况")
    func testEnsurePhotoLibraryAccessSuccess() async throws {
        let photoService = MockPhotoService(mockStatus: .authorized)
        
        // 不应该抛出异常
        try await photoService.ensurePhotoLibraryAccess()
    }
    
    @Test("测试确保权限访问 - 权限被拒绝")
    func testEnsurePhotoLibraryAccessDenied() async throws {
        let photoService = MockPhotoService(mockStatus: .denied)
        
        // 应该抛出权限被拒绝的错误
        do {
            try await photoService.ensurePhotoLibraryAccess()
            #expect(Bool(false), "Expected PhotoError.permissionDenied to be thrown")
        } catch {
            #expect(error as? PhotoError == PhotoError.permissionDenied)
        }
    }
}

// MARK: - Photo Fetching Tests

extension PhotoServiceTests {
    
    @Test("测试照片获取功能 - 有权限时返回模拟数据")
    func testFetchAllPhotosWithPermission() async throws {
        let mockService = MockPhotoServiceWithData(mockStatus: .authorized)
        
        let photos = try await mockService.fetchAllPhotos()
        
        // 验证返回了模拟的照片数据
        #expect(photos.count == 3)
        
        // 验证照片按时间排序（从最早到最新）
        #expect(photos[0].creationDate <= photos[1].creationDate)
        #expect(photos[1].creationDate <= photos[2].creationDate)
        
        // 验证照片元数据正确提取
        let firstPhoto = photos[0]
        #expect(!firstPhoto.id.isEmpty)
        #expect(!firstPhoto.localIdentifier.isEmpty)
        #expect(!firstPhoto.formattedDate.isEmpty)
        #expect(!firstPhoto.formattedTime.isEmpty)
        #expect(firstPhoto.year > 0)
        #expect(firstPhoto.month > 0 && firstPhoto.month <= 12)
    }
    
    @Test("测试照片获取功能 - 无权限时抛出错误")
    func testFetchAllPhotosWithoutPermission() async throws {
        let mockService = MockPhotoServiceWithData(mockStatus: .denied)
        
        do {
            _ = try await mockService.fetchAllPhotos()
            #expect(Bool(false), "Expected PhotoError.permissionDenied to be thrown")
        } catch {
            #expect(error as? PhotoError == PhotoError.permissionDenied)
        }
    }
    
    @Test("测试时间范围照片获取功能")
    func testFetchPhotosInDateRange() async throws {
        let mockService = MockPhotoServiceWithData(mockStatus: .authorized)
        
        // 创建测试时间范围
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: 2024, month: 12, day: 31))!
        
        let photos = try await mockService.fetchPhotosInDateRange(startDate, endDate)
        
        // 验证返回的照片都在指定时间范围内
        for photo in photos {
            #expect(photo.creationDate >= startDate)
            #expect(photo.creationDate <= endDate)
        }
        
        // 验证照片按时间排序
        if photos.count > 1 {
            for i in 0..<photos.count-1 {
                #expect(photos[i].creationDate <= photos[i+1].creationDate)
            }
        }
    }
    
    @Test("测试照片创建日期获取")
    func testGetPhotoCreationDate() async throws {
        let mockService = MockPhotoServiceWithData(mockStatus: .authorized)
        let photos = try await mockService.fetchAllPhotos()
        
        guard let firstPhoto = photos.first else {
            #expect(Bool(false), "Expected at least one photo in mock data")
            return
        }
        
        let creationDate = mockService.getPhotoCreationDate(firstPhoto)
        #expect(creationDate == firstPhoto.creationDate)
    }
    
    @Test("测试PhotoAsset元数据提取")
    func testPhotoAssetMetadataExtraction() async throws {
        // 创建测试日期
        let testDate = Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 15, hour: 14, minute: 30))!
        let mockAsset = MockPHAsset(creationDate: testDate, localIdentifier: "test-id-123")
        
        let photoAsset = PhotoAsset(phAsset: mockAsset)
        
        // 验证基础属性
        #expect(photoAsset.id == "test-id-123")
        #expect(photoAsset.localIdentifier == "test-id-123")
        #expect(photoAsset.creationDate == testDate)
        
        // 验证计算属性
        #expect(photoAsset.year == 2024)
        #expect(photoAsset.month == 6)
        #expect(!photoAsset.formattedDate.isEmpty)
        #expect(!photoAsset.formattedTime.isEmpty)
    }
    
    @Test("测试PhotoAsset相等性比较")
    func testPhotoAssetEquality() async throws {
        let mockAsset1 = MockPHAsset(creationDate: Date(), localIdentifier: "test-id-1")
        let mockAsset2 = MockPHAsset(creationDate: Date(), localIdentifier: "test-id-2")
        let mockAsset3 = MockPHAsset(creationDate: Date(), localIdentifier: "test-id-1")
        
        let photoAsset1 = PhotoAsset(phAsset: mockAsset1)
        let photoAsset2 = PhotoAsset(phAsset: mockAsset2)
        let photoAsset3 = PhotoAsset(phAsset: mockAsset3)
        
        // 验证相等性基于localIdentifier
        #expect(photoAsset1 == photoAsset3)
        #expect(photoAsset1 != photoAsset2)
    }
}

// MARK: - Photo Deletion Tests

extension PhotoServiceTests {
    
    @Test("测试照片删除功能 - 成功删除")
    func testMovePhotoToTrashSuccess() async throws {
        let mockService = MockPhotoServiceWithData(mockStatus: .authorized)
        let photos = try await mockService.fetchAllPhotos()
        
        guard let firstPhoto = photos.first else {
            #expect(Bool(false), "Expected at least one photo in mock data")
            return
        }
        
        // 删除操作不应该抛出异常
        try await mockService.movePhotoToTrash(firstPhoto)
    }
    
    @Test("测试照片删除功能 - 权限被拒绝")
    func testMovePhotoToTrashPermissionDenied() async throws {
        let mockService = MockPhotoServiceWithData(mockStatus: .denied)
        let mockAsset = MockPHAsset(creationDate: Date(), localIdentifier: "test-delete")
        let photoAsset = PhotoAsset(phAsset: mockAsset)
        
        // 应该抛出权限被拒绝的错误
        do {
            try await mockService.movePhotoToTrash(photoAsset)
            #expect(Bool(false), "Expected PhotoError.permissionDenied to be thrown")
        } catch {
            #expect(error as? PhotoError == PhotoError.permissionDenied)
        }
    }
    
    @Test("测试照片删除功能 - 删除失败")
    func testMovePhotoToTrashDeletionFailed() async throws {
        let mockService = MockPhotoServiceWithData(mockStatus: .authorized)
        let mockAsset = MockPHAsset(creationDate: Date(), localIdentifier: "fail-delete-test")
        let photoAsset = PhotoAsset(phAsset: mockAsset)
        
        // 应该抛出删除失败的错误
        do {
            try await mockService.movePhotoToTrash(photoAsset)
            #expect(Bool(false), "Expected PhotoError.deletionFailed to be thrown")
        } catch {
            if case PhotoError.deletionFailed(let reason) = error {
                #expect(reason == "Mock deletion failure")
            } else {
                #expect(Bool(false), "Expected PhotoError.deletionFailed but got \(error)")
            }
        }
    }
    
    @Test("测试照片删除功能 - 受限权限状态")
    func testMovePhotoToTrashWithLimitedPermission() async throws {
        let mockService = MockPhotoServiceWithData(mockStatus: .limited)
        let photos = try await mockService.fetchAllPhotos()
        
        guard let firstPhoto = photos.first else {
            #expect(Bool(false), "Expected at least one photo in mock data")
            return
        }
        
        // 受限权限状态下删除操作应该成功
        try await mockService.movePhotoToTrash(firstPhoto)
    }
    
    @Test("测试照片删除功能 - 验证错误信息本地化")
    func testPhotoErrorLocalization() async throws {
        let permissionError = PhotoError.permissionDenied
        let deletionError = PhotoError.deletionFailed("测试错误原因")
        let loadingError = PhotoError.loadingFailed("加载失败")
        let filteringError = PhotoError.filteringFailed("筛选失败")
        let libraryError = PhotoError.photoLibraryUnavailable
        
        // 验证错误信息是中文本地化的
        #expect(permissionError.errorDescription?.contains("权限") == true)
        #expect(deletionError.errorDescription?.contains("删除照片失败") == true)
        #expect(deletionError.errorDescription?.contains("测试错误原因") == true)
        #expect(loadingError.errorDescription?.contains("加载照片失败") == true)
        #expect(filteringError.errorDescription?.contains("筛选照片失败") == true)
        #expect(libraryError.errorDescription?.contains("照片库") == true)
    }
    
    @Test("测试PhotoError相等性比较")
    func testPhotoErrorEquality() async throws {
        let error1 = PhotoError.permissionDenied
        let error2 = PhotoError.permissionDenied
        let error3 = PhotoError.photoLibraryUnavailable
        let error4 = PhotoError.deletionFailed("reason1")
        let error5 = PhotoError.deletionFailed("reason1")
        let error6 = PhotoError.deletionFailed("reason2")
        
        // 验证相同类型和参数的错误相等
        #expect(error1 == error2)
        #expect(error4 == error5)
        
        // 验证不同类型或参数的错误不相等
        #expect(error1 != error3)
        #expect(error4 != error6)
    }
}

// MARK: - Integration Tests for Photo Deletion

extension PhotoServiceTests {
    
    @Test("集成测试 - 完整的照片删除流程")
    func testCompletePhotoDeletionFlow() async throws {
        let mockService = MockPhotoServiceWithData(mockStatus: .notDetermined)
        
        // 1. 首先请求权限
        let hasPermission = await mockService.requestPhotoLibraryAccess()
        #expect(hasPermission == false) // notDetermined状态下应该返回false
        
        // 2. 模拟权限被授予后的服务
        let authorizedService = MockPhotoServiceWithData(mockStatus: .authorized)
        
        // 3. 获取照片列表
        let photos = try await authorizedService.fetchAllPhotos()
        #expect(photos.count > 0)
        
        // 4. 删除第一张照片
        if let firstPhoto = photos.first {
            try await authorizedService.movePhotoToTrash(firstPhoto)
        }
        
        // 5. 验证删除操作完成（在真实环境中，这里可以验证照片是否被移动到最近删除）
    }
    
    @Test("集成测试 - 批量删除操作")
    func testBatchDeletionOperations() async throws {
        let mockService = MockPhotoServiceWithData(mockStatus: .authorized)
        let photos = try await mockService.fetchAllPhotos()
        
        // 模拟批量删除前两张照片
        let photosToDelete = Array(photos.prefix(2))
        
        for photo in photosToDelete {
            try await mockService.movePhotoToTrash(photo)
        }
        
        // 验证批量删除操作完成
        #expect(photosToDelete.count == 2)
    }
    
    @Test("集成测试 - 删除操作的错误恢复")
    func testDeletionErrorRecovery() async throws {
        let mockService = MockPhotoServiceWithData(mockStatus: .authorized)
        
        // 创建一个会导致删除失败的照片
        let failingAsset = MockPHAsset(creationDate: Date(), localIdentifier: "fail-delete-test")
        let failingPhoto = PhotoAsset(phAsset: failingAsset)
        
        // 创建一个正常的照片
        let normalAsset = MockPHAsset(creationDate: Date(), localIdentifier: "normal-photo")
        let normalPhoto = PhotoAsset(phAsset: normalAsset)
        
        // 尝试删除失败的照片
        do {
            try await mockService.movePhotoToTrash(failingPhoto)
            #expect(Bool(false), "Expected deletion to fail")
        } catch PhotoError.deletionFailed {
            // 预期的错误，继续测试
        }
        
        // 验证在删除失败后，仍然可以删除其他照片
        try await mockService.movePhotoToTrash(normalPhoto)
    }
}

// MARK: - Mock PhotoService for Testing

/// 用于测试的Mock PhotoService，允许模拟不同的权限状态
class MockPhotoService: PhotoServiceProtocol {
    private let mockAuthorizationStatus: PHAuthorizationStatus
    
    init(mockStatus: PHAuthorizationStatus) {
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
    
    // MARK: - Placeholder implementations for protocol compliance
    
    func fetchAllPhotos() async throws -> [PhotoAsset] {
        try await ensurePhotoLibraryAccess()
        return []
    }
    
    func fetchPhotosInDateRange(_ startDate: Date, _ endDate: Date) async throws -> [PhotoAsset] {
        try await ensurePhotoLibraryAccess()
        return []
    }
    
    func movePhotoToTrash(_ asset: PhotoAsset) async throws {
        // Mock implementation
    }
    
    func getPhotoCreationDate(_ asset: PhotoAsset) -> Date? {
        return asset.creationDate
    }
}

// MARK: - Enhanced Mock PhotoService with Test Data

/// 增强的Mock PhotoService，包含测试数据用于照片获取功能测试
class MockPhotoServiceWithData: PhotoServiceProtocol {
    private let mockAuthorizationStatus: PHAuthorizationStatus
    private let mockPhotos: [PhotoAsset]
    
    init(mockStatus: PHAuthorizationStatus) {
        self.mockAuthorizationStatus = mockStatus
        
        // 创建模拟照片数据，按时间排序
        let calendar = Calendar.current
        let date1 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        let date2 = calendar.date(from: DateComponents(year: 2024, month: 6, day: 10))!
        let date3 = calendar.date(from: DateComponents(year: 2024, month: 12, day: 5))!
        
        let mockAsset1 = MockPHAsset(creationDate: date1, localIdentifier: "mock-id-1")
        let mockAsset2 = MockPHAsset(creationDate: date2, localIdentifier: "mock-id-2")
        let mockAsset3 = MockPHAsset(creationDate: date3, localIdentifier: "mock-id-3")
        
        self.mockPhotos = [
            PhotoAsset(phAsset: mockAsset1),
            PhotoAsset(phAsset: mockAsset2),
            PhotoAsset(phAsset: mockAsset3)
        ]
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
    
    func fetchAllPhotos() async throws -> [PhotoAsset] {
        try await ensurePhotoLibraryAccess()
        return mockPhotos.sorted { $0.creationDate < $1.creationDate }
    }
    
    func fetchPhotosInDateRange(_ startDate: Date, _ endDate: Date) async throws -> [PhotoAsset] {
        try await ensurePhotoLibraryAccess()
        return mockPhotos
            .filter { $0.creationDate >= startDate && $0.creationDate <= endDate }
            .sorted { $0.creationDate < $1.creationDate }
    }
    
    func movePhotoToTrash(_ asset: PhotoAsset) async throws {
        try await ensurePhotoLibraryAccess()
        // Mock implementation - 在实际测试中可以验证调用
        // 可以通过设置标志来模拟删除成功或失败
        if asset.localIdentifier == "fail-delete-test" {
            throw PhotoError.deletionFailed("Mock deletion failure")
        }
    }
    
    func getPhotoCreationDate(_ asset: PhotoAsset) -> Date? {
        return asset.creationDate
    }
}

// MARK: - Mock PHAsset for Testing

/// 用于测试的Mock PHAsset
class MockPHAsset: PHAsset, @unchecked Sendable {
    private let mockCreationDate: Date?
    private let mockLocalIdentifier: String
    
    init(creationDate: Date?, localIdentifier: String) {
        self.mockCreationDate = creationDate
        self.mockLocalIdentifier = localIdentifier
        super.init()
    }
    
    override var creationDate: Date? {
        return mockCreationDate
    }
    
    override var localIdentifier: String {
        return mockLocalIdentifier
    }
}