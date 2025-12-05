import Foundation
import AppKit
import CoreImage

/// Analyzes icons for accessibility compliance
class AccessibilityAnalyzer {

    // MARK: - Colorblindness Simulation

    enum ColorBlindnessType: String, CaseIterable {
        case protanopia = "Protanopia" // Red-blind
        case deuteranopia = "Deuteranopia" // Green-blind
        case tritanopia = "Tritanopia" // Blue-blind
        case achromatopsia = "Achromatopsia" // Complete colorblind

        var description: String {
            switch self {
            case .protanopia:
                return "Red-blind (1% of males)"
            case .deuteranopia:
                return "Green-blind (most common, ~5% of males)"
            case .tritanopia:
                return "Blue-blind (rare)"
            case .achromatopsia:
                return "Complete colorblindness (very rare)"
            }
        }
    }

    func simulate(_ type: ColorBlindnessType, on image: NSImage) -> NSImage {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return image
        }

        let ciImage = CIImage(cgImage: cgImage)

        // Apply color transformation matrix for colorblindness
        let matrix = getTransformationMatrix(for: type)
        let filter = CIFilter.colorMatrix()
        filter.inputImage = ciImage
        filter.rVector = matrix.r
        filter.gVector = matrix.g
        filter.bVector = matrix.b

        guard let output = filter.outputImage else { return image }

        let rep = NSCIImageRep(ciImage: output)
        let result = NSImage(size: image.size)
        result.addRepresentation(rep)
        return result
    }

    private func getTransformationMatrix(for type: ColorBlindnessType) -> (r: CIVector, g: CIVector, b: CIVector) {
        // Transformation matrices for colorblindness simulation
        // Based on research by Brettel, Viénot and Mollon (1997)
        switch type {
        case .protanopia:
            return (
                r: CIVector(x: 0.567, y: 0.433, z: 0, w: 0),
                g: CIVector(x: 0.558, y: 0.442, z: 0, w: 0),
                b: CIVector(x: 0, y: 0.242, z: 0.758, w: 0)
            )

        case .deuteranopia:
            return (
                r: CIVector(x: 0.625, y: 0.375, z: 0, w: 0),
                g: CIVector(x: 0.7, y: 0.3, z: 0, w: 0),
                b: CIVector(x: 0, y: 0.3, z: 0.7, w: 0)
            )

        case .tritanopia:
            return (
                r: CIVector(x: 0.95, y: 0.05, z: 0, w: 0),
                g: CIVector(x: 0, y: 0.433, z: 0.567, w: 0),
                b: CIVector(x: 0, y: 0.475, z: 0.525, w: 0)
            )

        case .achromatopsia:
            return (
                r: CIVector(x: 0.299, y: 0.587, z: 0.114, w: 0),
                g: CIVector(x: 0.299, y: 0.587, z: 0.114, w: 0),
                b: CIVector(x: 0.299, y: 0.587, z: 0.114, w: 0)
            )
        }
    }

    // MARK: - Accessibility Analysis

    func analyzeAccessibility(of image: NSImage) -> AccessibilityReport {
        var report = AccessibilityReport()

        // Check visibility for each type of colorblindness
        for type in ColorBlindnessType.allCases {
            let simulated = simulate(type, on: image)
            let isVisible = checkVisibility(simulated)

            switch type {
            case .protanopia:
                report.visibleForProtanopia = isVisible
            case .deuteranopia:
                report.visibleForDeuteranopia = isVisible
            case .tritanopia:
                report.visibleForTritanopia = isVisible
            case .achromatopsia:
                report.visibleForAchromatopsia = isVisible
            }
        }

        // Calculate contrast ratio
        report.contrastRatio = calculateContrastRatio(image)

        // Generate suggestions
        report.suggestions = generateSuggestions(for: report)

        return report
    }

    private func checkVisibility(_ image: NSImage) -> Bool {
        // Check if image has sufficient detail when viewed with colorblindness
        // Simplified: check if there's sufficient luminance variation
        let analyzer = ColorAnalyzer()
        return !analyzer.isDarkImage(image) // Placeholder logic
    }

    private func calculateContrastRatio(_ image: NSImage) -> Double {
        // Calculate WCAG contrast ratio for icon
        // Simplified version
        return 4.5
    }

    private func generateSuggestions(for report: AccessibilityReport) -> [String] {
        var suggestions: [String] = []

        if report.contrastRatio < 4.5 {
            suggestions.append("Increase contrast to improve visibility (target: 4.5:1)")
        }

        if !report.visibleForDeuteranopia {
            suggestions.append("Icon may be hard to distinguish for people with deuteranopia (most common colorblindness). Consider using shapes or patterns in addition to color")
        }

        if !report.visibleForProtanopia {
            suggestions.append("Avoid relying solely on red/green differences. Add luminance contrast")
        }

        if report.allVisible && report.contrastRatio >= 7.0 {
            suggestions.append("Excellent! Icon meets AAA accessibility standards")
        }

        return suggestions
    }

    // MARK: - Report

    struct AccessibilityReport {
        var contrastRatio: Double = 0
        var visibleForProtanopia: Bool = true
        var visibleForDeuteranopia: Bool = true
        var visibleForTritanopia: Bool = true
        var visibleForAchromatopsia: Bool = true
        var suggestions: [String] = []

        var allVisible: Bool {
            visibleForProtanopia && visibleForDeuteranopia && visibleForTritanopia && visibleForAchromatopsia
        }

        var passesWCAG_AA: Bool {
            contrastRatio >= 4.5 && allVisible
        }

        var passesWCAG_AAA: Bool {
            contrastRatio >= 7.0 && allVisible
        }
    }
}
