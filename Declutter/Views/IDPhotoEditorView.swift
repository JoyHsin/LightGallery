
import SwiftUI
import PhotosUI

struct IDPhotoEditorView: View {
    @Environment(\.dismiss) var dismiss
    
    // UI State
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showSaveSuccess = false
    
    // Editor State
    @State private var processingResult: IDPhotoService.ProcessingResult?
    @State private var selectedSize: IDPhotoSize = .oneInch
    @State private var selectedColor: ColorOption = .white
    @State private var finalImage: UIImage?
    
    // Source State (to determine Retake behavior)
    @State private var isFromCamera = false
    
    // Predefined Colors
    enum ColorOption: String, CaseIterable, Identifiable {
        case white = "White"
        case blue = "Blue"
        case red = "Red"
        case gray = "Gray"
        
        var id: String { rawValue }
        
        var color: Color {
            switch self {
            case .white: return .white
            case .blue: return Color(red: 0, green: 0.75, blue: 1) // #00BFFF
            case .red: return Color(red: 0.77, green: 0.05, blue: 0.13) // #C40C20 approx
            case .gray: return .gray
            }
        }
        
        var uiColor: UIColor {
            switch self {
            case .white: return .white
            case .blue: return UIColor(red: 0, green: 0.75, blue: 1, alpha: 1)
            case .red: return UIColor(red: 0.77, green: 0.05, blue: 0.13, alpha: 1)
            case .gray: return .gray
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let result = processingResult, let finalImg = finalImage {
                    // Editor UI
                    editorView(result: result, image: finalImg)
                } else {
                    // Landing / Picker UI
                    landingView
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("ID Photo Maker".localized)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCamera) {
            CustomCameraView(
                onImageCaptured: { image in
                    showCamera = false
                    isFromCamera = true
                    processImage(image)
                },
                onCancel: {
                    showCamera = false
                }
            )
            .ignoresSafeArea()
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    isFromCamera = false
                    processImage(image)
                }
            }
        }
        .onChange(of: selectedSize) { _ in updatePreview() }
        .onChange(of: selectedColor) { _ in updatePreview() }
        .alert("Error".localized, isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK".localized) {}
        } message: {
            Text(errorMessage?.localized ?? "")
        }
        .alert("Saved".localized, isPresented: $showSaveSuccess) {
            Button("OK".localized) {}
        } message: {
            Text("Photo saved to Camera Roll.".localized)
        }
    }
    
    // MARK: - Subviews
    
    private var landingView: some View {
        VStack(spacing: 30) {
            Spacer(minLength: 40)
            
            Image(systemName: "person.crop.rectangle.badge.plus")
                .font(.system(size: 70))
                .foregroundColor(.blue)
                .padding()
                .background(Circle().fill(Color.blue.opacity(0.1)).frame(width: 140, height: 140))
            
            VStack(spacing: 10) {
                Text("Create Professional ID Photos".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Automatically remove background, center face, and export compliant photos.".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer(minLength: 20)
            
            if isProcessing {
                ProgressView("Analyzing...".localized)
                    .padding()
            } else {
                VStack(spacing: 16) {
                    // Select from Library
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Choose from Library".localized)
                        }
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Take Photo
                    Button {
                        showCamera = true
                    } label: {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Take Selfie".localized)
                        }
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.15))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
    }
    
    private func editorView(result: IDPhotoService.ProcessingResult, image: UIImage) -> some View {
        VStack(spacing: 24) {
            // Preview
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 400)
                .cornerRadius(8)
                .shadow(radius: 10)
                .padding(.top)
            
            // Controls
            VStack(alignment: .leading, spacing: 20) {
                // Size Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Size".localized)
                        .font(.headline)
                    Picker("Size".localized, selection: $selectedSize) {
                        ForEach(IDPhotoSize.allCases) { size in
                            Text(size.rawValue.localized).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Color Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Background Color".localized)
                        .font(.headline)
                    HStack(spacing: 16) {
                        ForEach(ColorOption.allCases) { option in
                            Circle()
                                .fill(option.color)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .foregroundColor(option == .white ? .black : .white)
                                        .opacity(selectedColor == option ? 1 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = option
                                }
                        }
                    }
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            // Buttons
            HStack(spacing: 16) {
                if isFromCamera {
                    Button(role: .cancel) {
                        reset()
                        showCamera = true
                    } label: {
                        Text("Retake".localized)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                } else {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Text("Reselect".localized)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                }
                
                Button {
                    savePhoto()
                } label: {
                    Text("Save to Photos".localized)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.bottom)
        }
    }
    
    // MARK: - Logic
    
    private func processImage(_ image: UIImage) {
        // Fix orientation if needed
        isProcessing = true
        
        Task {
            do {
                // Process (Heavy Analysis)
                let result = try await IDPhotoService.shared.processImage(image)
                await MainActor.run {
                    self.processingResult = result
                    // Trigger initial render
                    updatePreview()
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to process photo. Please try a clearer selfie.".localized
                    isProcessing = false
                }
            }
        }
    }
    
    private func updatePreview() {
        guard let result = processingResult else { return }
        
        // Render (Fast)
        do {
            finalImage = try IDPhotoService.shared.renderIDPhoto(from: result, size: selectedSize, color: selectedColor.uiColor)
        } catch {
            print("Render failed: \(error)")
        }
    }
    
    private func savePhoto() {
        guard let image = finalImage else { return }
        
        Task {
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetCreationRequest.creationRequestForAsset(from: image)
                }
                await MainActor.run {
                    showSaveSuccess = true
                    // keep editor open for now? or reset?
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save photo.".localized
                }
            }
        }
    }
    
    private func reset() {
        processingResult = nil
        finalImage = nil
        selectedItem = nil
        // We do not reset isFromCamera here to allow proper decision making in the view for next actions if needed
        // But if we are resetting to Landing, it doesn't matter much until next selection.
        // Actually, if we go back to Landing, we should probably reset isFromCamera to false?
        // But if user clicks 'Retake' (Camera), we set showCamera=true.
    }
}
