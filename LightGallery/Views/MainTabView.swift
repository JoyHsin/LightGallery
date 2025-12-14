//
//  MainTabView.swift
//  LightGallery
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    @EnvironmentObject var loginPromptManager: LoginPromptManager
    @State private var selectedTab = 0
    @State private var showRenewalPrompt = false
    @State private var showPaywall = false
    @State private var paywallFeature: PremiumFeature?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home".localized)
                }
                .tag(0)
            
            GalleryView()
                .tabItem {
                    Image(systemName: "square.stack.fill")
                    Text("Gallery".localized)
                }
                .tag(1)
            
            ToolsView()
                .tabItem {
                    Image(systemName: "wand.and.stars")
                    Text("Tools".localized)
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings".localized)
                }
                .tag(3)
        }
        .tint(.blue)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .onReceive(NotificationCenter.default.publisher(for: .subscriptionExpired)) { _ in
            // Show renewal prompt when subscription expires
            if subscriptionViewModel.isSubscriptionExpired {
                showRenewalPrompt = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showPaywall)) { notification in
            // Handle paywall display for features
            if let feature = notification.userInfo?["feature"] as? PremiumFeature {
                paywallFeature = feature
                showPaywall = true
            }
        }
        .sheet(isPresented: $showRenewalPrompt) {
            if let expiredSubscription = subscriptionViewModel.currentSubscription {
                RenewalPromptView(expiredSubscription: expiredSubscription)
                    .environmentObject(subscriptionViewModel)
            }
        }
        .sheet(isPresented: $showPaywall) {
            if let feature = paywallFeature {
                PaywallView(feature: feature)
            }
        }
        .alert(loginPromptManager.alertTitle, isPresented: $loginPromptManager.showLoginAlert) {
            Button("取消", role: .cancel) {
                loginPromptManager.cancelLogin()
            }
            Button("去登录") {
                loginPromptManager.showLogin()
            }
        } message: {
            Text(loginPromptManager.alertMessage)
        }
        .sheet(isPresented: $loginPromptManager.showLoginView) {
            LoginView()
                .onDisappear {
                    // Check if user logged in successfully
                    if AuthenticationService.shared.getCurrentUser() != nil {
                        loginPromptManager.handleLoginSuccess()
                    } else {
                        loginPromptManager.cancelLogin()
                    }
                }
        }
    }
}

#Preview {
    MainTabView()
}
