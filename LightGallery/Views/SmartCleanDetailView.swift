//
//  SmartCleanDetailView.swift
//  LightGallery
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI
import Photos

struct SmartCleanDetailView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let category: SmartCleanCategory
    @ObservedObject var viewModel: SmartCleanViewModel
    
    @State private var isSelecting = false
    @State private var selectedIds: Set<String> = []
    @State private var showSwipeReview = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(category.assets) { asset in
                        if isSelecting {
                            PhotoThumbnailView(
                                asset: asset.phAsset,
                                isSelected: selectedIds.contains(asset.id),
                                isSelecting: true
                            ) {
                                toggleSelection(asset.id)
                            }
                        } else {
                            NavigationLink(destination: PhotoPreviewView(asset: asset.phAsset)) {
                                PhotoThumbnailView(
                                    asset: asset.phAsset,
                                    isSelected: false,
                                    isSelecting: false
                                ) {
                                    // No-op, NavigationLink handles tap
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            // Bottom Bar
            if isSelecting && !selectedIds.isEmpty {
                VStack {
                    Divider()
                    Button(action: {
                        deleteSelected()
                    }) {
                        Text("Delete".localized + " \(selectedIds.count) " + "Photos".localized) // Simplified
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                            .padding()
                    }
                }
                .background(Color(uiColor: .systemBackground))
            }
        }
        .navigationTitle(category.type.rawValue.localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    if !isSelecting {
                        Button(action: {
                            showSwipeReview = true
                        }) {
                            Image(systemName: "rectangle.stack")
                        }
                    }
                    
                    Button(isSelecting ? "Done".localized : "Select".localized) {
                        isSelecting.toggle()
                        if !isSelecting {
                            selectedIds.removeAll()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSwipeReview) {
            SwipeReviewView(assets: category.assets) { deletedAssets in
                viewModel.deleteAssets(deletedAssets, from: category.type)
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
    
    private func deleteSelected() {
        let assetsToDelete = category.assets.filter { selectedIds.contains($0.id) }
        viewModel.deleteAssets(assetsToDelete, from: category.type)
        isSelecting = false
        selectedIds.removeAll()
    }
}
