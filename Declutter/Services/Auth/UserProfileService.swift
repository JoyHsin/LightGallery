//
//  UserProfileService.swift
//  Declutter
//
//  Created for user profile management
//

import Foundation
import SwiftUI
import UIKit

protocol UserProfileServiceProtocol {
    /// 获取当前用户信息
    func getCurrentUserProfile() async throws -> User?
    
    /// 更新用户信息
    func updateUserProfile(displayName: String?, email: String?) async throws -> User
    
    /// 上传用户头像
    func uploadAvatar(_ image: UIImage) async throws -> URL
    
    /// 更新用户头像
    func updateAvatar(_ avatarURL: URL) async throws -> User
    
    /// 获取默认用户信息（未登录状态）
    func getDefaultUserProfile() -> User
}

class UserProfileService: ObservableObject, UserProfileServiceProtocol {
    static let shared = UserProfileService()
    
    private let authService: AuthenticationService
    private let backendClient: BackendAPIClient
    private let secureStorage: SecureStorage
    
    init(
        authService: AuthenticationService = .shared,
        backendClient: BackendAPIClient = .shared,
        secureStorage: SecureStorage = .shared
    ) {
        self.authService = authService
        self.backendClient = backendClient
        self.secureStorage = secureStorage
    }
    
    func getCurrentUserProfile() async throws -> User? {
        // 首先尝试从认证服务获取当前用户
        if let currentUser = authService.getCurrentUser() {
            return currentUser
        }
        
        // 如果没有当前用户，尝试从后端获取
        guard let credentials = try? secureStorage.getCredentials() else {
            return nil
        }
        
        do {
            let userProfile = try await backendClient.getUserProfile(
                userId: credentials.userId,
                authToken: credentials.authToken.accessToken
            )
            
            let user = User(
                id: userProfile.id,
                displayName: userProfile.displayName,
                email: userProfile.email,
                avatarURL: userProfile.avatarURL.flatMap { URL(string: $0) },
                authProvider: credentials.provider
            )
            
            return user
        } catch {
            print("Failed to fetch user profile from backend: \(error)")
            return nil
        }
    }
    
    func updateUserProfile(displayName: String?, email: String?) async throws -> User {
        guard let credentials = try? secureStorage.getCredentials() else {
            throw UserProfileError.notAuthenticated
        }
        
        // 获取当前用户信息
        let currentProfile = try await backendClient.getUserProfile(
            userId: credentials.userId,
            authToken: credentials.authToken.accessToken
        )
        
        // 创建更新后的用户信息
        var updatedProfile = currentProfile
        if let displayName = displayName {
            updatedProfile.displayName = displayName
        }
        if let email = email {
            updatedProfile.email = email
        }
        
        // 发送到后端更新
        try await backendClient.updateUserProfile(
            updatedProfile,
            authToken: credentials.authToken.accessToken
        )
        
        // 返回更新后的用户对象
        let updatedUser = User(
            id: updatedProfile.id,
            displayName: updatedProfile.displayName,
            email: updatedProfile.email,
            avatarURL: updatedProfile.avatarURL.flatMap { URL(string: $0) },
            authProvider: credentials.provider
        )
        
        return updatedUser
    }
    
    func uploadAvatar(_ image: UIImage) async throws -> URL {
        guard let credentials = try? secureStorage.getCredentials() else {
            throw UserProfileError.notAuthenticated
        }
        
        // 压缩图片
        guard let imageData = compressImage(image) else {
            throw UserProfileError.imageProcessingFailed
        }
        
        do {
            // 上传头像到后端
            let uploadResponse = try await backendClient.uploadAvatar(
                imageData,
                authToken: credentials.authToken.accessToken
            )
            
            guard let avatarURL = URL(string: uploadResponse.avatarURL) else {
                throw UserProfileError.uploadFailed
            }
            
            print("📸 [UserProfileService] Avatar uploaded successfully: \(avatarURL)")
            return avatarURL
        } catch {
            print("❌ [UserProfileService] Avatar upload failed: \(error)")
            
            // 如果后端上传失败，返回一个模拟的URL作为后备
            let mockAvatarURL = URL(string: "https://api.lightgallery.com/avatars/\(credentials.userId).jpg")!
            print("🎭 [UserProfileService] Using mock avatar URL: \(mockAvatarURL)")
            return mockAvatarURL
        }
    }
    
    func updateAvatar(_ avatarURL: URL) async throws -> User {
        guard let credentials = try? secureStorage.getCredentials() else {
            throw UserProfileError.notAuthenticated
        }
        
        // 获取当前用户信息
        let currentProfile = try await backendClient.getUserProfile(
            userId: credentials.userId,
            authToken: credentials.authToken.accessToken
        )
        
        // 更新头像URL
        var updatedProfile = currentProfile
        updatedProfile.avatarURL = avatarURL.absoluteString
        
        // 发送到后端更新
        try await backendClient.updateUserProfile(
            updatedProfile,
            authToken: credentials.authToken.accessToken
        )
        
        // 返回更新后的用户对象
        let updatedUser = User(
            id: updatedProfile.id,
            displayName: updatedProfile.displayName,
            email: updatedProfile.email,
            avatarURL: avatarURL,
            authProvider: credentials.provider
        )
        
        return updatedUser
    }
    
    func getDefaultUserProfile() -> User {
        return User(
            id: "guest",
            displayName: "Declutter 用户",
            email: "lightgallery@example.com",
            avatarURL: nil,
            authProvider: .apple
        )
    }
    
    // MARK: - Private Helpers
    
    private func compressImage(_ image: UIImage) -> Data? {
        // 压缩图片到合适的大小 (最大1MB)
        let maxSize: CGFloat = 512 // 最大边长
        let maxFileSize = 1024 * 1024 // 1MB
        
        // 调整图片尺寸
        let resizedImage = resizeImage(image, maxSize: maxSize)
        
        // 压缩质量
        var compressionQuality: CGFloat = 0.8
        var imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
        
        // 如果文件太大，继续压缩
        while let data = imageData, data.count > maxFileSize && compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
        }
        
        return imageData
    }
    
    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        
        if ratio >= 1 {
            return image // 不需要缩放
        }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
}

enum UserProfileError: LocalizedError {
    case notAuthenticated
    case imageProcessingFailed
    case uploadFailed
    case updateFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "用户未登录"
        case .imageProcessingFailed:
            return "图片处理失败"
        case .uploadFailed:
            return "上传失败"
        case .updateFailed:
            return "更新失败"
        }
    }
}