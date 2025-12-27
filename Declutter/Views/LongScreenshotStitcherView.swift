//
//  LongScreenshotStitcherView.swift
//  Declutter
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI
import PhotosUI

struct LongScreenshotStitcherView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var stitchedImage: UIImage?
    @State private var isProcessing = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if stitchedImage != nil {
                    // Result View
                    ScrollView {
                        Image(uiImage: stitchedImage!)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding()
                    }
                    
                    Button(action: { saveStitchedImage() }) {
                        Text("Save to Photos".localized)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding()
                } else {
                    // Selection View
                    VStack(spacing: 12) {
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Long Screenshot Stitcher".localized)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Select overlapping screenshots".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(selectedImages, id: \.self) { image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 150)
                                        .cornerRadius(8)
                                }
                            }
                            .padding()
                        }
                        
                        Button(action: { stitchImages() }) {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Stitch Images".localized)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .disabled(isProcessing)
                    }
                    
                    Spacer()
                    
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .screenshots) {
                        Text(selectedImages.isEmpty ? "Select Screenshots".localized : "Change Selection".localized)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .navigationTitle("Stitcher".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedItems) { newItems in
                Task {
                    var images: [UIImage] = []
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            images.append(image)
                        }
                    }
                    await MainActor.run {
                        self.selectedImages = images
                        self.stitchedImage = nil
                    }
                }
            }
            .alert("Success".localized, isPresented: $showSuccess) {
                Button("OK".localized) {
                    dismiss()
                }
            } message: {
                Text("Stitched image saved to Photos".localized)
            }
        }
    }
    
    private func stitchImages() {
        guard selectedImages.count > 1 else { return }
        isProcessing = true
        
        Task {
            if let result = await StitcherService.shared.stitchImages(images: selectedImages) {
                await MainActor.run {
                    self.stitchedImage = result
                    self.isProcessing = false
                }
            } else {
                await MainActor.run {
                    self.isProcessing = false
                    // Show error?
                }
            }
        }
    }
    
    private func saveStitchedImage() {
        guard let image = stitchedImage else { return }
        
        Task {
            try? await PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.creationRequestForAsset(from: image)
            }
            await MainActor.run {
                showSuccess = true
            }
        }
    }
}
