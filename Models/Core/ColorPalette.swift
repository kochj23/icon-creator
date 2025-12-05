import Foundation
import AppKit
import SwiftUI

/// A collection of harmonious colors for an icon
struct ColorPalette: Identifiable, Codable {
    let id: UUID
    var name: String
    var primary: ColorComponents
    var secondary: ColorComponents
    var accent: ColorComponents
    var background: ColorComponents
    var isDark: Bool

    init(
        id: UUID = UUID(),
        name: String,
        primary: NSColor,
        secondary: NSColor,
        accent: NSColor,
        background: NSColor,
        isDark: Bool
    ) {
        self.id = id
        self.name = name
        self.primary = ColorComponents(Color(nsColor: primary))
        self.secondary = ColorComponents(Color(nsColor: secondary))
        self.accent = ColorComponents(Color(nsColor: accent))
        self.background = ColorComponents(Color(nsColor: background))
        self.isDark = isDark
    }

    // MARK: - Preset Palettes

    static var iOSBlue: ColorPalette {
        ColorPalette(
            name: "iOS Blue",
            primary: .systemBlue,
            secondary: NSColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0),
            accent: NSColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0),
            background: .white,
            isDark: false
        )
    }

    static var sunset: ColorPalette {
        ColorPalette(
            name: "Sunset",
            primary: NSColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0),
            secondary: NSColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0),
            accent: NSColor(red: 0.9, green: 0.3, blue: 0.5, alpha: 1.0),
            background: NSColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1.0),
            isDark: false
        )
    }

    static var forest: ColorPalette {
        ColorPalette(
            name: "Forest",
            primary: NSColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1.0),
            secondary: NSColor(red: 0.3, green: 0.7, blue: 0.4, alpha: 1.0),
            accent: NSColor(red: 0.6, green: 0.8, blue: 0.3, alpha: 1.0),
            background: NSColor(red: 0.95, green: 0.98, blue: 0.95, alpha: 1.0),
            isDark: false
        )
    }

    static var ocean: ColorPalette {
        ColorPalette(
            name: "Ocean",
            primary: NSColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0),
            secondary: NSColor(red: 0.1, green: 0.7, blue: 0.9, alpha: 1.0),
            accent: NSColor(red: 0.0, green: 0.9, blue: 0.9, alpha: 1.0),
            background: NSColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0),
            isDark: false
        )
    }

    static var midnight: ColorPalette {
        ColorPalette(
            name: "Midnight",
            primary: NSColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 1.0),
            secondary: NSColor(red: 0.4, green: 0.4, blue: 0.6, alpha: 1.0),
            accent: NSColor(red: 0.6, green: 0.5, blue: 0.8, alpha: 1.0),
            background: NSColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0),
            isDark: true
        )
    }

    static var presets: [ColorPalette] {
        [iOSBlue, sunset, forest, ocean, midnight]
    }
}

/// Generates color harmonies based on color theory
class ColorHarmonyGenerator {

    // MARK: - Harmony Generation

    /// Generates complementary color (opposite on color wheel)
    func generateComplementary(for color: NSColor) -> NSColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // Complementary is 180° opposite
        let complementaryHue = fmod(hue + 0.5, 1.0)

        return NSColor(hue: complementaryHue, saturation: saturation, brightness: brightness, alpha: alpha)
    }

    /// Generates triadic color harmony (3 colors equally spaced on wheel)
    func generateTriadic(for color: NSColor) -> [NSColor] {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // Triadic colors are 120° apart
        let hue2 = fmod(hue + 1.0/3.0, 1.0)
        let hue3 = fmod(hue + 2.0/3.0, 1.0)

        return [
            color,
            NSColor(hue: hue2, saturation: saturation, brightness: brightness, alpha: alpha),
            NSColor(hue: hue3, saturation: saturation, brightness: brightness, alpha: alpha)
        ]
    }

    /// Generates analogous colors (adjacent on color wheel)
    func generateAnalogous(for color: NSColor, count: Int = 3) -> [NSColor] {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        var colors: [NSColor] = []
        let step = 30.0 / 360.0 // 30° steps

        for i in 0..<count {
            let offset = Double(i - count/2) * step
            let newHue = fmod(hue + offset + 1.0, 1.0)
            colors.append(NSColor(hue: newHue, saturation: saturation, brightness: brightness, alpha: alpha))
        }

        return colors
    }

    /// Generates monochromatic color scheme (same hue, different brightness/saturation)
    func generateMonochromatic(for color: NSColor, steps: Int = 5) -> [NSColor] {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        var colors: [NSColor] = []

        for i in 0..<steps {
            let factor = CGFloat(i) / CGFloat(steps - 1)
            let newBrightness = 0.2 + (brightness * 0.8 * factor)
            let newSaturation = saturation * (0.5 + factor * 0.5)

            colors.append(NSColor(hue: hue, saturation: newSaturation, brightness: newBrightness, alpha: alpha))
        }

        return colors
    }

    /// Generates split-complementary harmony
    func generateSplitComplementary(for color: NSColor) -> [NSColor] {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // Split-complementary: 150° and 210° from base
        let hue2 = fmod(hue + 150.0/360.0, 1.0)
        let hue3 = fmod(hue + 210.0/360.0, 1.0)

        return [
            color,
            NSColor(hue: hue2, saturation: saturation, brightness: brightness, alpha: alpha),
            NSColor(hue: hue3, saturation: saturation, brightness: brightness, alpha: alpha)
        ]
    }

    /// Generates tetradic (rectangle) harmony
    func generateTetradic(for color: NSColor) -> [NSColor] {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // Tetradic: 60°, 180°, 240° from base
        let hues = [0.0, 60.0/360.0, 180.0/360.0, 240.0/360.0].map { offset in
            fmod(hue + offset, 1.0)
        }

        return hues.map { h in
            NSColor(hue: h, saturation: saturation, brightness: brightness, alpha: alpha)
        }
    }
}
