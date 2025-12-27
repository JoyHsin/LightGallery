//
//  PaywallView.swift
//  Declutter
//
//  Created for user-auth-subscription feature
//

import SwiftUI

struct PaywallView: View {
    let feature: PremiumFeature
    @StateObject private var viewModel = SubscriptionViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Expired subscription banner
                    if viewModel.isSubscriptionExpired {
                        expiredBanner
                    }
                    
                    // Feature Icon
                    featureIcon
                    
                    // Feature Description
                    featureDescription
                    
                    // Feature Comparison
                    featureComparison
                    
                    // Subscription Options
                    subscriptionOptions
                    
                    // Subscription Terms (App Store Guideline 3.1.2 Compliance)
                    subscriptionTerms
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        errorSection(errorMessage)
                    }
                }
                .padding()
            }
            .navigationTitle(viewModel.isSubscriptionExpired ? "续订订阅" : "升级解锁")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
        .task {
            await viewModel.loadProducts()
            await viewModel.checkSubscriptionStatus()
        }
    }
    
    // MARK: - Expired Banner
    
    private var expiredBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("订阅已过期")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("续订以继续使用高级功能")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Feature Icon
    
    private var featureIcon: some View {
        VStack(spacing: 16) {
            Image(systemName: featureIconName)
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text(feature.displayName)
                .font(.title)
                .fontWeight(.bold)
        }
        .padding(.top, 32)
    }
    
    // MARK: - Feature Description
    
    private var featureDescription: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("功能介绍")
                .font(.headline)
            
            Text(featureDescriptionText)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Feature Comparison
    
    private var featureComparison: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("功能对比")
                .font(.headline)
            
            VStack(spacing: 12) {
                comparisonRow(tier: "免费版", hasFeature: false, description: "基础照片管理")
                comparisonRow(tier: "专业版", hasFeature: true, description: "所有高级功能 + 优先支持")
                comparisonRow(tier: "旗舰版", hasFeature: true, description: "所有高级功能 + 优先支持 + 未来新功能")
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Detailed feature list
            VStack(alignment: .leading, spacing: 8) {
                Text("高级功能包括:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                featureListItem("智能清理")
                featureListItem("重复照片检测")
                featureListItem("相似照片清理")
                featureListItem("照片增强")
                featureListItem("格式转换")
                featureListItem("更多工具...")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func comparisonRow(tier: String, hasFeature: Bool, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: hasFeature ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(hasFeature ? .green : .red)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(tier)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private func featureListItem(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.caption2)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Subscription Options
    
    private var subscriptionOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("选择订阅套餐")
                .font(.headline)
            
            ForEach(viewModel.availableProducts.filter { $0.tier != .free }) { product in
                subscriptionCard(product)
            }
        }
    }
    
    private func subscriptionCard(_ product: SubscriptionProduct) -> some View {
        Button {
            Task {
                await viewModel.purchase(product)
                // Dismiss on successful purchase
                if viewModel.currentSubscription != nil {
                    dismiss()
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.tier.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(product.billingPeriod.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(product.displayPrice)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if product.billingPeriod == .yearly {
                            Text("节省 17%")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
                
                // Features List
                VStack(alignment: .leading, spacing: 8) {
                    featureBullet("解锁所有高级功能")
                    featureBullet("无限制使用")
                    featureBullet("优先客服支持")
                }
                .padding(.top, 8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        product.tier == .max
                            ? LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                product.tier == .max ? Color.purple : Color.blue,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func featureBullet(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Subscription Terms (App Store Guideline 3.1.2 Compliance)
    
    private var subscriptionTerms: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.vertical, 8)
            
            Group {
                Text("• 订阅将自动续订，除非在当前订阅期结束前至少24小时关闭自动续订")
                Text("• 账户将在当前订阅期结束前24小时内按所选套餐价格扣款")
                Text("• 您可以在 App Store 账户设置中管理和取消订阅")
                Text("• 购买后，任何未使用的免费试用期部分将被作废")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                Button("隐私政策") {
                    openURL(AppConstants.privacyPolicyURL)
                }
                
                Button("使用条款") {
                    openURL(AppConstants.termsOfServiceURL)
                }
            }
            .font(.caption)
            .padding(.top, 8)
        }
        .padding(.top, 16)
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }
    
    // MARK: - Error Section
    
    private func errorSection(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Properties
    
    private var featureIconName: String {
        switch feature {
        case .toolbox: return "wrench.and.screwdriver.fill"
        case .smartClean: return "sparkles"
        case .duplicateDetection: return "doc.on.doc.fill"
        case .similarPhotoCleanup: return "photo.stack.fill"
        case .screenshotCleanup: return "camera.viewfinder"
        case .photoEnhancer: return "wand.and.stars"
        case .formatConverter: return "arrow.triangle.2.circlepath"
        case .livePhotoConverter: return "livephoto"
        case .idPhotoEditor: return "person.crop.square.fill"
        case .privacyWiper: return "eye.slash.fill"
        case .screenshotStitcher: return "rectangle.stack.fill"
        }
    }
    
    private var featureDescriptionText: String {
        switch feature {
        case .toolbox:
            return "解锁所有工具箱功能，包括照片增强、格式转换、证件照编辑等强大工具。"
        case .smartClean:
            return "智能分析您的照片库，自动识别可以清理的照片，释放存储空间。"
        case .duplicateDetection:
            return "快速找出重复的照片，帮助您清理冗余内容，节省空间。"
        case .similarPhotoCleanup:
            return "识别相似的照片，让您轻松选择保留最佳的那一张。"
        case .screenshotCleanup:
            return "自动识别截图，批量清理不再需要的截图文件。"
        case .photoEnhancer:
            return "一键增强照片质量，自动调整亮度、对比度和色彩。"
        case .formatConverter:
            return "在不同图片格式之间自由转换，支持 JPEG、PNG、HEIC 等。"
        case .livePhotoConverter:
            return "将 Live Photo 转换为视频或 GIF，方便分享。"
        case .idPhotoEditor:
            return "快速制作标准证件照，支持多种尺寸规格。"
        case .privacyWiper:
            return "安全擦除照片中的敏感信息，保护您的隐私。"
        case .screenshotStitcher:
            return "将多张截图拼接成长图，完整展示内容。"
        }
    }
}

#Preview {
    PaywallView(feature: .smartClean)
}
