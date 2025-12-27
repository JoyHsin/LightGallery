//
//  PhotoAnalysisService.swift
//  Declutter
//
//  Created by Antigravity on 2025/12/05.
//

import Foundation
import Photos
import Vision
import UIKit

/// Service responsible for analyzing photos to detect similarities and quality
actor PhotoAnalysisService {
    
    // Threshold for considering two photos as "similar"
    // Lower value means stricter similarity. 10-15 is usually a good range for "visually similar".
    // Threshold for considering two photos as "similar"
    // Lower value means stricter similarity. 10-15 is usually a good range for "visually similar".
    // Increased to 20.0 to be more lenient and find more matches.
    // Lower distance means more similar.
    // 16.0 was too loose. Lowering to 10.0 for stricter matching.
    private let similarityThreshold: Float = 10.0
    private let timeThreshold: TimeInterval = 120 // 2 minutes
    
    /// Analyzes a list of assets and groups them by similarity
    /// - Parameter assets: The list of PhotoAssets to analyze
    /// - Returns: A list of SimilarPhotoGroup
    func groupSimilarPhotos(assets: [PhotoAsset]) async -> [SimilarPhotoGroup] {
        var groups: [SimilarPhotoGroup] = []
        var processedIDs: Set<String> = []
        
        // We need PHAssets to fetch image data for Vision
        // Map localIdentifier to feature print for caching
        var featurePrints: [String: VNFeaturePrintObservation] = [:]
        
        print("Starting analysis for \(assets.count) photos...")
        
        // 1. Generate feature prints for all assets
        for asset in assets {
            if let observation = await generateFeaturePrint(for: asset.phAsset) {
                featurePrints[asset.id] = observation
            }
        }
        
        print("Generated feature prints for \(featurePrints.count) photos.")
        
        // 2. Grouping logic
        let sortedAssets = assets.sorted { $0.creationDate < $1.creationDate }
        
        for i in 0..<sortedAssets.count {
            let baseAsset = sortedAssets[i]
            
            if processedIDs.contains(baseAsset.id) { continue }
            
            guard let basePrint = featurePrints[baseAsset.id] else { continue }
            
            var currentGroupAssets: [PhotoAsset] = [baseAsset]
            processedIDs.insert(baseAsset.id)
            
            // Look ahead for similar photos
            for j in (i + 1)..<sortedAssets.count {
                let candidateAsset = sortedAssets[j]
                
                if processedIDs.contains(candidateAsset.id) { continue }
                
                // Time optimization: Stop if photos are too far apart (e.g. > 1 hour)
                if candidateAsset.creationDate.timeIntervalSince(baseAsset.creationDate) > 3600 {
                    break
                }
                
                guard let candidatePrint = featurePrints[candidateAsset.id] else { continue }
                
                do {
                    var distance: Float = 0
                    try candidatePrint.computeDistance(&distance, to: basePrint)
                    
                    if distance < similarityThreshold {
                        currentGroupAssets.append(candidateAsset)
                        processedIDs.insert(candidateAsset.id)
                    }
                } catch {
                    print("Error computing distance: \(error)")
                }
            }
            
            // Only create a group if we found at least one similar photo (size > 1)
            if currentGroupAssets.count > 1 {
                let bestShot = currentGroupAssets.first
                let group = SimilarPhotoGroup(assets: currentGroupAssets, bestShot: bestShot)
                groups.append(group)
            }
        }
        
        print("Found \(groups.count) groups of similar photos.")
        return groups
    }
    
    /// Generates a feature print observation for a given asset
    private func generateFeaturePrint(for asset: PHAsset) async -> VNFeaturePrintObservation? {
        return await withCheckedContinuation { continuation in
            let request = VNGenerateImageFeaturePrintRequest()
            request.imageCropAndScaleOption = .scaleFill
            
            let imageManager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat // Use lower quality for faster feature extraction
            options.isSynchronous = false
            options.resizeMode = .exact
            options.isNetworkAccessAllowed = true
            
            // Target size doesn't need to be huge for feature print
            let targetSize = CGSize(width: 512, height: 512)
            
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { (image: UIImage?, info) in
                guard let image = image else {
                    continuation.resume(returning: nil)
                    return
                }
                
                var cgImage: CGImage?
                
                #if canImport(UIKit)
                cgImage = image.cgImage
                #elseif canImport(AppKit)
                cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
                #endif
                
                guard let finalCGImage = cgImage else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let handler = VNImageRequestHandler(cgImage: finalCGImage, options: [:])
                do {
                    try handler.perform([request])
                    if let observation = request.results?.first as? VNFeaturePrintObservation {
                        continuation.resume(returning: observation)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    print("Vision request failed: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
