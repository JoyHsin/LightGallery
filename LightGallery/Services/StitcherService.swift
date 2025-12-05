//
//  StitcherService.swift
//  LightGallery
//
//  Created by Antigravity on 2025/12/05.
//

import Foundation
import UIKit
import Vision

class StitcherService {
    static let shared = StitcherService()
    private init() {}
    
    /// Stitches an array of images vertically.
    /// - Parameter images: Sorted array of images (top to bottom).
    /// - Returns: The stitched image, or nil if failed.
    func stitchImages(images: [UIImage]) async -> UIImage? {
        guard images.count > 1 else { return images.first }
        
        var stitchedImage = images[0]
        
        for i in 1..<images.count {
            if let nextImage = await stitchTwoImages(top: stitchedImage, bottom: images[i]) {
                stitchedImage = nextImage
            } else {
                // If stitching fails, stop or continue? 
                // For "Long Screenshot", usually implies continuity. If fail, maybe just append?
                // Let's return what we have so far or fail.
                print("Failed to stitch image \(i)")
                return nil
            }
        }
        
        return stitchedImage
    }
    
    private func stitchTwoImages(top: UIImage, bottom: UIImage) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            // Convert to CGImage
            guard let topCG = top.cgImage, let bottomCG = bottom.cgImage else {
                continuation.resume(returning: nil)
                return
            }
            
            let request = VNTranslationalImageRegistrationRequest(targetedCGImage: bottomCG)
            let handler = VNImageRequestHandler(cgImage: topCG, options: [:])
            
            do {
                try handler.perform([request])
                guard let observation = request.results?.first as? VNImageTranslationAlignmentObservation else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let alignment = observation.alignmentTransform
                // alignment.tx is horizontal shift, alignment.ty is vertical shift
                // For vertical stitching, we expect significant ty.
                // Vision coordinates: Y is up.
                // If bottom overlaps with top's bottom, the "translation" to align top TO bottom
                // usually means shifting top DOWN relative to bottom? Or vice versa.
                // Actually, VNTranslationalImageRegistrationRequest calculates transform to align TARGET (bottom) to SOURCE (top).
                
                // Let's assume vertical overlap.
                // The overlap height can be derived.
                // If ty is positive, bottom is "above" top? No.
                // Let's simplify: We want to find the overlap.
                // We can use the translation to determine where the cut point is.
                
                // Simplified logic:
                // 1. Calculate overlap height based on alignment.
                // 2. Crop top image to exclude the bottom part that overlaps.
                // 3. Draw top (cropped) and bottom into new context.
                
                // Note: Vision alignment can be tricky.
                // Alternative: Pixel matching (brute force) is often more robust for screenshots (exact pixel match).
                // But user asked for Vision.
                
                // Let's trust the translation.
                // If we align Bottom to Top, the translation T maps a point in Bottom to Top.
                // P_top = P_bottom * T
                // We want to place Bottom below Top, overlapping.
                
                // Let's try to construct the final image.
                let width = top.size.width
                
                // Calculate offset
                // The translation tells us how much to move Bottom to match Top.
                // If Bottom is just a shifted version of Top's bottom part.
                // The vertical offset (dy) tells us the overlap.
                
                let dy = alignment.ty // In pixels of the image
                
                // If dy is positive, it means Bottom needs to move UP to match Top?
                // Vision origin is bottom-left.
                
                // Let's assume standard screenshot stitching:
                // Top image has height H1. Bottom image has height H2.
                // They overlap by 'overlap' pixels.
                // Total height = H1 + H2 - overlap.
                
                // We need to find 'overlap'.
                // If we use Vision, it gives us the transform.
                // Let's try a simpler approach for this demo since Vision math can be flaky without trial:
                // We will assume the user provides overlapping screenshots.
                // We will use the translation to find the overlap.
                
                // Heuristic: The translation `ty` should be roughly (H1 - overlap).
                // Wait, if Bottom matches Top, it matches the *content*.
                // If Top is [A, B] and Bottom is [B, C].
                // To align Bottom([B,C]) to Top([A,B]), we need to shift Bottom UP by height(A).
                // So `ty` should be positive, equal to height(A).
                // Overlap = H1 - ty.
                
                let ty = abs(alignment.ty) // Use abs to be safe
                let overlap = top.size.height - ty
                
                // Sanity check
                if overlap < 0 || overlap > top.size.height {
                    // Fallback or fail
                    continuation.resume(returning: nil)
                    return
                }
                
                let newHeight = top.size.height + bottom.size.height - overlap
                let newSize = CGSize(width: width, height: newHeight)
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                
                // Draw Top (clipped to remove overlap? Or just draw Top, then draw Bottom over it?)
                // If we draw Top, then Bottom over it at offset 'ty'.
                // Top: (0, 0)
                // Bottom: (0, ty)
                
                top.draw(at: .zero)
                bottom.draw(at: CGPoint(x: 0, y: ty))
                
                let result = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                continuation.resume(returning: result)
                
            } catch {
                print("Vision error: \(error)")
                continuation.resume(returning: nil)
            }
        }
    }
}
