import Foundation
import AppKit
import Vision
import CoreImage

/// Intelligently removes backgrounds from images using Vision framework
class BackgroundRemover {

    // MARK: - Background Removal

    /// Removes background from an image using Vision's subject segmentation
    func removeBackground(from image: NSImage) async throws -> NSImage {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw BackgroundRemovalError.invalidImage
        }

        // Create Vision request
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .balanced
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8

        // Perform request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let result = request.results?.first else {
            throw BackgroundRemovalError.segmentationFailed
        }

        // Create mask from segmentation
        guard let maskPixelBuffer = result.pixelBuffer else {
            throw BackgroundRemovalError.maskCreationFailed
        }

        // Apply mask to original image
        let masked = try applyMask(maskPixelBuffer, to: cgImage)

        return NSImage(cgImage: masked, size: image.size)
    }

    /// Smart background removal for non-person subjects
    func removeBackgroundSmart(from image: NSImage) async throws -> NSImage {
        // Use saliency detection for non-person objects
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw BackgroundRemovalError.invalidImage
        }

        let request = VNGenerateAttentionBasedSaliencyImageObservationRequest()

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let result = request.results?.first else {
            throw BackgroundRemovalError.segmentationFailed
        }

        // Use saliency map to create mask
        guard let saliencyMap = result.pixelBuffer else {
            throw BackgroundRemovalError.maskCreationFailed
        }

        // Create mask and apply
        let masked = try applyMask(saliencyMap, to: cgImage)

        return NSImage(cgImage: masked, size: image.size)
    }

    // MARK: - Mask Application

    private func applyMask(_ maskBuffer: CVPixelBuffer, to image: CGImage) throws -> CGImage {
        // Create CI images
        let ciImage = CIImage(cgImage: image)
        let maskImage = CIImage(cvPixelBuffer: maskBuffer)

        // Scale mask to match image size
        let scaleX = CGFloat(image.width) / maskImage.extent.width
        let scaleY = CGFloat(image.height) / maskImage.extent.height
        let scaledMask = maskImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        // Apply mask
        let filter = CIFilter.blendWithMask()
        filter.inputImage = ciImage
        filter.backgroundImage = CIImage.empty()
        filter.maskImage = scaledMask

        guard let output = filter.outputImage else {
            throw BackgroundRemovalError.maskApplicationFailed
        }

        // Render to CGImage
        let context = CIContext()
        guard let result = context.createCGImage(output, from: output.extent) else {
            throw BackgroundRemovalError.renderingFailed
        }

        return result
    }

    // MARK: - Errors

    enum BackgroundRemovalError: LocalizedError {
        case invalidImage
        case segmentationFailed
        case maskCreationFailed
        case maskApplicationFailed
        case renderingFailed

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Invalid or corrupted image"
            case .segmentationFailed:
                return "Could not segment subject from background"
            case .maskCreationFailed:
                return "Failed to create segmentation mask"
            case .maskApplicationFailed:
                return "Failed to apply mask to image"
            case .renderingFailed:
                return "Failed to render final image"
            }
        }
    }
}
