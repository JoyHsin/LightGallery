//
//  SwipeReviewView.swift
//  LightGallery
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI
import Photos

struct SwipeReviewView: View {
    @State var assets: [PhotoAsset]
    var onDelete: ([PhotoAsset]) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var deletionQueue: [PhotoAsset] = []
    @State private var currentIndex = 0
    @State private var offset: CGSize = .zero
    @State private var showReviewSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if currentIndex < assets.count {
                    ForEach(assets.indices.reversed(), id: \.self) { index in
                        if index == currentIndex {
                            SwipeCard(asset: assets[index], offset: offset)
                                .zIndex(1)
                                .gesture(
                                    DragGesture()
                                        .onChanged { gesture in
                                            offset = gesture.translation
                                        }
                                        .onEnded { gesture in
                                            handleSwipe(width: gesture.translation.width)
                                        }
                                )
                        } else if index == currentIndex + 1 {
                            SwipeCard(asset: assets[index], offset: .zero)
                                .scaleEffect(0.95)
                                .opacity(0.8)
                                .zIndex(0)
                        }
                    }
                } else {
                    // End of stack reached
                    VStack(spacing: 20) {
                        Text("Review Complete".localized)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("\(deletionQueue.count) " + "photos marked for deletion".localized)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            showReviewSheet = true
                        }) {
                            Text("Review Deletion".localized)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .cornerRadius(24)
                        }
                    }
                }
                
                // Overlay Icons
                if currentIndex < assets.count {
                    HStack {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                            .opacity(offset.width < -100 ? 0.8 : 0)
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                            .opacity(offset.width > 100 ? 0.8 : 0)
                    }
                    .padding(40)
                    .allowsHitTesting(false)
                }
            }
            .navigationTitle("Review".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
                
                // Finish Button (Top Right)
                ToolbarItem(placement: .primaryAction) {
                    if currentIndex < assets.count {
                        Button("Finish".localized) {
                            showReviewSheet = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showReviewSheet) {
                DeletionReviewSheet(assetsToDelete: deletionQueue) { confirmedAssets in
                    onDelete(confirmedAssets)
                    dismiss()
                }
            }
        }
    }
    
    private func handleSwipe(width: CGFloat) {
        let threshold: CGFloat = 100
        if width < -threshold {
            // Swipe Left (Delete)
            deletionQueue.append(assets[currentIndex])
            withAnimation {
                offset = CGSize(width: -500, height: 0)
            }
            nextCard()
        } else if width > threshold {
            // Swipe Right (Keep)
            withAnimation {
                offset = CGSize(width: 500, height: 0)
            }
            nextCard()
        } else {
            // Reset
            withAnimation(.spring()) {
                offset = .zero
            }
        }
    }
    
    private func nextCard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            currentIndex += 1
            offset = .zero
        }
    }
}

struct DeletionReviewSheet: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let assetsToDelete: [PhotoAsset]
    let onConfirm: ([PhotoAsset]) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                if assetsToDelete.isEmpty {
                    ContentUnavailableView(
                        "No photos to delete".localized,
                        systemImage: "trash.slash",
                        description: Text("You haven't swiped left on any photos yet.".localized)
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 2)], spacing: 2) {
                            ForEach(assetsToDelete) { asset in
                                DeletionThumbnail(asset: asset)
                            }
                        }
                        .padding(.top)
                    }
                }
                
                // Bottom Bar
                VStack {
                    Divider()
                    Button(action: {
                        onConfirm(assetsToDelete)
                    }) {
                        Text("Delete".localized + " \(assetsToDelete.count) " + "Photos".localized)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(assetsToDelete.isEmpty ? Color.gray : Color.red)
                            .cornerRadius(12)
                            .padding()
                    }
                    .disabled(assetsToDelete.isEmpty)
                }
            }
            .navigationTitle("Photos to Delete".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Keep".localized) { // "Keep" means cancel deletion/dismiss sheet
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DeletionThumbnail: View {
    let asset: PhotoAsset
    @State private var image: UIImage?
    
    var body: some View {
        GeometryReader { geo in
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
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
        
        manager.requestImage(for: asset.phAsset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFill, options: options) { result, _ in
            self.image = result
        }
    }
}

struct SwipeCard: View {
    let asset: PhotoAsset
    let offset: CGSize
    @State private var image: UIImage?
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geo.size.width, height: geo.size.height)
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .background(Color.black)
            .cornerRadius(20)
            .shadow(radius: 10)
            .rotationEffect(.degrees(Double(offset.width / 20)))
            .offset(x: offset.width, y: offset.height * 0.5)
        }
        .padding()
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        
        manager.requestImage(for: asset.phAsset, targetSize: UIScreen.main.bounds.size, contentMode: .aspectFit, options: options) { result, _ in
            self.image = result
        }
    }
}
