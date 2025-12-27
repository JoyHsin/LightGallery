//
//  RenewalPromptView.swift
//  Declutter
//
//  Created for user-auth-subscription feature
//

import SwiftUI

/// View shown to users when their subscription has expired
struct RenewalPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionViewModel: SubscriptionViewModel
    
    let expiredSubscription: Subscription
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Expired icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .padding(.bottom, 8)
                
                // Title
                Text("订阅已过期")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Message
                VStack(spacing: 12) {
                    Text("您的 \(expiredSubscription.tier.displayName) 订阅已于 \(formattedDate(expiredSubscription.expiryDate)) 过期")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("续订以继续使用高级功能")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Renewal options
                VStack(spacing: 16) {
                    // Renew button
                    Button(action: {
                        dismiss()
                        // Navigate to subscription view
                        NotificationCenter.default.post(
                            name: .showSubscriptionView,
                            object: nil
                        )
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("立即续订")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    // Dismiss button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("稍后提醒")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let showSubscriptionView = Notification.Name("showSubscriptionView")
}

#Preview {
    RenewalPromptView(
        expiredSubscription: Subscription(
            userId: "test_user",
            tier: .pro,
            billingPeriod: .monthly,
            status: .expired,
            startDate: Date().addingTimeInterval(-60 * 60 * 24 * 30),
            expiryDate: Date().addingTimeInterval(-60 * 60 * 24),
            paymentMethod: .appleIAP
        )
    )
    .environmentObject(SubscriptionViewModel())
}
