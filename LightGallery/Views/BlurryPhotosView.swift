//
//  BlurryPhotosView.swift
//  LightGallery
//
//  Created by Claude on 2025/12/27.
//

import SwiftUI
import Photos

struct BlurryPhotosView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var viewModel = BlurryPhotosViewModel()
    @StateObject private var featureAccessManager = FeatureAccessManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Analyzing photos...".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("This may take a moment".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if viewModel.photos.isEmpty {
                    ContentUnavailableView(
                        "All Clear!".localized,
                        systemImage: "camera.aperture",
                        description: Text("No blurry photos found.".localized)
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Summary Card
                            BlurrySummaryCard(viewModel: viewModel)

                            // Selection Controls
                            HStack {
                                Text("\(viewModel.photos.count) " + "blurry photos".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Button(action: {
                                    if viewModel.selectedCount == viewModel.photos.count {
                                        viewModel.deselectAll()
                                    } else {
                                        viewModel.selectAll()
                                    }
                                }) {
                                    Text(viewModel.selectedCount == viewModel.photos.count ? "Deselect All".localized : "Select All".localized)
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)

                            // Photo Grid
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)
                            ], spacing: 8) {
                                ForEach(viewModel.photos) { photo in
                                    BlurryPhotoCell(
                                        photo: photo,
                                        isSelected: viewModel.selectedPhotos.contains(photo.id),
                                        onTap: { viewModel.toggleSelection(photo) },
                                        onDelete: { viewModel.deletePhoto(photo) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .padding(.bottom, 80) // Space for bottom bar
                    }

                    // Bottom Action Bar
                    if viewModel.selectedCount > 0 {
                        VStack {
                            Spacer()
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(viewModel.selectedCount) " + "selected".localized)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(viewModel.formattedSelectedSize)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button(action: {
                                    viewModel.showDeleteConfirmation = true
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Delete".localized)
                                    }
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.red)
                                    .cornerRadius(24)
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                        }
                    }
                }
            }
            .navigationTitle("Blurry Photos".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if featureAccessManager.canAccessFeature(.smartClean) {
                    viewModel.scan()
                } else {
                    showPaywall = true
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(feature: .smartClean)
            }
            .alert("Delete Blurry Photos?".localized, isPresented: $viewModel.showDeleteConfirmation) {
                Button("Delete".localized, role: .destructive) {
                    viewModel.deleteSelected()
                }
                Button("Cancel".localized, role: .cancel) {}
            } message: {
                Text("Delete \(viewModel.selectedCount) blurry photos? This action cannot be undone.".localized)
            }
        }
    }
}

// MARK: - Summary Card
struct BlurrySummaryCard: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @ObservedObject var viewModel: BlurryPhotosViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Space to Free".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.formattedTotalSize)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.purple)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: "camera.metering.unknown")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
            }

            // Blur Level Legend
            HStack(spacing: 16) {
                BlurLevelIndicator(level: .veryBlurry, count: viewModel.photos.filter { $0.blurLevel == .veryBlurry }.count)
                BlurLevelIndicator(level: .blurry, count: viewModel.photos.filter { $0.blurLevel == .blurry }.count)
                BlurLevelIndicator(level: .slightlyBlurry, count: viewModel.photos.filter { $0.blurLevel == .slightlyBlurry }.count)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Blur Level Indicator
struct BlurLevelIndicator: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let level: BlurryPhoto.BlurLevel
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(level.color))
                .frame(width: 8, height: 8)
            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
            Text(level.rawValue.localized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Photo Cell
struct BlurryPhotoCell: View {
    let photo: BlurryPhoto
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Photo
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
            }
            .frame(height: 120)
            .cornerRadius(12)
            .clipped()

            // Blur indicator
            VStack {
                Spacer()
                HStack {
                    Circle()
                        .fill(Color(photo.blurLevel.color))
                        .frame(width: 8, height: 8)
                    Spacer()
                }
                .padding(8)
            }

            // Selection checkbox
            Button(action: onTap) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color.black.opacity(0.3))
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(8)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
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

        manager.requestImage(
            for: photo.asset.phAsset,
            targetSize: CGSize(width: 240, height: 240),
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            self.image = result
        }
    }
}

#Preview {
    BlurryPhotosView()
}
