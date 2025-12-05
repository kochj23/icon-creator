import Foundation
import AppKit

/// Generate command for CLI
struct GenerateCommand {

    static func run(with arguments: [String]) -> CommandResult {
        let parser = ArgumentParser(arguments: arguments)

        // Required: source
        guard let sourcePath = parser.value(for: "--source") else {
            return .failure("--source is required")
        }

        // Load image
        guard let image = NSImage(contentsOfFile: sourcePath) else {
            return .failure("Cannot load image at \(sourcePath)")
        }

        // Parse platforms (default: iOS)
        let platformStrings = parser.values(for: "--platforms") ?? ["ios"]
        let platforms = platformStrings.compactMap { platformString -> Platform? in
            switch platformString.lowercased() {
            case "ios": return .iOS
            case "macos": return .macOS
            case "tvos": return .tvOS
            case "watchos": return .watchOS
            case "imessage": return .iMessage
            case "catalyst", "maccatalyst": return .macCatalyst
            default:
                print("⚠️ Unknown platform: \(platformString)")
                return nil
            }
        }

        guard !platforms.isEmpty else {
            return .failure("No valid platforms specified")
        }

        // Output path (default: current directory)
        let outputPath = parser.value(for: "--output") ?? FileManager.default.currentDirectoryPath
        let outputURL = URL(fileURLWithPath: outputPath)

        // Create icon generator
        let generator = IconGenerator()
        generator.sourceImage = image

        // Apply preset if specified
        if let presetName = parser.value(for: "--preset") {
            if let preset = getPreset(named: presetName) {
                generator.applySettings(preset.settings)
                print("📋 Applied preset: \(presetName)")
            } else {
                print("⚠️ Unknown preset: \(presetName), using defaults")
            }
        }

        // Apply custom settings
        if let scaleStr = parser.value(for: "--scale"), let scale = Double(scaleStr) {
            generator.scale = scale
        }

        if let paddingStr = parser.value(for: "--padding"), let padding = Double(paddingStr) {
            generator.padding = padding
        }

        if let bgHex = parser.value(for: "--background") {
            if let color = hexToColor(bgHex) {
                generator.backgroundColor = color
            }
        }

        if let cornersStr = parser.value(for: "--corners"), let corners = Double(cornersStr) {
            generator.effects.cornerRadiusEnabled = true
            generator.effects.cornerRadius = corners
        }

        if parser.hasFlag("--shadow") {
            generator.effects.shadowEnabled = true
        }

        if let borderStr = parser.value(for: "--border"), let border = Double(borderStr) {
            generator.effects.borderEnabled = true
            generator.effects.borderWidth = border
        }

        // Validate image
        let validation = generator.validateSourceImage()
        if !validation.isValid {
            return .failure(validation.error ?? "Image validation failed")
        }

        // Export format
        let exportFormat = parser.value(for: "--export-format")?.lowercased() ?? "xcode"

        // Generate icons
        print("🎨 Generating icons for \(platforms.count) platform(s)...")

        do {
            for platform in platforms {
                print("  → \(platform.rawValue)...", terminator: "")

                try generator.exportIcons(for: platform, to: outputURL) { progress in
                    // Show progress
                    let percent = Int(progress * 100)
                    if percent % 20 == 0 {
                        print(" \(percent)%", terminator: "")
                    }
                }

                print(" ✓")
            }

            // Additional export formats
            if exportFormat != "xcode" {
                let exportManager = ExportManager()
                let format: ExportManager.ExportFormat

                switch exportFormat {
                case "android":
                    format = .android
                case "web":
                    format = .web
                case "windows":
                    format = .windows
                case "electron":
                    format = .electron
                default:
                    print("⚠️ Unknown export format: \(exportFormat), defaulting to xcode")
                    format = .xcode
                }

                if format != .xcode {
                    print("📦 Exporting \(exportFormat) format...")
                    try await exportManager.export(icon: image, format: format, to: outputURL, settings: generator.currentSettings)
                }
            }

            return .success("Generated icons for \(platforms.count) platform(s) → \(outputURL.path)")

        } catch {
            return .failure("Export failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

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

    private static func hexToColor(_ hex: String) -> Color? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        return Color(red: r, green: g, blue: b)
    }
}
