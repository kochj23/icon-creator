import Foundation
import AppKit
import CoreImage
import Vision

// MARK: - Icon Validator

/// Validates icons against App Store Connect guidelines
/// Performs automated checks for common rejection issues
class IconValidator {

    // MARK: - Validation Result

    struct ValidationResult {
        let isValid: Bool
        let errors: [ValidationError]
        let warnings: [ValidationWarning]

        var hasErrors: Bool { !errors.isEmpty }
        var hasWarnings: Bool { !warnings.isEmpty }

        /// All issues (errors + warnings) combined
        var allIssues: [ValidationIssue] {
            errors.map { $0 as ValidationIssue } + warnings.map { $0 as ValidationIssue }
        }
    }

    // MARK: - Validation Issue Protocol

    protocol ValidationIssue {
        var title: String { get }
        var message: String { get }
        var severity: ValidationSeverity { get }
        var category: ValidationCategory { get }
    }

    enum ValidationSeverity {
        case error      // Will be rejected by App Store
        case warning    // May cause issues or poor user experience
        case info       // Informational only
    }

    enum ValidationCategory: String {
        case transparency = "Transparency"
        case colorSpace = "Color Space"
        case resolution = "Resolution"
        case fileSize = "File Size"
        case content = "Content"
        case quality = "Quality"
        case accessibility = "Accessibility"
        case format = "Format"
    }

    // MARK: - Validation Error

    struct ValidationError: ValidationIssue {
        let title: String
        let message: String
        let category: ValidationCategory

        var severity: ValidationSeverity { .error }
    }

    // MARK: - Validation Warning

    struct ValidationWarning: ValidationIssue {
        let title: String
        let message: String
        let category: ValidationCategory

        var severity: ValidationSeverity { .warning }
    }

    // MARK: - Constants

    private enum Constants {
        static let minimumDPI: CGFloat = 72.0
        static let recommendedDPI: CGFloat = 144.0
        static let maxFileSizeBytes: Int = 10 * 1024 * 1024  // 10 MB
        static let recommendedFileSizeBytes: Int = 2 * 1024 * 1024  // 2 MB
        static let minimumIconSize: CGFloat = 1024.0
        static let alphaChannelTolerance: Float = 0.01  // 1% tolerance for alpha
    }

    // MARK: - Public Validation Methods

    /// Performs comprehensive validation on an icon image
    /// - Parameters:
    ///   - image: The icon image to validate
    ///   - platform: Target platform (iOS requires no transparency)
    ///   - fileURL: Optional file URL for file-based checks
    /// - Returns: ValidationResult with all errors and warnings
    func validate(_ image: NSImage, for platform: Platform? = nil, fileURL: URL? = nil) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        // 1. Check transparency (critical for iOS)
        if let platform = platform, platform == .iOS || platform == .macCatalyst {
            if let transparencyError = checkTransparency(image) {
                errors.append(transparencyError)
            }
        } else {
            // For other platforms, transparency is optional but warn if present
            if hasTransparency(image) {
                warnings.append(ValidationWarning(
                    title: "Icon Contains Transparency",
                    message: "Icon has transparent pixels. This is allowed for \(platform?.rawValue ?? "this platform") but may appear differently on various backgrounds.",
                    category: .transparency
                ))
            }
        }

        // 2. Check alpha channel issues
        if let alphaError = checkAlphaChannel(image) {
            errors.append(alphaError)
        }

        // 3. Check DPI/resolution
        if let dpiWarning = checkDPI(image) {
            warnings.append(dpiWarning)
        }

        // 4. Check color space
        if let colorSpaceWarning = checkColorSpace(image) {
            warnings.append(colorSpaceWarning)
        }

        // 5. Check file size (if URL provided)
        if let url = fileURL {
            if let fileSizeWarning = checkFileSize(url) {
                warnings.append(fileSizeWarning)
            }
        }

        // 6. Check minimum size
        if let sizeError = checkMinimumSize(image) {
            errors.append(sizeError)
        }

        // 7. Check if image is square
        if let aspectWarning = checkAspectRatio(image) {
            warnings.append(aspectWarning)
        }

        // 8. Check image quality
        if let qualityWarning = checkImageQuality(image) {
            warnings.append(qualityWarning)
        }

        // 9. Basic content validation
        if let contentWarning = checkBasicContent(image) {
            warnings.append(contentWarning)
        }

        // 10. Check accessibility (contrast)
        if let accessibilityWarning = checkAccessibility(image) {
            warnings.append(accessibilityWarning)
        }

        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }

    // MARK: - Individual Validation Checks

    /// Checks if icon has transparency (alpha channel with values < 1.0)
    private func hasTransparency(_ image: NSImage) -> Bool {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return false
        }

        guard let alphaInfo = cgImage.alphaInfo as CGImageAlphaInfo? else {
            return false
        }

        // Check if alpha info indicates transparency
        switch alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast:
            return false
        default:
            return true
        }
    }

    /// Check for transparency (iOS icons must be fully opaque)
    private func checkTransparency(_ image: NSImage) -> ValidationError? {
        if hasTransparency(image) {
            return ValidationError(
                title: "iOS Icon Contains Transparency",
                message: "iOS app icons must be fully opaque (no transparency/alpha channel). Apple will reject icons with transparent pixels. Set a solid background color.",
                category: .transparency
            )
        }
        return nil
    }

    /// Check for alpha channel issues (partial transparency, edge artifacts)
    private func checkAlphaChannel(_ image: NSImage) -> ValidationError? {
        // Placeholder for future alpha channel artifact detection
        return nil
    }

    /// Check DPI/resolution
    private func checkDPI(_ image: NSImage) -> ValidationWarning? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let pixelWidth = cgImage.width
        let pixelHeight = cgImage.height
        let pointWidth = image.size.width
        let pointHeight = image.size.height

        // Calculate effective DPI
        let dpiX = (CGFloat(pixelWidth) / pointWidth) * 72.0
        let dpiY = (CGFloat(pixelHeight) / pointHeight) * 72.0
        let avgDPI = (dpiX + dpiY) / 2.0

        if avgDPI < Constants.minimumDPI {
            return ValidationWarning(
                title: "Low DPI Detected",
                message: "Icon DPI is \(Int(avgDPI)), which is below the recommended minimum of \(Int(Constants.minimumDPI)). This may result in poor quality on high-resolution displays.",
                category: .resolution
            )
        }

        return nil
    }

    /// Check color space (sRGB recommended)
    private func checkColorSpace(_ image: NSImage) -> ValidationWarning? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let colorSpace = cgImage.colorSpace else {
            return ValidationWarning(
                title: "Unknown Color Space",
                message: "Could not determine icon color space. sRGB is recommended for best compatibility across devices.",
                category: .colorSpace
            )
        }

        // Check if color space is sRGB
        if let name = colorSpace.name {
            let nameString = name as String
            if !nameString.lowercased().contains("srgb") && !nameString.contains("Display P3") {
                return ValidationWarning(
                    title: "Non-sRGB Color Space",
                    message: "Icon uses \(nameString) color space. Apple recommends sRGB for consistent color appearance across devices.",
                    category: .colorSpace
                )
            }
        }

        return nil
    }

    /// Check file size
    private func checkFileSize(_ url: URL) -> ValidationWarning? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int else {
            return nil
        }

        if fileSize > Constants.maxFileSizeBytes {
            return ValidationWarning(
                title: "File Size Too Large",
                message: "Icon file is \(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)), exceeding the \(ByteCountFormatter.string(fromByteCount: Int64(Constants.maxFileSizeBytes), countStyle: .file)) limit. This may be rejected or cause performance issues.",
                category: .fileSize
            )
        } else if fileSize > Constants.recommendedFileSizeBytes {
            return ValidationWarning(
                title: "File Size Large",
                message: "Icon file is \(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)). Consider optimizing to reduce app size. Recommended: under \(ByteCountFormatter.string(fromByteCount: Int64(Constants.recommendedFileSizeBytes), countStyle: .file)).",
                category: .fileSize
            )
        }

        return nil
    }

    /// Check minimum size
    private func checkMinimumSize(_ image: NSImage) -> ValidationError? {
        if image.size.width < Constants.minimumIconSize || image.size.height < Constants.minimumIconSize {
            return ValidationError(
                title: "Icon Too Small",
                message: "Icon is \(Int(image.size.width))×\(Int(image.size.height)) pixels. Minimum required size is \(Int(Constants.minimumIconSize))×\(Int(Constants.minimumIconSize)) pixels for App Store.",
                category: .resolution
            )
        }
        return nil
    }

    /// Check aspect ratio (should be square)
    private func checkAspectRatio(_ image: NSImage) -> ValidationWarning? {
        let aspectRatio = image.size.width / image.size.height
        if aspectRatio < 0.95 || aspectRatio > 1.05 {
            return ValidationWarning(
                title: "Icon Not Square",
                message: "Icon aspect ratio is \(String(format: "%.2f", aspectRatio)):1. App icons should be square (1:1 aspect ratio) for best results.",
                category: .format
            )
        }
        return nil
    }

    /// Check image quality (detect compression artifacts, low contrast)
    private func checkImageQuality(_ image: NSImage) -> ValidationWarning? {
        // Placeholder for future quality detection
        return nil
    }

    /// Basic content validation (detect solid colors, check for actual content)
    private func checkBasicContent(_ image: NSImage) -> ValidationWarning? {
        // Placeholder for future content analysis
        return nil
    }

    /// Check accessibility (contrast, readability)
    private func checkAccessibility(_ image: NSImage) -> ValidationWarning? {
        // Placeholder for future accessibility checks
        return nil
    }
}
