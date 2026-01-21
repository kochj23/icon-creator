import Foundation
import AppKit
import CoreImage
import Vision

//
//  IconStyleTransfer.swift
//  Icon Creator
//
//  AI-powered style transfer for icons
//  Apply the style from one icon to another
//  Author: Jordan Koch
//  Date: 2026-01-21
//

/// AI-powered icon style transfer
/// Applies visual style from one icon to another while preserving content
class IconStyleTransfer: ObservableObject {

    // MARK: - Published Properties

    @Published var isProcessing = false
    @Published var progress: Double = 0

    // MARK: - Style Transfer

    /// Apply style from styleIcon to contentIcon
    func transferStyle(
        from styleIcon: NSImage,
        to contentIcon: NSImage,
        strength: Double = 0.8
    ) async throws -> NSImage {

        await MainActor.run {
            isProcessing = true
            progress = 0
        }

        defer {
            Task { @MainActor in
                isProcessing = false
                progress = 0
            }
        }

        // Update progress
        await updateProgress(0.2)

        // Extract style features from style icon
        let styleFeatures = try extractStyleFeatures(from: styleIcon)

        await updateProgress(0.4)

        // Extract content features from content icon
        let contentFeatures = try extractContentFeatures(from: contentIcon)

        await updateProgress(0.6)

        // Apply style transfer
        let result = try applyStyleTransfer(
            contentImage: contentIcon,
            styleFeatures: styleFeatures,
            contentFeatures: contentFeatures,
            strength: strength
        )

        await updateProgress(1.0)

        return result
    }

    // MARK: - Feature Extraction

    /// Extract style features (colors, textures, patterns)
    private func extractStyleFeatures(from image: NSImage) throws -> StyleFeatures {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw StyleTransferError.invalidImage
        }

        let ciImage = CIImage(cgImage: cgImage)

        // Extract color palette
        let colors = extractDominantColors(from: ciImage, count: 5)

        // Analyze texture
        let texture = analyzeTexture(from: ciImage)

        // Detect patterns
        let patterns = detectPatterns(in: ciImage)

        // Analyze lighting
        let lighting = analyzeLighting(from: ciImage)

        return StyleFeatures(
            colors: colors,
            texture: texture,
            patterns: patterns,
            lighting: lighting
        )
    }

    /// Extract content features (shapes, structures)
    private func extractContentFeatures(from image: NSImage) throws -> ContentFeatures {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw StyleTransferError.invalidImage
        }

        // Detect edges and shapes
        let edges = detectEdges(in: cgImage)

        // Detect contours
        let contours = extractContours(from: cgImage)

        // Analyze composition
        let composition = analyzeComposition(in: cgImage)

        return ContentFeatures(
            edges: edges,
            contours: contours,
            composition: composition
        )
    }

    // MARK: - Style Analysis

    private func extractDominantColors(from image: CIImage, count: Int) -> [NSColor] {
        let inputImage = CIImage(image: image)

        let extractor = CIAreaAverage()
        extractor.inputImage = inputImage
        extractor.inputExtent = CIVector(cgRect: image.extent)

        guard let outputImage = extractor.outputImage else { return [] }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext()
        let bounds = CGRect(x: 0, y: 0, width: 1, height: 1)

        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: bounds, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

        // In production, would use k-means clustering for better color extraction
        // For now, return average color
        let r = CGFloat(bitmap[0]) / 255.0
        let g = CGFloat(bitmap[1]) / 255.0
        let b = CGFloat(bitmap[2]) / 255.0
        let a = CGFloat(bitmap[3]) / 255.0

        return [NSColor(red: r, green: g, blue: b, alpha: a)]
    }

    private func analyzeTexture(from image: CIImage) -> TextureInfo {
        // Analyze texture using gabor filters or frequency analysis
        // For now, return basic info

        let roughness = calculateRoughness(image)
        let contrast = calculateContrast(image)

        return TextureInfo(roughness: roughness, contrast: contrast)
    }

    private func detectPatterns(in image: CIImage) -> [Pattern] {
        // Detect repeating patterns using autocorrelation or FFT
        // For now, return empty array
        return []
    }

    private func analyzeLighting(from image: CIImage) -> LightingInfo {
        // Analyze brightness distribution and shadows
        let brightness = calculateAverageBrightness(image)
        let contrast = calculateContrast(image)

        return LightingInfo(brightness: brightness, contrast: contrast, hasGradient: detectGradient(image))
    }

    // MARK: - Content Analysis

    private func detectEdges(in cgImage: CGImage) -> CIImage {
        let ciImage = CIImage(cgImage: cgImage)

        guard let edgeFilter = CIFilter(name: "CIEdges") else {
            return ciImage
        }

        edgeFilter.setValue(ciImage, forKey: kCIInputImageKey)
        edgeFilter.setValue(1.0, forKey: kCIInputIntensityKey)

        return edgeFilter.outputImage ?? ciImage
    }

    private func extractContours(from cgImage: CGImage) -> [Contour] {
        // Use Vision framework for contour detection
        // For now, return empty array
        return []
    }

    private func analyzeComposition(in cgImage: CGImage) -> CompositionInfo {
        let width = cgImage.width
        let height = cgImage.height

        return CompositionInfo(
            centerOfMass: CGPoint(x: Double(width) / 2, y: Double(height) / 2),
            symmetry: 0.5
        )
    }

    // MARK: - Style Application

    private func applyStyleTransfer(
        contentImage: NSImage,
        styleFeatures: StyleFeatures,
        contentFeatures: ContentFeatures,
        strength: Double
    ) throws -> NSImage {

        guard let cgImage = contentImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw StyleTransferError.processingFailed
        }

        var ciImage = CIImage(cgImage: cgImage)

        // Apply color mapping
        ciImage = applyColorMapping(to: ciImage, colors: styleFeatures.colors, strength: strength)

        // Apply texture
        ciImage = applyTexture(to: ciImage, texture: styleFeatures.texture, strength: strength)

        // Apply lighting
        ciImage = applyLighting(to: ciImage, lighting: styleFeatures.lighting, strength: strength)

        // Preserve content edges
        let edges = contentFeatures.edges
        ciImage = preserveEdges(in: ciImage, using: edges, strength: 1.0 - strength)

        // Convert back to NSImage
        let context = CIContext()
        guard let outputCGImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw StyleTransferError.processingFailed
        }

        return NSImage(cgImage: outputCGImage, size: contentImage.size)
    }

    private func applyColorMapping(to image: CIImage, colors: [NSColor], strength: Double) -> CIImage {
        guard let targetColor = colors.first else { return image }

        // Map colors from source to target palette
        guard let colorFilter = CIFilter(name: "CIColorMatrix") else { return image }

        let r = targetColor.redComponent
        let g = targetColor.greenComponent
        let b = targetColor.blueComponent

        colorFilter.setValue(image, forKey: kCIInputImageKey)
        colorFilter.setValue(CIVector(x: r, y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorFilter.setValue(CIVector(x: 0, y: g, z: 0, w: 0), forKey: "inputGVector")
        colorFilter.setValue(CIVector(x: 0, y: 0, z: b, w: 0), forKey: "inputBVector")

        guard let output = colorFilter.outputImage else { return image }

        // Blend with original based on strength
        return blendImages(original: image, filtered: output, strength: strength)
    }

    private func applyTexture(to image: CIImage, texture: TextureInfo, strength: Double) -> CIImage {
        // Apply texture characteristics
        guard let noiseFilter = CIFilter(name: "CIRandomGenerator") else { return image }

        guard let noiseImage = noiseFilter.outputImage else { return image }

        let scaledNoise = noiseImage.transformed(by: CGAffineTransform(scaleX: texture.roughness * 0.1, y: texture.roughness * 0.1))

        guard let blendFilter = CIFilter(name: "CIOverlayBlendMode") else { return image }
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(scaledNoise.cropped(to: image.extent), forKey: kCIInputImageKey)

        guard let output = blendFilter.outputImage else { return image }

        return blendImages(original: image, filtered: output, strength: strength * 0.3)
    }

    private func applyLighting(to image: CIImage, lighting: LightingInfo, strength: Double) -> CIImage {
        guard let brightnessFilter = CIFilter(name: "CIColorControls") else { return image }

        brightnessFilter.setValue(image, forKey: kCIInputImageKey)
        brightnessFilter.setValue((lighting.brightness - 0.5) * strength, forKey: kCIInputBrightnessKey)
        brightnessFilter.setValue(1.0 + (lighting.contrast - 1.0) * strength, forKey: kCIInputContrastKey)

        return brightnessFilter.outputImage ?? image
    }

    private func preserveEdges(in image: CIImage, using edges: CIImage, strength: Double) -> CIImage {
        guard let blendFilter = CIFilter(name: "CIOverlayBlendMode") else { return image }

        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(edges, forKey: kCIInputImageKey)

        guard let output = blendFilter.outputImage else { return image }

        return blendImages(original: image, filtered: output, strength: strength)
    }

    private func blendImages(original: CIImage, filtered: CIImage, strength: Double) -> CIImage {
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { return filtered }

        // Create alpha mask based on strength
        let alpha = CIImage(color: CIColor(red: 1, green: 1, blue: 1, alpha: strength)).cropped(to: original.extent)

        blendFilter.setValue(filtered, forKey: kCIInputImageKey)
        blendFilter.setValue(original, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(alpha, forKey: kCIInputMaskImageKey)

        return blendFilter.outputImage ?? filtered
    }

    // MARK: - Helper Methods

    private func calculateRoughness(_ image: CIImage) -> Double {
        // Calculate texture roughness using standard deviation
        return 0.5 // Placeholder
    }

    private func calculateContrast(_ image: CIImage) -> Double {
        // Calculate contrast ratio
        return 1.0 // Placeholder
    }

    private func calculateAverageBrightness(_ image: CIImage) -> Double {
        return 0.5 // Placeholder
    }

    private func detectGradient(_ image: CIImage) -> Bool {
        return false // Placeholder
    }

    private func updateProgress(_ value: Double) async {
        await MainActor.run {
            progress = value
        }
    }
}

// MARK: - Models

struct StyleFeatures {
    let colors: [NSColor]
    let texture: TextureInfo
    let patterns: [Pattern]
    let lighting: LightingInfo
}

struct ContentFeatures {
    let edges: CIImage
    let contours: [Contour]
    let composition: CompositionInfo
}

struct TextureInfo {
    let roughness: Double
    let contrast: Double
}

struct Pattern {
    let type: PatternType
    let frequency: Double

    enum PatternType {
        case grid
        case radial
        case organic
    }
}

struct LightingInfo {
    let brightness: Double
    let contrast: Double
    let hasGradient: Bool
}

struct Contour {
    let points: [CGPoint]
}

struct CompositionInfo {
    let centerOfMass: CGPoint
    let symmetry: Double
}

enum StyleTransferError: LocalizedError {
    case invalidImage
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image for style transfer"
        case .processingFailed:
            return "Style transfer processing failed"
        }
    }
}
