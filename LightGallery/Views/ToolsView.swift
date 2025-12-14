//
//  ToolsView.swift
//  LightGallery
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI

struct ToolsView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var featureAccessManager = FeatureAccessManager.shared

    
    var body: some View {
        NavigationStack {
            List {

                
                Section {
                    NavigationLink {
                        if featureAccessManager.canAccessFeature(.privacyWiper) {
                            PrivacyWiperView()
                        } else {
                            PaywallView(feature: .privacyWiper)
                        }
                    } label: {
                        ToolRow(
                            title: "Privacy Wiper".localized,
                            subtitle: "Remove location & device info".localized,
                            iconName: "shield.slash.fill",
                            iconColor: .purple,
                            isLocked: featureAccessManager.isFeatureLocked(.privacyWiper)
                        )
                    }
                    
                    NavigationLink {
                        if featureAccessManager.canAccessFeature(.idPhotoEditor) {
                            IDPhotoEditorView()
                        } else {
                            PaywallView(feature: .idPhotoEditor)
                        }
                    } label: {
                        ToolRow(
                            title: "Smart ID Photo".localized,
                            subtitle: "Create compliant ID photos".localized,
                            iconName: "person.crop.rectangle.badge.plus",
                            iconColor: .blue,
                            isLocked: featureAccessManager.isFeatureLocked(.idPhotoEditor)
                        )
                    }
                    
                    NavigationLink {
                        if featureAccessManager.canAccessFeature(.livePhotoConverter) {
                            LivePhotoConverterView()
                        } else {
                            PaywallView(feature: .livePhotoConverter)
                        }
                    } label: {
                        ToolRow(
                            title: "Live Photo Converter".localized,
                            subtitle: "Convert to Video/GIF".localized,
                            iconName: "livephoto",
                            iconColor: .yellow,
                            isLocked: featureAccessManager.isFeatureLocked(.livePhotoConverter)
                        )
                    }
                    
                    NavigationLink {
                        if featureAccessManager.canAccessFeature(.screenshotStitcher) {
                            LongScreenshotStitcherView()
                        } else {
                            PaywallView(feature: .screenshotStitcher)
                        }
                    } label: {
                        ToolRow(
                            title: "Stitcher".localized,
                            subtitle: "Combine screenshots".localized,
                            iconName: "rectangle.stack.fill",
                            iconColor: .green,
                            isLocked: featureAccessManager.isFeatureLocked(.screenshotStitcher)
                        )
                    }
                    
                    NavigationLink {
                        if featureAccessManager.canAccessFeature(.photoEnhancer) {
                            EnhancerView()
                        } else {
                            PaywallView(feature: .photoEnhancer)
                        }
                    } label: {
                        ToolRow(
                            title: "AI Enhancer".localized,
                            subtitle: "Upscale and restore".localized,
                            iconName: "wand.and.stars",
                            iconColor: .pink,
                            isLocked: featureAccessManager.isFeatureLocked(.photoEnhancer)
                        )
                    }
                    
                    NavigationLink {
                        if featureAccessManager.canAccessFeature(.formatConverter) {
                            FormatConverterView()
                        } else {
                            PaywallView(feature: .formatConverter)
                        }
                    } label: {
                        ToolRow(
                            title: "Format Converter".localized,
                            subtitle: "HEIC to JPEG/PNG".localized,
                            iconName: "arrow.triangle.2.circlepath",
                            iconColor: .orange,
                            isLocked: featureAccessManager.isFeatureLocked(.formatConverter)
                        )
                    }
                    
                    ToolRow(
                        title: "Secret Space".localized,
                        subtitle: "Hide private photos".localized,
                        iconName: "lock.fill",
                        iconColor: .gray
                    )
                    

                }
                

            }
            .navigationTitle("Tools".localized)

        }
    }

}

// MARK: - Tool Row
struct ToolRow: View {
    let title: String
    let subtitle: String
    let iconName: String
    let iconColor: Color
    var isDisabled: Bool = false
    var isLocked: Bool = false
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor)
                    .frame(width: 40, height: 40)
                Image(systemName: iconName)
                    .foregroundColor(.white)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isLocked ? .secondary : .primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            } else if isDisabled {
                Text("Soon".localized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray)
                    .cornerRadius(8)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .opacity(isDisabled ? 0.6 : 1)
        .padding(.vertical, 4)
    }
}

#Preview {
    ToolsView()
}
