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
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings".localized)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

#Preview {
    SettingsView()
}
