//
//  LivePhotoConverterView.swift
//  Declutter
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI
import PhotosUI

struct LivePhotoConverterView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedAsset: PHAsset?
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var successMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "livephoto")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    
                    Text("Live Photo Converter".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Convert Live Photos to Video or GIF".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Selection
                if selectedAsset == nil {
                    PhotosPicker(selection: $selectedItem, matching: .livePhotos) {
                        VStack {
                            Image(systemName: "photo.badge.plus")
                                .font(.largeTitle)
                            Text("Select Live Photo".localized)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                } else {
                    VStack {
                        Text("Live Photo Selected".localized)
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Button("Change".localized) {
                            selectedAsset = nil
                            selectedItem = nil
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Actions
                    HStack(spacing: 20) {
                        Button(action: { convertToVideo() }) {
                            VStack {
                                Image(systemName: "video.fill")
                                    .font(.title)
                                Text("Save as Video".localized)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: { convertToGIF() }) {
                            VStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.title)
                                Text("Save as GIF".localized)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .disabled(isProcessing)
                }
                
                if isProcessing {
                    ProgressView("Processing...".localized)
                }
                
                Spacer()
            }
            .navigationTitle("Live Photo".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let newItem = newItem {
                        // Get PHAsset identifier
                        if let identifier = newItem.itemIdentifier {
                            let result = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
                            self.selectedAsset = result.firstObject
                        }
                    }
                }
            }
            .alert("Success".localized, isPresented: $showSuccess) {
                Button("OK".localized) {
                    selectedAsset = nil
                    selectedItem = nil
                }
            } message: {
                Text(successMessage)
            }
        }
    }
    
    private func convertToVideo() {
        guard let asset = selectedAsset else { return }
        isProcessing = true
        
        Task {
            if let url = await LivePhotoService.shared.extractVideo(from: asset) {
                // Save to library
                try? await PHPhotoLibrary.shared().performChanges {
                    PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }
                await MainActor.run {
                    successMessage = "Video saved to Photos".localized
                    showSuccess = true
                    isProcessing = false
                }
            } else {
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }
    
    private func convertToGIF() {
        guard let asset = selectedAsset else { return }
        isProcessing = true
        
        Task {
            if let url = await LivePhotoService.shared.extractVideo(from: asset),
               let gifData = await LivePhotoService.shared.createGIF(from: url) {
                // Save GIF to library
                try? await PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: gifData, options: nil)
                }
                await MainActor.run {
                    successMessage = "GIF saved to Photos".localized
                    showSuccess = true
                    isProcessing = false
                }
            } else {
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }
}
