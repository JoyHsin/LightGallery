//
//  EditProfileView.swift
//  Declutter
//
//  Created for user profile editing
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var userProfileService = UserProfileService.shared
    
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var avatarImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let currentUser: User
    
    init(user: User) {
        self.currentUser = user
        self._displayName = State(initialValue: user.displayName)
        self._email = State(initialValue: user.email ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar Section
                    avatarSection
                    
                    // Form Section
                    formSection
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("编辑个人信息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveProfile()
                    }
                    .disabled(isLoading || displayName.isEmpty)
                }
            }
            .disabled(isLoading)
        }
        .alert("提示", isPresented: $showAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let newItem = newItem {
                    await loadSelectedPhoto(newItem)
                }
            }
        }
    }
    
    // MARK: - Avatar Section
    
    private var avatarSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                if let avatarImage = avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else if let avatarURL = currentUser.avatarURL {
                    AsyncImage(url: avatarURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                }
                
                // Loading overlay
                if isLoading {
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 120, height: 120)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            
            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text("更换头像")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .disabled(isLoading)
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Display Name
            VStack(alignment: .leading, spacing: 8) {
                Text("昵称")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("请输入昵称", text: $displayName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
            }
            
            // Email
            VStack(alignment: .leading, spacing: 8) {
                Text("邮箱")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("请输入邮箱", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            // Provider Info
            VStack(alignment: .leading, spacing: 8) {
                Text("登录方式")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: providerIcon)
                        .foregroundColor(.blue)
                    
                    Text(currentUser.authProvider.displayName)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var providerIcon: String {
        switch currentUser.authProvider {
        case .apple:
            return "applelogo"
        case .wechat:
            return "message.fill"
        case .alipay:
            return "creditcard.fill"
        }
    }
    
    // MARK: - Actions
    
    private func saveProfile() {
        Task {
            await performSave()
        }
    }
    
    @MainActor
    private func performSave() async {
        isLoading = true
        
        do {
            // 如果有新头像，先上传头像
            if let avatarImage = avatarImage {
                let avatarURL = try await userProfileService.uploadAvatar(avatarImage)
                _ = try await userProfileService.updateAvatar(avatarURL)
            }
            
            // 更新用户信息
            _ = try await userProfileService.updateUserProfile(
                displayName: displayName.isEmpty ? nil : displayName,
                email: email.isEmpty ? nil : email
            )
            
            alertMessage = "个人信息更新成功"
            showAlert = true
            
            // 延迟关闭页面
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                dismiss()
            }
            
        } catch {
            alertMessage = "更新失败: \(error.localizedDescription)"
            showAlert = true
        }
        
        isLoading = false
    }
    
    private func loadSelectedPhoto(_ item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.avatarImage = image
                }
            }
        } catch {
            await MainActor.run {
                alertMessage = "加载图片失败: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

#Preview {
    EditProfileView(user: User(
        displayName: "测试用户",
        email: "test@example.com",
        authProvider: .apple
    ))
}