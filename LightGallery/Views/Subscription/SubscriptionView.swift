//
//  SubscriptionView.swift
//  LightGallery
//
//  Created for user-auth-subscription feature
//

import SwiftUI

struct SubscriptionView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Current Subscription Status
                    if let subscription = viewModel.currentSubscription {
                        currentSubscriptionSection(subscription)
                    }
                    
                    // Available Products
                    productsSection
                    
                    // Restore Purchases Button
                    restorePurchasesButton
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        errorSection(errorMessage)
                    }
                }
                .padding()
            }
            .navigationTitle("订阅管理")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
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
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("升级到高级版")
                .font(.title)
                .fontWeight(.bold)
            
            Text("解锁所有高级功能，提升照片管理体验")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    // MARK: - Current Subscription Section
    
    private func currentSubscriptionSection(_ subscription: Subscription) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text("当前订阅")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("套餐:")
                        .foregroundColor(.secondary)
                    Text(subscription.tier.displayName)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("计费周期:")
                        .foregroundColor(.secondary)
                    Text(subscription.billingPeriod.displayName)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("到期时间:")
                        .foregroundColor(.secondary)
                    Text(subscription.expiryDate, style: .date)
                        .fontWeight(.semibold)
                }
                
                if subscription.daysRemaining > 0 {
                    HStack {
                        Text("剩余天数:")
                            .foregroundColor(.secondary)
                        Text("\(subscription.daysRemaining) 天")
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Products Section
    
    private var productsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("选择订阅套餐")
                .font(.headline)
            
            ForEach(groupedProducts(), id: \.tier) { group in
                tierSection(tier: group.tier, products: group.products)
            }
        }
    }
    
    private func tierSection(tier: SubscriptionTier, products: [SubscriptionProduct]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(tier.displayName)
                    .font(.title3)
                    .fontWeight(.bold)
                
                // Highlight current tier
                if viewModel.currentSubscription?.tier == tier {
                    Text("当前")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            
            // Show Free tier info
            if tier == .free {
                freeTierCard()
            } else {
                ForEach(products) { product in
                    productCard(product)
                }
            }
        }
    }
    
    private func freeTierCard() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("基础功能")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("免费使用基本照片管理功能")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text("免费")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray, lineWidth: 1)
                )
        )
    }
    
    private func productCard(_ product: SubscriptionProduct) -> some View {
        let isCurrentSubscription = viewModel.currentSubscription?.tier == product.tier &&
                                   viewModel.currentSubscription?.billingPeriod == product.billingPeriod
        
        return Button {
            Task {
                await viewModel.purchase(product)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayTitle)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if isCurrentSubscription {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                    
                    Text(product.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if product.billingPeriod == .yearly {
                        Text("节省 17%")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCurrentSubscription ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isCurrentSubscription ? Color.green : Color.blue, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isCurrentSubscription)
    }
    
    // MARK: - Restore Purchases Button
    
    private var restorePurchasesButton: some View {
        Button {
            Task {
                await viewModel.restorePurchases()
            }
        } label: {
            Text("恢复购买")
                .font(.subheadline)
                .foregroundColor(.blue)
        }
        .padding(.top)
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
    
    // MARK: - Helper Methods
    
    private func groupedProducts() -> [(tier: SubscriptionTier, products: [SubscriptionProduct])] {
        let tiers: [SubscriptionTier] = [.free, .pro, .max]
        return tiers.map { tier in
            let products = viewModel.availableProducts.filter { $0.tier == tier }
            return (tier, products)
        }
    }
}

#Preview {
    SubscriptionView()
}
