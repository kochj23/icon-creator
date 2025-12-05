import Foundation
import AppKit

/// Batch processing command for CLI
struct BatchCommand {

    static func run(with arguments: [String]) -> CommandResult {
        let parser = ArgumentParser(arguments: arguments)

        // Required: directory
        guard let directoryPath = parser.value(for: "--directory") else {
            return .failure("--directory is required")
        }

        let directoryURL = URL(fileURLWithPath: directoryPath)

        guard FileManager.default.fileExists(atPath: directoryURL.path) else {
            return .failure("Directory does not exist: \(directoryPath)")
        }

        // Find all images in directory
        let imageExtensions = ["png", "jpg", "jpeg", "heic", "tiff", "bmp", "gif"]
        guard let enumerator = FileManager.default.enumerator(at: directoryURL, includingPropertiesForKeys: nil) else {
            return .failure("Cannot read directory: \(directoryPath)")
        }

        var imageURLs: [URL] = []
        for case let fileURL as URL in enumerator {
            if imageExtensions.contains(fileURL.pathExtension.lowercased()) {
                imageURLs.append(fileURL)
            }
        }

        guard !imageURLs.isEmpty else {
            return .failure("No images found in directory: \(directoryPath)")
        }

        print("📁 Found \(imageURLs.count) image(s) to process\n")

        // Parse options
        let platformStrings = parser.values(for: "--platforms") ?? ["ios"]
        let platforms = platformStrings.compactMap { platformString -> Platform? in
            switch platformString.lowercased() {
            case "ios": return .iOS
            case "macos": return .macOS
            case "tvos": return .tvOS
            case "watchos": return .watchOS
            case "imessage": return .iMessage
            case "catalyst": return .macCatalyst
            default: return nil
            }
        }

        let outputPath = parser.value(for: "--output") ?? directoryURL.appendingPathComponent("generated").path
        let outputURL = URL(fileURLWithPath: outputPath)

        // Create output directory
        try? FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        // Get preset if specified
        var settings = IconSettings.default
        if let presetName = parser.value(for: "--preset") {
            if let preset = getPreset(named: presetName) {
                settings = preset.settings
                print("📋 Using preset: \(presetName)\n")
            }
        }

        // Process each image
        var successCount = 0
        var failureCount = 0

        for (index, imageURL) in imageURLs.enumerated() {
            print("[\(index + 1)/\(imageURLs.count)] \(imageURL.lastPathComponent)...", terminator: " ")

            guard let image = NSImage(contentsOf: imageURL) else {
                print("❌ Failed to load")
                failureCount += 1
                continue
            }

            let generator = IconGenerator()
            generator.sourceImage = image
            generator.applySettings(settings)

            // Create subdirectory for this image
            let imageName = imageURL.deletingPathExtension().lastPathComponent
            let imageOutputURL = outputURL.appendingPathComponent(imageName)
            try? FileManager.default.createDirectory(at: imageOutputURL, withIntermediateDirectories: true)

            // Generate for all platforms
            var imageSuccess = true
            for platform in platforms {
                do {
                    try generator.exportIcons(for: platform, to: imageOutputURL)
                } catch {
                    imageSuccess = false
                    print("❌ \(platform.rawValue) failed")
                    break
                }
            }

            if imageSuccess {
                print("✅")
                successCount += 1
            } else {
                failureCount += 1
            }
        }

        // Summary
        print("\n" + String(repeating: "-", count: 40))
        print("📊 Batch Processing Complete")
        print(String(repeating: "-", count: 40))
        print("  Total: \(imageURLs.count)")
        print("  Success: \(successCount)")
        print("  Failed: \(failureCount)")
        print("  Output: \(outputURL.path)")

        return successCount > 0 ?
            .success("Processed \(successCount)/\(imageURLs.count) image(s)") :
            .failure("All images failed to process")
    }

    private static func getPreset(named name: String) -> IconPreset? {
        switch name.lowercased() {
        case "minimalist": return .minimalist
        case "padded": return .padded
        case "fullbleed": return .fullBleed
        case "rounded": return .rounded
        case "shadowed": return .shadowed
        case "gradient": return .gradient
        case "bordered": return .bordered
        default: return nil
        }
    }
}
