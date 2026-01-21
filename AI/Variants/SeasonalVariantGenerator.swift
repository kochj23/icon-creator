import Foundation
import AppKit
import CoreImage

//
//  SeasonalVariantGenerator.swift
//  Icon Creator
//
//  Automatically generate seasonal and holiday icon variants
//  Author: Jordan Koch
//  Date: 2026-01-21
//

/// Generates seasonal and holiday-themed icon variants
/// Automatically applies seasonal styling based on calendar events
class SeasonalVariantGenerator: ObservableObject {

    // MARK: - Published Properties

    @Published var isGenerating = false
    @Published var availableSeasons: [Season] = []

    // MARK: - Initialization

    init() {
        self.availableSeasons = Season.allCases
    }

    // MARK: - Generation

    /// Generate seasonal variant
    func generateVariant(from sourceIcon: NSImage, season: Season) async throws -> NSImage {
        await MainActor.run {
            isGenerating = true
        }

        defer {
            Task { @MainActor in
                isGenerating = false
            }
        }

        guard let cgImage = sourceIcon.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw VariantError.invalidImage
        }

        var ciImage = CIImage(cgImage: cgImage)

        // Apply seasonal effects based on season type
        switch season {
        case .spring:
            ciImage = applySpringTheme(to: ciImage)
        case .summer:
            ciImage = applySummerTheme(to: ciImage)
        case .fall:
            ciImage = applyFallTheme(to: ciImage)
        case .winter:
            ciImage = applyWinterTheme(to: ciImage)
        case .christmas:
            ciImage = applyChristmasTheme(to: ciImage)
        case .halloween:
            ciImage = applyHalloweenTheme(to: ciImage)
        case .valentines:
            ciImage = applyValentinesTheme(to: ciImage)
        case .easter:
            ciImage = applyEasterTheme(to: ciImage)
        case .thanksgiving:
            ciImage = applyThanksgivingTheme(to: ciImage)
        case .newYear:
            ciImage = applyNewYearTheme(to: ciImage)
        case .stPatricks:
            ciImage = applyStPatricksTheme(to: ciImage)
        case .july4th:
            ciImage = applyJuly4thTheme(to: ciImage)
        }

        // Convert back to NSImage
        let context = CIContext()
        guard let outputCGImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw VariantError.processingFailed
        }

        return NSImage(cgImage: outputCGImage, size: sourceIcon.size)
    }

    /// Suggest seasonal variant based on current date
    func suggestSeason(for date: Date = Date()) -> Season? {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        // Check specific holidays first
        if month == 12 && day >= 20 {
            return .christmas
        } else if month == 10 && day >= 25 {
            return .halloween
        } else if month == 2 && day == 14 {
            return .valentines
        } else if month == 3 && day == 17 {
            return .stPatricks
        } else if month == 7 && day == 4 {
            return .july4th
        } else if month == 11 && day >= 20 {
            return .thanksgiving
        } else if month == 1 && day <= 7 {
            return .newYear
        }

        // Check seasons
        switch month {
        case 3, 4, 5:
            return .spring
        case 6, 7, 8:
            return .summer
        case 9, 10, 11:
            return .fall
        case 12, 1, 2:
            return .winter
        default:
            return nil
        }
    }

    // MARK: - Seasonal Themes

    private func applySpringTheme(to image: CIImage) -> CIImage {
        var output = image

        // Increase saturation and brightness
        if let colorFilter = CIFilter(name: "CIColorControls") {
            colorFilter.setValue(output, forKey: kCIInputImageKey)
            colorFilter.setValue(1.2, forKey: kCIInputSaturationKey)
            colorFilter.setValue(0.1, forKey: kCIInputBrightnessKey)
            output = colorFilter.outputImage ?? output
        }

        // Add pastel color overlay
        let pastelColor = CIColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 0.2)
        output = addColorOverlay(to: output, color: pastelColor)

        // Add soft glow
        output = addGlow(to: output, radius: 15, intensity: 0.3)

        return output
    }

    private func applySummerTheme(to image: CIImage) -> CIImage {
        var output = image

        // Increase vibrance and warmth
        if let vibranceFilter = CIFilter(name: "CIVibrance") {
            vibranceFilter.setValue(output, forKey: kCIInputImageKey)
            vibranceFilter.setValue(1.5, forKey: "inputAmount")
            output = vibranceFilter.outputImage ?? output
        }

        // Add warm color overlay
        let warmColor = CIColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 0.2)
        output = addColorOverlay(to: output, color: warmColor)

        // Add sunlight effect
        output = addGlow(to: output, radius: 20, intensity: 0.5)

        return output
    }

    private func applyFallTheme(to image: CIImage) -> CIImage {
        var output = image

        // Add autumn colors
        if let temperatureFilter = CIFilter(name: "CITemperatureAndTint") {
            temperatureFilter.setValue(output, forKey: kCIInputImageKey)
            temperatureFilter.setValue(CIVector(x: 8000, y: 0), forKey: "inputNeutral")
            temperatureFilter.setValue(CIVector(x: 6500, y: 0), forKey: "inputTargetNeutral")
            output = temperatureFilter.outputImage ?? output
        }

        // Add orange/brown tint
        let fallColor = CIColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 0.25)
        output = addColorOverlay(to: output, color: fallColor)

        // Reduce saturation slightly
        if let colorFilter = CIFilter(name: "CIColorControls") {
            colorFilter.setValue(output, forKey: kCIInputImageKey)
            colorFilter.setValue(0.9, forKey: kCIInputSaturationKey)
            output = colorFilter.outputImage ?? output
        }

        return output
    }

    private func applyWinterTheme(to image: CIImage) -> CIImage {
        var output = image

        // Add cool blue tint
        let winterColor = CIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.3)
        output = addColorOverlay(to: output, color: winterColor)

        // Reduce saturation
        if let colorFilter = CIFilter(name: "CIColorControls") {
            colorFilter.setValue(output, forKey: kCIInputImageKey)
            colorFilter.setValue(0.7, forKey: kCIInputSaturationKey)
            colorFilter.setValue(-0.05, forKey: kCIInputBrightnessKey)
            output = colorFilter.outputImage ?? output
        }

        // Add crystalline effect
        output = addGlow(to: output, radius: 10, intensity: 0.4)

        return output
    }

    private func applyChristmasTheme(to image: CIImage) -> CIImage {
        var output = image

        // Add red and green color shifts
        let christmasColor = CIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 0.2)
        output = addColorOverlay(to: output, color: christmasColor)

        // Add sparkle effect
        output = addGlow(to: output, radius: 25, intensity: 0.6)

        // Increase saturation for festive look
        if let colorFilter = CIFilter(name: "CIColorControls") {
            colorFilter.setValue(output, forKey: kCIInputImageKey)
            colorFilter.setValue(1.3, forKey: kCIInputSaturationKey)
            output = colorFilter.outputImage ?? output
        }

        return output
    }

    private func applyHalloweenTheme(to image: CIImage) -> CIImage {
        var output = image

        // Add orange and purple tones
        let halloweenColor = CIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.25)
        output = addColorOverlay(to: output, color: halloweenColor)

        // Increase contrast for dramatic effect
        if let colorFilter = CIFilter(name: "CIColorControls") {
            colorFilter.setValue(output, forKey: kCIInputImageKey)
            colorFilter.setValue(1.2, forKey: kCIInputContrastKey)
            output = colorFilter.outputImage ?? output
        }

        // Add eerie glow
        output = addGlow(to: output, radius: 30, intensity: 0.5)

        return output
    }

    private func applyValentinesTheme(to image: CIImage) -> CIImage {
        var output = image

        // Add pink/red romantic tint
        let valentineColor = CIColor(red: 1.0, green: 0.7, blue: 0.8, alpha: 0.3)
        output = addColorOverlay(to: output, color: valentineColor)

        // Add soft romantic glow
        output = addGlow(to: output, radius: 20, intensity: 0.4)

        // Increase saturation for vibrant look
        if let colorFilter = CIFilter(name: "CIColorControls") {
            colorFilter.setValue(output, forKey: kCIInputImageKey)
            colorFilter.setValue(1.2, forKey: kCIInputSaturationKey)
            output = colorFilter.outputImage ?? output
        }

        return output
    }

    private func applyEasterTheme(to image: CIImage) -> CIImage {
        var output = image

        // Add pastel colors
        let easterColor = CIColor(red: 0.95, green: 0.9, blue: 1.0, alpha: 0.2)
        output = addColorOverlay(to: output, color: easterColor)

        // Lighten and soften
        if let colorFilter = CIFilter(name: "CIColorControls") {
            colorFilter.setValue(output, forKey: kCIInputImageKey)
            colorFilter.setValue(0.15, forKey: kCIInputBrightnessKey)
            colorFilter.setValue(0.9, forKey: kCIInputContrastKey)
            output = colorFilter.outputImage ?? output
        }

        return output
    }

    private func applyThanksgivingTheme(to image: CIImage) -> CIImage {
        // Similar to fall but with warmer tones
        var output = applyFallTheme(to: image)

        // Add extra warmth
        let thanksgivingColor = CIColor(red: 0.95, green: 0.7, blue: 0.4, alpha: 0.2)
        output = addColorOverlay(to: output, color: thanksgivingColor)

        return output
    }

    private func applyNewYearTheme(to image: CIImage) -> CIImage {
        var output = image

        // Add gold/silver sparkle
        let newYearColor = CIColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 0.3)
        output = addColorOverlay(to: output, color: newYearColor)

        // Add celebratory glow
        output = addGlow(to: output, radius: 30, intensity: 0.7)

        // Increase brightness and contrast
        if let colorFilter = CIFilter(name: "CIColorControls") {
            colorFilter.setValue(output, forKey: kCIInputImageKey)
            colorFilter.setValue(0.2, forKey: kCIInputBrightnessKey)
            colorFilter.setValue(1.1, forKey: kCIInputContrastKey)
            output = colorFilter.outputImage ?? output
        }

        return output
    }

    private func applyStPatricksTheme(to image: CIImage) -> CIImage {
        var output = image

        // Add green tint
        let stPatricksColor = CIColor(red: 0.3, green: 0.9, blue: 0.3, alpha: 0.3)
        output = addColorOverlay(to: output, color: stPatricksColor)

        // Increase saturation for vibrant green
        if let colorFilter = CIFilter(name: "CIColorControls") {
            colorFilter.setValue(output, forKey: kCIInputImageKey)
            colorFilter.setValue(1.3, forKey: kCIInputSaturationKey)
            output = colorFilter.outputImage ?? output
        }

        return output
    }

    private func applyJuly4thTheme(to image: CIImage) -> CIImage {
        var output = image

        // Add patriotic red/white/blue
        let july4thColor = CIColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 0.2)
        output = addColorOverlay(to: output, color: july4thColor)

        // Add fireworks-like glow
        output = addGlow(to: output, radius: 25, intensity: 0.6)

        // Increase contrast and saturation
        if let colorFilter = CIFilter(name: "CIColorControls") {
            colorFilter.setValue(output, forKey: kCIInputImageKey)
            colorFilter.setValue(1.2, forKey: kCIInputSaturationKey)
            colorFilter.setValue(1.1, forKey: kCIInputContrastKey)
            output = colorFilter.outputImage ?? output
        }

        return output
    }

    // MARK: - Helper Effects

    private func addColorOverlay(to image: CIImage, color: CIColor) -> CIImage {
        guard let overlayFilter = CIFilter(name: "CIConstantColorGenerator") else { return image }
        overlayFilter.setValue(color, forKey: kCIInputColorKey)

        guard let colorImage = overlayFilter.outputImage?.cropped(to: image.extent) else { return image }

        guard let blendFilter = CIFilter(name: "CISourceAtopCompositing") else { return image }
        blendFilter.setValue(colorImage, forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)

        return blendFilter.outputImage ?? image
    }

    private func addGlow(to image: CIImage, radius: Double, intensity: Double) -> CIImage {
        guard let glowFilter = CIFilter(name: "CIBloom") else { return image }

        glowFilter.setValue(image, forKey: kCIInputImageKey)
        glowFilter.setValue(intensity, forKey: kCIInputIntensityKey)
        glowFilter.setValue(radius, forKey: kCIInputRadiusKey)

        return glowFilter.outputImage ?? image
    }
}

// MARK: - Season Enum

enum Season: String, CaseIterable, Identifiable {
    case spring = "Spring"
    case summer = "Summer"
    case fall = "Fall"
    case winter = "Winter"
    case christmas = "Christmas"
    case halloween = "Halloween"
    case valentines = "Valentine's Day"
    case easter = "Easter"
    case thanksgiving = "Thanksgiving"
    case newYear = "New Year"
    case stPatricks = "St. Patrick's Day"
    case july4th = "July 4th"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .spring: return "🌸"
        case .summer: return "☀️"
        case .fall: return "🍂"
        case .winter: return "❄️"
        case .christmas: return "🎄"
        case .halloween: return "🎃"
        case .valentines: return "💝"
        case .easter: return "🐰"
        case .thanksgiving: return "🦃"
        case .newYear: return "🎉"
        case .stPatricks: return "☘️"
        case .july4th: return "🎆"
        }
    }
}

enum VariantError: LocalizedError {
    case invalidImage
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid source image"
        case .processingFailed:
            return "Failed to process seasonal variant"
        }
    }
}
