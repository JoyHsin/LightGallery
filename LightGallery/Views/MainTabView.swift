//
//  MainTabView.swift
//  LightGallery
//
//  Created by Antigravity on 2025/12/05.
//  Lite version - No subscription or login prompts
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedTab = 0

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
    }
}

#Preview {
    MainTabView()
}
