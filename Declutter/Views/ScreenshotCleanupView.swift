//
//  ScreenshotCleanupView.swift
//  Declutter
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI
import Photos

struct ScreenshotCleanupView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ScreenshotCleanupViewModel()
    
    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 2)
    ]
    
    @State private var showSwipeReview = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading screenshots...".localized)
                } else if viewModel.screenshots.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No screenshots found".localized)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Grid View
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(viewModel.screenshots) { asset in
                                    ScreenshotItemView(
                                        asset: asset,
                                        isSelected: viewModel.selectedIDs.contains(asset.id)
                                    )
                                    .onTapGesture {
                                        viewModel.toggleSelection(for: asset.id)
                                    }
                                }
                            }
                            .padding(.top, 2)
                        }
                        
                        // Bottom Toolbar
                        VStack(spacing: 0) {
                            Divider()
                            HStack {
                                Button(action: {
                                    viewModel.toggleSelectAll()
                                }) {
                                    Text(viewModel.isAllSelected ? "Deselect All".localized : "Select All".localized)
                                }
                                
                                Spacer()
                                
                                Text("Selected items".localized + " \(viewModel.selectedIDs.count)")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.deleteSelected()
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(viewModel.selectedIDs.isEmpty ? .gray : .red)
                                }
                                .disabled(viewModel.selectedIDs.isEmpty)
                            }
                            .padding()
                            .background(backgroundColor)
                        }
                    }
                }
            }
            .navigationTitle("Screenshot Cleanup".localized)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if !viewModel.screenshots.isEmpty {
                        Button(action: {
                            showSwipeReview = true
                        }) {
                            Image(systemName: "rectangle.stack")
                        }
                    }
                }
            }
            .sheet(isPresented: $showSwipeReview) {
                SwipeReviewView(assets: viewModel.screenshots) { deletedAssets in
                    viewModel.deleteAssets(deletedAssets)
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadScreenshots()
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #elseif canImport(AppKit)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.white
        #endif
    }
}

struct ScreenshotItemView: View {
    let asset: PhotoAsset
    let isSelected: Bool
    @State private var image: PlatformImage?
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                if let image = image {
                    #if os(iOS)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                    #elseif os(macOS)
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                    #endif
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .background(Color.white.clipShape(Circle()))
                        .padding(4)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                        .padding(4)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
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
        
        manager.requestImage(for: asset.phAsset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFill, options: options) { result, _ in
            #if os(iOS)
            self.image = result
            #elseif os(macOS)
            self.image = result
            #endif
        }
    }
}

class ScreenshotCleanupViewModel: ObservableObject {
    @Published var screenshots: [PhotoAsset] = []
    @Published var selectedIDs: Set<String> = []
    @Published var isLoading = true
    
    private let photoService = PhotoService()
    
    var isAllSelected: Bool {
        return !screenshots.isEmpty && selectedIDs.count == screenshots.count
    }
    
    func loadScreenshots() async {
        await MainActor.run { isLoading = true }
        do {
            let assets = try await photoService.fetchScreenshots()
            await MainActor.run {
                self.screenshots = assets
                self.isLoading = false
            }
        } catch {
            print("Failed to fetch screenshots: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
    
    func toggleSelection(for id: String) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }
    
    func toggleSelectAll() {
        if isAllSelected {
            selectedIDs.removeAll()
        } else {
            selectedIDs = Set(screenshots.map { $0.id })
        }
    }
    
    func deleteSelected() {
        let idsToDelete = selectedIDs
        guard !idsToDelete.isEmpty else { return }
        
        // Find assets to delete
        let assetsToDelete = screenshots.filter { idsToDelete.contains($0.id) }
        deleteAssets(assetsToDelete)
    }
    
    func deleteAssets(_ assets: [PhotoAsset]) {
        guard !assets.isEmpty else { return }
        
        Task {
            do {
                try await photoService.deletePhotos(assets)
                
                // Wait a bit before reloading
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await loadScreenshots()
                await MainActor.run {
                    selectedIDs.removeAll()
                }
            } catch {
                print("Deletion failed: \(error)")
            }
        }
    }
}
