import Foundation
import AppKit
import Vision
import CoreImage

//
//  SmartCropper.swift
//  Icon Creator - AI-Powered Smart Cropping
//
//  Automatically crop images to optimal composition using Vision framework
//  Author: Jordan Koch
//  Date: 2026-01-21
//

/// AI-powered smart cropping using Vision framework
/// Detects important areas (faces, objects, salient regions) and crops optimally
class SmartCropper: ObservableObject {

    // MARK: - Published Properties

    @Published var isCropping = false
    @Published var progress: Double = 0

    // MARK: - Smart Crop

    /// Automatically crop image to target size with optimal composition
    /// Uses Vision framework to detect important areas and preserve them
    func smartCrop(
        image: NSImage,
        targetSize: CGSize,
        preserveImportantAreas: Bool = true
    ) async throws -> NSImage {

        await MainActor.run {
            isCropping = true
            progress = 0
        }

        defer {
            Task { @MainActor in
                isCropping = false
                progress = 0
            }
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw CropError.invalidImage
        }

        await updateProgress(0.2)

        // Detect important areas
        let importantRegions = try await detectImportantRegions(in: cgImage)

        await updateProgress(0.5)

        // Calculate optimal crop rect
        let cropRect = calculateOptimalCrop(
            imageSize: CGSize(width: cgImage.width, height: cgImage.height),
            targetSize: targetSize,
            importantRegions: importantRegions,
            preserveImportant: preserveImportantAreas
        )

        await updateProgress(0.8)

        // Perform crop
        let croppedImage = crop(cgImage, to: cropRect, targetSize: targetSize)

        await updateProgress(1.0)

        return croppedImage
    }

    // MARK: - Region Detection

    /// Detect important regions using Vision framework
    private func detectImportantRegions(in image: CGImage) async throws -> [ImportantRegion] {
        var regions: [ImportantRegion] = []

        // 1. Detect faces
        let faceRegions = try await detectFaces(in: image)
        regions.append(contentsOf: faceRegions)

        // 2. Detect salient objects
        let objectRegions = try await detectSalientObjects(in: image)
        regions.append(contentsOf: objectRegions)

        // 3. Calculate attention-based saliency
        let saliencyRegions = try await detectSaliency(in: image)
        regions.append(contentsOf: saliencyRegions)

        return regions
    }

    /// Detect faces using Vision framework
    private func detectFaces(in image: CGImage) async throws -> [ImportantRegion] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results = request.results as? [VNFaceObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let regions = results.map { face in
                    ImportantRegion(
                        rect: face.boundingBox,
                        importance: 1.0, // Faces are always important
                        type: .face
                    )
                }

                continuation.resume(returning: regions)
            }

            let handler = VNImageRequestHandler(cgImage: image, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Detect salient objects using Vision framework
    private func detectSalientObjects(in image: CGImage) async throws -> [ImportantRegion] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateObjectnessBasedSaliencyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let result = request.results?.first as? VNSaliencyImageObservation else {
                    continuation.resume(returning: [])
                    return
                }

                let salientObjects = result.salientObjects ?? []

                let regions = salientObjects.map { object in
                    ImportantRegion(
                        rect: object.boundingBox,
                        importance: Double(object.confidence),
                        type: .object
                    )
                }

                continuation.resume(returning: regions)
            }

            let handler = VNImageRequestHandler(cgImage: image, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Detect salient regions using attention-based saliency
    private func detectSaliency(in image: CGImage) async throws -> [ImportantRegion] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let result = request.results?.first as? VNSaliencyImageObservation else {
                    continuation.resume(returning: [])
                    return
                }

                let salientObjects = result.salientObjects ?? []

                let regions = salientObjects.map { object in
                    ImportantRegion(
                        rect: object.boundingBox,
                        importance: Double(object.confidence),
                        type: .saliency
                    )
                }

                continuation.resume(returning: regions)
            }

            let handler = VNImageRequestHandler(cgImage: image, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Crop Calculation

    /// Calculate optimal crop rect based on important regions
    private func calculateOptimalCrop(
        imageSize: CGSize,
        targetSize: CGSize,
        importantRegions: [ImportantRegion],
        preserveImportant: Bool
    ) -> CGRect {

        // Calculate target aspect ratio
        let targetAspect = targetSize.width / targetSize.height

        // If no important regions or not preserving them, use center crop
        guard preserveImportant && !importantRegions.isEmpty else {
            return calculateCenterCrop(imageSize: imageSize, targetAspect: targetAspect)
        }

        // Calculate bounding box that contains all important regions
        var minX = CGFloat(1.0)
        var minY = CGFloat(1.0)
        var maxX = CGFloat(0.0)
        var maxY = CGFloat(0.0)

        for region in importantRegions {
            // Vision uses normalized coordinates (0-1)
            minX = min(minX, region.rect.minX)
            minY = min(minY, region.rect.minY)
            maxX = max(maxX, region.rect.maxX)
            maxY = max(maxY, region.rect.maxY)
        }

        // Add padding around important regions (10%)
        let padding = CGFloat(0.1)
        minX = max(0, minX - padding)
        minY = max(0, minY - padding)
        maxX = min(1, maxX + padding)
        maxY = min(1, maxY + padding)

        // Calculate center of important regions
        let centerX = (minX + maxX) / 2
        let centerY = (minY + maxY) / 2

        // Calculate crop dimensions that match target aspect ratio
        let regionWidth = maxX - minX
        let regionHeight = maxY - minY
        let regionAspect = regionWidth / regionHeight

        var cropWidth: CGFloat
        var cropHeight: CGFloat

        if regionAspect > targetAspect {
            // Region is wider than target
            cropWidth = regionWidth
            cropHeight = cropWidth / targetAspect
        } else {
            // Region is taller than target
            cropHeight = regionHeight
            cropWidth = cropHeight * targetAspect
        }

        // Ensure crop doesn't exceed image bounds
        cropWidth = min(cropWidth, 1.0)
        cropHeight = min(cropHeight, 1.0)

        // Center crop around important regions
        var cropX = centerX - cropWidth / 2
        var cropY = centerY - cropHeight / 2

        // Adjust if out of bounds
        if cropX < 0 { cropX = 0 }
        if cropY < 0 { cropY = 0 }
        if cropX + cropWidth > 1.0 { cropX = 1.0 - cropWidth }
        if cropY + cropHeight > 1.0 { cropY = 1.0 - cropHeight }

        // Convert from normalized coordinates to pixel coordinates
        return CGRect(
            x: cropX * imageSize.width,
            y: cropY * imageSize.height,
            width: cropWidth * imageSize.width,
            height: cropHeight * imageSize.height
        )
    }

    /// Calculate center crop as fallback
    private func calculateCenterCrop(imageSize: CGSize, targetAspect: CGFloat) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height

        var cropWidth: CGFloat
        var cropHeight: CGFloat

        if imageAspect > targetAspect {
            // Image is wider than target
            cropHeight = imageSize.height
            cropWidth = cropHeight * targetAspect
        } else {
            // Image is taller than target
            cropWidth = imageSize.width
            cropHeight = cropWidth / targetAspect
        }

        let cropX = (imageSize.width - cropWidth) / 2
        let cropY = (imageSize.height - cropHeight) / 2

        return CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
    }

    // MARK: - Cropping

    /// Perform actual crop operation
    private func crop(_ cgImage: CGImage, to rect: CGRect, targetSize: CGSize) -> NSImage {
        // Crop the image
        guard let croppedCGImage = cgImage.cropping(to: rect) else {
            return NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
        }

        // Resize to target size
        let croppedImage = NSImage(cgImage: croppedCGImage, size: rect.size)

        return resizeImage(croppedImage, to: targetSize)
    }

    private func resizeImage(_ image: NSImage, to newSize: CGSize) -> NSImage {
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = .high

        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )

        newImage.unlockFocus()
        return newImage
    }

    // MARK: - Helper

    private func updateProgress(_ value: Double) async {
        await MainActor.run {
            progress = value
        }
    }
}

// MARK: - Models

struct ImportantRegion {
    let rect: CGRect // Normalized coordinates (0-1)
    let importance: Double // 0-1
    let type: RegionType

    enum RegionType {
        case face
        case object
        case saliency
    }
}

enum CropError: LocalizedError {
    case invalidImage
    case visionFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image for cropping"
        case .visionFailed:
            return "Vision framework analysis failed"
        }
    }
}

// MARK: - Example Usage

extension SmartCropper {
    static func exampleUsage() -> String {
        return """
        // Basic smart crop
        let cropper = SmartCropper()

        let cropped = try await cropper.smartCrop(
            image: sourceImage,
            targetSize: CGSize(width: 1024, height: 1024),
            preserveImportantAreas: true
        )

        // The crop will:
        // 1. Detect faces (highest priority)
        // 2. Detect salient objects
        // 3. Analyze attention-based saliency
        // 4. Calculate optimal crop that preserves important areas
        // 5. Center composition appropriately
        """
    }
}
