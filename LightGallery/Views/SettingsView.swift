//
//  SettingsView.swift
//  LightGallery
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 60)
                            Image(systemName: "person.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("LightGallery Pro")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("Upgrade Plan".localized)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
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
                    
                    NavigationLink {
                        Text("Privacy Policy Content")
                            .navigationTitle("Privacy Policy".localized)
                    } label: {
                        Label("Privacy Policy".localized, systemImage: "hand.raised.fill")
                    }
                    
                    NavigationLink {
                        Text("Terms of Service Content")
                            .navigationTitle("Terms of Service".localized)
                    } label: {
                        Label("Terms of Service".localized, systemImage: "doc.text.fill")
                    }
                }
                
                // Support
                Section(header: Text("Support".localized)) {
                    NavigationLink {
                        Text("Help Center Content")
                            .navigationTitle("Help Center".localized)
                    } label: {
                        Label("Help Center".localized, systemImage: "questionmark.circle.fill")
                    }
                    
                    Button {
                        // Rate app action
                    } label: {
                        Label("Rate This App".localized, systemImage: "star.fill")
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
