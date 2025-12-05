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

    /// Required icon sizes in points for this platform
    /// Note: These sizes may need @2x and @3x variants
    var iconSizes: [Int] {
        switch self {
        case .iOS, .macCatalyst:
            // iPhone/iPad icon sizes: notification, settings, spotlight, app icon, App Store
            return [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024]
        case .macOS:
            // macOS icon sizes for different display densities
            return [16, 32, 64, 128, 256, 512, 1024]
        case .tvOS:
            // Apple TV icon sizes: home screen and App Store
            return [400, 1280]
        case .watchOS:
            // Apple Watch icon sizes: notification, companion, home screen, App Store
            return [24, 27, 29, 40, 44, 50, 51, 86, 98, 108, 117, 129, 1024]
        case .iMessage:
            // iMessage app icon sizes
            return [60, 67, 74, 81, 120, 134, 148, 180, 1024]
        }
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
            // Clamp scale to valid range
            scale = max(Constants.minScale, min(Constants.maxScale, scale))
        }
    }

    /// Padding percentage around the image (0-30%)
    /// Default: 10%
    @Published var padding: Double = 10.0 {
        didSet {
            // Clamp padding to valid range
            padding = max(Constants.minPadding, min(Constants.maxPadding, padding))
        }
    }

    /// Background color for the icon
    /// Default: white
    @Published var backgroundColor: Color = .white

    /// Whether to automatically crop non-square images to square
    /// Default: true
    @Published var autoCropToSquare: Bool = true

    /// Stores the original image before cropping (if cropped)
    private var originalImage: NSImage?

    /// Whether the current image was auto-cropped
    @Published var wasAutoCropped: Bool = false

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

    /// Cache for generated previews to avoid redundant rendering
    private var previewCache: [String: NSImage] = [:]

    // MARK: - Public Methods

    /// Resets all settings to default values
    func resetSettings() {
        scale = 1.0
        padding = 10.0
        backgroundColor = .white
        previewCache.removeAll()
    }

    /// Automatically crops an image to square by trimming edges
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

        // Create cropped image
        let croppedImage = NSImage(size: NSSize(width: cropSize, height: cropSize))
        croppedImage.lockFocus()
        defer { croppedImage.unlockFocus() }  // Ensure unlock even if error occurs

        // Draw the cropped portion
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let sourceRect = CGRect(x: xOffset, y: yOffset, width: cropSize, height: cropSize)

            if let croppedCGImage = cgImage.cropping(to: sourceRect) {
                let nsImage = NSImage(cgImage: croppedCGImage, size: NSSize(width: cropSize, height: cropSize))
                nsImage.draw(in: NSRect(x: 0, y: 0, width: cropSize, height: cropSize))
            }
        }

        print("✂️ Auto-cropped image from \(Int(size.width))×\(Int(size.height)) to \(Int(cropSize))×\(Int(cropSize))")

        return croppedImage
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
        let cacheKey = "\(size)_\(scale)_\(padding)_\(backgroundColor.description)"

        // Return cached image if available
        if let cached = previewCache[cacheKey] {
            return cached
        }

        // Generate new icon
        guard let icon = generateIcon(from: source, size: size) else {
            return nil
        }

        // Cache the result
        previewCache[cacheKey] = icon

        return icon
    }

    /// Generates an icon at the specified size with current settings
    /// - Parameters:
    ///   - image: Source image to convert
    ///   - size: Target size in pixels (width and height)
    /// - Returns: Generated icon, or nil if generation fails
    func generateIcon(from image: NSImage, size: Int) -> NSImage? {
        let targetSize = CGFloat(size)

        // Calculate padding amount in pixels
        let paddingAmount = targetSize * (padding / 100.0)
        let contentSize = targetSize - (paddingAmount * 2)

        // Calculate final scaled size
        let scaledSize = contentSize * scale

        // Validate that scaled size fits within bounds
        guard scaledSize > 0 && scaledSize <= targetSize else {
            print("⚠️ Invalid scaled size: \(scaledSize) for target: \(targetSize)")
            return nil
        }

        // Create output image
        let outputImage = NSImage(size: NSSize(width: targetSize, height: targetSize))

        // Use autoreleasepool to prevent memory buildup
        autoreleasepool {
            outputImage.lockFocus()
            defer { outputImage.unlockFocus() }  // Ensure unlock even if error occurs

            // Draw background color
            let nsColor = NSColor(backgroundColor)
            nsColor.setFill()
            NSRect(x: 0, y: 0, width: targetSize, height: targetSize).fill()

            // Calculate position to center the scaled image
            let x = (targetSize - scaledSize) / 2
            let y = (targetSize - scaledSize) / 2

            // Draw source image with high quality interpolation
            let sourceRect = NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            let destRect = NSRect(x: x, y: y, width: scaledSize, height: scaledSize)

            NSGraphicsContext.current?.imageInterpolation = .high
            image.draw(in: destRect, from: sourceRect, operation: .sourceOver, fraction: 1.0)
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
