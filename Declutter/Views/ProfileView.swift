//
//  ProfileView.swift
//  Declutter
//
//  Created for user-auth-subscription feature
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var featureAccessManager = FeatureAccessManager.shared
    @StateObject private var userProfileViewModel = UserProfileViewModel()
    @State private var showSubscriptionView = false
    @State private var showEditProfile = false
    @State private var showSignOutAlert = false
    @State private var showLoginView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader
                    
                    // Subscription Status or Feature Introduction
                    if userProfileViewModel.isLoggedIn {
                        subscriptionStatusSection
                    } else {
                        featureIntroductionSection
                    }
                    
                    // Account Actions
                    accountActionsSection
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("个人信息")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showSubscriptionView) {
            SubscriptionView()
        }
        .sheet(isPresented: $showEditProfile) {
            if let user = userProfileViewModel.currentUser {
                EditProfileView(user: user)
            }
        }
        .sheet(isPresented: $showLoginView) {
            LoginView()
        }
        .alert("确认登出", isPresented: $showSignOutAlert) {
            Button("取消", role: .cancel) { }
            Button("登出", role: .destructive) {
                Task {
                    await userProfileViewModel.signOut()
                }
            }
        } message: {
            Text("确定要登出当前账户吗？")
        }
        .task {
            await userProfileViewModel.loadUserProfile()
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidLogin)) { _ in
            Task {
                await userProfileViewModel.loadUserProfile()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidLogout)) { _ in
            Task {
                await userProfileViewModel.loadUserProfile()
            }
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                if let avatarURL = userProfileViewModel.avatarURL {
                    AsyncImage(url: avatarURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                }
                
                if userProfileViewModel.isLoading {
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 100, height: 100)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            
            VStack(spacing: 8) {
                Text(userProfileViewModel.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if userProfileViewModel.isLoggedIn {
                    Text(userProfileViewModel.displayEmail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: providerIcon)
                            .foregroundColor(.blue)
                        Text("通过\(userProfileViewModel.authProvider.displayName)登录")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("未登录")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    Button("立即登录") {
                        showLoginView = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical)
    }
    
    private var providerIcon: String {
        switch userProfileViewModel.authProvider {
        case .apple:
            return "applelogo"
        case .wechat:
            return "message.fill"
        case .alipay:
            return "creditcard.fill"
        }
    }
    
    // MARK: - Feature Introduction (for non-logged in users)
    
    private var featureIntroductionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("高级功能")
                .font(.headline)
            
            featureIntroductionCard
        }
    }
    
    private var featureIntroductionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                
                Text("解锁所有高级功能")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text("登录后可升级到专业版或旗舰版，享受智能清理、重复照片检测、格式转换等强大功能")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button {
                showLoginView = true
            } label: {
                Text("登录并了解更多")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Subscription Status
    
    private var subscriptionStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("订阅状态")
                .font(.headline)
            
            subscriptionStatusCard
        }
    }
    
    private var subscriptionStatusCard: some View {
        let tier = featureAccessManager.getCurrentTier()
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: tier == .free ? "person.circle" : "crown.fill")
                    .foregroundColor(tier == .free ? .gray : .orange)
                
                Text(tier.displayName)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if tier != .free {
                    Text("活跃")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
            
            if tier == .free {
                if userProfileViewModel.isLoggedIn {
                    Text("升级到高级版，解锁所有功能")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button {
                        showSubscriptionView = true
                    } label: {
                        Text("立即升级")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                } else {
                    Text("登录后可升级到高级版，解锁所有功能")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button {
                        showLoginView = true
                    } label: {
                        Text("登录并升级")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
            } else {
                Text("感谢您的支持！您已解锁所有高级功能。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button {
                    showSubscriptionView = true
                } label: {
                    Text("管理订阅")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Account Actions
    
    private var accountActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("账户操作")
                .font(.headline)
            
            VStack(spacing: 12) {
                accountActionRow(
                    title: userProfileViewModel.isLoggedIn ? "编辑个人信息" : "登录后编辑信息",
                    icon: "person.crop.circle",
                    action: {
                        if userProfileViewModel.isLoggedIn {
                            showEditProfile = true
                        } else {
                            showLoginView = true
                        }
                    }
                )
                
                if userProfileViewModel.isLoggedIn {
                    accountActionRow(
                        title: "更改密码",
                        icon: "key.fill",
                        action: {
                            // TODO: Implement change password
                        }
                    )
                }
                
                accountActionRow(
                    title: "通知设置",
                    icon: "bell.fill",
                    action: {
                        // TODO: Implement notification settings
                    }
                )
                
                accountActionRow(
                    title: "隐私设置",
                    icon: "hand.raised.fill",
                    action: {
                        // TODO: Implement privacy settings
                    }
                )
                
                Divider()
                
                if userProfileViewModel.isLoggedIn {
                    accountActionRow(
                        title: "退出登录",
                        icon: "rectangle.portrait.and.arrow.right",
                        textColor: .red,
                        action: {
                            showSignOutAlert = true
                        }
                    )
                } else {
                    accountActionRow(
                        title: "登录账户",
                        icon: "person.badge.plus",
                        textColor: .blue,
                        action: {
                            showLoginView = true
                        }
                    )
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    private func accountActionRow(
        title: String,
        icon: String,
        textColor: Color = .primary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(textColor)
                    .frame(width: 20)
                
                Text(title)
                    .foregroundColor(textColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
}