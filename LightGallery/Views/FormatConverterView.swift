//
//  FormatConverterView.swift
//  LightGallery
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI
import PhotosUI

struct FormatConverterView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedAssets: [PhotoAsset] = []
    @State private var selectedFormat: ImageFormat = .jpeg
    @State private var quality: CGFloat = 0.8
    @State private var isProcessing = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Format Converter".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Convert HEIC to JPEG/PNG".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Settings
                Form {
                    Section(header: Text("Output Format".localized)) {
                        Picker("Format".localized, selection: $selectedFormat) {
                            Text("JPEG").tag(ImageFormat.jpeg)
                            Text("PNG").tag(ImageFormat.png)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    if selectedFormat == .jpeg {
                        Section(header: Text("Quality".localized)) {
                            HStack {
                                Text("Low".localized)
                                Slider(value: $quality, in: 0.1...1.0)
                                Text("High".localized)
                            }
                        }
                    }
                    
                    Section(header: Text("Selected Photos".localized)) {
                        if selectedItems.isEmpty {
                            Text("No photos selected".localized)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(selectedItems.count) " + "photos selected".localized)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                
                // Actions
                VStack(spacing: 16) {
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 50, matching: .images) {
                        Text(selectedItems.isEmpty ? "Select Photos".localized : "Change Selection".localized)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button(action: { convertPhotos() }) {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Convert & Save".localized)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedItems.isEmpty ? Color.gray : Color.orange)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(selectedItems.isEmpty || isProcessing)
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Converter".localized)
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
                    var assets: [PhotoAsset] = []
                    for item in newItems {
                        if let identifier = item.itemIdentifier {
                             let result = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
                             if let phAsset = result.firstObject {
                                 assets.append(PhotoAsset(phAsset: phAsset))
                             }
                        }
                    }
                    await MainActor.run {
                        self.selectedAssets = assets
                    }
                }
            }
            .alert("Success".localized, isPresented: $showSuccess) {
                Button("OK".localized) {
                    selectedItems = []
                    selectedAssets = []
                }
            } message: {
                Text("Converted photos saved to Camera Roll".localized)
            }
        }
    }
    
    private func convertPhotos() {
        guard !selectedAssets.isEmpty else { return }
        isProcessing = true
        
        Task {
            let urls = await FormatConverterService.shared.convert(assets: selectedAssets, to: selectedFormat, quality: quality)
            try? await FormatConverterService.shared.saveToLibrary(urls: urls)
            
            await MainActor.run {
                isProcessing = false
                showSuccess = true
            }
        }
    }
}
