# Icon Creator - Comprehensive Feature Implementation Plan

## Executive Summary

This plan outlines the implementation of 20 major feature categories totaling 50+ individual features for Icon Creator. The implementation is organized into 5 phases over an estimated timeline, with a focus on maintaining code quality, backward compatibility, and user experience.

**Current Architecture Analysis:**
- **MVVM Pattern**: ContentView (View) + IconGenerator/XcodeProjectManager (ViewModels)
- **SwiftUI**: Modern declarative UI with @Published properties
- **Async/Await**: Modern concurrency for exports
- **File Management**: Security-scoped resources with sandboxing

---

## Phase 1: Core Enhancements (High Priority - Quick Wins)

### 1.1 Batch Processing System
**Files to Create:**
- `BatchProcessingManager.swift` - Manages queue of images to process
- `BatchQueueView.swift` - UI for viewing and managing batch queue

**Files to Modify:**
- `ContentView.swift` - Add batch UI components
- `IconGenerator.swift` - Add batch export method

**Implementation Details:**
```swift
class BatchProcessingManager: ObservableObject {
    struct BatchItem: Identifiable {
        let id = UUID()
        var image: NSImage
        var targetProject: XcodeProject?
        var platforms: Set<Platform>
        var status: BatchStatus
        var settings: IconSettings // scale, padding, etc.
    }

    enum BatchStatus {
        case pending, processing, completed, failed(Error)
    }

    @Published var queue: [BatchItem] = []
    @Published var isProcessing = false
    @Published var currentItem: BatchItem?

    func add(image: NSImage, project: XcodeProject?, platforms: Set<Platform>)
    func processQueue() async
    func remove(itemID: UUID)
    func clearCompleted()
}
```

**UI Changes:**
- Add "Batch Mode" toggle to ContentView
- Add queue panel showing thumbnail grid
- Add progress indicator for batch operations
- Support drag-drop of multiple images

---

### 1.2 Icon Templates & Presets System
**Files to Create:**
- `IconPreset.swift` - Model for presets (Codable for persistence)
- `PresetManager.swift` - Manages loading/saving presets
- `PresetLibraryView.swift` - UI for browsing/managing presets
- `PresetEditorSheet.swift` - Sheet for creating/editing presets

**Files to Modify:**
- `IconGenerator.swift` - Add `IconSettings` struct to encapsulate all settings
- `ContentView.swift` - Add preset selector UI

**Implementation Details:**
```swift
struct IconPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var scale: Double
    var padding: Double
    var backgroundColor: ColorComponents // Codable wrapper for Color
    var cornerRadius: Double?
    var shadowEnabled: Bool
    var shadowBlur: Double
    // ... other settings

    static var builtInPresets: [IconPreset] {
        [minimalist, padded, fullBleed, rounded, shadowed]
    }
}

class PresetManager: ObservableObject {
    @Published var userPresets: [IconPreset] = []
    @Published var selectedPreset: IconPreset?

    func loadPresets() // from UserDefaults or file
    func savePreset(_ preset: IconPreset)
    func deletePreset(id: UUID)
    func exportPreset(_ preset: IconPreset) -> Data
    func importPreset(from data: Data) -> IconPreset?
}
```

**Built-in Presets:**
1. **Minimalist**: scale=0.7, padding=15%, white background
2. **Padded**: scale=0.8, padding=20%, light gray background
3. **Full Bleed**: scale=1.2, padding=0%, transparent/color
4. **Rounded**: scale=0.9, padding=10%, corner radius=20%
5. **Shadowed**: scale=0.85, padding=12%, drop shadow enabled

---

### 1.3 Advanced Image Processing
**Files to Create:**
- `ImageProcessor.swift` - Core image processing operations
- `ImageEffectsView.swift` - UI for effects panel
- `GradientEditor.swift` - Custom gradient picker

**Files to Modify:**
- `IconGenerator.swift` - Integrate image processing pipeline
- `ContentView.swift` - Add effects UI section

**Implementation Details:**
```swift
class ImageProcessor {
    // Core operations
    func applyRoundedCorners(to image: NSImage, radius: Double) -> NSImage
    func applyDropShadow(to image: NSImage, blur: Double, offset: CGSize, color: NSColor) -> NSImage
    func applyBorder(to image: NSImage, width: Double, color: NSColor) -> NSImage
    func applyGradientBackground(size: CGSize, gradient: Gradient) -> NSImage

    // Filters
    func adjustBrightness(_ image: NSImage, by amount: Double) -> NSImage
    func adjustContrast(_ image: NSImage, by amount: Double) -> NSImage
    func adjustSaturation(_ image: NSImage, by amount: Double) -> NSImage

    // Smart cropping
    enum CropMode {
        case center, smart, manual(CGRect)
    }
    func crop(_ image: NSImage, mode: CropMode) -> NSImage

    // Multi-layer composition
    func composeImage(background: NSImage, icon: NSImage, overlay: NSImage?) -> NSImage
}

struct ImageEffects {
    var cornerRadius: Double = 0 // 0-50%
    var shadowEnabled: Bool = false
    var shadowBlur: Double = 10
    var shadowOffset: CGSize = .zero
    var shadowColor: Color = .black.opacity(0.5)

    var borderEnabled: Bool = false
    var borderWidth: Double = 2
    var borderColor: Color = .black

    var backgroundType: BackgroundType = .solid
    enum BackgroundType {
        case solid(Color)
        case gradient(Gradient, GradientType)
        case transparent
    }

    var brightnessAdjustment: Double = 0 // -1 to 1
    var contrastAdjustment: Double = 0 // -1 to 1
    var saturationAdjustment: Double = 0 // -1 to 1
}
```

**UI Layout:**
- Collapsible "Effects" section in ContentView
- Real-time preview updates
- Reset button for each effect
- "Reset All Effects" button

---

### 1.4 Enhanced Preview System
**Files to Create:**
- `ContextPreviewView.swift` - Mockup previews (home screen, App Store, etc.)
- `DeviceMockups.swift` - Device frame assets/generators
- `PreviewMode.swift` - Enum for different preview types

**Files to Modify:**
- `PreviewView.swift` (rename from current preview) - Enhance with context options
- `ContentView.swift` - Add preview mode selector

**Implementation Details:**
```swift
enum PreviewContext {
    case allSizes // Current behavior
    case homeScreen(device: Device, appearance: Appearance)
    case appStore
    case spotlight
    case settings
    case notifications
    case widget
    case sideB Side(before: NSImage?, after: NSImage?)
    case actualSize
}

enum Device {
    case iPhone15Pro, iPhone15ProMax, iPadPro13, mac, appleWatch, appleTV

    var screenSize: CGSize { /* ... */ }
    var mockupImage: NSImage? { /* ... */ }
}

enum Appearance {
    case light, dark
    var backgroundColor: Color { /* ... */ }
}

struct ContextPreviewView: View {
    let icon: NSImage
    let context: PreviewContext

    var body: some View {
        switch context {
        case .homeScreen(let device, let appearance):
            DeviceMockupView(device: device) {
                HomeScreenGrid(icon: icon, appearance: appearance)
            }
        case .appStore:
            AppStorePreview(icon: icon)
        // ... other contexts
        }
    }
}
```

**Preview Contexts to Implement:**
1. **Home Screen**: Show icon on iOS/macOS home screen with neighboring apps
2. **App Store**: Show as it appears in App Store listing
3. **Spotlight**: Small icon view
4. **Settings**: Icon in Settings app context
5. **Notifications**: Icon in notification banner
6. **Widget**: Icon in widget view
7. **Side-by-Side**: Compare two versions
8. **Actual Size**: View at real pixel dimensions with ruler

---

### 1.5 Multi-Platform Install
**Files to Modify:**
- `ContentView.swift` - Remove "only first platform" limitation
- `XcodeProjectManager.swift` - Add `installMultiplePlatforms` method

**Implementation Details:**
```swift
extension XcodeProjectManager {
    /// Installs icons for multiple platforms simultaneously
    func installMultiplePlatforms(
        from baseURL: URL,
        platforms: Set<Platform>,
        to project: XcodeProject
    ) async throws -> [Platform: Result<Void, Error>] {
        var results: [Platform: Result<Void, Error>] = [:]

        for platform in platforms {
            let platformURL = baseURL.appendingPathComponent(platform.folderName)
            let appiconsetURL = platformURL.appendingPathComponent("AppIcon.appiconset")

            // Create platform-specific asset catalog structure
            let assetsURL = try findOrCreateAssetsFolder(in: project)
            let destinationName = "AppIcon-\(platform.folderName).appiconset"
            let destinationURL = assetsURL.appendingPathComponent(destinationName)

            do {
                try installIcons(from: appiconsetURL, to: project, platform: platform)
                results[platform] = .success(())
            } catch {
                results[platform] = .failure(error)
            }
        }

        return results
    }
}
```

---

## Phase 2: Workflow & Automation

### 2.1 Project Management System
**Files to Create:**
- `RecentProjectsManager.swift` - Manages recent/favorite projects
- `ProjectMetadata.swift` - Stores project notes, last updated, icon history
- `ProjectBrowserView.swift` - Enhanced project selection UI

**Implementation Details:**
```swift
struct ProjectMetadata: Codable {
    let projectID: UUID
    var lastIconUpdate: Date
    var notes: String
    var isFavorite: Bool
    var iconHistory: [IconHistoryEntry]
    var customName: String? // User can override display name

    struct IconHistoryEntry: Codable {
        let date: Date
        let platforms: [Platform]
        let thumbnailData: Data? // Small preview
    }
}

class RecentProjectsManager: ObservableObject {
    @Published var recentProjects: [XcodeProject] = []
    @Published var favoriteProjects: [XcodeProject] = []
    @Published var metadata: [UUID: ProjectMetadata] = [:]

    func recordProjectUse(_ project: XcodeProject)
    func toggleFavorite(_ project: XcodeProject)
    func addNote(to project: XcodeProject, note: String)
    func getIconHistory(for project: XcodeProject) -> [IconHistoryEntry]
    func searchProjects(query: String) -> [XcodeProject]
}
```

**UI Enhancements:**
- Tabs for "All Projects" / "Recent" / "Favorites"
- Search/filter bar
- Project cards with metadata display
- Star icon for favorites
- Notes panel

---

###2.2 Custom Project Paths
**Files to Create:**
- `PathConfiguration.swift` - Manages custom paths
- `PathManagerView.swift` - UI for adding/removing paths

**Files to Modify:**
- `XcodeProjectManager.swift` - Support custom paths alongside defaults

**Implementation Details:**
```swift
class PathConfiguration: ObservableObject {
    @Published var customPaths: [URL] = []

    func addPath(_ url: URL) throws
    func removePath(_ url: URL)
    func validatePath(_ url: URL) -> Bool
    func loadFromUserDefaults()
    func saveToUserDefaults()
}

extension XcodeProjectManager {
    func setCustomPaths(_ paths: [URL]) {
        self.searchDirectories = Self.getCommonProjectLocations() + paths
        discoverProjects()
    }
}
```

---

### 2.3 Export Options & Formats
**Files to Create:**
- `ExportManager.swift` - Handles various export formats
- `ExportOptionsView.swift` - UI for export configuration
- `DocumentationGenerator.swift` - Generates HTML/PDF icon docs

**Implementation Details:**
```swift
class ExportManager {
    enum ExportFormat {
        case xcode // Current .appiconset format
        case png(sizes: [Int])
        case pdf // Vector-based single file
        case svg // For web use
        case favicon // .ico format
        case android // Adaptive icon format
        case documentation(format: DocFormat)
    }

    enum DocFormat {
        case html, pdf, markdown
    }

    func export(
        icon: NSImage,
        format: ExportFormat,
        to url: URL,
        settings: IconSettings
    ) async throws

    func generateDocumentation(
        icons: [Platform: [NSImage]],
        format: DocFormat
    ) -> Data
}

struct AndroidAdaptiveIcon {
    let foreground: NSImage
    let background: NSImage

    func export(to url: URL) throws {
        // Generate res/mipmap-* directories
        // Create foreground and background layers
        // Generate XML manifest
    }
}
```

---

### 2.4 Quality Validation System
**Files to Create:**
- `IconValidator.swift` - Comprehensive validation rules
- `ValidationReportView.swift` - Display validation results
- `AppleGuidelinesChecker.swift` - Checks against Apple HIG

**Implementation Details:**
```swift
class IconValidator {
    struct ValidationResult {
        var errors: [ValidationIssue] = []
        var warnings: [ValidationIssue] = []
        var suggestions: [ValidationIssue] = []

        var isValid: Bool { errors.isEmpty }
    }

    struct ValidationIssue {
        let severity: Severity
        let category: Category
        let message: String
        let fixAction: (() -> Void)?

        enum Severity {
            case error, warning, info
        }

        enum Category {
            case size, transparency, contrast, guidelines, performance
        }
    }

    func validate(image: NSImage, platform: Platform) -> ValidationResult {
        var result = ValidationResult()

        // Check minimum size
        if image.size.width < 1024 {
            result.warnings.append(.init(
                severity: .warning,
                category: .size,
                message: "Image smaller than 1024px may reduce quality",
                fixAction: nil
            ))
        }

        // Check transparency
        if hasTransparency(image) {
            result.warnings.append(.init(
                severity: .warning,
                category: .transparency,
                message: "Icons should not have transparency per Apple guidelines",
                fixAction: { /* Remove transparency */ }
            ))
        }

        // Check contrast
        let contrastRatio = calculateContrast(image)
        if contrastRatio < 3.0 {
            result.warnings.append(.init(
                severity: .warning,
                category: .contrast,
                message: "Low contrast - icon may not stand out on all backgrounds",
                fixAction: nil
            ))
        }

        // Check Apple HIG compliance
        result.append(contentsOf: AppleGuidelinesChecker.check(image, platform: platform))

        return result
    }

    private func hasTransparency(_ image: NSImage) -> Bool
    private func calculateContrast(_ image: NSImage) -> Double
}

class AppleGuidelinesChecker {
    static func check(_ image: NSImage, platform: Platform) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []

        // Platform-specific checks
        switch platform {
        case .iOS:
            // Check rounded corners (iOS app icons are auto-rounded)
            if hasRoundedCorners(image) {
                issues.append(.init(
                    severity: .info,
                    category: .guidelines,
                    message: "iOS automatically rounds corners - manual rounding not needed",
                    fixAction: nil
                ))
            }
        case .macOS:
            // macOS icons should have perspective/shadow
        // ... other platform-specific rules
        }

        return issues
    }
}
```

---

### 2.5 Command-Line Interface
**Files to Create:**
- `CLIArguments.swift` - Argument parser
- `CLICommands/` (directory with command implementations)
  - `GenerateCommand.swift`
  - `ValidateCommand.swift`
  - `BatchCommand.swift`

**Implementation Details:**
```swift
// Usage: icon-creator generate --source icon.png --project MyApp --platforms ios,macos
@main
struct IconCreatorCLI {
    static func main() {
        let args = CommandLine.arguments

        guard args.count > 1 else {
            printUsage()
            return
        }

        let command = args[1]
        let arguments = Array(args.dropFirst(2))

        switch command {
        case "generate":
            GenerateCommand.run(with: arguments)
        case "validate":
            ValidateCommand.run(with: arguments)
        case "batch":
            BatchCommand.run(with: arguments)
        default:
            print("Unknown command: \(command)")
            printUsage()
        }
    }

    static func printUsage() {
        print("""
        Icon Creator CLI

        USAGE:
            icon-creator <command> [options]

        COMMANDS:
            generate    Generate icons from source image
            validate    Validate an image for icon generation
            batch       Process multiple images

        GENERATE OPTIONS:
            --source <path>         Source image path
            --project <name>        Xcode project name
            --platforms <list>      Comma-separated platforms (ios,macos,tvos,watchos)
            --output <path>         Output directory (default: current directory)
            --preset <name>         Use preset configuration
            --scale <value>         Scale factor (0.5-2.0)
            --padding <value>       Padding percentage (0-30)
            --background <color>    Background color (hex or name)

        EXAMPLES:
            icon-creator generate --source icon.png --platforms ios,macos
            icon-creator validate --source icon.png
            icon-creator batch --directory ./icons --project MyApp
        """)
    }
}

struct GenerateCommand {
    static func run(with arguments: [String]) {
        let parser = ArgumentParser(arguments)

        guard let sourcePath = parser.value(for: "--source") else {
            print("Error: --source is required")
            return
        }

        // Parse other arguments
        let platforms = parser.value(for: "--platforms")?.split(separator: ",").compactMap { Platform(rawValue: String($0)) } ?? [.iOS]
        let outputPath = parser.value(for: "--output") ?? FileManager.default.currentDirectoryPath
        // ... parse other options

        // Load image
        guard let image = NSImage(contentsOfFile: sourcePath) else {
            print("Error: Cannot load image at \(sourcePath)")
            return
        }

        // Generate icons
        let generator = IconGenerator()
        generator.sourceImage = image
        // Apply settings from arguments

        // Export
        let outputURL = URL(fileURLWithPath: outputPath)
        for platform in platforms {
            do {
                try generator.exportIcons(for: platform, to: outputURL) { progress in
                    print("\r[\(platform.rawValue)] \(Int(progress * 100))%", terminator: "")
                }
                print("\n✅ Generated \(platform.rawValue) icons")
            } catch {
                print("\n❌ Failed to generate \(platform.rawValue): \(error)")
            }
        }
    }
}
```

---

## Phase 3: Advanced Features

### 3.1 Color Management System
**Files to Create:**
- `ColorAnalyzer.swift` - Extract/analyze colors from images
- `ColorPalette.swift` - Color palette model
- `ColorHarmonyGenerator.swift` - Generate complementary colors
- `ColorPickerEnhanced.swift` - Advanced color picker UI

**Implementation Details:**
```swift
class ColorAnalyzer {
    func extractDominantColors(from image: NSImage, count: Int = 5) -> [NSColor] {
        // K-means clustering on image pixels
        // Return most prominent colors
    }

    func generatePalette(from image: NSImage) -> ColorPalette {
        let colors = extractDominantColors(from: image, count: 5)
        return ColorPalette(
            primary: colors[0],
            secondary: colors[1],
            accent: colors[2],
            background: suggestBackgroundColor(for: colors),
            isDark: isDarkImage(image)
        )
    }

    func suggestBackgroundColor(for iconColors: [NSColor]) -> NSColor {
        // Analyze icon colors
        // Suggest contrasting background
    }

    func calculateContrast(between color1: NSColor, and color2: NSColor) -> Double {
        // WCAG contrast ratio
    }
}

struct ColorPalette: Identifiable {
    let id = UUID()
    var name: String
    var primary: NSColor
    var secondary: NSColor
    var accent: NSColor
    var background: NSColor
    var isDark: Bool

    static var presets: [ColorPalette] {
        [
            .init(name: "iOS Blue", primary: .systemBlue, ...),
            .init(name: "Sunset", primary: .orange, ...),
            // ... more presets
        ]
    }
}

class ColorHarmonyGenerator {
    func generateComplementary(for color: NSColor) -> NSColor
    func generateTriadic(for color: NSColor) -> [NSColor]
    func generateAnalogous(for color: NSColor) -> [NSColor]
    func generateMonochromatic(for color: NSColor, steps: Int) -> [NSColor]
}
```

**UI Components:**
- Color extraction button: "Extract from Image"
- Palette preview with color swatches
- Color harmony suggestions
- Quick palette presets

---

### 3.2 Icon Variants System
**Files to Create:**
- `IconVariant.swift` - Model for alternate icons
- `VariantGenerator.swift` - Generate variations
- `VariantManagerView.swift` - UI for managing variants
- `SeasonalThemes.swift` - Seasonal variant templates

**Implementation Details:**
```swift
struct IconVariant: Identifiable {
    let id = UUID()
    var name: String
    var baseImage: NSImage
    var modifications: [Modification]
    var platforms: Set<Platform>

    enum Modification {
        case badge(BadgeType, position: BadgePosition)
        case overlay(NSImage, position: CGPoint, alpha: Double)
        case tint(Color, intensity: Double)
        case seasonal(SeasonalTheme)
        case beta(text: String)
    }

    enum BadgeType {
        case beta, debug, dev, number(Int), custom(NSImage)
    }

    enum BadgePosition {
        case topLeft, topRight, bottomLeft, bottomRight, center
    }

    enum SeasonalTheme {
        case halloween, christmas, newYear, spring, summer

        var overlayImage: NSImage { /* ... */ }
        var colorScheme: ColorPalette { /* ... */ }
    }
}

class VariantGenerator {
    func generateVariant(
        from base: NSImage,
        applying modifications: [IconVariant.Modification]
    ) -> NSImage {
        var result = base

        for modification in modifications {
            switch modification {
            case .badge(let type, let position):
                result = applyBadge(to: result, type: type, position: position)
            case .overlay(let image, let position, let alpha):
                result = applyOverlay(to: result, overlay: image, at: position, alpha: alpha)
            case .tint(let color, let intensity):
                result = applyTint(to: result, color: color, intensity: intensity)
            case .seasonal(let theme):
                result = applySeasonalTheme(to: result, theme: theme)
            case .beta(let text):
                result = applyBetaBadge(to: result, text: text)
            }
        }

        return result
    }

    // Helper methods for each modification type
    private func applyBadge(to image: NSImage, type: BadgeType, position: BadgePosition) -> NSImage
    private func applyOverlay(to image: NSImage, overlay: NSImage, at position: CGPoint, alpha: Double) -> NSImage
    // ... other helpers
}
```

**iOS Alternate Icons Support:**
```swift
// Generate Info.plist entries for alternate icons
extension IconVariant {
    func generateInfoPlistEntry() -> [String: Any] {
        [
            "CFBundleAlternateIcons": [
                name: [
                    "CFBundleIconFiles": platforms.map { "\(name)-\($0.folderName)" },
                    "UIPrerenderedIcon": false
                ]
            ]
        ]
    }
}
```

---

### 3.3 Collaboration Features
**Files to Create:**
- `ProjectExporter.swift` - Export project settings
- `CollaborationPackage.swift` - Package format for sharing
- `CommentSystem.swift` - Add comments/annotations
- `VersionHistory.swift` - Track icon versions

**Implementation Details:**
```swift
struct CollaborationPackage: Codable {
    let version: String
    let projectName: String
    let createdDate: Date
    let author: String

    var iconSettings: IconSettings
    var presets: [IconPreset]
    var variants: [IconVariant]
    var comments: [Comment]
    var sourceImage: Data? // Optional: include source

    struct Comment: Codable {
        let id: UUID
        let author: String
        let text: String
        let timestamp: Date
        let attachedTo: CommentTarget

        enum CommentTarget: Codable {
            case general
            case variant(UUID)
            case platform(Platform)
        }
    }
}

class ProjectExporter {
    func exportCollaborationPackage(
        iconGenerator: IconGenerator,
        presetManager: PresetManager,
        variants: [IconVariant],
        comments: [Comment]
    ) throws -> Data {
        let package = CollaborationPackage(
            version: "1.0",
            projectName: "Icon Project",
            createdDate: Date(),
            author: NSFullUserName(),
            iconSettings: iconGenerator.currentSettings,
            presets: presetManager.userPresets,
            variants: variants,
            comments: comments,
            sourceImage: iconGenerator.sourceImage?.tiffRepresentation
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(package)
    }

    func importCollaborationPackage(from data: Data) throws -> CollaborationPackage {
        let decoder = JSONDecoder()
        return try decoder.decode(CollaborationPackage.self, from: data)
    }
}

class VersionHistory: ObservableObject {
    struct Version: Identifiable {
        let id = UUID()
        let timestamp: Date
        let thumbnail: NSImage
        let settings: IconSettings
        let platforms: Set<Platform>
        let note: String?
    }

    @Published var versions: [Version] = []

    func saveVersion(from generator: IconGenerator, note: String?)
    func restoreVersion(_ version: Version, to generator: IconGenerator)
    func compareVersions(_ v1: Version, _ v2: Version) -> VersionDiff
    func exportHistory() -> Data
    func importHistory(from data: Data)
}
```

---

### 3.4 Watch Folder Mode & Automation
**Files to Create:**
- `WatchFolderManager.swift` - Monitor folder for changes
- `AutomationEngine.swift` - Execute automated workflows
- `TriggerSystem.swift` - Define triggers and actions
- `WatchFolderSettingsView.swift` - UI for watch folder config

**Implementation Details:**
```swift
class WatchFolderManager: ObservableObject {
    @Published var isWatching = false
    @Published var watchedFolder: URL?
    @Published var processedCount = 0

    private var fileMonitor: DispatchSourceFileSystemObject?

    func startWatching(folder: URL, rules: [ProcessingRule]) {
        stopWatching()

        let fileDescriptor = open(folder.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        fileMonitor = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend],
            queue: .main
        )

        fileMonitor?.setEventHandler { [weak self] in
            self?.handleFileSystemEvent(in: folder, rules: rules)
        }

        fileMonitor?.resume()
        isWatching = true
    }

    func stopWatching() {
        fileMonitor?.cancel()
        fileMonitor = nil
        isWatching = false
    }

    private func handleFileSystemEvent(in folder: URL, rules: [ProcessingRule]) {
        // Scan for new images
        let newImages = scanForNewImages(in: folder)

        // Process according to rules
        for image in newImages {
            Task {
                await processImage(image, rules: rules)
            }
        }
    }

    private func scanForNewImages(in folder: URL) -> [URL]
    private func processImage(_ imageURL: URL, rules: [ProcessingRule]) async
}

struct ProcessingRule: Identifiable {
    let id = UUID()
    var name: String
    var trigger: Trigger
    var actions: [Action]

    enum Trigger {
        case fileAdded(extensions: [String])
        case fileModified
        case schedule(interval: TimeInterval)
    }

    enum Action {
        case generateIcons(platforms: Set<Platform>)
        case applyPreset(IconPreset)
        case installToProject(XcodeProject)
        case exportTo(URL, format: ExportManager.ExportFormat)
        case validate
        case notify(message: String)
    }
}

class AutomationEngine {
    func executeRule(_ rule: ProcessingRule, on imageURL: URL) async throws {
        guard let image = NSImage(contentsOf: imageURL) else {
            throw AutomationError.invalidImage
        }

        for action in rule.actions {
            switch action {
            case .generateIcons(let platforms):
                // Generate icons for platforms
            case .applyPreset(let preset):
                // Apply preset settings
            case .installToProject(let project):
                // Install to project
            case .exportTo(let url, let format):
                // Export with format
            case .validate:
                // Run validation
            case .notify(let message):
                // Show notification
                sendNotification(message)
            }
        }
    }

    private func sendNotification(_ message: String) {
        let notification = NSUserNotification()
        notification.title = "Icon Creator"
        notification.informativeText = message
        NSUserNotificationCenter.default.deliver(notification)
    }
}
```

---

### 3.5 AppleScript & Shortcuts Support
**Files to Create:**
- `ScriptingBridge.swift` - AppleScript interface
- `IntentsExtension/` - Shortcuts intents (separate target)
  - `GenerateIconIntent.swift`
  - `ValidateImageIntent.swift`

**Implementation Details:**
```swift
// Expose app to AppleScript
@objc(IconCreatorApplication)
class IconCreatorApplication: NSApplication {
    @objc func generate(sourceImage: String, platforms: [String], outputPath: String) -> Bool {
        // Load image
        guard let image = NSImage(contentsOfFile: sourceImage) else {
            return false
        }

        // Parse platforms
        let platformSet = Set(platforms.compactMap { Platform(rawValue: $0) })

        // Generate
        let generator = IconGenerator()
        generator.sourceImage = image

        let outputURL = URL(fileURLWithPath: outputPath)
        for platform in platformSet {
            do {
                try generator.exportIcons(for: platform, to: outputURL)
            } catch {
                return false
            }
        }

        return true
    }
}

// Shortcuts Intent
@available(macOS 12.0, *)
class GenerateIconIntent: NSObject, INIntent {
    // Define intent parameters
    @Parameter(title: "Source Image")
    var sourceImage: INFile?

    @Parameter(title: "Platforms")
    var platforms: [String]?

    @Parameter(title: "Output Folder")
    var outputFolder: INFile?

    // Perform intent
    func perform() async throws -> GenerateIconIntentResponse {
        // Execute icon generation
        // Return success/failure
    }
}
```

---

## Phase 4: Platform-Specific & Export Features

### 4.1 Platform-Specific Optimizations
**Files to Create:**
- `PlatformOptimizer.swift` - Platform-specific adjustments
- `ComplicationGenerator.swift` - watchOS complications
- `WidgetIconGenerator.swift` - iOS widget icons
- `MenuBarIconGenerator.swift` - macOS menu bar icons

**Implementation Details:**
```swift
class PlatformOptimizer {
    func optimize(icon: NSImage, for platform: Platform, size: Int) -> NSImage {
        switch platform {
        case .watchOS:
            return optimizeForWatch(icon, size: size)
        case .macOS:
            return optimizeForMac(icon, size: size)
        case .iOS:
            return optimizeForIOS(icon, size: size)
        case .tvOS:
            return optimizeForTVOS(icon, size: size)
        default:
            return icon
        }
    }

    private func optimizeForWatch(_ icon: NSImage, size: Int) -> NSImage {
        // watchOS icons need high contrast
        // Apply subtle edge enhancement
        // Ensure visibility at small sizes
    }

    private func optimizeForMac(_ icon: NSImage, size: Int) -> NSImage {
        // macOS icons use perspective
        // Add subtle shadow/depth
        // Follow Big Sur icon style
    }

    private func optimizeForIOS(_ icon: NSImage, size: Int) -> NSImage {
        // iOS icons are rounded automatically
        // Ensure good visibility on various wallpapers
        // Optimize for dark mode
    }

    private func optimizeForTVOS(_ icon: NSImage, size: Int) -> NSImage {
        // tvOS icons have parallax layers
        // Ensure visibility from distance
        // High resolution required
    }
}

class ComplicationGenerator {
    enum ComplicationType {
        case circular, modular, utilitarian, graphicCorner, graphicCircular
    }

    func generate(
        from icon: NSImage,
        type: ComplicationType
    ) -> NSImage {
        // Generate complication-specific icon
        // Follow Apple Watch design guidelines
    }
}
```

---

### 4.2 Asset Management & Generation
**Files to Create:**
- `LaunchScreenGenerator.swift` - Generate launch screens
- `PlaceholderGenerator.swift` - App placeholder images
- `ScreenshotTemplateGenerator.swift` - Marketing assets
- `SocialMediaExporter.swift` - Social media formats

**Implementation Details:**
```swift
class LaunchScreenGenerator {
    func generateLaunchScreen(
        from icon: NSImage,
        backgroundColor: Color,
        style: LaunchScreenStyle
    ) -> NSImage {
        // Create launch screen with icon centered
        // Follow platform guidelines
    }

    enum LaunchScreenStyle {
        case iconOnly, iconWithName, minimal, fullBranding
    }
}

class SocialMediaExporter {
    enum Platform {
        case twitter, facebook, linkedin, appStore

        var iconSize: CGSize {
            switch self {
            case .twitter: return CGSize(width: 400, height: 400)
            case .facebook: return CGSize(width: 1200, height: 630)
            case .linkedin: return CGSize(width: 1200, height: 627)
            case .appStore: return CGSize(width: 1024, height: 1024)
            }
        }
    }

    func export(icon: NSImage, for platform: Platform) -> NSImage {
        // Resize and optimize for social media
        // Add background if needed
        // Ensure proper compression
    }
}
```

---

### 4.3 Cross-Platform Export
**Files to Create:**
- `AndroidExporter.swift` - Android adaptive icons
- `WindowsExporter.swift` - Windows app icons
- `WebExporter.swift` - Web app manifests & favicons
- `ElectronExporter.swift` - Electron app icons

**Implementation Details:**
```swift
class AndroidExporter {
    func exportAdaptiveIcon(
        foreground: NSImage,
        background: NSImage,
        to url: URL
    ) throws {
        // Create res/mipmap-* directories
        // Generate foreground and background layers
        // Export for all densities: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi
        // Generate adaptive-icon.xml
    }

    func exportLegacyIcon(_ icon: NSImage, to url: URL) throws {
        // Export traditional launcher icons
        // Sizes: 48, 72, 96, 144, 192, 512
    }
}

class WebExporter {
    func exportWebManifest(
        icon: NSImage,
        appName: String,
        to url: URL
    ) throws {
        // Generate favicon.ico (16x16, 32x32, 48x48)
        // Generate apple-touch-icon.png (180x180)
        // Generate manifest icons (192x192, 512x512)
        // Create manifest.json
    }
}
```

---

## Phase 5: AI/ML & Cloud Features

### 5.1 AI-Powered Features
**Files to Create:**
- `MLUpscaler.swift` - AI upscaling for low-res images
- `BackgroundRemover.swift` - Smart background removal
- `StyleTransfer.swift` - Apply artistic styles
- `AccessibilityAnalyzer.swift` - Colorblind simulation

**Implementation Details:**
```swift
import CoreML
import Vision

class MLUpscaler {
    private let model: VNCoreMLModel

    init() throws {
        // Load Core ML upscaling model
        // Could use ESRGAN or similar
        let mlModel = try MLModel(contentsOf: /* model URL */)
        self.model = try VNCoreMLModel(for: mlModel)
    }

    func upscale(_ image: NSImage, targetSize: CGSize) async throws -> NSImage {
        // Use Core ML for intelligent upscaling
        // Preserve details better than simple interpolation
    }
}

class BackgroundRemover {
    func removeBackground(from image: NSImage) async throws -> NSImage {
        // Use Vision framework for salient object detection
        let request = VNGeneratePersonSegmentationRequest()

        // Or use custom Core ML model
        // Return image with transparent background
    }
}

class StyleTransfer {
    enum Style {
        case sketch, watercolor, oil, cartoon, geometric
    }

    func applyStyle(_ style: Style, to image: NSImage) async throws -> NSImage {
        // Use Core ML style transfer model
        // Apply artistic style while preserving recognizability
    }
}

class AccessibilityAnalyzer {
    enum ColorBlindnessType {
        case protanopia, deuteranopia, tritanopia, achromatopsia
    }

    func simulate(_ type: ColorBlindnessType, on image: NSImage) -> NSImage {
        // Apply color transformation matrix
        // Simulate how icon appears to colorblind users
    }

    func analyzeAccessibility(of image: NSImage) -> AccessibilityReport {
        // Check contrast ratios
        // Verify visibility for colorblind users
        // Suggest improvements
    }

    struct AccessibilityReport {
        var contrastRatio: Double
        var visibleForProtanopia: Bool
        var visibleForDeuteranopia: Bool
        var visibleForTritanopia: Bool
        var suggestions: [String]
    }
}
```

---

### 5.2 Cloud Sync (Optional - Advanced)
**Files to Create:**
- `CloudSyncManager.swift` - iCloud integration
- `CloudStorageProvider.swift` - Abstract cloud provider
- `SyncConflictResolver.swift` - Handle sync conflicts

**Implementation Details:**
```swift
class CloudSyncManager: ObservableObject {
    @Published var isSyncing = false
    @Published var syncError: Error?

    private let container: CKContainer
    private let database: CKDatabase

    init() {
        container = CKContainer.default()
        database = container.privateCloudDatabase
    }

    func syncPresets() async throws {
        // Upload user presets to iCloud
        // Download from iCloud
        // Merge changes
    }

    func syncTemplates() async throws {
        // Sync icon templates
    }

    func syncProjectMetadata() async throws {
        // Sync project notes, favorites, etc.
    }
}
```

---

## Architecture & Code Organization

### New Directory Structure
```
Icon Creator/
├── Models/
│   ├── Core/
│   │   ├── IconPreset.swift
│   │   ├── IconVariant.swift
│   │   ├── IconSettings.swift
│   │   └── ColorPalette.swift
│   ├── Project/
│   │   ├── XcodeProject.swift (existing)
│   │   ├── ProjectMetadata.swift
│   │   └── RecentProjectsManager.swift
│   └── Batch/
│       ├── BatchItem.swift
│       └── BatchQueue.swift
├── ViewModels/
│   ├── IconGenerator.swift (existing - enhance)
│   ├── XcodeProjectManager.swift (existing - enhance)
│   ├── BatchProcessingManager.swift
│   ├── PresetManager.swift
│   └── ValidationEngine.swift
├── Views/
│   ├── Main/
│   │   ├── ContentView.swift (existing - major enhancements)
│   │   └── MainToolbar.swift
│   ├── Batch/
│   │   ├── BatchQueueView.swift
│   │   └── BatchItemCard.swift
│   ├── Presets/
│   │   ├── PresetLibraryView.swift
│   │   ├── PresetEditorSheet.swift
│   │   └── PresetCard.swift
│   ├── Preview/
│   │   ├── PreviewView.swift (existing - enhance)
│   │   ├── ContextPreviewView.swift
│   │   └── DeviceMockupView.swift
│   ├── Effects/
│   │   ├── ImageEffectsPanel.swift
│   │   ├── ColorPickerEnhanced.swift
│   │   └── GradientEditor.swift
│   └── Settings/
│       ├── SettingsView.swift
│       ├── PathManagerView.swift
│       └── WatchFolderSettingsView.swift
├── Services/
│   ├── ImageProcessing/
│   │   ├── ImageProcessor.swift
│   │   ├── FilterEngine.swift
│   │   └── EffectsRenderer.swift
│   ├── Export/
│   │   ├── ExportManager.swift
│   │   ├── AndroidExporter.swift
│   │   ├── WebExporter.swift
│   │   └── DocumentationGenerator.swift
│   ├── Validation/
│   │   ├── IconValidator.swift
│   │   └── AppleGuidelinesChecker.swift
│   ├── ML/
│   │   ├── MLUpscaler.swift
│   │   ├── BackgroundRemover.swift
│   │   └── StyleTransfer.swift
│   └── Automation/
│       ├── WatchFolderManager.swift
│       ├── AutomationEngine.swift
│       └── ScriptingBridge.swift
├── Utilities/
│   ├── ColorAnalyzer.swift
│   ├── FileSystemMonitor.swift
│   └── VersionControl.swift
├── CLI/
│   ├── IconCreatorCLI.swift
│   ├── ArgumentParser.swift
│   └── Commands/
│       ├── GenerateCommand.swift
│       ├── ValidateCommand.swift
│       └── BatchCommand.swift
└── Resources/
    ├── Presets/
    │   └── BuiltInPresets.json
    ├── Mockups/
    │   ├── iPhone.png
    │   ├── iPad.png
    │   └── Mac.png
    └── ML Models/
        ├── Upscaler.mlmodel
        └── BackgroundRemoval.mlmodel
```

---

## Data Persistence Strategy

### UserDefaults Keys
```swift
enum UserDefaultsKeys {
    static let userPresets = "user_presets"
    static let recentProjects = "recent_projects"
    static let favoriteProjects = "favorite_projects"
    static let customPaths = "custom_paths"
    static let lastUsedSettings = "last_used_settings"
    static let watchFolderConfig = "watch_folder_config"
}
```

### File Storage
- **User Presets**: `~/Library/Application Support/Icon Creator/Presets/`
- **Project Metadata**: `~/Library/Application Support/Icon Creator/Projects/`
- **Icon History**: `~/Library/Application Support/Icon Creator/History/`
- **Templates**: `~/Library/Application Support/Icon Creator/Templates/`
- **Cache**: `~/Library/Caches/Icon Creator/`

---

## Testing Strategy

### Unit Tests
```swift
class IconGeneratorTests: XCTestCase {
    func testIconGeneration()
    func testScaling()
    func testPadding()
    func testAutoC ropping()
    func testValidation()
}

class BatchProcessingTests: XCTestCase {
    func testQueueManagement()
    func testConcurrentProcessing()
    func testErrorHandling()
}

class ValidationTests: XCTestCase {
    func testSizeValidation()
    func testTransparencyDetection()
    func testContrastCalculation()
    func testGuidelineCompliance()
}
```

### UI Tests
```swift
class IconCreatorUITests: XCTestCase {
    func testDragAndDrop()
    func testBatchQueue()
    func testPresetSelection()
    func testExport()
}
```

---

## Performance Optimizations

### Memory Management
```swift
// Use autoreleasepool for batch operations
for image in images {
    autoreleasepool {
        processImage(image)
    }
}

// Implement image caching with size limits
class ImageCache {
    private var cache: [String: NSImage] = [:]
    private let maxCacheSize = 100_000_000 // 100MB

    func store(_ image: NSImage, for key: String) {
        // Implement LRU eviction
    }
}
```

### Async Processing
```swift
// Use Task groups for parallel processing
await withTaskGroup(of: Result<NSImage, Error>.self) { group in
    for size in sizes {
        group.addTask {
            return await self.generateIcon(size: size)
        }
    }

    for await result in group {
        // Handle results
    }
}
```

---

## Security Considerations

### Input Validation
```swift
// Sanitize all file paths
func sanitizePath(_ path: String) -> String {
    // Remove path traversal attempts
    // Validate against whitelist
}

// Validate image data before processing
func validateImageData(_ data: Data) throws {
    // Check file signature (magic bytes)
    // Verify not malicious
}
```

### Sandboxing
```swift
// Request proper entitlements
// Icon_Creator.entitlements
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.files.downloads.read-write</key>
<true/>
```

---

## Documentation Plan

### User Documentation
- **Getting Started Guide**: Quickstart for new users
- **Feature Tutorials**: Step-by-step for each major feature
- **Video Demos**: Screen recordings of workflows
- **FAQ**: Common questions and troubleshooting

### Developer Documentation
- **API Reference**: DocC documentation for all public APIs
- **Architecture Guide**: System design and patterns
- **Contributing Guide**: How to contribute features
- **Plugin System**: API for extending functionality

---

## Migration Strategy

### Backward Compatibility
```swift
// Support old settings format
func migrateSettings(from old: OldSettings) -> IconSettings {
    IconSettings(
        scale: old.scale,
        padding: old.padding,
        backgroundColor: old.backgroundColor
        // ... map old to new
    )
}

// Versioned file formats
struct SavedProject: Codable {
    let version: Int
    var data: Data

    init(from decoder: Decoder) throws {
        // Handle different versions
        switch version {
        case 1:
            // Parse v1 format
        case 2:
            // Parse v2 format
        default:
            throw DecodingError.dataCorrupted(/* ... */)
        }
    }
}
```

---

## Release Strategy

### Version Numbering
- **Major (X.0.0)**: Breaking changes, major features
- **Minor (1.X.0)**: New features, backward compatible
- **Patch (1.0.X)**: Bug fixes only

### Phased Rollout
- **Phase 1** (v2.0): Core enhancements (Batch, Presets, Advanced Processing, Enhanced Preview, Multi-platform)
- **Phase 2** (v2.1): Workflow & Automation (Project Management, Custom Paths, Export Options, Validation, CLI)
- **Phase 3** (v2.2): Advanced Features (Color Management, Variants, Collaboration, Watch Folder, Scripting)
- **Phase 4** (v2.3): Platform-Specific & Cross-platform (Platform Optimizations, Asset Management, Android/Web/Windows)
- **Phase 5** (v3.0): AI/ML & Cloud (ML Upscaling, Background Removal, Style Transfer, Cloud Sync)

---

## Success Metrics

### Performance Targets
- Icon generation: < 100ms per icon
- Batch processing: > 10 images/second
- Preview render: < 50ms
- App launch time: < 2 seconds

### Quality Targets
- Unit test coverage: > 80%
- UI test coverage: > 60%
- Zero memory leaks
- Zero crashes in production

---

## Questions for Clarification

Before proceeding with implementation, please confirm:

1. **Priority**: Should I implement all phases, or focus on Phase 1 first?
2. **Core ML Models**: Should I include ML models in the app bundle, or download on-demand?
3. **Cloud Sync**: Is iCloud sync a required feature, or optional?
4. **CLI**: Should the CLI be a separate executable, or integrated into the main app?
5. **Pricing**: Will this be a paid app? Affects feature availability decisions.
6. **App Store**: Planning to distribute via App Store? Affects entitlements and sandboxing.

---

## Implementation Timeline Estimate

### Phase 1: 2-3 weeks
- Batch Processing: 3-4 days
- Presets System: 3-4 days
- Advanced Image Processing: 4-5 days
- Enhanced Previews: 3-4 days
- Multi-Platform Install: 1-2 days

### Phase 2: 2-3 weeks
- Project Management: 3-4 days
- Custom Paths: 1-2 days
- Export Options: 3-4 days
- Validation System: 3-4 days
- CLI: 2-3 days

### Phase 3: 3-4 weeks
- Color Management: 3-4 days
- Icon Variants: 4-5 days
- Collaboration: 3-4 days
- Watch Folder: 3-4 days
- AppleScript/Shortcuts: 2-3 days

### Phase 4: 2-3 weeks
- Platform Optimizations: 3-4 days
- Asset Management: 3-4 days
- Cross-Platform Export: 4-5 days

### Phase 5: 2-3 weeks
- AI/ML Features: 5-7 days
- Cloud Sync: 4-5 days

**Total Estimate: 11-16 weeks** (full implementation of all phases)

---

## Next Steps

Upon your approval, I will:

1. Create all new files in the proper directory structure
2. Implement features phase-by-phase
3. Add comprehensive documentation
4. Write unit and UI tests
5. Update README and user documentation
6. Create example workflows
7. Generate release notes

Ready to proceed when you give the go-ahead!
