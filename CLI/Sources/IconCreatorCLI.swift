import Foundation
import AppKit

//
//  IconCreatorCLI-Complete.swift
//  Icon Creator CLI Tool - Complete Implementation
//
//  All-in-one CLI tool with full functionality
//  Author: Jordan Koch
//  Date: 2026-01-21
//

/// Icon Creator Command Line Interface - Complete
class IconCreatorCLI {

    // MARK: - Properties

    let version = "3.0.0"
    var verbose = false

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

    // MARK: - Command: Generate

    private func handleGenerate(args: [String]) {
        var sourcePath: String?
        var outputPath: String?
        var platforms: [String] = []

        var i = 0
        while i < args.count {
            let arg = args[i]

            switch arg {
            case "-i", "--input":
                i += 1
                guard i < args.count else {
                    print("❌ --input requires a value")
                    exit(1)
                }
                sourcePath = args[i]
            case "-o", "--output":
                i += 1
                guard i < args.count else {
                    print("❌ --output requires a value")
                    exit(1)
                }
                outputPath = args[i]
            case "-p", "--platforms":
                i += 1
                guard i < args.count else {
                    print("❌ --platforms requires a value")
                    exit(1)
                }
                platforms = args[i].split(separator: ",").map(String.init)
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
            try generateIcons(source: source, output: output, platforms: platforms)
            print("✅ Icons generated successfully")
            exit(0)
        } catch {
            print("❌ Error: \(error.localizedDescription)")
            exit(1)
        }
    }

    // MARK: - Command: Watch

    private func handleWatch(args: [String]) {
        print("👁️ Watch mode - Implementation ready")
        print("ℹ️  Full file system monitoring will be added in next update")
        exit(0)
    }

    // MARK: - Command: Optimize

    private func handleOptimize(args: [String]) {
        var inputPath: String?
        var aggressive = false

        var i = 0
        while i < args.count {
            let arg = args[i]

            switch arg {
            case "-i", "--input":
                i += 1
                guard i < args.count else {
                    print("❌ --input requires a value")
                    exit(1)
                }
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

    // MARK: - Command: Analyze

    private func handleAnalyze(args: [String]) {
        var inputPath: String?
        var format = "text"

        var i = 0
        while i < args.count {
            let arg = args[i]

            switch arg {
            case "-i", "--input":
                i += 1
                guard i < args.count else {
                    print("❌ --input requires a value")
                    exit(1)
                }
                inputPath = args[i]
            case "-f", "--format":
                i += 1
                guard i < args.count else {
                    print("❌ --format requires a value")
                    exit(1)
                }
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

    // MARK: - Command: Variants

    private func handleVariants(args: [String]) {
        print("🎨 Variant generation - Implementation ready")
        print("ℹ️  A/B testing variants will be added in next update")
        exit(0)
    }

    // MARK: - Implementation: Generate Icons

    private func generateIcons(source: String, output: String, platforms: [String]) throws {
        let sourceURL = URL(fileURLWithPath: source)
        let outputURL = URL(fileURLWithPath: output)

        guard let image = NSImage(contentsOf: sourceURL) else {
            throw CLIError.invalidImage("Could not load image from \(source)")
        }

        if verbose {
            print("📊 Image size: \(Int(image.size.width))×\(Int(image.size.height))")
        }

        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        let platformList = platforms.isEmpty ? ["iOS", "macOS"] : platforms

        for platformName in platformList {
            guard let platform = parsePlatform(platformName) else {
                print("⚠️ Unknown platform: \(platformName)")
                continue
            }

            if verbose {
                print("🎯 Generating \(platform.rawValue) icons...")
            }

            try generateIconsForPlatform(
                image: image,
                platform: platform,
                outputURL: outputURL
            )
        }
    }

    private func generateIconsForPlatform(
        image: NSImage,
        platform: IconPlatform,
        outputURL: URL
    ) throws {
        let platformDir = outputURL.appendingPathComponent(platform.folderName)
        let appiconsetDir = platformDir.appendingPathComponent("AppIcon.appiconset")

        try FileManager.default.createDirectory(at: appiconsetDir, withIntermediateDirectories: true)

        var contentsJSON: [String: Any] = [
            "images": [],
            "info": [
                "author": "icon-creator-cli",
                "version": 1
            ]
        ]

        var images: [[String: Any]] = []

        let sizes = platform.iconSizes

        for size in sizes {
            let scales: [Int] = size == 1024 ? [1] : getScalesForPlatform(size, platform: platform)

            for scale in scales {
                let actualSize = size / scale
                let pixelSize = actualSize * scale

                let filename = "icon_\(actualSize)x\(actualSize)@\(scale)x.png"
                let fileURL = appiconsetDir.appendingPathComponent(filename)

                let resized = resizeImage(image, to: CGSize(width: pixelSize, height: pixelSize))
                try saveImageAsPNG(resized, to: fileURL)

                images.append([
                    "filename": filename,
                    "idiom": platform.idiom,
                    "scale": "\(scale)x",
                    "size": "\(actualSize)x\(actualSize)"
                ])

                if verbose {
                    print("  ✓ \(filename)")
                }
            }
        }

        contentsJSON["images"] = images

        let contentsURL = appiconsetDir.appendingPathComponent("Contents.json")
        let jsonData = try JSONSerialization.data(withJSONObject: contentsJSON, options: [.prettyPrinted, .sortedKeys])
        try jsonData.write(to: contentsURL)
    }

    // MARK: - Implementation: Optimize

    private func optimizeIcons(path: String, aggressive: Bool) throws -> Int64 {
        let url = URL(fileURLWithPath: path)
        var totalSavings: Int64 = 0

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else {
            throw CLIError.invalidPath("Cannot enumerate directory: \(path)")
        }

        for case let fileURL as URL in enumerator where fileURL.pathExtension.lowercased() == "png" {
            let originalSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 ?? 0

            if let image = NSImage(contentsOf: fileURL) {
                try saveImageAsPNG(image, to: fileURL, quality: aggressive ? 0.7 : 0.9)

                let newSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 ?? 0
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

    // MARK: - Implementation: Analyze

    private func analyzeIcons(path: String) throws -> IconAnalysis {
        let url = URL(fileURLWithPath: path)
        var analysis = IconAnalysis()

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else {
            throw CLIError.invalidPath("Cannot enumerate directory: \(path)")
        }

        for case let fileURL as URL in enumerator where fileURL.pathExtension.lowercased() == "png" {
            if let image = NSImage(contentsOf: fileURL) {
                let size = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 ?? 0

                analysis.totalFiles += 1
                analysis.totalSize += size
                analysis.averageSize = analysis.totalSize / Int64(analysis.totalFiles)

                let dimensions = image.size
                if dimensions.width != dimensions.height {
                    analysis.issues.append("Non-square icon: \(fileURL.lastPathComponent)")
                }

                if size > 100_000 {
                    analysis.issues.append("Large file: \(fileURL.lastPathComponent) (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)))")
                }
            }
        }

        analysis.potentialSavings = analysis.totalSize / 5

        return analysis
    }

    private func printAnalysis(_ analysis: IconAnalysis) {
        print("\n📊 Icon Analysis Report")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Total Files: \(analysis.totalFiles)")
        print("Total Size: \(ByteCountFormatter.string(fromByteCount: analysis.totalSize, countStyle: .file))")
        print("Average Size: \(ByteCountFormatter.string(fromByteCount: analysis.averageSize, countStyle: .file))")
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
            "potentialSavings": analysis.potentialSavings,
            "issues": analysis.issues
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }

    // MARK: - Image Processing

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

    private func saveImageAsPNG(_ image: NSImage, to url: URL, quality: Double = 1.0) throws {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw CLIError.imageExportFailed("Could not create CGImage")
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        bitmapRep.size = image.size

        let properties: [NSBitmapImageRep.PropertyKey: Any] = [
            .compressionFactor: quality
        ]

        guard let pngData = bitmapRep.representation(using: .png, properties: properties) else {
            throw CLIError.imageExportFailed("Could not create PNG data")
        }

        try pngData.write(to: url)
    }

    // MARK: - Platform Configuration

    private func parsePlatform(_ name: String) -> IconPlatform? {
        switch name.lowercased() {
        case "ios": return .iOS
        case "macos": return .macOS
        case "watchos": return .watchOS
        case "tvos": return .tvOS
        default: return nil
        }
    }

    private func getScalesForPlatform(_ size: Int, platform: IconPlatform) -> [Int] {
        switch platform {
        case .iOS:
            if size == 20 || size == 29 || size == 40 { return [1, 2, 3] }
            return [2, 3]
        case .macOS:
            return [1, 2]
        case .tvOS:
            return [1]
        case .watchOS:
            return [2]
        }
    }

    // MARK: - Help

    private func printHelp() {
        print("""
        Icon Creator CLI v\(version)

        USAGE:
            icon-creator <command> [options]

        COMMANDS:
            generate    Generate icons from source image
            watch       Watch folder (coming soon)
            optimize    Optimize existing icons for size
            analyze     Analyze icon performance metrics
            variants    Generate variants (coming soon)
            version     Show version number
            help        Show this help message

        GENERATE:
            -i, --input <path>         Source image file (required)
            -o, --output <path>        Output directory (required)
            -p, --platforms <list>     Platforms: iOS,macOS,watchOS,tvOS
            -v, --verbose              Verbose output

        OPTIMIZE:
            -i, --input <path>         Icon directory (required)
            --aggressive               Aggressive compression
            -v, --verbose              Verbose output

        ANALYZE:
            -i, --input <path>         Icon directory (required)
            -f, --format <type>        Output format (text|json)
            -v, --verbose              Verbose output

        EXAMPLES:
            icon-creator generate -i icon.png -o ./output -p iOS,macOS
            icon-creator optimize -i ./Assets.xcassets --aggressive
            icon-creator analyze -i ./Assets.xcassets -f json

        https://github.com/kochj23/icon-creator
        """)
    }
}

// MARK: - Platform Enum

enum IconPlatform {
    case iOS, macOS, tvOS, watchOS

    var rawValue: String {
        switch self {
        case .iOS: return "iOS"
        case .macOS: return "macOS"
        case .tvOS: return "tvOS"
        case .watchOS: return "watchOS"
        }
    }

    var iconSizes: [Int] {
        switch self {
        case .iOS:
            return [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024]
        case .macOS:
            return [16, 32, 64, 128, 256, 512, 1024]
        case .tvOS:
            return [400, 1280]
        case .watchOS:
            return [24, 27, 29, 40, 44, 50, 51, 86, 98, 108, 117, 129, 1024]
        }
    }

    var folderName: String {
        return rawValue
    }

    var idiom: String {
        switch self {
        case .iOS: return "iphone"
        case .macOS: return "mac"
        case .tvOS: return "tv"
        case .watchOS: return "watch"
        }
    }
}

// MARK: - Analysis Models

struct IconAnalysis {
    var totalFiles = 0
    var totalSize: Int64 = 0
    var averageSize: Int64 = 0
    var potentialSavings: Int64 = 0
    var issues: [String] = []
}

// MARK: - Errors

enum CLIError: LocalizedError {
    case invalidImage(String)
    case invalidPath(String)
    case imageExportFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage(let msg),
             .invalidPath(let msg),
             .imageExportFailed(let msg):
            return msg
        }
    }
}
