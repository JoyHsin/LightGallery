//
//  PhotoPreviewView.swift
//  Declutter
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI
import Photos

struct PhotoPreviewView: View {
    let asset: PHAsset
    @Environment(\.dismiss) var dismiss
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    // Share action could go here
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .task {
            await loadImage()
        }
        .onTapGesture {
            // Toggle controls visibility if needed
        }
    }
    
    private func loadImage() async {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        
        manager.requestImage(for: asset, targetSize: UIScreen.main.bounds.size, contentMode: .aspectFit, options: options) { result, _ in
            self.image = result
        }
    }
}
