import SwiftUI
import AppKit

// MARK: - Platform Configuration

/// Represents all Apple platforms that support app icons
/// Each platform has specific icon size requirements and scaling factors
enum Platform: String, CaseIterable, Hashable {
    case iOS = "iOS"
    case macOS = "macOS"
    case tvOS = "tvOS"
    case watchOS = "watchOS"
    case iMessage = "iMessage"
    case macCatalyst = "Mac Catalyst"

    /// SF Symbol icon name for UI display
    var iconName: String {
        switch self {
        case .iOS: return "iphone"
        case .macOS: return "desktopcomputer"
        case .tvOS: return "appletv"
        case .watchOS: return "applewatch"
        case .iMessage: return "message.fill"
        case .macCatalyst: return "laptopcomputer.and.iphone"
        }
    }

    /// Required icon sizes in points for this platform.
    /// Checks for a user-configurable JSON file first (IconSizes.json in Application Support),
    /// falling back to hardcoded defaults. This allows updating sizes without recompiling.
    var iconSizes: [Int] {
        // Check for user-configurable overrides from JSON
        if let overrides = Platform.loadIconSizeOverrides(), let sizes = overrides[self.rawValue], !sizes.isEmpty {
            return sizes
        }

        // Hardcoded defaults
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

    /// Loads platform icon size overrides from an optional JSON configuration file.
    /// File location: ~/Library/Application Support/Icon Creator/IconSizes.json
    /// Format: { "watchOS": [24, 27, 29, ...], "iOS": [20, 29, ...] }
    private static func loadIconSizeOverrides() -> [String: [Int]]? {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else { return nil }

        let configURL = appSupport
            .appendingPathComponent("Icon Creator", isDirectory: true)
            .appendingPathComponent("IconSizes.json")

        guard FileManager.default.fileExists(atPath: configURL.path),
              let data = try? Data(contentsOf: configURL),
              let dict = try? JSONDecoder().decode([String: [Int]].self, from: data) else {
            return nil
        }

        return dict
    }

    /// Folder name for export (removes spaces)
    var folderName: String {
        return rawValue.replacingOccurrences(of: " ", with: "")
    }
}

// MARK: - Icon Generator

/// Main class responsible for generating app icons from source images
/// Handles image scaling, padding, background colors, and export to Xcode-compatible format
class IconGenerator: ObservableObject {
    // MARK: - Published Properties

    /// Source image provided by the user
    @Published var sourceImage: NSImage?

    /// Scale factor for the image (0.5 = 50%, 2.0 = 200%)
    /// Default: 1.0 (100%)
    @Published var scale: Double = 1.0 {
        didSet {
            // Clamp scale to valid range. The self-assignment MUST be guarded:
            // writing back unconditionally inside a @Published property's didSet
            // re-enters the observer on every set and recurses without bound
            // (stack overflow / SIGSEGV) — that is what crashed the app the instant
            // the scale slider moved. Only write back when the value is genuinely
            // out of range so the re-entrant didSet sees an already-clamped value
            // and terminates.
            let clamped = max(Constants.minScale, min(Constants.maxScale, scale))
            if scale != clamped { scale = clamped }
            clearCache()
        }
    }

    /// Padding percentage around the image (0-30%)
    /// Default: 10%
    @Published var padding: Double = 10.0 {
        didSet {
            // Clamp padding to valid range. Guard the self-assignment for the same
            // reason as `scale` above — an unconditional write-back inside a
            // @Published didSet recurses without bound and crashed the app when the
            // padding slider moved. Only write back when actually out of range.
            let clamped = max(Constants.minPadding, min(Constants.maxPadding, padding))
            if padding != clamped { padding = clamped }
            clearCache()
        }
    }

    /// Background color for the icon
    /// Default: white
    @Published var backgroundColor: Color = .white {
        didSet {
            clearCache()
        }
    }

    /// Whether to automatically crop non-square images to square
    /// Default: true
    @Published var autoCropToSquare: Bool = true

    /// Image effects configuration
    @Published var effects: ImageEffects = ImageEffects()

    /// Stores the original image before cropping (if cropped)
    private var originalImage: NSImage?

    /// Whether the current image was auto-cropped
    @Published var wasAutoCropped: Bool = false

    /// Image processor for applying effects
    private let imageProcessor = ImageProcessor()

    // MARK: - Constants

    private enum Constants {
        static let minScale: Double = 0.5
        static let maxScale: Double = 2.0
        static let minPadding: Double = 0.0
        static let maxPadding: Double = 30.0
        static let minImageSize: CGFloat = 64.0  // Minimum source image size
        static let recommendedImageSize: CGFloat = 1024.0  // Recommended source image size
    }

    // MARK: - Image Cache

    /// NSCache-backed preview cache with automatic eviction under memory pressure.
    /// More efficient than a plain dictionary — the system can purge entries when needed.
    private let previewCache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 100   // Max 100 cached previews
        cache.totalCostLimit = 200 * 1024 * 1024  // ~200 MB limit
        return cache
    }()

    // MARK: - Public Methods

    /// Resets all settings to default values
    func resetSettings() {
        scale = 1.0
        padding = 10.0
        backgroundColor = .white
        effects = ImageEffects()
        previewCache.removeAllObjects()
    }

    /// Clears the preview cache
    func clearCache() {
        previewCache.removeAllObjects()
    }

    /// Gets current settings as IconSettings struct
    var currentSettings: IconSettings {
        IconSettings(
            scale: scale,
            padding: padding,
            backgroundColor: ColorComponents(backgroundColor),
            autoCropToSquare: autoCropToSquare,
            effects: effects
        )
    }

    /// Applies IconSettings to this generator
    func applySettings(_ settings: IconSettings) {
        scale = settings.scale
        padding = settings.padding
        backgroundColor = settings.backgroundColor.color
        autoCropToSquare = settings.autoCropToSquare
        effects = settings.effects
    }

    /// Automatically crops an image to square by trimming edges.
    /// Uses CGContext instead of the deprecated lockFocus()/unlockFocus() pattern.
    /// - Parameter image: The image to crop
    /// - Returns: Square-cropped image, or original if already square
    func autoCropImageToSquare(_ image: NSImage) -> NSImage {
        let size = image.size

        // Already square (or close enough)
        let aspectRatio = size.width / size.height
        if aspectRatio >= 0.95 && aspectRatio <= 1.05 {
            return image
        }

        // Determine crop size (smallest dimension)
        let cropSize = min(size.width, size.height)

        // Calculate crop offset (center crop)
        let xOffset = (size.width - cropSize) / 2
        let yOffset = (size.height - cropSize) / 2

        // Use CGImage cropping — no lockFocus needed
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return image
        }

        // CGImage coordinates may differ from NSImage coordinates due to scale
        let scaleX = CGFloat(cgImage.width) / size.width
        let scaleY = CGFloat(cgImage.height) / size.height
        let cropRect = CGRect(
            x: xOffset * scaleX,
            y: yOffset * scaleY,
            width: cropSize * scaleX,
            height: cropSize * scaleY
        )

        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return image
        }

        let result = NSImage(cgImage: croppedCGImage, size: NSSize(width: cropSize, height: cropSize))
        print("Auto-cropped image from \(Int(size.width))x\(Int(size.height)) to \(Int(cropSize))x\(Int(cropSize))")
        return result
    }

    /// Validates the source image for icon generation
    /// Automatically crops to square if enabled
    /// - Returns: Validation result with optional error message
    func validateSourceImage() -> (isValid: Bool, error: String?) {
        guard let image = sourceImage else {
            return (false, "No image selected")
        }

        // Check minimum size
        if image.size.width < Constants.minImageSize || image.size.height < Constants.minImageSize {
            return (false, "Image is too small. Minimum size: \(Int(Constants.minImageSize))×\(Int(Constants.minImageSize)) pixels")
        }

        // Check if image is square (or close to it)
        let aspectRatio = image.size.width / image.size.height
        if aspectRatio < 0.9 || aspectRatio > 1.1 {
            // Auto-crop if enabled
            if autoCropToSquare {
                originalImage = image
                sourceImage = autoCropImageToSquare(image)
                wasAutoCropped = true

                // Re-validate after cropping
                guard let croppedImage = sourceImage else {
                    return (false, "Failed to crop image")
                }

                // Check if cropped image meets size requirements
                if croppedImage.size.width < Constants.minImageSize {
                    return (false, "Image is too small after cropping. Minimum size: \(Int(Constants.minImageSize))×\(Int(Constants.minImageSize)) pixels")
                }

                // Return warning about auto-crop
                return (true, "✂️ Image auto-cropped to square (\(Int(croppedImage.size.width))×\(Int(croppedImage.size.height)))")
            } else {
                return (false, "Image should be square or nearly square for best results")
            }
        }

        wasAutoCropped = false

        // Warn if image is smaller than recommended
        if image.size.width < Constants.recommendedImageSize {
            return (true, "⚠️ Image is smaller than recommended (\(Int(Constants.recommendedImageSize))×\(Int(Constants.recommendedImageSize))). Quality may be reduced.")
        }

        return (true, nil)
    }

    /// Restores the original image if it was auto-cropped
    func restoreOriginalImage() {
        if let original = originalImage {
            sourceImage = original
            wasAutoCropped = false
            originalImage = nil
            print("↩️ Restored original image")
        }
    }

    /// Generates a preview icon at the specified size
    /// Uses caching to improve performance
    /// - Parameter size: Target size in pixels
    /// - Returns: Generated icon image, or nil if generation fails
    func generatePreview(size: Int) -> NSImage? {
        guard let source = sourceImage else { return nil }

        // Generate cache key based on current settings
        let cacheKey = "\(size)_\(scale)_\(padding)_\(backgroundColor.description)" as NSString

        // Return cached image if available
        if let cached = previewCache.object(forKey: cacheKey) {
            return cached
        }

        // Generate new icon
        guard let icon = generateIcon(from: source, size: size) else {
            return nil
        }

        // Cache the result with approximate cost in bytes
        let estimatedCost = size * size * 4  // RGBA, 4 bytes per pixel
        previewCache.setObject(icon, forKey: cacheKey, cost: estimatedCost)

        return icon
    }

    /// Generates an icon at the specified size with current settings
    /// - Parameters:
    ///   - image: Source image to convert
    ///   - size: Target size in pixels (width and height)
    /// - Returns: Generated icon, or nil if generation fails
    func generateIcon(from image: NSImage, size: Int) -> NSImage? {
        // Check if any effects are enabled
        let hasEffects = effects.cornerRadiusEnabled || effects.shadowEnabled ||
                        effects.borderEnabled || effects.brightness != 0 ||
                        effects.contrast != 0 || effects.saturation != 0 ||
                        effects.backgroundType != .solid

        // Use ImageProcessor if effects are enabled
        if hasEffects {
            return imageProcessor.processImage(image, with: currentSettings, targetSize: size)
        }

        // Otherwise use the CGContext fast path (avoids deprecated lockFocus)
        let targetSize = CGFloat(size)

        // Calculate padding amount in pixels
        let paddingAmount = targetSize * (padding / 100.0)
        let contentSize = targetSize - (paddingAmount * 2)

        // Calculate final scaled size
        let scaledSize = contentSize * scale

        // Validate geometry. Only reject genuinely invalid values — non-positive
        // or non-finite. Upscaling past targetSize is intentional: the render canvas
        // is a fixed targetSize×targetSize bitmap, so a scaledSize larger than the
        // canvas simply clips the zoomed image at its edges (that is the entire point
        // of a 0.5–2.0 scale slider). scaledSize > targetSize must NOT be rejected or
        // clamped — doing so blanked the preview whenever scale went above 1.0. (The
        // crash-on-slider itself was the @Published didSet recursion, fixed above.)
        guard scaledSize > 0, scaledSize.isFinite, targetSize > 0 else {
            print("Invalid geometry: scaledSize \(scaledSize) for target \(targetSize)")
            return nil
        }

        // Canvas must be at least 1×1 pixel to construct a valid bitmap rep.
        let pixelWidth = max(1, Int(targetSize))
        let pixelHeight = max(1, Int(targetSize))

        // Use NSBitmapImageRep + NSGraphicsContext instead of lockFocus/unlockFocus
        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelWidth,
            pixelsHigh: pixelHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }

        let outputImage: NSImage = autoreleasepool {
            guard let context = NSGraphicsContext(bitmapImageRep: bitmapRep) else {
                return NSImage()
            }
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = context
            context.imageInterpolation = .high

            // Draw background color
            let nsColor = NSColor(backgroundColor)
            nsColor.setFill()
            NSRect(x: 0, y: 0, width: targetSize, height: targetSize).fill()

            // Calculate position to center the scaled image
            let x = (targetSize - scaledSize) / 2
            let y = (targetSize - scaledSize) / 2

            // Draw source image
            let sourceRect = NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            let destRect = NSRect(x: x, y: y, width: scaledSize, height: scaledSize)
            image.draw(in: destRect, from: sourceRect, operation: .sourceOver, fraction: 1.0)

            NSGraphicsContext.restoreGraphicsState()

            let result = NSImage(size: NSSize(width: targetSize, height: targetSize))
            result.addRepresentation(bitmapRep)
            return result
        }

        return outputImage
    }

    /// Exports icons for a specific platform to the given directory
    /// Creates an AppIcon.appiconset folder with all required sizes and Contents.json
    /// - Parameters:
    ///   - platform: Target platform (iOS, macOS, etc.)
    ///   - baseURL: Base directory URL for export
    ///   - progressHandler: Optional closure called with progress updates (0.0 to 1.0)
    /// - Throws: IconGeneratorError for various failure conditions
    func exportIcons(for platform: Platform, to baseURL: URL, progressHandler: ((Double) -> Void)? = nil) throws {
        // Validate source image
        guard let source = sourceImage else {
            throw IconGeneratorError.noSourceImage
        }

        let validation = validateSourceImage()
        if !validation.isValid {
            throw IconGeneratorError.invalidImage(validation.error ?? "Unknown error")
        }

        // Create platform folder
        let platformURL = baseURL.appendingPathComponent(platform.folderName)
        try FileManager.default.createDirectory(at: platformURL, withIntermediateDirectories: true)

        // Create AppIcon.appiconset folder
        let appiconsetURL = platformURL.appendingPathComponent("AppIcon.appiconset")
        try FileManager.default.createDirectory(at: appiconsetURL, withIntermediateDirectories: true)

        // Generate icons with progress tracking
        var contentsJSON = ContentsJSON(platform: platform)
        let allSizes = platform.iconSizes
        var processedCount = 0
        let totalCount = allSizes.reduce(0) { count, size in
            let scales = size == 1024 ? [1] : getScalesForSize(size, platform: platform)
            return count + scales.count
        }

        for size in allSizes {
            // Generate @1x, @2x, @3x if applicable
            let scales: [Int] = size == 1024 ? [1] : getScalesForSize(size, platform: platform)

            for scaleValue in scales {
                try autoreleasepool {
                    let actualSize = size / scaleValue
                    let filename = "icon_\(actualSize)x\(actualSize)@\(scaleValue)x.png"
                    let fileURL = appiconsetURL.appendingPathComponent(filename)

                    if let resizedImage = generateIcon(from: source, size: actualSize * scaleValue) {
                        do {
                            try saveAsPNG(image: resizedImage, to: fileURL)

                            contentsJSON.addImage(
                                filename: filename,
                                size: "\(actualSize)x\(actualSize)",
                                scale: "\(scaleValue)x",
                                idiom: platform.idiom
                            )
                        } catch {
                            print("⚠️ Failed to generate icon: \(filename) - \(error.localizedDescription)")
                            throw IconGeneratorError.exportFailed("Failed to generate \(filename): \(error.localizedDescription)")
                        }
                    }

                    processedCount += 1
                    progressHandler?(Double(processedCount) / Double(totalCount))
                }
            }
        }

        // Save Contents.json with pretty printing
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let contentsData = try encoder.encode(contentsJSON)
        let contentsURL = appiconsetURL.appendingPathComponent("Contents.json")
        try contentsData.write(to: contentsURL)

        print("✅ Successfully exported \(processedCount) icons for \(platform.rawValue)")
    }

    // MARK: - Private Methods

    /// Determines the appropriate scale factors for a given size and platform
    /// - Parameters:
    ///   - size: Icon size in points
    ///   - platform: Target platform
    /// - Returns: Array of scale factors (1, 2, or 3)
    private func getScalesForSize(_ size: Int, platform: Platform) -> [Int] {
        switch platform {
        case .iOS, .macCatalyst:
            // Notification, settings, and spotlight icons need all three scales
            if size == 20 || size == 29 || size == 40 { return [1, 2, 3] }
            // App icons only need @2x and @3x
            return [2, 3]
        case .macOS:
            // macOS supports @1x and @2x
            return [1, 2]
        case .tvOS:
            // tvOS only uses @1x (already at high resolution)
            return [1]
        case .watchOS:
            // watchOS primarily uses @2x
            return [2]
        case .iMessage:
            // iMessage apps use @2x and @3x
            return [2, 3]
        }
    }

    /// Saves an NSImage as PNG to the specified URL
    /// - Parameters:
    ///   - image: Image to save
    ///   - url: Destination file URL
    /// - Throws: IconGeneratorError.pngConversionFailed if conversion fails
    private func saveAsPNG(image: NSImage, to url: URL) throws {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            throw IconGeneratorError.pngConversionFailed
        }

        try pngData.write(to: url)
    }
}

// MARK: - Error Handling

/// Custom errors for icon generation
enum IconGeneratorError: LocalizedError {
    case noSourceImage
    case invalidImage(String)
    case pngConversionFailed
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .noSourceImage:
            return "No source image selected"
        case .invalidImage(let message):
            return "Invalid image: \(message)"
        case .pngConversionFailed:
            return "Failed to convert image to PNG format"
        case .exportFailed(let message):
            return "Export failed: \(message)"
        }
    }
}

// MARK: - Platform Extension

extension Platform {
    /// Xcode idiom identifier for Contents.json
    var idiom: String {
        switch self {
        case .iOS, .macCatalyst: return "iphone"
        case .macOS: return "mac"
        case .tvOS: return "tv"
        case .watchOS: return "watch"
        case .iMessage: return "iphone"
        }
    }
}

// MARK: - Contents.json Structure

/// Represents the Contents.json file structure for Xcode asset catalogs
struct ContentsJSON: Codable {
    var images: [ImageEntry] = []
    var info: InfoEntry = InfoEntry()

    /// Initializes a new Contents.json structure
    /// - Parameter platform: Target platform (used for documentation)
    init(platform: Platform) {
        // Platform is used to ensure proper initialization context
        // but doesn't affect the structure
    }

    /// Adds an image entry to the contents
    mutating func addImage(filename: String, size: String, scale: String, idiom: String) {
        images.append(ImageEntry(
            filename: filename,
            idiom: idiom,
            scale: scale,
            size: size
        ))
    }

    /// Individual image entry in Contents.json
    struct ImageEntry: Codable {
        let filename: String
        let idiom: String
        let scale: String
        let size: String
    }

    /// Metadata entry in Contents.json
    struct InfoEntry: Codable {
        var author: String = "xcode"
        var version: Int = 1

        enum CodingKeys: String, CodingKey {
            case author
            case version
        }
    }
}
