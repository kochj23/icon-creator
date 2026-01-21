import Foundation
import AppKit
import CoreImage

//
//  IconPerformanceAnalyzer.swift
//  Icon Creator
//
//  Analyzes icon performance metrics and provides optimization recommendations
//  Author: Jordan Koch
//  Date: 2026-01-21
//

/// Comprehensive performance analyzer for app icons
/// Provides file size optimization, compression recommendations, and quality metrics
class IconPerformanceAnalyzer: ObservableObject {

    // MARK: - Published Properties

    @Published var isAnalyzing = false
    @Published var currentAnalysis: PerformanceAnalysis?
    @Published var optimizationRecommendations: [OptimizationRecommendation] = []

    // MARK: - Analysis

    /// Analyze a complete icon set
    func analyzeIconSet(at url: URL) async throws -> PerformanceAnalysis {
        await MainActor.run {
            isAnalyzing = true
        }

        defer {
            Task { @MainActor in
                isAnalyzing = false
            }
        }

        var analysis = PerformanceAnalysis()
        let fileManager = FileManager.default

        // Enumerate all PNG files
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
        ) else {
            throw AnalyzerError.invalidDirectory
        }

        for case let fileURL as URL in enumerator where fileURL.pathExtension.lowercased() == "png" {
            if let image = NSImage(contentsOf: fileURL) {
                let fileAnalysis = try analyzeFile(fileURL, image: image)
                analysis.files.append(fileAnalysis)
            }
        }

        // Calculate aggregate metrics
        analysis.calculateAggregates()

        // Generate recommendations
        analysis.recommendations = generateRecommendations(for: analysis)

        await MainActor.run {
            self.currentAnalysis = analysis
            self.optimizationRecommendations = analysis.recommendations
        }

        return analysis
    }

    /// Analyze a single icon file
    private func analyzeFile(_ url: URL, image: NSImage) throws -> FileAnalysis {
        let fileManager = FileManager.default
        let attributes = try fileManager.attributesOfItem(atPath: url.path)

        let fileSize = attributes[.size] as? Int64 ?? 0
        let modificationDate = attributes[.modificationDate] as? Date ?? Date()

        var analysis = FileAnalysis(
            url: url,
            fileName: url.lastPathComponent,
            fileSize: fileSize,
            modificationDate: modificationDate,
            dimensions: image.size
        )

        // Check if square
        analysis.isSquare = image.size.width == image.size.height

        // Analyze image properties
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            analysis.hasAlphaChannel = cgImage.alphaInfo != .none
            analysis.bitsPerPixel = cgImage.bitsPerPixel
            analysis.colorSpace = cgImage.colorSpace?.name as String? ?? "Unknown"

            // Calculate actual pixel count
            analysis.pixelCount = Int(image.size.width * image.size.height)

            // Calculate bytes per pixel
            analysis.bytesPerPixel = Double(fileSize) / Double(analysis.pixelCount)

            // Estimate compression ratio
            let uncompressedSize = analysis.pixelCount * 4 // RGBA
            analysis.compressionRatio = Double(uncompressedSize) / Double(fileSize)

            // Analyze complexity (entropy)
            analysis.complexity = calculateImageComplexity(cgImage)

            // Check for unnecessary alpha channel
            if analysis.hasAlphaChannel {
                analysis.actuallyUsesAlpha = checkAlphaUsage(cgImage)
            }
        }

        // Calculate quality score (0-100)
        analysis.qualityScore = calculateQualityScore(analysis)

        // Estimate potential savings
        analysis.potentialSavings = estimateSavings(analysis)

        return analysis
    }

    // MARK: - Detailed Analysis Methods

    /// Calculate image complexity using entropy
    private func calculateImageComplexity(_ cgImage: CGImage) -> Double {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ) else {
            return 0.5
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return 0.5 }

        // Sample pixels and calculate variance
        let pixelData = data.assumingMemoryBound(to: UInt8.self)
        var values: [Double] = []
        let sampleRate = max(1, (width * height) / 10000) // Sample up to 10k pixels

        for i in stride(from: 0, to: width * height, by: sampleRate) {
            let offset = i * bytesPerPixel
            let r = Double(pixelData[offset])
            let g = Double(pixelData[offset + 1])
            let b = Double(pixelData[offset + 2])

            // Grayscale value
            let gray = (r + g + b) / 3.0
            values.append(gray)
        }

        // Calculate standard deviation (proxy for complexity)
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let stdDev = sqrt(variance)

        // Normalize to 0-1
        return min(1.0, stdDev / 128.0)
    }

    /// Check if alpha channel is actually being used
    private func checkAlphaUsage(_ cgImage: CGImage) -> Bool {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ) else {
            return false
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return false }

        let pixelData = data.assumingMemoryBound(to: UInt8.self)

        // Check if any alpha values are not fully opaque
        for i in 0..<(width * height) {
            let alphaOffset = i * bytesPerPixel + 3
            if pixelData[alphaOffset] < 255 {
                return true // Found transparent/translucent pixel
            }
        }

        return false // All pixels are fully opaque
    }

    /// Calculate quality score (0-100)
    private func calculateQualityScore(_ analysis: FileAnalysis) -> Int {
        var score = 100.0

        // Penalize non-square icons
        if !analysis.isSquare {
            score -= 20
        }

        // Penalize inefficient compression
        if analysis.bytesPerPixel > 1.0 {
            score -= 15
        } else if analysis.bytesPerPixel > 0.5 {
            score -= 5
        }

        // Penalize unused alpha channel
        if analysis.hasAlphaChannel && !analysis.actuallyUsesAlpha {
            score -= 10
        }

        // Penalize oversized files
        let expectedSize = Double(analysis.pixelCount) * 0.5 // 0.5 bytes/pixel is good
        if Double(analysis.fileSize) > expectedSize * 2 {
            score -= 20
        } else if Double(analysis.fileSize) > expectedSize * 1.5 {
            score -= 10
        }

        // Bonus for good compression on complex images
        if analysis.complexity > 0.7 && analysis.compressionRatio > 15 {
            score += 5
        }

        return max(0, min(100, Int(score)))
    }

    /// Estimate potential file size savings
    private func estimateSavings(_ analysis: FileAnalysis) -> Int64 {
        var savings: Int64 = 0

        // Savings from better compression
        let optimalBytesPerPixel = 0.5
        if analysis.bytesPerPixel > optimalBytesPerPixel {
            let excessBytes = analysis.bytesPerPixel - optimalBytesPerPixel
            savings += Int64(excessBytes * Double(analysis.pixelCount))
        }

        // Savings from removing unused alpha
        if analysis.hasAlphaChannel && !analysis.actuallyUsesAlpha {
            savings += analysis.fileSize / 4 // Roughly 25% savings
        }

        return savings
    }

    // MARK: - Recommendations

    /// Generate optimization recommendations
    private func generateRecommendations(for analysis: PerformanceAnalysis) -> [OptimizationRecommendation] {
        var recommendations: [OptimizationRecommendation] = []

        // Overall file size check
        if analysis.totalSize > 500_000 { // 500KB
            recommendations.append(.init(
                severity: .high,
                category: .fileSize,
                title: "Total icon size is large",
                description: "Your icon set is \(ByteCountFormatter.string(fromByteCount: analysis.totalSize, countStyle: .file)). Consider optimizing for faster app launches.",
                potentialSavings: analysis.totalPotentialSavings,
                action: .optimize
            ))
        }

        // Check for unused alpha channels
        let unusedAlphaCount = analysis.files.filter { $0.hasAlphaChannel && !$0.actuallyUsesAlpha }.count
        if unusedAlphaCount > 0 {
            recommendations.append(.init(
                severity: .medium,
                category: .alphaChannel,
                title: "\(unusedAlphaCount) file(s) with unused transparency",
                description: "Remove alpha channel to reduce file size by ~25%",
                potentialSavings: analysis.files.filter { $0.hasAlphaChannel && !$0.actuallyUsesAlpha }
                    .reduce(0) { $0 + ($1.fileSize / 4) },
                action: .removeAlpha
            ))
        }

        // Check for inefficient compression
        let inefficientFiles = analysis.files.filter { $0.bytesPerPixel > 1.0 }
        if !inefficientFiles.isEmpty {
            let totalInefficient = inefficientFiles.reduce(0) { $0 + $1.fileSize }
            recommendations.append(.init(
                severity: .medium,
                category: .compression,
                title: "\(inefficientFiles.count) file(s) poorly compressed",
                description: "Re-compress these files with better settings",
                potentialSavings: totalInefficient / 3,
                action: .recompress
            ))
        }

        // Check for non-square icons
        let nonSquareCount = analysis.files.filter { !$0.isSquare }.count
        if nonSquareCount > 0 {
            recommendations.append(.init(
                severity: .low,
                category: .dimensions,
                title: "\(nonSquareCount) non-square icon(s)",
                description: "Icons should be square for proper display on all devices",
                potentialSavings: 0,
                action: .fixDimensions
            ))
        }

        // Check average quality
        if analysis.averageQualityScore < 70 {
            recommendations.append(.init(
                severity: .high,
                category: .quality,
                title: "Overall icon quality is below optimal",
                description: "Average quality score: \(analysis.averageQualityScore)/100",
                potentialSavings: analysis.totalPotentialSavings,
                action: .optimize
            ))
        }

        // Retina vs standard recommendations
        let retinaFiles = analysis.files.filter { $0.dimensions.width >= 512 }
        if !retinaFiles.isEmpty {
            recommendations.append(.init(
                severity: .info,
                category: .retina,
                title: "Retina assets detected",
                description: "\(retinaFiles.count) high-resolution icons. Ensure standard resolution versions exist.",
                potentialSavings: 0,
                action: .ensureStandardRes
            ))
        }

        // Sort by severity
        return recommendations.sorted { $0.severity.rawValue > $1.severity.rawValue }
    }

    // MARK: - Optimization

    /// Apply automated optimizations
    func optimizeIcons(at url: URL, aggressively: Bool = false) async throws -> OptimizationResult {
        var result = OptimizationResult()

        let analysis = try await analyzeIconSet(at: url)

        for fileAnalysis in analysis.files {
            guard let image = NSImage(contentsOf: fileAnalysis.url) else { continue }

            var optimized = false
            let originalSize = fileAnalysis.fileSize

            // Remove unused alpha channel
            if fileAnalysis.hasAlphaChannel && !fileAnalysis.actuallyUsesAlpha {
                // Convert to non-alpha
                if let optimizedImage = removeAlphaChannel(from: image) {
                    try saveOptimizedImage(optimizedImage, to: fileAnalysis.url, quality: aggressively ? 0.7 : 0.9)
                    optimized = true
                }
            }

            // Recompress if needed
            if !optimized && fileAnalysis.bytesPerPixel > 0.7 {
                try saveOptimizedImage(image, to: fileAnalysis.url, quality: aggressively ? 0.7 : 0.9)
                optimized = true
            }

            if optimized {
                let newSize = try FileManager.default.attributesOfItem(atPath: fileAnalysis.url.path)[.size] as? Int64 ?? 0
                let saved = originalSize - newSize

                result.filesOptimized += 1
                result.bytesSaved += saved
            }
        }

        return result
    }

    private func removeAlphaChannel(from image: NSImage) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 3,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let newCGImage = context.makeImage() else {
            return nil
        }

        return NSImage(cgImage: newCGImage, size: image.size)
    }

    private func saveOptimizedImage(_ image: NSImage, to url: URL, quality: Double) throws {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw AnalyzerError.imageProcessingFailed
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        bitmapRep.size = image.size

        let properties: [NSBitmapImageRep.PropertyKey: Any] = [
            .compressionFactor: quality,
            .compressionMethod: NSNumber(value: NSTIFFCompression.lzw.rawValue)
        ]

        guard let pngData = bitmapRep.representation(using: .png, properties: properties) else {
            throw AnalyzerError.imageProcessingFailed
        }

        try pngData.write(to: url)
    }
}

// MARK: - Models

struct PerformanceAnalysis {
    var files: [FileAnalysis] = []
    var totalSize: Int64 = 0
    var averageSize: Int64 = 0
    var totalPotentialSavings: Int64 = 0
    var averageQualityScore: Int = 0
    var averageComplexity: Double = 0
    var recommendations: [OptimizationRecommendation] = []

    mutating func calculateAggregates() {
        totalSize = files.reduce(0) { $0 + $1.fileSize }
        averageSize = files.isEmpty ? 0 : totalSize / Int64(files.count)
        totalPotentialSavings = files.reduce(0) { $0 + $1.potentialSavings }
        averageQualityScore = files.isEmpty ? 0 : files.reduce(0) { $0 + $1.qualityScore } / files.count
        averageComplexity = files.isEmpty ? 0 : files.reduce(0.0) { $0 + $1.complexity } / Double(files.count)
    }
}

struct FileAnalysis: Identifiable {
    let id = UUID()
    let url: URL
    let fileName: String
    let fileSize: Int64
    let modificationDate: Date
    let dimensions: CGSize

    var isSquare = false
    var hasAlphaChannel = false
    var actuallyUsesAlpha = false
    var bitsPerPixel = 0
    var colorSpace = ""
    var pixelCount = 0
    var bytesPerPixel: Double = 0
    var compressionRatio: Double = 0
    var complexity: Double = 0
    var qualityScore = 0
    var potentialSavings: Int64 = 0
}

struct OptimizationRecommendation: Identifiable {
    let id = UUID()
    let severity: Severity
    let category: Category
    let title: String
    let description: String
    let potentialSavings: Int64
    let action: Action

    enum Severity: Int {
        case high = 3
        case medium = 2
        case low = 1
        case info = 0

        var color: NSColor {
            switch self {
            case .high: return .systemRed
            case .medium: return .systemOrange
            case .low: return .systemYellow
            case .info: return .systemBlue
            }
        }
    }

    enum Category {
        case fileSize
        case compression
        case alphaChannel
        case dimensions
        case quality
        case retina
    }

    enum Action {
        case optimize
        case removeAlpha
        case recompress
        case fixDimensions
        case ensureStandardRes
    }
}

struct OptimizationResult {
    var filesOptimized = 0
    var bytesSaved: Int64 = 0

    var savedPercentage: Double {
        // Would need original total for accurate percentage
        0.0
    }
}

enum AnalyzerError: LocalizedError {
    case invalidDirectory
    case imageProcessingFailed

    var errorDescription: String? {
        switch self {
        case .invalidDirectory:
            return "Invalid directory for analysis"
        case .imageProcessingFailed:
            return "Failed to process image"
        }
    }
}
