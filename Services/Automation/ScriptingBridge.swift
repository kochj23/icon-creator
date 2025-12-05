import Foundation
import AppKit

/// AppleScript bridge for Icon Creator automation
class ScriptingBridge: NSObject {

    // MARK: - AppleScript Handlers

    /// Generate icons via AppleScript
    /// Usage: tell application "Icon Creator" to generate icon from "/path/to/image.png" for platforms "ios,macos"
    @objc func generateIcon(
        fromFile sourcePath: String,
        forPlatforms platformString: String,
        withPreset presetName: String?,
        toOutput outputPath: String?
    ) -> Bool {
        // Load image
        guard let image = NSImage(contentsOfFile: sourcePath) else {
            print("❌ Cannot load image: \(sourcePath)")
            return false
        }

        // Parse platforms
        let platformNames = platformString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        let platforms = platformNames.compactMap { name -> Platform? in
            switch name.lowercased() {
            case "ios": return .iOS
            case "macos": return .macOS
            case "tvos": return .tvOS
            case "watchos": return .watchOS
            case "imessage": return .iMessage
            case "catalyst": return .macCatalyst
            default: return nil
            }
        }

        guard !platforms.isEmpty else {
            print("❌ No valid platforms specified")
            return false
        }

        // Create generator
        let generator = IconGenerator()
        generator.sourceImage = image

        // Apply preset if specified
        if let presetName = presetName {
            if let preset = getPreset(named: presetName) {
                generator.applySettings(preset.settings)
            }
        }

        // Determine output
        let output = outputPath ?? FileManager.default.currentDirectoryPath
        let outputURL = URL(fileURLWithPath: output)

        // Generate icons
        do {
            for platform in platforms {
                try generator.exportIcons(for: platform, to: outputURL)
            }
            return true
        } catch {
            print("❌ Generation failed: \(error)")
            return false
        }
    }

    /// Validate image via AppleScript
    @objc func validateImage(atPath sourcePath: String, forPlatform platformName: String) -> [String: Any] {
        guard let image = NSImage(contentsOfFile: sourcePath) else {
            return ["valid": false, "error": "Cannot load image"]
        }

        let platform: Platform
        switch platformName.lowercased() {
        case "ios": platform = .iOS
        case "macos": platform = .macOS
        case "tvos": platform = .tvOS
        case "watchos": platform = .watchOS
        default: platform = .iOS
        }

        let validator = IconValidator()
        let result = validator.validate(image: image, for: platform)

        return [
            "valid": result.isValid,
            "errors": result.errors.count,
            "warnings": result.warnings.count
        ]
    }

    // MARK: - Helpers

    private func getPreset(named name: String) -> IconPreset? {
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

// MARK: - AppleScript Support Info

/*
 AppleScript Example Usage:

 -- Generate icons
 tell application "Icon Creator"
     generate icon from "/Users/username/Desktop/icon.png" for platforms "ios,macos" with preset "rounded" to output "/Users/username/Desktop/output"
 end tell

 -- Validate image
 tell application "Icon Creator"
     set result to validate image at path "/Users/username/Desktop/icon.png" for platform "ios"
     if valid of result is true then
         display notification "Image is valid!"
     else
         display notification "Image has errors"
     end if
 end tell

 -- Batch process
 tell application "Icon Creator"
     set imageFolder to POSIX path of (choose folder with prompt "Select folder with images")
     set imageFiles to list folder imageFolder
     repeat with imageFile in imageFiles
         if imageFile ends with ".png" then
             set imagePath to imageFolder & imageFile
             generate icon from imagePath for platforms "ios" with preset "minimalist"
         end if
     end repeat
 end tell

 To enable AppleScript support:
 1. Add NSAppleScriptEnabled = YES to Info.plist
 2. Add AppleScript suite definition (.sdef file)
 3. Register scripting bridge in app delegate
 */
