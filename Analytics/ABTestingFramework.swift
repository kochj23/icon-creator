import Foundation
import AppKit

//
//  ABTestingFramework.swift
//  Icon Creator
//
//  A/B Testing framework for icon variants
//  Author: Jordan Koch
//  Date: 2026-01-21
//

/// A/B Testing framework for data-driven icon selection
/// Generates variants, manages tracking IDs, and integrates with Firebase Remote Config
class ABTestingFramework: ObservableObject {

    // MARK: - Published Properties

    @Published var currentExperiment: IconExperiment?
    @Published var variants: [IconVariant] = []
    @Published var isGenerating = false

    // MARK: - Properties

    private let storage = ABTestStorage()
    private let firebaseIntegration: FirebaseIntegration?

    // MARK: - Initialization

    init(firebaseEnabled: Bool = false) {
        if firebaseEnabled {
            self.firebaseIntegration = FirebaseIntegration()
        } else {
            self.firebaseIntegration = nil
        }
    }

    // MARK: - Experiment Creation

    /// Create a new A/B testing experiment
    func createExperiment(
        name: String,
        sourceImage: NSImage,
        variantCount: Int = 5,
        styles: [VariantStyle] = []
    ) async throws -> IconExperiment {

        await MainActor.run {
            isGenerating = true
        }

        defer {
            Task { @MainActor in
                isGenerating = false
            }
        }

        let experiment = IconExperiment(
            id: UUID(),
            name: name,
            createdAt: Date(),
            status: .active
        )

        // Generate variants
        let stylesToUse = styles.isEmpty ? VariantStyle.allCases : styles

        for (index, style) in stylesToUse.prefix(variantCount).enumerated() {
            let trackingID = generateTrackingID(experiment: experiment.id, variant: index)

            let variantImage = applyStyle(to: sourceImage, style: style)

            let variant = IconVariant(
                id: UUID(),
                experimentID: experiment.id,
                trackingID: trackingID,
                variantIndex: index,
                style: style,
                image: variantImage,
                createdAt: Date()
            )

            await MainActor.run {
                variants.append(variant)
            }
        }

        // Save experiment
        try storage.saveExperiment(experiment, variants: variants)

        // Upload to Firebase if enabled
        if let firebase = firebaseIntegration {
            try await firebase.uploadExperiment(experiment, variants: variants)
        }

        await MainActor.run {
            currentExperiment = experiment
        }

        return experiment
    }

    /// Generate unique tracking ID for variant
    private func generateTrackingID(experiment: UUID, variant: Int) -> String {
        let experimentShort = experiment.uuidString.prefix(8)
        return "icon_\(experimentShort)_v\(String(format: "%02d", variant + 1))"
    }

    // MARK: - Style Application

    /// Apply visual style to icon
    private func applyStyle(to image: NSImage, style: VariantStyle) -> NSImage {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return image
        }

        let ciImage = CIImage(cgImage: cgImage)

        var outputImage: CIImage

        switch style {
        case .original:
            outputImage = ciImage

        case .gradient:
            outputImage = applyGradientOverlay(to: ciImage)

        case .shadow:
            outputImage = applyShadow(to: ciImage)

        case .rounded:
            outputImage = applyRoundedCorners(to: ciImage)

        case .vibrant:
            outputImage = applyVibrantColors(to: ciImage)

        case .desaturated:
            outputImage = applyDesaturation(to: ciImage)

        case .glossy:
            outputImage = applyGlossEffect(to: ciImage)

        case .flat:
            outputImage = applyFlatStyle(to: ciImage)

        case .neon:
            outputImage = applyNeonGlow(to: ciImage)

        case .vintage:
            outputImage = applyVintageFilter(to: ciImage)
        }

        // Convert back to NSImage
        let context = CIContext()
        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }

        return NSImage(cgImage: outputCGImage, size: image.size)
    }

    // MARK: - Style Filters

    private func applyGradientOverlay(to image: CIImage) -> CIImage {
        guard let gradientFilter = CIFilter(name: "CILinearGradient") else { return image }

        gradientFilter.setValue(CIVector(x: 0, y: 0), forKey: "inputPoint0")
        gradientFilter.setValue(CIVector(x: image.extent.width, y: image.extent.height), forKey: "inputPoint1")
        gradientFilter.setValue(CIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.3), forKey: "inputColor0")
        gradientFilter.setValue(CIColor(red: 1.0, green: 0.3, blue: 0.5, alpha: 0.3), forKey: "inputColor1")

        guard let gradientOutput = gradientFilter.outputImage else { return image }

        guard let blendFilter = CIFilter(name: "CISourceAtopCompositing") else { return image }
        blendFilter.setValue(gradientOutput, forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)

        return blendFilter.outputImage ?? image
    }

    private func applyShadow(to image: CIImage) -> CIImage {
        guard let shadowFilter = CIFilter(name: "CIShadow") else { return image }

        shadowFilter.setValue(image, forKey: kCIInputImageKey)
        shadowFilter.setValue(15.0, forKey: "inputRadius")

        return shadowFilter.outputImage ?? image
    }

    private func applyRoundedCorners(to image: CIImage) -> CIImage {
        // Create rounded mask
        let cornerRadius: CGFloat = image.extent.width * 0.2

        guard let maskFilter = CIFilter(name: "CIRoundedRectangleGenerator") else { return image }
        maskFilter.setValue(image.extent, forKey: "inputExtent")
        maskFilter.setValue(cornerRadius, forKey: "inputRadius")

        guard let mask = maskFilter.outputImage else { return image }

        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { return image }
        blendFilter.setValue(image, forKey: kCIInputImageKey)
        blendFilter.setValue(mask, forKey: kCIInputMaskImageKey)

        return blendFilter.outputImage ?? image
    }

    private func applyVibrantColors(to image: CIImage) -> CIImage {
        guard let vibrantFilter = CIFilter(name: "CIVibrance") else { return image }

        vibrantFilter.setValue(image, forKey: kCIInputImageKey)
        vibrantFilter.setValue(1.5, forKey: "inputAmount")

        return vibrantFilter.outputImage ?? image
    }

    private func applyDesaturation(to image: CIImage) -> CIImage {
        guard let desaturateFilter = CIFilter(name: "CIColorControls") else { return image }

        desaturateFilter.setValue(image, forKey: kCIInputImageKey)
        desaturateFilter.setValue(0.3, forKey: kCIInputSaturationKey)

        return desaturateFilter.outputImage ?? image
    }

    private func applyGlossEffect(to image: CIImage) -> CIImage {
        // Apply highlight on top half
        guard let glossFilter = CIFilter(name: "CILinearGradient") else { return image }

        let midY = image.extent.height / 2

        glossFilter.setValue(CIVector(x: 0, y: midY), forKey: "inputPoint0")
        glossFilter.setValue(CIVector(x: 0, y: image.extent.height), forKey: "inputPoint1")
        glossFilter.setValue(CIColor(red: 1, green: 1, blue: 1, alpha: 0.4), forKey: "inputColor0")
        glossFilter.setValue(CIColor(red: 1, green: 1, blue: 1, alpha: 0), forKey: "inputColor1")

        guard let gloss = glossFilter.outputImage else { return image }

        guard let blendFilter = CIFilter(name: "CISourceAtopCompositing") else { return image }
        blendFilter.setValue(gloss, forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)

        return blendFilter.outputImage ?? image
    }

    private func applyFlatStyle(to image: CIImage) -> CIImage {
        // Reduce detail, increase solid areas
        guard let posterizeFilter = CIFilter(name: "CIColorPosterize") else { return image }

        posterizeFilter.setValue(image, forKey: kCIInputImageKey)
        posterizeFilter.setValue(6, forKey: "inputLevels")

        return posterizeFilter.outputImage ?? image
    }

    private func applyNeonGlow(to image: CIImage) -> CIImage {
        guard let glowFilter = CIFilter(name: "CIBloom") else { return image }

        glowFilter.setValue(image, forKey: kCIInputImageKey)
        glowFilter.setValue(1.0, forKey: kCIInputIntensityKey)
        glowFilter.setValue(25.0, forKey: kCIInputRadiusKey)

        return glowFilter.outputImage ?? image
    }

    private func applyVintageFilter(to image: CIImage) -> CIImage {
        guard let sepiaFilter = CIFilter(name: "CISepiaTone") else { return image }

        sepiaFilter.setValue(image, forKey: kCIInputImageKey)
        sepiaFilter.setValue(0.8, forKey: kCIInputIntensityKey)

        guard let sepiaOutput = sepiaFilter.outputImage else { return image }

        // Add vignette
        guard let vignetteFilter = CIFilter(name: "CIVignette") else { return sepiaOutput }
        vignetteFilter.setValue(sepiaOutput, forKey: kCIInputImageKey)
        vignetteFilter.setValue(1.5, forKey: kCIInputIntensityKey)

        return vignetteFilter.outputImage ?? sepiaOutput
    }

    // MARK: - Export

    /// Export variants for deployment
    func exportVariants(experiment: IconExperiment, outputDirectory: URL) throws {
        let fileManager = FileManager.default

        // Create experiment directory
        let experimentDir = outputDirectory.appendingPathComponent(experiment.name)
        try fileManager.createDirectory(at: experimentDir, withIntermediateDirectories: true)

        // Export each variant
        for variant in variants where variant.experimentID == experiment.id {
            let variantDir = experimentDir.appendingPathComponent(variant.trackingID)
            try fileManager.createDirectory(at: variantDir, withIntermediateDirectories: true)

            // Save image
            let imageURL = variantDir.appendingPathComponent("icon.png")
            try saveImage(variant.image, to: imageURL)

            // Save metadata
            let metadata = VariantMetadata(
                trackingID: variant.trackingID,
                style: variant.style.rawValue,
                variantIndex: variant.variantIndex,
                createdAt: variant.createdAt
            )

            let metadataURL = variantDir.appendingPathComponent("metadata.json")
            let jsonData = try JSONEncoder().encode(metadata)
            try jsonData.write(to: metadataURL)
        }

        // Export experiment catalog
        let catalog = ExperimentCatalog(
            experiment: experiment,
            variants: variants.filter { $0.experimentID == experiment.id }
                .map { VariantInfo(trackingID: $0.trackingID, style: $0.style.rawValue) }
        )

        let catalogURL = experimentDir.appendingPathComponent("experiment.json")
        let catalogData = try JSONEncoder().encode(catalog)
        try catalogData.write(to: catalogURL)
    }

    private func saveImage(_ image: NSImage, to url: URL) throws {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ABTestError.imageExportFailed
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        bitmapRep.size = image.size

        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw ABTestError.imageExportFailed
        }

        try pngData.write(to: url)
    }

    // MARK: - Analytics

    /// Generate analytics report
    func generateAnalyticsReport(for experiment: IconExperiment) -> ExperimentReport {
        let variantsInExperiment = variants.filter { $0.experimentID == experiment.id }

        return ExperimentReport(
            experimentID: experiment.id,
            experimentName: experiment.name,
            totalVariants: variantsInExperiment.count,
            createdAt: experiment.createdAt,
            status: experiment.status
        )
    }
}

// MARK: - Firebase Integration

class FirebaseIntegration {

    func uploadExperiment(_ experiment: IconExperiment, variants: [IconVariant]) async throws {
        // This would integrate with Firebase Remote Config
        // For now, it's a placeholder for the actual implementation

        print("🔥 Firebase: Uploading experiment \(experiment.name)")
        print("   Variants: \(variants.count)")

        // In production:
        // 1. Upload images to Firebase Storage
        // 2. Update Remote Config with variant metadata
        // 3. Set distribution percentages for A/B test
    }

    func fetchResults(for experimentID: UUID) async throws -> [String: Any] {
        // Fetch analytics from Firebase
        return [:]
    }
}

// MARK: - Storage

class ABTestStorage {

    private let storageURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        storageURL = appSupport.appendingPathComponent("IconCreator/ABTesting")

        try? FileManager.default.createDirectory(at: storageURL, withIntermediateDirectories: true)
    }

    func saveExperiment(_ experiment: IconExperiment, variants: [IconVariant]) throws {
        let experimentDir = storageURL.appendingPathComponent(experiment.id.uuidString)
        try FileManager.default.createDirectory(at: experimentDir, withIntermediateDirectories: true)

        // Save experiment data
        let experimentData = try JSONEncoder().encode(experiment)
        try experimentData.write(to: experimentDir.appendingPathComponent("experiment.json"))

        // Save variant metadata (not images, too large)
        let variantMetadata = variants.map { variant in
            [
                "id": variant.id.uuidString,
                "trackingID": variant.trackingID,
                "style": variant.style.rawValue,
                "index": variant.variantIndex
            ] as [String: Any]
        }

        let variantData = try JSONSerialization.data(withJSONObject: variantMetadata)
        try variantData.write(to: experimentDir.appendingPathComponent("variants.json"))
    }

    func loadExperiment(_ id: UUID) throws -> IconExperiment {
        let experimentURL = storageURL.appendingPathComponent(id.uuidString).appendingPathComponent("experiment.json")
        let data = try Data(contentsOf: experimentURL)
        return try JSONDecoder().decode(IconExperiment.self, from: data)
    }
}

// MARK: - Models

struct IconExperiment: Identifiable, Codable {
    let id: UUID
    let name: String
    let createdAt: Date
    var status: ExperimentStatus

    enum ExperimentStatus: String, Codable {
        case draft
        case active
        case paused
        case completed
    }
}

struct IconVariant: Identifiable {
    let id: UUID
    let experimentID: UUID
    let trackingID: String
    let variantIndex: Int
    let style: VariantStyle
    let image: NSImage
    let createdAt: Date
}

enum VariantStyle: String, CaseIterable, Codable {
    case original
    case gradient
    case shadow
    case rounded
    case vibrant
    case desaturated
    case glossy
    case flat
    case neon
    case vintage
}

struct VariantMetadata: Codable {
    let trackingID: String
    let style: String
    let variantIndex: Int
    let createdAt: Date
}

struct VariantInfo: Codable {
    let trackingID: String
    let style: String
}

struct ExperimentCatalog: Codable {
    let experiment: IconExperiment
    let variants: [VariantInfo]
}

struct ExperimentReport {
    let experimentID: UUID
    let experimentName: String
    let totalVariants: Int
    let createdAt: Date
    let status: IconExperiment.ExperimentStatus
}

enum ABTestError: LocalizedError {
    case imageExportFailed
    case firebaseError(String)

    var errorDescription: String? {
        switch self {
        case .imageExportFailed:
            return "Failed to export image"
        case .firebaseError(let message):
            return "Firebase error: \(message)"
        }
    }
}
