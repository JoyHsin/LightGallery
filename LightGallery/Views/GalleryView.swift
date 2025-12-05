//
//  GalleryView.swift
//  LightGallery
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI
import Photos

struct GalleryView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var photosByDate: [(String, [PHAsset])] = []
    @State private var isLoading = true
    @State private var isSelecting = false
    @State private var selectedIds: Set<String> = []
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading photos...".localized)
                } else if photosByDate.isEmpty {
                    ContentUnavailableView(
                        "No Photos",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("Your photo library is empty.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(photosByDate, id: \.0) { dateString, assets in
                                Section {
                                    LazyVGrid(columns: columns, spacing: 2) {
                                        ForEach(assets, id: \.localIdentifier) { asset in
                                            PhotoThumbnailView(
                                                asset: asset,
                                                isSelected: selectedIds.contains(asset.localIdentifier),
                                                isSelecting: isSelecting
                                            ) {
                                                if isSelecting {
                                                    toggleSelection(asset.localIdentifier)
                                                }
                                            }
                                        }
                                    }
                                } header: {
                                    Text(dateString)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal)
                                        .padding(.top, 8)
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Gallery".localized)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSelecting ? "Done".localized : "Select".localized) {
                        isSelecting.toggle()
                        if !isSelecting {
                            selectedIds.removeAll()
                        }
                    }
                }
            }
            .onAppear {
                loadPhotos()
            }
        }
    }
    
    private func toggleSelection(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }
    
    private func loadPhotos() {
        Task {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.fetchLimit = 500
            
            let result = PHAsset.fetchAssets(with: .image, options: options)
            var grouped: [String: [PHAsset]] = [:]
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = Locale(identifier: "zh_CN")
            
            result.enumerateObjects { asset, _, _ in
                let dateKey = formatter.string(from: asset.creationDate ?? Date())
                grouped[dateKey, default: []].append(asset)
            }
            
            // Sort by date (most recent first)
            let sorted = grouped.sorted { lhs, rhs in
                let lhsDate = grouped[lhs.key]?.first?.creationDate ?? Date.distantPast
                let rhsDate = grouped[rhs.key]?.first?.creationDate ?? Date.distantPast
                return lhsDate > rhsDate
            }
            
            await MainActor.run {
                photosByDate = sorted
                isLoading = false
            }
        }
    }
}

// MARK: - Photo Thumbnail
struct PhotoThumbnailView: View {
    let asset: PHAsset
    let isSelected: Bool
    let isSelecting: Bool
    let onTap: () -> Void
    
    @State private var image: UIImage?
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                
                if isSelecting {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 24, height: 24)
                        if isSelected {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 24, height: 24)
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(6)
                    .shadow(radius: 2)
                    .transition(.scale)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelecting)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isSelected)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        
        manager.requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: options) { result, _ in
            self.image = result
        }
    }
}

#Preview {
    GalleryView()
}
