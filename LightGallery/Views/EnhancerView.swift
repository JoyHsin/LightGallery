//
//  EnhancerView.swift
//  LightGallery
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI
import PhotosUI

struct EnhancerView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var originalImage: UIImage?
    @State private var enhancedImage: UIImage?
    @State private var isProcessing = false
    @State private var sliderValue: CGFloat = 0.5
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let original = originalImage, let enhanced = enhancedImage {
                    // Compare View
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Enhanced Image (Bottom)
                            Image(uiImage: enhanced)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geo.size.width, height: geo.size.height)
                            
                            // Original Image (Top, Masked)
                            Image(uiImage: original)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .mask(
                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .frame(width: geo.size.width * sliderValue)
                                        Spacer()
                                    }
                                )
                            
                            // Slider Handle
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 2, height: geo.size.height)
                                .offset(x: geo.size.width * sliderValue)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            sliderValue = min(max(value.location.x / geo.size.width, 0), 1)
                                        }
                                )
                            
                            // Labels
                            HStack {
                                Text("Before".localized)
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                                    .padding()
                                Spacer()
                                Text("After".localized)
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                                    .padding()
                            }
                        }
                    }
                    .padding()
                    
                    Button(action: { saveEnhancedImage() }) {
                        Text("Save Enhanced Photo".localized)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding()
                    
                } else {
                    // Selection
                    VStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        Text("AI Photo Enhancer".localized)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Upscale and restore photos".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    if isProcessing {
                        ProgressView("Enhancing...".localized)
                            .padding()
                    }
                    
                    Spacer()
                    
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Text("Select Photo".localized)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding()
                    .disabled(isProcessing)
                }
            }
            .navigationTitle("Enhancer".localized)
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
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            self.originalImage = image
                            self.isProcessing = true
                        }
                        
                        if let result = await PhotoEnhancerService.shared.enhancePhoto(image: image) {
                            await MainActor.run {
                                self.enhancedImage = result
                                self.isProcessing = false
                            }
                        }
                    }
                }
            }
            .alert("Success".localized, isPresented: $showSuccess) {
                Button("OK".localized) {
                    dismiss()
                }
            } message: {
                Text("Enhanced photo saved to Photos".localized)
            }
        }
    }
    
    private func saveEnhancedImage() {
        guard let image = enhancedImage else { return }
        
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
