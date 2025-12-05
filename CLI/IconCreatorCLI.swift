import Foundation
import AppKit

/// Command-line interface for Icon Creator
/// Usage: icon-creator <command> [options]
@main
struct IconCreatorCLI {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())

        guard !args.isEmpty else {
            printUsage()
            exit(0)
        }

        let command = args[0]
        let commandArgs = Array(args.dropFirst())

        let result: CommandResult
        switch command {
        case "generate":
            result = GenerateCommand.run(with: commandArgs)
        case "validate":
            result = ValidateCommand.run(with: commandArgs)
        case "batch":
            result = BatchCommand.run(with: commandArgs)
        case "help", "--help", "-h":
            printUsage()
            exit(0)
        case "version", "--version", "-v":
            print("Icon Creator CLI v2.0.0")
            exit(0)
        default:
            print("❌ Unknown command: \(command)")
            printUsage()
            exit(1)
        }

        if result.success {
            print("✅ \(result.message)")
            exit(0)
        } else {
            print("❌ \(result.message)")
            exit(1)
        }
    }

    static func printUsage() {
        print("""
        Icon Creator CLI v2.0.0
        Generate app icons from the command line

        USAGE:
            icon-creator <command> [options]

        COMMANDS:
            generate    Generate icons from source image
            validate    Validate an image for icon generation
            batch       Process multiple images from a directory
            help        Show this help message
            version     Show version information

        GENERATE OPTIONS:
            --source <path>           Source image path (required)
            --platforms <list>        Comma-separated platforms (ios,macos,tvos,watchos,imessage)
            --output <path>           Output directory (default: current directory)
            --preset <name>           Use preset (minimalist,padded,fullbleed,rounded,shadowed,gradient,bordered)
            --scale <value>           Scale factor (0.5-2.0, default: 1.0)
            --padding <value>         Padding percentage (0-30, default: 10)
            --background <hex>        Background color in hex (e.g., ffffff)
            --corners <percent>       Corner radius percentage (0-50)
            --shadow                  Enable drop shadow
            --border <width>          Border width in pixels
            --export-format <format>  Export format (xcode,android,web,windows,electron)

        VALIDATE OPTIONS:
            --source <path>           Source image path (required)
            --platform <name>         Platform to validate for (ios,macos,tvos,watchos)
            --verbose                 Show detailed validation report

        BATCH OPTIONS:
            --directory <path>        Directory containing images (required)
            --platforms <list>        Platforms for all images
            --preset <name>           Preset to apply to all images
            --output <path>           Output directory

        EXAMPLES:
            # Generate iOS and macOS icons
            icon-creator generate --source icon.png --platforms ios,macos

            # Generate with preset
            icon-creator generate --source icon.png --preset rounded --platforms ios

            # Generate with custom settings
            icon-creator generate --source icon.png --scale 0.9 --padding 15 --corners 20

            # Validate an image
            icon-creator validate --source icon.png --platform ios --verbose

            # Batch process directory
            icon-creator batch --directory ./icons --platforms ios,macos --preset minimalist

            # Export to Android format
            icon-creator generate --source icon.png --export-format android

        PRESETS:
            minimalist   - 70% scale, 15% padding, white background
            padded       - 80% scale, 20% padding, light gray background
            fullbleed    - 120% scale, 0% padding, fills entire space
            rounded      - 90% scale, 20% corner radius, modern look
            shadowed     - 85% scale, drop shadow, professional depth
            gradient     - 90% scale, gradient background
            bordered     - 85% scale, border outline

        For more information, visit: https://github.com/kochj23/icon-creator
        """)
    }
}

// MARK: - Command Result

struct CommandResult {
    let success: Bool
    let message: String

    static func success(_ message: String) -> CommandResult {
        CommandResult(success: true, message: message)
    }

    static func failure(_ message: String) -> CommandResult {
        CommandResult(success: false, message: message)
    }
}

// MARK: - Argument Parser

struct ArgumentParser {
    let arguments: [String]

    func value(for flag: String) -> String? {
        guard let index = arguments.firstIndex(of: flag),
              index + 1 < arguments.count else {
            return nil
        }
        return arguments[index + 1]
    }

    func hasFlag(_ flag: String) -> Bool {
        arguments.contains(flag)
    }

    func values(for flag: String, separator: String = ",") -> [String]? {
        guard let value = value(for: flag) else { return nil }
        return value.split(separator: separator).map(String.init)
    }
}
