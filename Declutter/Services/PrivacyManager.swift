//
//  PrivacyManager.swift
//  Declutter
//
//  Created by Antigravity on 2025/12/05.
//

import Foundation
import UIKit
import ImageIO
import Photos

class PrivacyManager {
    static let shared = PrivacyManager()
    private init() {}
    
    /// Removes sensitive metadata (GPS, Exif, TIFF) from the image data.
    /// - Parameter data: The original image data.
    /// - Returns: Cleaned image data, or nil if processing fails.
    func removeMetadata(from data: Data) -> Data? {
        // The most reliable way to strip ALL metadata is to:
        // 1. Decode the image to a CGImage/UIImage (which discards metadata)
        // 2. Re-encode it to JPEG/PNG (which creates a fresh file without the old metadata)
        
        guard let image = UIImage(data: data) else { return nil }
        
        // Re-encode as JPEG with high quality
        // This completely strips all EXIF, GPS, TIFF metadata
        guard let cleanData = image.jpegData(compressionQuality: 0.95) else {
            // Try PNG as fallback
            return image.pngData()
        }
        
        return cleanData
    }
    
    /// Reads metadata from a PHAsset to display to the user.
    func getMetadataSummary(for asset: PHAsset) async -> [String: String] {
        return await withCheckedContinuation { continuation in
            let options = PHContentEditingInputRequestOptions()
            options.isNetworkAccessAllowed = true
            
            asset.requestContentEditingInput(with: options) { input, _ in
                var summary: [String: String] = [:]
                
                if let url = input?.fullSizeImageURL,
                   let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                   let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] {
                    
                    // GPS
                    if let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
                        summary["GPS"] = "Contains Location Data"
                    } else {
                        summary["GPS"] = "No Location Data"
                    }
                    
                    // Device
                    if let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
                       let model = tiff[kCGImagePropertyTIFFModel as String] as? String {
                        summary["Device"] = model
                    } else {
                        summary["Device"] = "Unknown Device"
                    }
                    
                } else {
                    summary["GPS"] = "Unknown"
                    summary["Device"] = "Unknown"
                }
                
                continuation.resume(returning: summary)
            }
        }
    }
}
