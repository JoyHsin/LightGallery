//
//  LivePhotoService.swift
//  Declutter
//
//  Created by Antigravity on 2025/12/05.
//

import Foundation
import Photos
import UIKit
import ImageIO
import UniformTypeIdentifiers

class LivePhotoService {
    static let shared = LivePhotoService()
    private init() {}
    
    /// Extracts the video component from a Live Photo asset.
    /// - Parameter livePhoto: The Live Photo PHAsset.
    /// - Returns: A URL to the saved video file, or nil if failed.
    func extractVideo(from livePhoto: PHAsset) async -> URL? {
        return await withCheckedContinuation { continuation in
            let resources = PHAssetResource.assetResources(for: livePhoto)
            guard let videoResource = resources.first(where: { $0.type == .pairedVideo }) else {
                continuation.resume(returning: nil)
                return
            }
            
            let fileName = "livephoto_video_\(UUID().uuidString).mov"
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            // Remove existing file if any
            try? FileManager.default.removeItem(at: fileURL)
            
            PHAssetResourceManager.default().writeData(for: videoResource, toFile: fileURL, options: nil) { error in
                if let error = error {
                    print("Error extracting video: \(error)")
                    continuation.resume(returning: nil)
                } else {
                    continuation.resume(returning: fileURL)
                }
            }
        }
    }
    
    /// Creates a GIF from a video URL.
    /// - Parameter videoURL: The URL of the video.
    /// - Returns: The GIF data, or nil if failed.
    func createGIF(from videoURL: URL) async -> Data? {
        return await withCheckedContinuation { continuation in
            guard let asset = AVAsset(url: videoURL) as? AVURLAsset else {
                continuation.resume(returning: nil)
                return
            }
            
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero
            
            let duration = asset.duration.seconds
            let frameRate = 10.0 // Reduced framerate for GIF
            let frameCount = Int(duration * frameRate)
            let timePoints = (0..<frameCount).map { CMTime(seconds: Double($0) / frameRate, preferredTimescale: 600) }
            
            let destinationData = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(destinationData, UTType.gif.identifier as CFString, frameCount, nil) else {
                continuation.resume(returning: nil)
                return
            }
            
            let fileProperties: [String: Any] = [
                kCGImagePropertyGIFDictionary as String: [
                    kCGImagePropertyGIFLoopCount as String: 0 // Loop forever
                ]
            ]
            CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
            
            let frameProperties: [String: Any] = [
                kCGImagePropertyGIFDictionary as String: [
                    kCGImagePropertyGIFDelayTime as String: 1.0 / frameRate
                ]
            ]
            
            var processedCount = 0
            
            // Generate frames
            // Note: generateCGImagesAsynchronously is better but complex to bridge to synchronous CGImageDestinationAddImage
            // For simplicity in this context, we'll try a loop or use the async version with a group.
            // Given "async" context, let's use the new async API if available (iOS 15+) or just synchronous loop for simplicity in this snippet.
            
            // Using synchronous loop for simplicity as we are already in a detached Task via 'await'
            for time in timePoints {
                do {
                    let image = try generator.copyCGImage(at: time, actualTime: nil)
                    // Resize image to save size? Optional but recommended for GIFs.
                    // For now, add as is.
                    CGImageDestinationAddImage(destination, image, frameProperties as CFDictionary)
                } catch {
                    print("Error generating frame at \(time.seconds): \(error)")
                }
            }
            
            if CGImageDestinationFinalize(destination) {
                continuation.resume(returning: destinationData as Data)
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
}
