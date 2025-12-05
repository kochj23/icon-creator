import Foundation
import AppKit

/// Validate command for CLI
struct ValidateCommand {

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

        // Parse platform (default: iOS)
        let platformString = parser.value(for: "--platform") ?? "ios"
        let platform: Platform
        switch platformString.lowercased() {
        case "ios": platform = .iOS
        case "macos": platform = .macOS
        case "tvos": platform = .tvOS
        case "watchos": platform = .watchOS
        case "imessage": platform = .iMessage
        case "catalyst": platform = .macCatalyst
        default:
            return .failure("Unknown platform: \(platformString)")
        }

        let verbose = parser.hasFlag("--verbose")

        // Validate
        let validator = IconValidator()
        let result = validator.validate(image: image, for: platform)

        // Print results
        print("\n🔍 Validation Report for \(platform.rawValue)\n")
        print("Image: \(sourcePath)")
        print("Size: \(Int(image.size.width))×\(Int(image.size.height)) pixels\n")

        if result.isValid {
            print("✅ Image is valid for icon generation\n")
        } else {
            print("❌ Image has \(result.errors.count) error(s)\n")
        }

        // Errors
        if !result.errors.isEmpty {
            print("ERRORS:")
            for error in result.errors {
                print("  ❌ \(error.message)")
            }
            print("")
        }

        // Warnings
        if !result.warnings.isEmpty {
            print("WARNINGS:")
            for warning in result.warnings {
                print("  ⚠️  \(warning.message)")
            }
            print("")
        }

        // Suggestions
        if verbose && !result.suggestions.isEmpty {
            print("SUGGESTIONS:")
            for suggestion in result.suggestions {
                print("  💡 \(suggestion.message)")
            }
            print("")
        }

        // Summary
        let summary = """
        SUMMARY:
          Errors: \(result.errors.count)
          Warnings: \(result.warnings.count)
          Suggestions: \(result.suggestions.isEmpty)

        Status: \(result.isValid ? "✅ PASSED" : "❌ FAILED")
        """

        print(summary)

        return result.isValid ? .success("Validation passed") : .failure("Validation failed with \(result.errors.count) error(s)")
    }
}
