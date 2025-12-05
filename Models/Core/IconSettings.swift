import SwiftUI

/// Encapsulates all icon generation settings
/// Codable for persistence and sharing
struct IconSettings: Codable, Equatable {
    // MARK: - Basic Settings
    var scale: Double = 1.0
    var padding: Double = 10.0
    var backgroundColor: ColorComponents = ColorComponents(.white)
    var autoCropToSquare: Bool = true

    // MARK: - Effects
    var effects: ImageEffects = ImageEffects()

    // MARK: - Defaults
    static let `default` = IconSettings()

    // MARK: - Validation
    var isValid: Bool {
        scale >= 0.5 && scale <= 2.0 &&
        padding >= 0 && padding <= 30
    }
}

/// Image effects configuration
struct ImageEffects: Codable, Equatable {
    // Corner radius
    var cornerRadiusEnabled: Bool = false
    var cornerRadius: Double = 0 // 0-50%

    // Shadow
    var shadowEnabled: Bool = false
    var shadowBlur: Double = 10
    var shadowOffsetX: Double = 0
    var shadowOffsetY: Double = 4
    var shadowColor: ColorComponents = ColorComponents(.black.opacity(0.5))

    // Border
    var borderEnabled: Bool = false
    var borderWidth: Double = 2
    var borderColor: ColorComponents = ColorComponents(.black)

    // Background type
    var backgroundType: BackgroundType = .solid

    enum BackgroundType: Codable, Equatable {
        case solid
        case gradient(GradientComponents, GradientDirection)
        case transparent
    }

    enum GradientDirection: String, Codable {
        case vertical, horizontal, diagonal, radial
    }

    // Image adjustments
    var brightness: Double = 0 // -1 to 1
    var contrast: Double = 0 // -1 to 1
    var saturation: Double = 0 // -1 to 1
}

/// Codable wrapper for Color
struct ColorComponents: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(_ color: Color) {
        // Convert SwiftUI Color to components
        #if canImport(AppKit)
        let nsColor = NSColor(color)
        if let ciColor = CIColor(color: nsColor) {
            self.red = Double(ciColor.red)
            self.green = Double(ciColor.green)
            self.blue = Double(ciColor.blue)
            self.alpha = Double(ciColor.alpha)
        } else {
            // Fallback
            self.red = 1
            self.green = 1
            self.blue = 1
            self.alpha = 1
        }
        #else
        // Fallback for non-AppKit platforms
        self.red = 1
        self.green = 1
        self.blue = 1
        self.alpha = 1
        #endif
    }

    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    var nsColor: NSColor {
        NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

/// Codable wrapper for Gradient
struct GradientComponents: Codable, Equatable {
    var stops: [GradientStop]

    struct GradientStop: Codable, Equatable {
        var color: ColorComponents
        var location: Double
    }

    init(_ gradient: Gradient) {
        self.stops = gradient.stops.map { stop in
            GradientStop(
                color: ColorComponents(stop.color),
                location: stop.location
            )
        }
    }

    init(stops: [GradientStop]) {
        self.stops = stops
    }

    var gradient: Gradient {
        Gradient(stops: stops.map { stop in
            Gradient.Stop(color: stop.color.color, location: stop.location)
        })
    }

    // Common gradients
    static var sunset: GradientComponents {
        GradientComponents(stops: [
            GradientStop(color: ColorComponents(.orange), location: 0.0),
            GradientStop(color: ColorComponents(.pink), location: 1.0)
        ])
    }

    static var ocean: GradientComponents {
        GradientComponents(stops: [
            GradientStop(color: ColorComponents(.blue), location: 0.0),
            GradientStop(color: ColorComponents(.cyan), location: 1.0)
        ])
    }

    static var forest: GradientComponents {
        GradientComponents(stops: [
            GradientStop(color: ColorComponents(.green), location: 0.0),
            GradientStop(color: ColorComponents(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0), location: 1.0)
        ])
    }
}
