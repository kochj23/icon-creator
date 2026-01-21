import Foundation
import AppKit

//
//  IconCreatorCLI+Core.swift
//  Icon Creator CLI - Core Icon Generation Logic
//
//  This file contains the core icon generation logic
//  Extracted from the main IconGenerator to be reusable in CLI
//  Author: Jordan Koch
//  Date: 2026-01-21
//

extension IconCreatorCLI {

    // MARK: - Icon Generation (Real Implementation)

    func generateIcons(source: String, output: String, platforms: [String], preset: String?) throws {
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

        // Determine platforms to generate
        let platformList = platforms.isEmpty ? ["iOS", "macOS", "watchOS", "tvOS"] : platforms

        // Generate for each platform
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

        // Generate icons for all required sizes
        let sizes = platform.iconSizes

        for size in sizes {
            let scales: [Int] = size == 1024 ? [1] : getScalesForPlatform(size, platform: platform)

            for scale in scales {
                let actualSize = size / scale
                let pixelSize = actualSize * scale

                let filename = "icon_\(actualSize)x\(actualSize)@\(scale)x.png"
                let fileURL = appiconsetDir.appendingPathComponent(filename)

                // Resize and save image
                let resized = resizeImage(image, to: CGSize(width: pixelSize, height: pixelSize))
                try saveImageAsPNG(resized, to: fileURL)

                // Add to Contents.json
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

        // Save Contents.json
        let contentsURL = appiconsetDir.appendingPathComponent("Contents.json")
        let jsonData = try JSONSerialization.data(withJSONObject: contentsJSON, options: [.prettyPrinted, .sortedKeys])
        try jsonData.write(to: contentsURL)
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

    private func saveImageAsPNG(_ image: NSImage, to url: URL) throws {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw CLIError.imageExportFailed("Could not create CGImage")
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        bitmapRep.size = image.size

        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
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
        case "imessage": return .iMessage
        case "maccatalyst", "catalyst": return .macCatalyst
        default: return nil
        }
    }

    private func getScalesForPlatform(_ size: Int, platform: IconPlatform) -> [Int] {
        switch platform {
        case .iOS, .macCatalyst:
            if size == 20 || size == 29 || size == 40 { return [1, 2, 3] }
            return [2, 3]
        case .macOS:
            return [1, 2]
        case .tvOS:
            return [1]
        case .watchOS:
            return [2]
        case .iMessage:
            return [2, 3]
        }
    }
}

// MARK: - Platform Enum

enum IconPlatform {
    case iOS
    case macOS
    case tvOS
    case watchOS
    case iMessage
    case macCatalyst

    var rawValue: String {
        switch self {
        case .iOS: return "iOS"
        case .macOS: return "macOS"
        case .tvOS: return "tvOS"
        case .watchOS: return "watchOS"
        case .iMessage: return "iMessage"
        case .macCatalyst: return "Mac Catalyst"
        }
    }

    var iconSizes: [Int] {
        switch self {
        case .iOS, .macCatalyst:
            return [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024]
        case .macOS:
            return [16, 32, 64, 128, 256, 512, 1024]
        case .tvOS:
            return [400, 1280]
        case .watchOS:
            return [24, 27, 29, 40, 44, 50, 51, 86, 98, 108, 117, 129, 1024]
        case .iMessage:
            return [60, 67, 74, 81, 120, 134, 148, 180, 1024]
        }
    }

    var folderName: String {
        return rawValue.replacingOccurrences(of: " ", with: "")
    }

    var idiom: String {
        switch self {
        case .iOS, .macCatalyst: return "iphone"
        case .macOS: return "mac"
        case .tvOS: return "tv"
        case .watchOS: return "watch"
        case .iMessage: return "ios-marketing"
        }
    }
}

// MARK: - Errors

enum CLIError: LocalizedError {
    case invalidImage(String)
    case invalidPath(String)
    case exportFailed(String)
    case imageExportFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage(let message),
             .invalidPath(let message),
             .exportFailed(let message),
             .imageExportFailed(let message):
            return message
        }
    }
}
