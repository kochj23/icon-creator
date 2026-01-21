#!/usr/bin/env swift
//
//  IconCreatorCLI.swift
//  Icon Creator CLI Tool
//
//  Command-line interface for Icon Creator
//  Author: Jordan Koch
//  Date: 2026-01-21
//

import Foundation
import AppKit

/// Icon Creator Command Line Interface
/// Enables automation and CI/CD integration for icon generation
class IconCreatorCLI {

    // MARK: - Properties

    private let version = "1.0.0"
    private var verbose = false

    // MARK: - Main Entry Point

    func run() {
        let args = CommandLine.arguments

        if args.count < 2 {
            printHelp()
            exit(0)
        }

        let command = args[1]

        switch command {
        case "generate":
            handleGenerate(args: Array(args.dropFirst(2)))
        case "watch":
            handleWatch(args: Array(args.dropFirst(2)))
        case "optimize":
            handleOptimize(args: Array(args.dropFirst(2)))
        case "analyze":
            handleAnalyze(args: Array(args.dropFirst(2)))
        case "variants":
            handleVariants(args: Array(args.dropFirst(2)))
        case "version":
            print("Icon Creator CLI v\(version)")
            exit(0)
        case "help", "-h", "--help":
            printHelp()
            exit(0)
        default:
            print("❌ Unknown command: \(command)")
            printHelp()
            exit(1)
        }
    }

    // MARK: - Command Handlers

    /// Generate icons from source image
    private func handleGenerate(args: [String]) {
        var sourcePath: String?
        var outputPath: String?
        var platforms: [String] = []
        var preset: String?

        var i = 0
        while i < args.count {
            let arg = args[i]

            switch arg {
            case "-i", "--input":
                i += 1
                sourcePath = args[i]
            case "-o", "--output":
                i += 1
                outputPath = args[i]
            case "-p", "--platforms":
                i += 1
                platforms = args[i].split(separator: ",").map(String.init)
            case "--preset":
                i += 1
                preset = args[i]
            case "-v", "--verbose":
                verbose = true
            default:
                print("⚠️ Unknown option: \(arg)")
            }

            i += 1
        }

        guard let source = sourcePath else {
            print("❌ Error: --input is required")
            exit(1)
        }

        guard let output = outputPath else {
            print("❌ Error: --output is required")
            exit(1)
        }

        if verbose {
            print("📥 Input: \(source)")
            print("📤 Output: \(output)")
            print("🎯 Platforms: \(platforms.isEmpty ? "all" : platforms.joined(separator: ", "))")
            if let p = preset { print("🎨 Preset: \(p)") }
        }

        do {
            try generateIcons(source: source, output: output, platforms: platforms, preset: preset)
            print("✅ Icons generated successfully")
            exit(0)
        } catch {
            print("❌ Error: \(error.localizedDescription)")
            exit(1)
        }
    }

    /// Watch folder for changes and auto-regenerate
    private func handleWatch(args: [String]) {
        var watchPath: String?
        var outputPath: String?
        var debounceSeconds = 2.0

        var i = 0
        while i < args.count {
            let arg = args[i]

            switch arg {
            case "-i", "--input":
                i += 1
                watchPath = args[i]
            case "-o", "--output":
                i += 1
                outputPath = args[i]
            case "--debounce":
                i += 1
                debounceSeconds = Double(args[i]) ?? 2.0
            case "-v", "--verbose":
                verbose = true
            default:
                print("⚠️ Unknown option: \(arg)")
            }

            i += 1
        }

        guard let watch = watchPath else {
            print("❌ Error: --input is required")
            exit(1)
        }

        guard let output = outputPath else {
            print("❌ Error: --output is required")
            exit(1)
        }

        print("👁️ Watching: \(watch)")
        print("📤 Output: \(output)")
        print("⏱️ Debounce: \(debounceSeconds)s")
        print("Press Ctrl+C to stop")

        watchFolder(path: watch, output: output, debounce: debounceSeconds)
    }

    /// Optimize existing icons
    private func handleOptimize(args: [String]) {
        var inputPath: String?
        var aggressive = false

        var i = 0
        while i < args.count {
            let arg = args[i]

            switch arg {
            case "-i", "--input":
                i += 1
                inputPath = args[i]
            case "--aggressive":
                aggressive = true
            case "-v", "--verbose":
                verbose = true
            default:
                print("⚠️ Unknown option: \(arg)")
            }

            i += 1
        }

        guard let input = inputPath else {
            print("❌ Error: --input is required")
            exit(1)
        }

        do {
            let savings = try optimizeIcons(path: input, aggressive: aggressive)
            print("✅ Optimization complete")
            print("💾 Saved: \(ByteCountFormatter.string(fromByteCount: savings, countStyle: .file))")
            exit(0)
        } catch {
            print("❌ Error: \(error.localizedDescription)")
            exit(1)
        }
    }

    /// Analyze icon performance
    private func handleAnalyze(args: [String]) {
        var inputPath: String?
        var format = "text"

        var i = 0
        while i < args.count {
            let arg = args[i]

            switch arg {
            case "-i", "--input":
                i += 1
                inputPath = args[i]
            case "-f", "--format":
                i += 1
                format = args[i]
            case "-v", "--verbose":
                verbose = true
            default:
                print("⚠️ Unknown option: \(arg)")
            }

            i += 1
        }

        guard let input = inputPath else {
            print("❌ Error: --input is required")
            exit(1)
        }

        do {
            let analysis = try analyzeIcons(path: input)

            if format == "json" {
                printJSON(analysis)
            } else {
                printAnalysis(analysis)
            }

            exit(0)
        } catch {
            print("❌ Error: \(error.localizedDescription)")
            exit(1)
        }
    }

    /// Generate icon variants for A/B testing
    private func handleVariants(args: [String]) {
        var sourcePath: String?
        var outputPath: String?
        var variantCount = 3
        var styles: [String] = []

        var i = 0
        while i < args.count {
            let arg = args[i]

            switch arg {
            case "-i", "--input":
                i += 1
                sourcePath = args[i]
            case "-o", "--output":
                i += 1
                outputPath = args[i]
            case "-n", "--count":
                i += 1
                variantCount = Int(args[i]) ?? 3
            case "--styles":
                i += 1
                styles = args[i].split(separator: ",").map(String.init)
            case "-v", "--verbose":
                verbose = true
            default:
                print("⚠️ Unknown option: \(arg)")
            }

            i += 1
        }

        guard let source = sourcePath else {
            print("❌ Error: --input is required")
            exit(1)
        }

        guard let output = outputPath else {
            print("❌ Error: --output is required")
            exit(1)
        }

        do {
            let variants = try generateVariants(source: source, output: output, count: variantCount, styles: styles)

            print("✅ Generated \(variants.count) variants")
            for (index, variant) in variants.enumerated() {
                print("  \(index + 1). \(variant)")
            }

            exit(0)
        } catch {
            print("❌ Error: \(error.localizedDescription)")
            exit(1)
        }
    }

    // MARK: - Implementation Methods

    private func generateIcons(source: String, output: String, platforms: [String], preset: String?) throws {
        let sourceURL = URL(fileURLWithPath: source)
        let outputURL = URL(fileURLWithPath: output)

        guard let image = NSImage(contentsOf: sourceURL) else {
            throw CLIError.invalidImage("Could not load image from \(source)")
        }

        if verbose {
            print("📊 Image size: \(Int(image.size.width))×\(Int(image.size.height))")
        }

        // Create output directory
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        // Generate platform-specific icon sets
        let platformList = platforms.isEmpty ? ["iOS", "macOS", "watchOS", "tvOS"] : platforms

        for platform in platformList {
            if verbose {
                print("🎯 Generating \(platform) icons...")
            }

            let platformDir = outputURL.appendingPathComponent(platform)
            try FileManager.default.createDirectory(at: platformDir, withIntermediateDirectories: true)

            // Generate sizes based on platform
            let sizes = getSizesForPlatform(platform)
            for size in sizes {
                let resized = resize(image: image, to: CGSize(width: size, height: size))
                let filename = "icon_\(Int(size))x\(Int(size)).png"
                let fileURL = platformDir.appendingPathComponent(filename)

                try saveImage(resized, to: fileURL)

                if verbose {
                    print("  ✓ \(filename)")
                }
            }
        }
    }

    private func watchFolder(path: String, output: String, debounce: TimeInterval) {
        let fileManager = FileManager.default
        var lastChangeTime = Date()
        var isProcessing = false

        // Setup file system monitor
        let watchURL = URL(fileURLWithPath: path)

        print("✅ Watch mode started")

        // Simple polling implementation (production would use FSEvents)
        var lastModificationDates: [String: Date] = [:]

        while true {
            Thread.sleep(forTimeInterval: 1.0)

            guard let enumerator = fileManager.enumerator(at: watchURL, includingPropertiesForKeys: [.contentModificationDateKey]) else {
                continue
            }

            for case let fileURL as URL in enumerator {
                guard fileURL.pathExtension.lowercased() == "png" ||
                      fileURL.pathExtension.lowercased() == "jpg" ||
                      fileURL.pathExtension.lowercased() == "jpeg" else {
                    continue
                }

                if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                   let modDate = attributes[.modificationDate] as? Date {

                    let key = fileURL.path

                    if let lastDate = lastModificationDates[key] {
                        if modDate > lastDate && !isProcessing {
                            let timeSinceChange = Date().timeIntervalSince(lastChangeTime)

                            if timeSinceChange >= debounce {
                                print("\n🔄 Change detected: \(fileURL.lastPathComponent)")
                                isProcessing = true

                                do {
                                    try generateIcons(source: fileURL.path, output: output, platforms: [], preset: nil)
                                    print("✅ Regenerated icons")
                                } catch {
                                    print("❌ Error: \(error.localizedDescription)")
                                }

                                isProcessing = false
                                lastChangeTime = Date()
                            }
                        }
                    }

                    lastModificationDates[key] = modDate
                }
            }
        }
    }

    private func optimizeIcons(path: String, aggressive: Bool) throws -> Int64 {
        let url = URL(fileURLWithPath: path)
        var totalSavings: Int64 = 0

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            throw CLIError.invalidPath("Cannot enumerate directory: \(path)")
        }

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension.lowercased() == "png" else { continue }

            let originalSize = try fileManager.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 ?? 0

            if let image = NSImage(contentsOf: fileURL) {
                // Re-save with optimized compression
                try saveImage(image, to: fileURL, quality: aggressive ? 0.7 : 0.9)

                let newSize = try fileManager.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 ?? 0
                let saved = originalSize - newSize

                if saved > 0 {
                    totalSavings += saved

                    if verbose {
                        let percent = Double(saved) / Double(originalSize) * 100
                        print("  \(fileURL.lastPathComponent): -\(String(format: "%.1f", percent))%")
                    }
                }
            }
        }

        return totalSavings
    }

    private func analyzeIcons(path: String) throws -> IconAnalysis {
        let url = URL(fileURLWithPath: path)
        var analysis = IconAnalysis()

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            throw CLIError.invalidPath("Cannot enumerate directory: \(path)")
        }

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension.lowercased() == "png" else { continue }

            if let image = NSImage(contentsOf: fileURL) {
                let size = try fileManager.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 ?? 0

                analysis.totalFiles += 1
                analysis.totalSize += size
                analysis.averageSize = analysis.totalSize / Int64(analysis.totalFiles)

                let dimensions = image.size
                if dimensions.width != dimensions.height {
                    analysis.issues.append("Non-square icon: \(fileURL.lastPathComponent)")
                }

                if size > 100_000 { // 100KB
                    analysis.issues.append("Large file: \(fileURL.lastPathComponent) (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)))")
                }

                // Check for transparency
                if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    if cgImage.alphaInfo != .none {
                        analysis.hasTransparency = true
                    }
                }
            }
        }

        // Calculate optimization potential
        analysis.potentialSavings = analysis.totalSize / 5 // Estimate 20% savings

        return analysis
    }

    private func generateVariants(source: String, output: String, count: Int, styles: [String]) throws -> [String] {
        let sourceURL = URL(fileURLWithPath: source)
        let outputURL = URL(fileURLWithPath: output)

        guard let image = NSImage(contentsOf: sourceURL) else {
            throw CLIError.invalidImage("Could not load image from \(source)")
        }

        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        var generatedVariants: [String] = []

        // Generate variants with different styles
        let variantStyles = styles.isEmpty ? ["original", "gradient", "shadow", "rounded"] : styles

        for (index, style) in variantStyles.prefix(count).enumerated() {
            let variantID = String(format: "variant_%02d", index + 1)
            let variantDir = outputURL.appendingPathComponent(variantID)
            try FileManager.default.createDirectory(at: variantDir, withIntermediateDirectories: true)

            // Apply style transformation
            let styledImage = applyStyle(to: image, style: style)

            // Save variant
            let variantFile = variantDir.appendingPathComponent("icon.png")
            try saveImage(styledImage, to: variantFile)

            // Create metadata
            let metadata = [
                "id": variantID,
                "style": style,
                "created": ISO8601DateFormatter().string(from: Date())
            ]

            let metadataFile = variantDir.appendingPathComponent("metadata.json")
            let jsonData = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
            try jsonData.write(to: metadataFile)

            generatedVariants.append(variantID)

            if verbose {
                print("  ✓ \(variantID) (\(style))")
            }
        }

        return generatedVariants
    }

    // MARK: - Helper Methods

    private func getSizesForPlatform(_ platform: String) -> [CGFloat] {
        switch platform.lowercased() {
        case "ios":
            return [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024]
        case "macos":
            return [16, 32, 64, 128, 256, 512, 1024]
        case "watchos":
            return [24, 27.5, 29, 40, 44, 50, 86, 98, 108, 117, 129, 1024]
        case "tvos":
            return [400, 1280]
        default:
            return [1024]
        }
    }

    private func resize(image: NSImage, to newSize: CGSize) -> NSImage {
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)

        newImage.unlockFocus()
        return newImage
    }

    private func saveImage(_ image: NSImage, to url: URL, quality: Double = 1.0) throws {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw CLIError.invalidImage("Could not create CGImage")
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        bitmapRep.size = image.size

        let properties: [NSBitmapImageRep.PropertyKey: Any] = [
            .compressionFactor: quality
        ]

        guard let pngData = bitmapRep.representation(using: .png, properties: properties) else {
            throw CLIError.exportFailed("Could not generate PNG data")
        }

        try pngData.write(to: url)
    }

    private func applyStyle(to image: NSImage, style: String) -> NSImage {
        // Style transformations would be implemented here
        // For now, return original image
        // In production: gradient overlays, shadows, corner radius, etc.
        return image
    }

    private func printAnalysis(_ analysis: IconAnalysis) {
        print("\n📊 Icon Analysis Report")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Total Files: \(analysis.totalFiles)")
        print("Total Size: \(ByteCountFormatter.string(fromByteCount: analysis.totalSize, countStyle: .file))")
        print("Average Size: \(ByteCountFormatter.string(fromByteCount: analysis.averageSize, countStyle: .file))")
        print("Has Transparency: \(analysis.hasTransparency ? "Yes" : "No")")
        print("Potential Savings: \(ByteCountFormatter.string(fromByteCount: analysis.potentialSavings, countStyle: .file))")

        if !analysis.issues.isEmpty {
            print("\n⚠️ Issues Found:")
            for issue in analysis.issues {
                print("  • \(issue)")
            }
        }

        print("\n✅ Analysis complete")
    }

    private func printJSON(_ analysis: IconAnalysis) {
        let dict: [String: Any] = [
            "totalFiles": analysis.totalFiles,
            "totalSize": analysis.totalSize,
            "averageSize": analysis.averageSize,
            "hasTransparency": analysis.hasTransparency,
            "potentialSavings": analysis.potentialSavings,
            "issues": analysis.issues
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }

    private func printHelp() {
        print("""
        Icon Creator CLI v\(version)

        USAGE:
            icon-creator <command> [options]

        COMMANDS:
            generate    Generate icons from source image
            watch       Watch folder and auto-regenerate on changes
            optimize    Optimize existing icons for size
            analyze     Analyze icon performance metrics
            variants    Generate A/B testing variants
            version     Show version number
            help        Show this help message

        GENERATE OPTIONS:
            -i, --input <path>         Source image file (required)
            -o, --output <path>        Output directory (required)
            -p, --platforms <list>     Comma-separated platforms (iOS,macOS,watchOS,tvOS)
            --preset <name>            Apply named preset
            -v, --verbose              Verbose output

        WATCH OPTIONS:
            -i, --input <path>         Watch directory (required)
            -o, --output <path>        Output directory (required)
            --debounce <seconds>       Debounce time (default: 2.0)
            -v, --verbose              Verbose output

        OPTIMIZE OPTIONS:
            -i, --input <path>         Icon directory (required)
            --aggressive               Aggressive compression
            -v, --verbose              Verbose output

        ANALYZE OPTIONS:
            -i, --input <path>         Icon directory (required)
            -f, --format <type>        Output format (text|json, default: text)
            -v, --verbose              Verbose output

        VARIANTS OPTIONS:
            -i, --input <path>         Source image (required)
            -o, --output <path>        Output directory (required)
            -n, --count <number>       Number of variants (default: 3)
            --styles <list>            Comma-separated styles
            -v, --verbose              Verbose output

        EXAMPLES:
            # Generate icons for all platforms
            icon-creator generate -i icon.png -o ./output

            # Generate iOS icons only
            icon-creator generate -i icon.png -o ./output -p iOS

            # Watch folder for changes
            icon-creator watch -i ./source -o ./output

            # Optimize existing icons
            icon-creator optimize -i ./Assets.xcassets --aggressive

            # Analyze icon performance
            icon-creator analyze -i ./Assets.xcassets -f json

            # Generate 5 variants for A/B testing
            icon-creator variants -i icon.png -o ./variants -n 5

        For more information: https://github.com/kochj23/icon-creator
        """)
    }
}

// MARK: - Supporting Types

struct IconAnalysis {
    var totalFiles = 0
    var totalSize: Int64 = 0
    var averageSize: Int64 = 0
    var hasTransparency = false
    var potentialSavings: Int64 = 0
    var issues: [String] = []
}

enum CLIError: LocalizedError {
    case invalidImage(String)
    case invalidPath(String)
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage(let message),
             .invalidPath(let message),
             .exportFailed(let message):
            return message
        }
    }
}

// MARK: - Entry Point

let cli = IconCreatorCLI()
cli.run()
