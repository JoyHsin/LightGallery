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
    @State private var selectedTab = 0
    @State private var showRenewalPrompt = false
    
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
        .sheet(isPresented: $showRenewalPrompt) {
            if let expiredSubscription = subscriptionViewModel.currentSubscription {
                RenewalPromptView(expiredSubscription: expiredSubscription)
                    .environmentObject(subscriptionViewModel)
            }
        }
    }
}

#Preview {
    MainTabView()
}
