//
//  SimilarPhotoGroupView.swift
//  Declutter
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI
import Photos

struct SimilarPhotoGroupView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Binding var group: SimilarPhotoGroup
    var onMerge: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(groupDateString)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("\(group.assets.count) " + "photos".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    onMerge()
                }) {
                    Text("Merge".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal)
            
            // Photos Grid/Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(group.assets) { asset in
                        SimilarPhotoItemView(
                            asset: asset,
                            isBestShot: group.bestShot?.id == asset.id,
                            isSelectedForDeletion: group.selectedForDeletion.contains(asset.id),
                            onTap: {
                                toggleSelection(for: asset)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(backgroundColor)
        .cornerRadius(16)
    }
    
    private var backgroundColor: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemBackground)
        #elseif canImport(AppKit)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }
    
    private var groupDateString: String {
        guard let first = group.assets.first else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let localeIdentifier = (localizationManager.language == .simplifiedChinese || localizationManager.language == .traditionalChinese) ? "zh_CN" : "en_US"
        formatter.locale = Locale(identifier: localeIdentifier)
        return formatter.string(from: first.creationDate)
    }
    
    private func toggleSelection(for asset: PhotoAsset) {
        if group.selectedForDeletion.contains(asset.id) {
            group.selectedForDeletion.remove(asset.id)
        } else {
            group.selectedForDeletion.insert(asset.id)
            if group.bestShot?.id == asset.id {
                group.bestShot = nil
            }
        }
    }
}

struct SimilarPhotoItemView: View {
    let asset: PhotoAsset
    let isBestShot: Bool
    let isSelectedForDeletion: Bool
    let onTap: () -> Void
    
    @State private var image: PlatformImage?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Image
            Group {
                if let image = image {
                    #if os(iOS)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    #elseif os(macOS)
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    #endif
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: 120, height: 160)
            .cornerRadius(12)
            .clipped()
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isBestShot ? Color.yellow : (isSelectedForDeletion ? Color.red : Color.clear), lineWidth: 3)
            )
            .onTapGesture {
                onTap()
            }
            
            // Badges
            if isBestShot {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .padding(6)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .padding(4)
            } else if isSelectedForDeletion {
                Image(systemName: "trash.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                    .background(Color.white.clipShape(Circle()))
                    .padding(4)
            } else {
                Image(systemName: "circle")
                    .font(.title2)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                    .padding(4)
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        
        manager.requestImage(for: asset.phAsset, targetSize: CGSize(width: 240, height: 320), contentMode: .aspectFill, options: options) { result, _ in
            #if os(iOS)
            self.image = result
            #elseif os(macOS)
            self.image = result
            #endif
        }
    }
}
