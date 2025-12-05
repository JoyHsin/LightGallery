//
//  FormatConverterService.swift
//  LightGallery
//
//  Created by Antigravity on 2025/12/05.
//

import Foundation
import UIKit
import Photos

enum ImageFormat: String, CaseIterable {
    case jpeg = "JPEG"
    case png = "PNG"
}

class FormatConverterService {
    static let shared = FormatConverterService()
    private init() {}
    
    /// Converts assets to the specified format.
    /// - Parameters:
    ///   - assets: List of PHAssets to convert.
    ///   - format: Target format (JPEG/PNG).
    ///   - quality: Compression quality (0.0 - 1.0).
    /// - Returns: List of URLs to the converted files.
    func convert(assets: [PhotoAsset], to format: ImageFormat, quality: CGFloat) async -> [URL] {
        var resultURLs: [URL] = []
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false // We use async wrapper
        
        for asset in assets {
            await withCheckedContinuation { continuation in
                manager.requestImage(for: asset.phAsset, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: options) { image, info in
                    guard let image = image else {
                        continuation.resume()
                        return
                    }
                    
                    // Convert
                    let fileName = "converted_\(asset.id).\(format.rawValue.lowercased())"
                    let tempDir = FileManager.default.temporaryDirectory
                    let fileURL = tempDir.appendingPathComponent(fileName)
                    
                    var data: Data?
                    switch format {
                    case .jpeg:
                        data = image.jpegData(compressionQuality: quality)
                    case .png:
                        data = image.pngData()
                    }
                    
                    if let data = data {
                        try? data.write(to: fileURL)
                        resultURLs.append(fileURL)
                    }
                    
                    continuation.resume()
                }
            }
        }
        
        return resultURLs
    }
    
    /// Saves files to Camera Roll.
    func saveToLibrary(urls: [URL]) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            for url in urls {
                PHAssetCreationRequest.creationRequestForAssetFromImage(atFileURL: url)
            }
        }
    }
}
