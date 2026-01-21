import Foundation
import AppKit

//
//  IconCreatorCLI.swift
//  Icon Creator CLI Tool
//
//  Main command-line interface class
//  Author: Jordan Koch
//  Date: 2026-01-21
//

/// Icon Creator Command Line Interface
/// Enables automation and CI/CD integration for icon generation
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

    // MARK: - Command Handlers

    /// Generate icons from source image
    func handleGenerate(args: [String]) {
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
            case "--preset":
                i += 1
                guard i < args.count else {
                    print("❌ --preset requires a value")
                    exit(1)
                }
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

    // MARK: - Help

    func printHelp() {
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
