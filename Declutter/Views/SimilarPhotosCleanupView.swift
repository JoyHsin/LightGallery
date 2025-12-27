//
//  SimilarPhotosCleanupView.swift
//  Declutter
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI
import Photos

struct SimilarPhotosCleanupView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SimilarPhotosViewModel()
    @StateObject private var featureAccessManager = FeatureAccessManager.shared
    @State private var showPaywall = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Scanning for similar photos...".localized)
                            .foregroundColor(.secondary)
                        Text("This may take a while depending on your library size".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if viewModel.groups.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("No similar photos found".localized)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Your library is clean!".localized)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack {
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                ForEach($viewModel.groups) { $group in
                                    SimilarPhotoGroupView(
                                        group: $group,
                                        onMerge: {
                                            viewModel.mergeGroup(group)
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top)
                        }
                        
                        // Bottom Action Bar
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("To Delete".localized + ": \(viewModel.totalSelectedCount) " + "photos".localized)
                                        .font(.headline)
                                    Text("Space to free: Calculating...".localized) // In a real app we'd calc size
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.deleteSelectedPhotos()
                                }) {
                                    Text("Delete Selected".localized + " (\(viewModel.totalSelectedCount))")
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(viewModel.totalSelectedCount > 0 ? Color.red : Color.gray)
                                        .cornerRadius(24)
                                }
                                .disabled(viewModel.totalSelectedCount == 0)
                            }
                            .padding()
                            .background(backgroundColor)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -5)
                        }
                    }
                }
            }
            .navigationTitle("Similar Photo Cleanup".localized)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
            }
            .task {
                // Check access before scanning
                if featureAccessManager.canAccessFeature(.similarPhotoCleanup) {
                    await viewModel.scanForSimilarPhotos()
                } else {
                    showPaywall = true
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(feature: .similarPhotoCleanup)
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

class SimilarPhotosViewModel: ObservableObject {
    @Published var groups: [SimilarPhotoGroup] = []
    @Published var isLoading = true
    
    private let analysisService = PhotoAnalysisService()
    private let photoService = PhotoService() // Reuse existing service for fetching assets
    
    var totalSelectedCount: Int {
        groups.reduce(0) { $0 + $1.selectedForDeletion.count }
    }
    
    func scanForSimilarPhotos() async {
        await MainActor.run { isLoading = true }
        
        // 1. Fetch all photos (or recent ones)
        // For demo performance, let's limit to recent 500 photos or so, or fetch all if fast enough
        // We need a method in PhotoService to fetch all assets as PhotoAsset
        // Since PhotoService uses PHFetchResult, we might need to adapt.
        
        // Let's quickly fetch assets here or add a method to PhotoService.
        // For now, I'll do a quick fetch here to keep it self-contained, 
        // but ideally we should move this to PhotoService.
        let assets = await fetchRecentAssets()
        
        // 2. Analyze
        let foundGroups = await analysisService.groupSimilarPhotos(assets: assets)
        
        await MainActor.run {
            self.groups = foundGroups
            self.isLoading = false
        }
    }
    
    func deleteSelectedPhotos() {
        let idsToDelete = groups.flatMap { $0.selectedForDeletion }
        guard !idsToDelete.isEmpty else { return }
        
        PHPhotoLibrary.shared().performChanges {
            let assetsToDelete = PHAsset.fetchAssets(withLocalIdentifiers: idsToDelete, options: nil)
            PHAssetChangeRequest.deleteAssets(assetsToDelete)
        } completionHandler: { success, error in
            if success {
                DispatchQueue.main.async {
                    // Re-scan for correctness after deletion
                    Task {
                        await self.scanForSimilarPhotos()
                    }
                }
            } else {
                print("Deletion failed: \(String(describing: error))")
            }
        }
    }
    
    private func fetchRecentAssets() async -> [PhotoAsset] {
        // Fetch more photos to find similarities
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1000 // Increased from 200 to 1000
        
        let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var assets: [PhotoAsset] = []
        
        result.enumerateObjects { asset, _, _ in
            assets.append(PhotoAsset(phAsset: asset))
        }
        
        return assets
    }
    
    func mergeGroup(_ group: SimilarPhotoGroup) {
        // Keep best shot, delete others
        guard let bestShot = group.bestShot else { return }
        
        let assetsToDelete = group.assets.filter { $0.id != bestShot.id }
        let idsToDelete = assetsToDelete.map { $0.id }
        
        guard !idsToDelete.isEmpty else { return }
        
        PHPhotoLibrary.shared().performChanges {
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: idsToDelete, options: nil)
            PHAssetChangeRequest.deleteAssets(assets)
        } completionHandler: { success, error in
            if success {
                DispatchQueue.main.async {
                    // Remove the group from UI
                    self.groups.removeAll { $0.id == group.id }
                }
            }
        }
    }
}
