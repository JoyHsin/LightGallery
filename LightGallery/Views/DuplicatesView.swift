//
//  DuplicatesView.swift
//  LightGallery
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI
import Photos

struct DuplicatesView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var viewModel = DuplicatesViewModel()
    @StateObject private var featureAccessManager = FeatureAccessManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showPaywall = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Scanning for duplicates...".localized)
                } else if viewModel.groups.isEmpty {
                    ContentUnavailableView(
                        "No Duplicates".localized,
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("Your library is free of duplicates.".localized)
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(viewModel.groups) { group in
                                DuplicateGroupCard(group: group) {
                                    viewModel.mergeGroup(group)
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom, 80) // Space for bottom bar
                    }
                }
                
                // Bottom Bar
                if !viewModel.groups.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Text("\(viewModel.groups.count) " + "Sets Found".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button(action: {
                                viewModel.showMergeConfirmation = true
                            }) {
                                Text("Merge All".localized)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .cornerRadius(24)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                    }
                }
            }
            .navigationTitle("Duplicates".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Check access before scanning
                if featureAccessManager.canAccessFeature(.duplicateDetection) {
                    viewModel.scan()
                } else {
                    showPaywall = true
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(feature: .duplicateDetection)
            }
            .alert("Merge All Duplicates?".localized, isPresented: $viewModel.showMergeConfirmation) {
                Button("Merge".localized, role: .destructive) {
                    viewModel.mergeAll()
                }
                Button("Cancel".localized, role: .cancel) {}
            } message: {
                Text("This will keep one version of each set and delete the rest. This action cannot be undone.".localized)
            }
        }
    }
}

struct DuplicateGroupCard: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let group: DuplicateGroup
    let onMerge: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.dateString)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("\(group.assets.count) " + "photos".localized) // Simplified
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onMerge) {
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
            
            // Photos Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(group.assets) { asset in
                        DuplicatePhotoItem(asset: asset)
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct DuplicatePhotoItem: View {
    let asset: PhotoAsset
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 140)
                    .cornerRadius(12)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .cornerRadius(12)
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
        
        manager.requestImage(for: asset.phAsset, targetSize: CGSize(width: 280, height: 280), contentMode: .aspectFill, options: options) { result, _ in
            self.image = result
        }
    }
}
