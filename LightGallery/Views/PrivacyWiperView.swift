//
//  PrivacyWiperView.swift
//  LightGallery
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI
import PhotosUI

struct PrivacyWiperView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var selectedAsset: PHAsset? // We need this to read original metadata
    @State private var metadataSummary: [String: String] = [:]
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "shield.slash.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        Text("Privacy Wiper".localized)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Remove location and device info".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Image Selection
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 300)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 300)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.largeTitle)
                                            .foregroundColor(.blue)
                                        Text("Select a Photo".localized)
                                            .foregroundColor(.blue)
                                    }
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    if selectedImage != nil {
                        Button(action: { selectedItem = nil; selectedImage = nil; metadataSummary = [:] }) {
                            Text("Change Photo".localized)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Hidden onChange handler
                    Color.clear
                        .frame(height: 0)
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    self.selectedImage = image
                                    await analyzeMetadata(from: data)
                                }
                            }
                        }
                    
                    // Metadata Summary
                    if selectedImage != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Metadata Found:".localized)
                                .font(.headline)
                            
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.red)
                                Text("GPS:".localized)
                                Spacer()
                                Text(metadataSummary["GPS"] ?? "Checking...".localized)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                            
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.orange)
                                Text("Device:".localized)
                                Spacer()
                                Text(metadataSummary["Device"] ?? "Checking...".localized)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Action Button
                        Button(action: {
                            wipeAndSave()
                        }) {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Wipe & Save Copy".localized)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Privacy Wiper".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
            }
            .alert("Success".localized, isPresented: $showSuccess) {
                Button("OK".localized) {
                    selectedImage = nil
                    selectedItem = nil
                    metadataSummary = [:]
                }
            } message: {
                Text("Photo saved to Camera Roll without metadata.".localized)
            }
            .alert("Error".localized, isPresented: $showError) {
                Button("OK".localized) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func analyzeMetadata(from data: Data) async {
        // Read metadata directly from data
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            metadataSummary = ["GPS": "Unknown".localized, "Device": "Unknown".localized]
            return
        }
        
        var summary: [String: String] = [:]
        
        // GPS
        if let _ = properties[kCGImagePropertyGPSDictionary as String] {
            summary["GPS"] = "Contains Location".localized
        } else {
            summary["GPS"] = "Clean".localized
        }
        
        // Device
        if let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
           let model = tiff[kCGImagePropertyTIFFModel as String] as? String {
            summary["Device"] = model
        } else {
            summary["Device"] = "Unknown".localized
        }
        
        metadataSummary = summary
    }
    
    private func wipeAndSave() {
        guard let item = selectedItem else { return }
        isProcessing = true
        
        Task {
            do {
                guard let data = try? await item.loadTransferable(type: Data.self) else {
                    throw NSError(domain: "App", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image data"])
                }
                
                guard let cleanData = PrivacyManager.shared.removeMetadata(from: data) else {
                    throw NSError(domain: "App", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])
                }
                
                // Save to Photo Library
                try await PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: cleanData, options: nil)
                }
                
                await MainActor.run {
                    isProcessing = false
                    showSuccess = true
                }
                
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}
