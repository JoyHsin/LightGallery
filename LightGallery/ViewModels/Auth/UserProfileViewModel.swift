//
//  UserProfileViewModel.swift
//  LightGallery
//
//  Created for user profile management
//

import Foundation
import SwiftUI

@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userProfileService: UserProfileServiceProtocol
    private let authService: AuthenticationService
    
    init(
        userProfileService: UserProfileServiceProtocol = UserProfileService.shared,
        authService: AuthenticationService = .shared
    ) {
        self.userProfileService = userProfileService
        self.authService = authService
    }
    
    /// 加载用户信息
    func loadUserProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let user = try await userProfileService.getCurrentUserProfile() {
                currentUser = user
            } else {
                // 如果没有登录用户，使用默认信息
                currentUser = userProfileService.getDefaultUserProfile()
            }
        } catch {
            errorMessage = "加载用户信息失败: \(error.localizedDescription)"
            // 使用默认用户信息作为后备
            currentUser = userProfileService.getDefaultUserProfile()
        }
        
        isLoading = false
    }
    
    /// 更新用户信息
    func updateUserProfile(displayName: String?, email: String?) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedUser = try await userProfileService.updateUserProfile(
                displayName: displayName,
                email: email
            )
            currentUser = updatedUser
            isLoading = false
            return true
        } catch {
            errorMessage = "更新用户信息失败: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// 上传并更新头像
    func updateAvatar(_ image: UIImage) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let avatarURL = try await userProfileService.uploadAvatar(image)
            let updatedUser = try await userProfileService.updateAvatar(avatarURL)
            currentUser = updatedUser
            isLoading = false
            return true
        } catch {
            errorMessage = "更新头像失败: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// 登出
    func signOut() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signOut()
            currentUser = userProfileService.getDefaultUserProfile()
            isLoading = false
            return true
        } catch {
            errorMessage = "登出失败: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// 检查是否已登录
    var isLoggedIn: Bool {
        guard let user = currentUser else { return false }
        return user.id != "guest"
    }
    
    /// 获取显示用的用户名
    var displayName: String {
        return currentUser?.displayName ?? "LightGallery 用户"
    }
    
    /// 获取显示用的邮箱
    var displayEmail: String {
        return currentUser?.email ?? "lightgallery@example.com"
    }
    
    /// 获取头像URL
    var avatarURL: URL? {
        return currentUser?.avatarURL
    }
    
    /// 获取认证提供商
    var authProvider: AuthProvider {
        return currentUser?.authProvider ?? .apple
    }
}