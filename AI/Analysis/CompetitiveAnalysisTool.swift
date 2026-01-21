import Foundation
import AppKit
import CoreImage
import Vision

//
//  CompetitiveAnalysisTool.swift
//  Icon Creator - Competitive Icon Analysis
//
//  Analyze and compare your icon against competitors
//  Author: Jordan Koch
//  Date: 2026-01-21
//

/// Competitive analysis tool for comparing icons
/// Analyzes visual similarity, style trends, and market positioning
class CompetitiveAnalysisTool: ObservableObject {

    // MARK: - Published Properties

    @Published var isAnalyzing = false
    @Published var currentAnalysis: CompetitiveAnalysis?

    // MARK: - Analysis

    /// Analyze your icon against competitor icons
    func analyzeIcon(
        yourIcon: NSImage,
        competitorIcons: [NSImage],
        appCategory: AppCategory
    ) async throws -> CompetitiveAnalysis {

        await MainActor.run {
            isAnalyzing = true
        }

        defer {
            Task { @MainActor in
                isAnalyzing = false
            }
        }

        var analysis = CompetitiveAnalysis(
            yourIcon: yourIcon,
            category: appCategory
        )

        // Analyze your icon
        let yourFeatures = try extractVisualFeatures(from: yourIcon)
        analysis.yourIconFeatures = yourFeatures

        // Analyze competitors
        for (index, competitorIcon) in competitorIcons.enumerated() {
            let features = try extractVisualFeatures(from: competitorIcon)

            let comparison = CompetitorComparison(
                competitorIndex: index,
                competitorIcon: competitorIcon,
                features: features,
                similarity: calculateSimilarity(yourFeatures, features)
            )

            analysis.competitors.append(comparison)
        }

        // Calculate market positioning
        analysis.marketPosition = calculateMarketPosition(analysis)

        // Generate recommendations
        analysis.recommendations = generateRecommendations(analysis)

        await MainActor.run {
            currentAnalysis = analysis
        }

        return analysis
    }

    // MARK: - Feature Extraction

    private func extractVisualFeatures(from image: NSImage) throws -> VisualFeatures {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw AnalysisError.invalidImage
        }

        let ciImage = CIImage(cgImage: cgImage)

        return VisualFeatures(
            dominantColors: extractDominantColors(from: ciImage),
            complexity: calculateComplexity(ciImage),
            brightness: calculateBrightness(ciImage),
            saturation: calculateSaturation(ciImage),
            hasGradient: detectGradient(ciImage),
            hasText: detectText(in: cgImage),
            style: detectStyle(ciImage)
        )
    }

    private func extractDominantColors(from image: CIImage) -> [NSColor] {
        // Simplified k-means clustering for dominant colors
        // In production, would use more sophisticated algorithm

        guard let cgImage = createCGImage(from: image) else { return [] }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * bytesPerPixel,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return []
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return [] }

        let pixelData = data.assumingMemoryBound(to: UInt8.self)

        // Sample colors
        var colorCounts: [RGB: Int] = [:]

        let stride = max(1, (width * height) / 1000)

        for i in stride(from: 0, to: width * height, by: stride) {
            let offset = i * bytesPerPixel
            let rgb = RGB(
                r: pixelData[offset],
                g: pixelData[offset + 1],
                b: pixelData[offset + 2]
            )

            colorCounts[rgb, default: 0] += 1
        }

        // Get top 5 colors
        let topColors = colorCounts.sorted { $0.value > $1.value }.prefix(5)

        return topColors.map { rgb, _ in
            NSColor(
                red: CGFloat(rgb.r) / 255.0,
                green: CGFloat(rgb.g) / 255.0,
                blue: CGFloat(rgb.b) / 255.0,
                alpha: 1.0
            )
        }
    }

    private func calculateComplexity(_ image: CIImage) -> Double {
        // Use edge detection to measure complexity
        guard let edgeFilter = CIFilter(name: "CIEdges") else { return 0.5 }

        edgeFilter.setValue(image, forKey: kCIInputImageKey)
        edgeFilter.setValue(1.0, forKey: kCIInputIntensityKey)

        guard let edges = edgeFilter.outputImage else { return 0.5 }

        // Count edge pixels
        guard let cgImage = createCGImage(from: edges) else { return 0.5 }

        // Higher edge count = more complex
        return min(1.0, Double(cgImage.width * cgImage.height) / 500000.0)
    }

    private func calculateBrightness(_ image: CIImage) -> Double {
        guard let cgImage = createCGImage(from: image) else { return 0.5 }

        let width = cgImage.width
        let height = cgImage.height

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return 0.5
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return 0.5 }

        let pixelData = data.assumingMemoryBound(to: UInt8.self)

        var totalBrightness = 0.0
        var count = 0

        let stride = max(1, (width * height) / 1000)

        for i in stride(from: 0, to: width * height, by: stride) {
            let offset = i * 4
            let r = Double(pixelData[offset])
            let g = Double(pixelData[offset + 1])
            let b = Double(pixelData[offset + 2])

            let luminance = 0.299 * r + 0.587 * g + 0.114 * b
            totalBrightness += luminance
            count += 1
        }

        return totalBrightness / (Double(count) * 255.0)
    }

    private func calculateSaturation(_ image: CIImage) -> Double {
        // Calculate average HSB saturation
        guard let cgImage = createCGImage(from: image) else { return 0.5 }

        let width = cgImage.width
        let height = cgImage.height

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return 0.5
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return 0.5 }

        let pixelData = data.assumingMemoryBound(to: UInt8.self)

        var totalSaturation = 0.0
        var count = 0

        let stride = max(1, (width * height) / 1000)

        for i in stride(from: 0, to: width * height, by: stride) {
            let offset = i * 4
            let r = Double(pixelData[offset]) / 255.0
            let g = Double(pixelData[offset + 1]) / 255.0
            let b = Double(pixelData[offset + 2]) / 255.0

            let maxC = max(r, g, b)
            let minC = min(r, g, b)

            let saturation = maxC == 0 ? 0 : (maxC - minC) / maxC

            totalSaturation += saturation
            count += 1
        }

        return totalSaturation / Double(count)
    }

    private func detectGradient(_ image: CIImage) -> Bool {
        // Simple gradient detection
        return false // Simplified
    }

    private func detectText(in image: CGImage) -> Bool {
        // Use Vision framework to detect text
        let request = VNRecognizeTextRequest()

        let handler = VNImageRequestHandler(cgImage: image, options: [:])

        do {
            try handler.perform([request])

            if let results = request.results, !results.isEmpty {
                return true
            }
        } catch {
            print("⚠️ Text detection failed: \(error)")
        }

        return false
    }

    private func detectStyle(_ image: CIImage) -> IconStyle {
        // Detect icon style based on visual features
        let complexity = calculateComplexity(image)
        let saturation = calculateSaturation(image)

        if complexity < 0.3 && saturation < 0.4 {
            return .minimalist
        } else if complexity < 0.3 && saturation > 0.7 {
            return .flat
        } else if saturation > 0.8 {
            return .vibrant
        } else if complexity > 0.7 {
            return .detailed
        } else {
            return .modern
        }
    }

    // MARK: - Similarity Calculation

    private func calculateSimilarity(_ features1: VisualFeatures, _ features2: VisualFeatures) -> Double {
        var similarity = 0.0

        // Color similarity (30% weight)
        let colorSim = calculateColorSimilarity(features1.dominantColors, features2.dominantColors)
        similarity += colorSim * 0.3

        // Complexity similarity (20% weight)
        let complexitySim = 1.0 - abs(features1.complexity - features2.complexity)
        similarity += complexitySim * 0.2

        // Brightness similarity (20% weight)
        let brightnessSim = 1.0 - abs(features1.brightness - features2.brightness)
        similarity += brightnessSim * 0.2

        // Saturation similarity (20% weight)
        let saturationSim = 1.0 - abs(features1.saturation - features2.saturation)
        similarity += saturationSim * 0.2

        // Style similarity (10% weight)
        let styleSim = features1.style == features2.style ? 1.0 : 0.5
        similarity += styleSim * 0.1

        return similarity
    }

    private func calculateColorSimilarity(_ colors1: [NSColor], _ colors2: [NSColor]) -> Double {
        guard !colors1.isEmpty && !colors2.isEmpty else { return 0 }

        var totalSimilarity = 0.0

        for color1 in colors1 {
            var maxSim = 0.0

            for color2 in colors2 {
                let sim = colorSimilarity(color1, color2)
                maxSim = max(maxSim, sim)
            }

            totalSimilarity += maxSim
        }

        return totalSimilarity / Double(colors1.count)
    }

    private func colorSimilarity(_ color1: NSColor, _ color2: NSColor) -> Double {
        let r1 = color1.redComponent
        let g1 = color1.greenComponent
        let b1 = color1.blueComponent

        let r2 = color2.redComponent
        let g2 = color2.greenComponent
        let b2 = color2.blueComponent

        let distance = sqrt(pow(r1 - r2, 2) + pow(g1 - g2, 2) + pow(b1 - b2, 2))

        return 1.0 - min(1.0, distance / sqrt(3.0))
    }

    // MARK: - Market Analysis

    private func calculateMarketPosition(_ analysis: CompetitiveAnalysis) -> MarketPosition {
        let averageSimilarity = analysis.competitors.reduce(0.0) { $0 + $1.similarity } / Double(max(1, analysis.competitors.count))

        if averageSimilarity > 0.8 {
            return .tooSimilar
        } else if averageSimilarity < 0.3 {
            return .tooUnique
        } else if averageSimilarity < 0.5 {
            return .distinctive
        } else {
            return .onTrend
        }
    }

    private func generateRecommendations(_ analysis: CompetitiveAnalysis) -> [String] {
        var recommendations: [String] = []

        switch analysis.marketPosition {
        case .tooSimilar:
            recommendations.append("Your icon is very similar to competitors. Consider adding unique elements to stand out.")
        case .tooUnique:
            recommendations.append("Your icon is very different from competitors. Ensure it still communicates your app's purpose.")
        case .distinctive:
            recommendations.append("Great! Your icon is distinctive while staying recognizable in the category.")
        case .onTrend:
            recommendations.append("Your icon aligns well with current trends in the \(analysis.category.rawValue) category.")
        }

        // Analyze specific features
        if let yourFeatures = analysis.yourIconFeatures {
            if yourFeatures.brightness < 0.3 {
                recommendations.append("Consider increasing brightness for better visibility in the App Store.")
            }

            if yourFeatures.complexity > 0.8 {
                recommendations.append("Icon may be too complex. Simplify for better recognition at small sizes.")
            }

            if yourFeatures.saturation < 0.2 {
                recommendations.append("Consider adding more color to make your icon more eye-catching.")
            }
        }

        return recommendations
    }

    // MARK: - Helper

    private func createCGImage(from ciImage: CIImage) -> CGImage? {
        let context = CIContext()
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
}

// MARK: - Models

struct CompetitiveAnalysis {
    let yourIcon: NSImage
    let category: AppCategory
    var yourIconFeatures: VisualFeatures?
    var competitors: [CompetitorComparison] = []
    var marketPosition: MarketPosition = .onTrend
    var recommendations: [String] = []
}

struct CompetitorComparison {
    let competitorIndex: Int
    let competitorIcon: NSImage
    let features: VisualFeatures
    let similarity: Double // 0-1, where 1 is identical
}

struct VisualFeatures {
    let dominantColors: [NSColor]
    let complexity: Double // 0-1
    let brightness: Double // 0-1
    let saturation: Double // 0-1
    let hasGradient: Bool
    let hasText: Bool
    let style: IconStyle
}

struct RGB: Hashable {
    let r: UInt8
    let g: UInt8
    let b: UInt8
}

enum IconStyle {
    case minimalist
    case flat
    case vibrant
    case detailed
    case modern
}

enum MarketPosition {
    case tooSimilar
    case onTrend
    case distinctive
    case tooUnique
}

enum AppCategory: String, CaseIterable {
    case productivity = "Productivity"
    case social = "Social"
    case entertainment = "Entertainment"
    case finance = "Finance"
    case health = "Health & Fitness"
    case travel = "Travel"
    case food = "Food & Drink"
    case education = "Education"
    case utilities = "Utilities"
    case weather = "Weather"
    case games = "Games"
    case news = "News"
    case photo = "Photo & Video"
    case music = "Music"
    case shopping = "Shopping"
}

enum AnalysisError: LocalizedError {
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image for analysis"
        }
    }
}
