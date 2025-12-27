//
//  SettingsView.swift
//  Declutter
//
//  Created by Antigravity on 2025/12/05.
//  Lite version - No subscription or profile management
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    var body: some View {
        NavigationStack {
            List {
                // Preferences
                Section(header: Text("Preferences".localized)) {
                    Picker(selection: $localizationManager.language) {
                        ForEach(Language.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    } label: {
                        Label("Language".localized, systemImage: "globe")
                    }

                    Toggle(isOn: $isDarkMode) {
                        Label("Dark Mode".localized, systemImage: "moon.fill")
                    }

                    Toggle(isOn: $notificationsEnabled) {
                        Label("Notifications".localized, systemImage: "bell.fill")
                    }
                }

                // About
                Section(header: Text("About".localized)) {
                    HStack {
                        Label("Version".localized, systemImage: "info.circle")
                        Spacer()
                        Text("2.0.0")
                            .foregroundColor(.secondary)
                    }

                    // Privacy Policy (App Store Guideline 5.1.1 Compliance)
                    Button {
                        openURL(AppConstants.privacyPolicyURL)
                    } label: {
                        HStack {
                            Label("Privacy Policy".localized, systemImage: "hand.raised.fill")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }

                    // Terms of Service
                    Button {
                        openURL(AppConstants.termsOfServiceURL)
                    } label: {
                        HStack {
                            Label("Terms of Service".localized, systemImage: "doc.text.fill")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Support
                Section(header: Text("Support".localized)) {
                    Button {
                        openURL(AppConstants.supportURL)
                    } label: {
                        HStack {
                            Label("Help Center".localized, systemImage: "questionmark.circle.fill")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        openURL(AppConstants.appStoreReviewURL)
                    } label: {
                        Label("Rate This App".localized, systemImage: "star.fill")
                    }
                }
            }
            .navigationTitle("Settings".localized)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    // MARK: - Helper Methods

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }
}

#Preview {
    SettingsView()
}
