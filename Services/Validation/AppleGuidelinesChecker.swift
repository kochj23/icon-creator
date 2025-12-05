import Foundation
import AppKit

/// Checks icons against Apple Human Interface Guidelines
class AppleGuidelinesChecker {

    static func check(_ image: NSImage, platform: Platform) -> [IconValidator.ValidationIssue] {
        var issues: [IconValidator.ValidationIssue] = []

        switch platform {
        case .iOS:
            issues.append(contentsOf: checkiOSGuidelines(image))
        case .macOS:
            issues.append(contentsOf: checkmacOSGuidelines(image))
        case .tvOS:
            issues.append(contentsOf: checktvOSGuidelines(image))
        case .watchOS:
            issues.append(contentsOf: checkWatchOSGuidelines(image))
        case .iMessage:
            issues.append(contentsOf: checkiMessageGuidelines(image))
        case .macCatalyst:
            issues.append(contentsOf: checkiOSGuidelines(image))
        }

        return issues
    }

    // MARK: - iOS Guidelines

    private static func checkiOSGuidelines(_ image: NSImage) -> [IconValidator.ValidationIssue] {
        var issues: [IconValidator.ValidationIssue] = []

        // iOS icons are automatically rounded by the system
        if imageHasRoundedCorners(image) {
            issues.append(IconValidator.ValidationIssue(
                severity: .info,
                category: .guidelines,
                message: "iOS automatically applies rounded corners to app icons. Manual rounding is not needed and may cause double-rounding",
                fixAction: nil
            ))
        }

        // Check for text
        if imageContainsText(image) {
            issues.append(IconValidator.ValidationIssue(
                severity: .warning,
                category: .guidelines,
                message: "Icons with text should ensure text is legible at small sizes (20×20 points)",
                fixAction: nil
            ))
        }

        return issues
    }

    // MARK: - macOS Guidelines

    private static func checkmacOSGuidelines(_ image: NSImage) -> [IconValidator.ValidationIssue] {
        var issues: [IconValidator.ValidationIssue] = []

        // macOS Big Sur style icons use perspective and shadows
        issues.append(IconValidator.ValidationIssue(
            severity: .info,
            category: .guidelines,
            message: "macOS Big Sur icons use a consistent design language with perspective and shadows. Consider using the 'Shadowed' preset",
            fixAction: nil
        ))

        return issues
    }

    // MARK: - tvOS Guidelines

    private static func checktvOSGuidelines(_ image: NSImage) -> [IconValidator.ValidationIssue] {
        var issues: [IconValidator.ValidationIssue] = []

        // tvOS icons need parallax layers (not validated here)
        issues.append(IconValidator.ValidationIssue(
            severity: .info,
            category: .guidelines,
            message: "tvOS icons support parallax effects with multiple layers. This tool generates static icons. Consider creating layered versions manually",
            fixAction: nil
        ))

        // High visibility requirement
        if !hasGoodContrast(image) {
            issues.append(IconValidator.ValidationIssue(
                severity: .warning,
                category: .guidelines,
                message: "tvOS icons should be highly visible from a distance. Ensure strong contrast and simple design",
                fixAction: nil
            ))
        }

        return issues
    }

    // MARK: - watchOS Guidelines

    private static func checkWatchOSGuidelines(_ image: NSImage) -> [IconValidator.ValidationIssue] {
        var issues: [IconValidator.ValidationIssue] = []

        // watchOS icons need high contrast for small displays
        issues.append(IconValidator.ValidationIssue(
            severity: .info,
            category: .guidelines,
            message: "watchOS icons appear very small. Use simple, bold designs with high contrast",
            fixAction: nil
        ))

        return issues
    }

    // MARK: - iMessage Guidelines

    private static func checkiMessageGuidelines(_ image: NSImage) -> [IconValidator.ValidationIssue] {
        var issues: [IconValidator.ValidationIssue] = []

        // iMessage icons should be fun and expressive
        issues.append(IconValidator.ValidationIssue(
            severity: .info,
            category: .guidelines,
            message: "iMessage app icons can be more playful and expressive than standard app icons",
            fixAction: nil
        ))

        return issues
    }

    // MARK: - Helper Methods

    private static func imageHasRoundedCorners(_ image: NSImage) -> Bool {
        // Simple heuristic: check if corners are transparent
        // This is a simplified check
        return false // Placeholder
    }

    private static func imageContainsText(_ image: NSImage) -> Bool {
        // Would require OCR or Vision framework
        // Placeholder for now
        return false
    }

    private static func hasGoodContrast(_ image: NSImage) -> Bool {
        // Simple contrast check
        return true // Placeholder
    }
}
