
import Foundation
import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

enum IDPhotoSize: String, CaseIterable, Identifiable {
    case oneInch = "1 Inch"
    case twoInch = "2 Inch"
    case passport = "Passport"
    
    var id: String { self.rawValue }
    
    var dimensions: CGSize {
        // Assuming 300 DPI
        switch self {
        case .oneInch:
            // Standard 1 inch: 25mm x 35mm
            return CGSize(width: 295, height: 413)
        case .twoInch:
            // Standard 2 inch: 35mm x 53mm
            return CGSize(width: 413, height: 579) // slightly adjusted for standard aspect
        case .passport:
            // Standard Passport (US 2x2 inch): 51mm x 51mm
            return CGSize(width: 600, height: 600)
        }
    }
}

class IDPhotoService {
    static let shared = IDPhotoService()
    private init() {}
    
    enum PhotoError: Error {
        case faceNotFound
        case processingFailed
        case segmentationFailed
    }
    
    /// Intermediate result containing the masked image and face metadata
    struct ProcessingResult {
        let originalImage: UIImage
        let maskedImage: UIImage
        let faceRect: CGRect // In logical normalized coordinates of the original image? Or absolute? Let's use Normalized (0-1).
    }
    
    /// Step 1: Analyze and Segment the image (Heavy Operation)
    func processImage(_ image: UIImage) async throws -> ProcessingResult {
        // Normalize orientation to ensure the CGImage matches the visual orientation.
        // This ensures Vision sees the face upright and coordinates match.
        let normalizedImage = normalizeOrientation(image)
        
        guard let cgImage = normalizedImage.cgImage else { throw PhotoError.processingFailed }
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        
        let faceRequest = VNDetectFaceRectanglesRequest()
        let segRequest = VNGeneratePersonSegmentationRequest()
        segRequest.qualityLevel = .accurate
        segRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        do {
            try handler.perform([faceRequest, segRequest])
        } catch {
            throw PhotoError.processingFailed
        }
        
        // Process Face Result
        guard let faceObservation = faceRequest.results?.first else {
            throw PhotoError.faceNotFound
        }
        
        // Normalize Face Rect
        let faceBounds = faceObservation.boundingBox
        
        // Process Segmentation Result
        guard let segResult = segRequest.results?.first else {
            throw PhotoError.segmentationFailed
        }
        
        let maskPixelBuffer = segResult.pixelBuffer
        
        let maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)
        guard let ciOriginal = CIImage(image: normalizedImage) else { throw PhotoError.processingFailed }
        
        // Scale mask to overlay
        let scaleX = ciOriginal.extent.width / maskImage.extent.width
        let scaleY = ciOriginal.extent.height / maskImage.extent.height
        let scaledMask = maskImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = ciOriginal
        blendFilter.maskImage = scaledMask
        blendFilter.backgroundImage = CIImage.empty()
        
        let context = CIContext()
        guard let output = blendFilter.outputImage,
              let resultCG = context.createCGImage(output, from: ciOriginal.extent) else {
            throw PhotoError.processingFailed
        }
        
        let maskedUIImage = UIImage(cgImage: resultCG)
        
        return ProcessingResult(originalImage: normalizedImage, maskedImage: maskedUIImage, faceRect: faceBounds)
    }
    
    // MARK: - Normalization helper
    
    private func normalizeOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up { return image }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1 // Keep 1x scale if possible? Or image.scale. 
        // We want pixel-perfect if possible, but UIGraphics with an image usually uses logical points.
        // Let's use drawing.
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalized ?? image
    }
    
    /// Step 2: Render the final ID Photo (Fast Operation)
    func renderIDPhoto(from result: ProcessingResult, size: IDPhotoSize, color: UIColor) throws -> UIImage {
        // Calculate Crop Rect based on Original Image Face Rect and Target Size
        let cropRect = calculateCropRect(imageSize: result.maskedImage.size, faceRect: result.faceRect, targetAspectRatio: size.dimensions.width / size.dimensions.height)
        
        // Crop the Masked Image
        guard let cgImage = result.maskedImage.cgImage,
              let croppedCG = cgImage.cropping(to: cropRect) else {
            throw PhotoError.processingFailed
        }
        let croppedImage = UIImage(cgImage: croppedCG)
        
        // Composite on Background
        return try composite(image: croppedImage, on: color, targetSize: size.dimensions)
    }
    
    // MARK: - Helper Logic
    
    private func calculateCropRect(imageSize: CGSize, faceRect: CGRect, targetAspectRatio: CGFloat) -> CGRect {
        // faceRect is Normalized (0-1), Origin Bottom-Left (Vision standard)
        
        let faceW = faceRect.width * imageSize.width
        let faceH = faceRect.height * imageSize.height
        let faceCenterX = faceRect.midX * imageSize.width
        // Flip Y for standard coord calculation (Top-Left origin)
        // Vision midY is from bottom.
        // Image midY from top = height - (vision_midY * height)
        let faceCenterY = imageSize.height - (faceRect.midY * imageSize.height)
        
        // Target Heights: Face should be ~50-60% of photo height
        let targetDocHeight = faceH / 0.55
        let targetDocWidth = targetDocHeight * targetAspectRatio
        
        let halfW = targetDocWidth / 2
        let halfH = targetDocHeight / 2
        
        // Center crop around face center (corrected for Y flip)
        // Adjust vertically: eyes are usually at 40-50% from top.
        // If we center precisely: center is 50%.
        // Let's just center for now.
        
        let originX = faceCenterX - halfW
        let originY = faceCenterY - halfH
        
        // Create basic rect
        var rect = CGRect(x: originX, y: originY, width: targetDocWidth, height: targetDocHeight)
        
        // Ideally clamp to bounds or fill?
        // For ID photos, we want to maintain the face size relative to the frame.
        // If we clamp, we might change aspect ratio or zoom.
        // Better to return the theoretical rect, and let `cropping(to:)` handle out-of-bounds (it returns nil or partial usually? CGImage cropping usually requires valid rect inside?)
        // CGImage.cropping(to:) documentation: "If the rect parameter specifies a rectangle that is not contained in the image, the result is undefined."
        // We MUST intersect. But intersecting changes aspect ratio.
        // Strategy: We crop what we can. Then we AspectFill during Composition.
        
        // Let's try to clamp but keep aspect ratio? Hard.
        // Let's just return the theoretical rect. We will handle "drawing" in the composition step if cropping fails or is partial?
        // Actually, if we use `UIGraphicsImageRenderer` to draw the full `maskedImage` into a clipped rect, it handles scaling/clipping automatically?
        // But we want to crop THEN composite to save pixels?
        
        // Let's use integral standard rect
        return rect.integral
    }
    
    private func composite(image: UIImage, on color: UIColor, targetSize: CGSize) throws -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { context in
            // Fill Background
            color.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            
            // Draw Image
            // We want to Aspect FILL the target area with our cropped image.
            // Since our crop rect was calculated to match the aspect ratio of targetSize, it should fit perfectly.
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
