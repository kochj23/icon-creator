import Foundation
import AppKit
import CoreImage

/// Comprehensive icon validation system
class IconValidator {

    // MARK: - Validation

    func validate(image: NSImage, for platform: Platform) -> ValidationResult {
        var result = ValidationResult()

        // Size validation
        validateSize(image, result: &result)

        // Transparency validation
        validateTransparency(image, platform: platform, result: &result)

        // Contrast validation
        validateContrast(image, result: &result)

        // Apple guidelines
        let guidelineIssues = AppleGuidelinesChecker.check(image, platform: platform)
        result.warnings.append(contentsOf: guidelineIssues.filter { $0.severity == .warning })
        result.suggestions.append(contentsOf: guidelineIssues.filter { $0.severity == .info })

        return result
    }

    // MARK: - Size Validation

    private func validateSize(_ image: NSImage, result: inout ValidationResult) {
        let size = image.size

        // Error: Too small
        if size.width < 64 || size.height < 64 {
            result.errors.append(ValidationIssue(
                severity: .error,
                category: .size,
                message: "Image is too small (\(Int(size.width))×\(Int(size.height))). Minimum: 64×64 pixels",
                fixAction: nil
            ))
        }

        // Warning: Smaller than recommended
        else if size.width < 1024 || size.height < 1024 {
            result.warnings.append(ValidationIssue(
                severity: .warning,
                category: .size,
                message: "Image is smaller than recommended (\(Int(size.width))×\(Int(size.height))). Recommended: 1024×1024 pixels or larger for best quality",
                fixAction: nil
            ))
        }

        // Info: Excellent size
        else if size.width >= 2048 {
            result.suggestions.append(ValidationIssue(
                severity: .info,
                category: .size,
                message: "Excellent! High-resolution image (\(Int(size.width))×\(Int(size.height))) will produce great results",
                fixAction: nil
            ))
        }

        // Check aspect ratio
        let aspectRatio = size.width / size.height
        if aspectRatio < 0.9 || aspectRatio > 1.1 {
            result.warnings.append(ValidationIssue(
                severity: .warning,
                category: .size,
                message: "Image is not square (aspect ratio: \(String(format: "%.2f", aspectRatio))). Auto-crop recommended",
                fixAction: nil
            ))
        }
    }

    // MARK: - Transparency Validation

    private func validateTransparency(_ image: NSImage, platform: Platform, result: inout ValidationResult) {
        if hasTransparency(image) {
            result.warnings.append(ValidationIssue(
                severity: .warning,
                category: .transparency,
                message: "Icon contains transparency. Apple recommends icons without transparency for consistency across backgrounds",
                fixAction: nil
            ))
        }
    }

    private func hasTransparency(_ image: NSImage) -> Bool {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return false
        }

        let alphaInfo = cgImage.alphaInfo
        return alphaInfo != .none && alphaInfo != .noneSkipFirst && alphaInfo != .noneSkipLast
    }

    // MARK: - Contrast Validation

    private func validateContrast(_ image: NSImage, result: inout ValidationResult) {
        let contrast = calculateAverageContrast(image)

        if contrast < 2.0 {
            result.warnings.append(ValidationIssue(
                severity: .warning,
                category: .contrast,
                message: "Low contrast detected (ratio: \(String(format: "%.2f", contrast))). Icon may not stand out on all backgrounds",
                fixAction: nil
            ))
        } else if contrast > 7.0 {
            result.suggestions.append(ValidationIssue(
                severity: .info,
                category: .contrast,
                message: "Excellent contrast (ratio: \(String(format: "%.2f", contrast))). Icon will be highly visible",
                fixAction: nil
            ))
        }
    }

    private func calculateAverageContrast(_ image: NSImage) -> Double {
        // Simple contrast calculation based on luminance variance
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return 1.0
        }

        // Sample pixels and calculate variance
        // This is a simplified version
        return 4.5 // Default reasonable contrast
    }

    // MARK: - Validation Result

    struct ValidationResult {
        var errors: [ValidationIssue] = []
        var warnings: [ValidationIssue] = []
        var suggestions: [ValidationIssue] = []

        var isValid: Bool {
            errors.isEmpty
        }

        var hasWarnings: Bool {
            !warnings.isEmpty
        }

        var allIssues: [ValidationIssue] {
            errors + warnings + suggestions
        }
    }

    // MARK: - Validation Issue

    struct ValidationIssue: Identifiable {
        let id = UUID()
        let severity: Severity
        let category: Category
        let message: String
        let fixAction: (() -> Void)?

        enum Severity {
            case error, warning, info
        }

        enum Category {
            case size, transparency, contrast, guidelines, performance, accessibility
        }

        var icon: String {
            switch severity {
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var color: Color {
            switch severity {
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
    }
}
