//
//  ProfileView.swift
//  LightGallery
//
//  Created for user-auth-subscription feature
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var featureAccessManager = FeatureAccessManager.shared
    @State private var showSubscriptionView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader
                    
                    // Subscription Status
                    subscriptionStatusSection
                    
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
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 100, height: 100)
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                Text("LightGallery 用户")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("lightgallery@example.com")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical)
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
                    title: "编辑个人信息",
                    icon: "person.crop.circle",
                    action: {
                        // TODO: Implement edit profile
                    }
                )
                
                accountActionRow(
                    title: "更改密码",
                    icon: "key.fill",
                    action: {
                        // TODO: Implement change password
                    }
                )
                
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
                
                accountActionRow(
                    title: "退出登录",
                    icon: "rectangle.portrait.and.arrow.right",
                    textColor: .red,
                    action: {
                        // TODO: Implement logout
                    }
                )
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