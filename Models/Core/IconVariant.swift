import Foundation
import AppKit
import SwiftUI

/// Represents a variant of an icon with modifications
struct IconVariant: Identifiable, Codable {
    let id: UUID
    var name: String
    var baseName: String // Name of source image
    var modifications: [Modification]
    var platforms: Set<Platform>
    var createdDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        baseName: String,
        modifications: [Modification] = [],
        platforms: Set<Platform> = [.iOS]
    ) {
        self.id = id
        self.name = name
        self.baseName = baseName
        self.modifications = modifications
        self.platforms = platforms
        self.createdDate = Date()
    }

    // MARK: - Modifications

    enum Modification: Codable, Equatable {
        case badge(BadgeType, position: BadgePosition)
        case overlay(overlayName: String, position: OverlayPosition, alpha: Double)
        case tint(ColorComponents, intensity: Double)
        case seasonal(SeasonalTheme)
        case betaBadge(text: String)
        case versionBadge(version: String)
    }

    enum BadgeType: Codable, Equatable {
        case beta
        case debug
        case dev
        case alpha
        case rc
        case number(Int)
    }

    enum BadgePosition: String, Codable {
        case topLeft, topRight, bottomLeft, bottomRight, center
    }

    enum OverlayPosition: Codable, Equatable {
        case topLeft, topRight, bottomLeft, bottomRight, center
        case custom(x: Double, y: Double)
    }

    enum SeasonalTheme: String, Codable, CaseIterable {
        case halloween = "Halloween"
        case christmas = "Christmas"
        case newYear = "New Year"
        case spring = "Spring"
        case summer = "Summer"
        case fall = "Fall"
        case winter = "Winter"

        var emoji: String {
            switch self {
            case .halloween: return "🎃"
            case .christmas: return "🎄"
            case .newYear: return "🎉"
            case .spring: return "🌸"
            case .summer: return "☀️"
            case .fall: return "🍂"
            case .winter: return "❄️"
            }
        }

        var tintColor: NSColor {
            switch self {
            case .halloween: return NSColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
            case .christmas: return NSColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
            case .newYear: return NSColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
            case .spring: return NSColor(red: 1.0, green: 0.7, blue: 0.8, alpha: 1.0)
            case .summer: return NSColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
            case .fall: return NSColor(red: 0.8, green: 0.4, blue: 0.1, alpha: 1.0)
            case .winter: return NSColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 1.0)
            }
        }
    }
}

/// Generates icon variants by applying modifications
class VariantGenerator {

    // MARK: - Variant Generation

    func generateVariant(
        from base: NSImage,
        applying modifications: [IconVariant.Modification]
    ) -> NSImage {
        var result = base

        for modification in modifications {
            switch modification {
            case .badge(let type, let position):
                result = applyBadge(to: result, type: type, position: position)

            case .overlay(let overlayName, let position, let alpha):
                // Would load overlay image by name
                result = applyOverlayEffect(to: result, position: position, alpha: alpha)

            case .tint(let colorComponents, let intensity):
                result = applyTint(to: result, color: colorComponents.nsColor, intensity: intensity)

            case .seasonal(let theme):
                result = applySeasonalTheme(to: result, theme: theme)

            case .betaBadge(let text):
                result = applyTextBadge(to: result, text: text, color: .orange, position: .topRight)

            case .versionBadge(let version):
                result = applyTextBadge(to: result, text: version, color: .blue, position: .bottomRight)
            }
        }

        return result
    }

    // MARK: - Badge Application

    private func applyBadge(to image: NSImage, type: IconVariant.BadgeType, position: IconVariant.BadgePosition) -> NSImage {
        let badgeText: String
        let badgeColor: NSColor

        switch type {
        case .beta:
            badgeText = "β"
            badgeColor = .orange
        case .debug:
            badgeText = "D"
            badgeColor = .red
        case .dev:
            badgeText = "DEV"
            badgeColor = .purple
        case .alpha:
            badgeText = "α"
            badgeColor = .yellow
        case .rc:
            badgeText = "RC"
            badgeColor = .green
        case .number(let num):
            badgeText = "\(num)"
            badgeColor = .blue
        }

        return applyTextBadge(to: image, text: badgeText, color: badgeColor, position: position)
    }

    private func applyTextBadge(to image: NSImage, text: String, color: NSColor, position: IconVariant.BadgePosition) -> NSImage {
        let size = image.size
        let badged = NSImage(size: size)

        badged.lockFocus()
        defer { badged.unlockFocus() }

        // Draw original image
        image.draw(in: NSRect(origin: .zero, size: size))

        // Calculate badge size (15% of icon size)
        let badgeSize = size.width * 0.15
        let badgeRect: NSRect

        switch position {
        case .topRight:
            badgeRect = NSRect(x: size.width - badgeSize, y: size.height - badgeSize, width: badgeSize, height: badgeSize)
        case .topLeft:
            badgeRect = NSRect(x: 0, y: size.height - badgeSize, width: badgeSize, height: badgeSize)
        case .bottomRight:
            badgeRect = NSRect(x: size.width - badgeSize, y: 0, width: badgeSize, height: badgeSize)
        case .bottomLeft:
            badgeRect = NSRect(x: 0, y: 0, width: badgeSize, height: badgeSize)
        case .center:
            badgeRect = NSRect(x: (size.width - badgeSize) / 2, y: (size.height - badgeSize) / 2, width: badgeSize, height: badgeSize)
        }

        // Draw badge circle
        color.setFill()
        let badgePath = NSBezierPath(ovalIn: badgeRect)
        badgePath.fill()

        // Draw text
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: badgeSize * 0.5),
            .foregroundColor: NSColor.white
        ]

        let textSize = text.size(withAttributes: attributes)
        let textRect = NSRect(
            x: badgeRect.midX - textSize.width / 2,
            y: badgeRect.midY - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )

        text.draw(in: textRect, withAttributes: attributes)

        return badged
    }

    // MARK: - Overlay Effects

    private func applyOverlayEffect(to image: NSImage, position: IconVariant.OverlayPosition, alpha: Double) -> NSImage {
        // Simplified overlay - would load actual overlay image
        return image
    }

    // MARK: - Tint Application

    private func applyTint(to image: NSImage, color: NSColor, intensity: Double) -> NSImage {
        let size = image.size
        let tinted = NSImage(size: size)

        tinted.lockFocus()
        defer { tinted.unlockFocus() }

        // Draw original
        image.draw(in: NSRect(origin: .zero, size: size))

        // Apply tint overlay
        color.withAlphaComponent(intensity).setFill()
        NSRect(origin: .zero, size: size).fill(using: .sourceAtop)

        return tinted
    }

    // MARK: - Seasonal Themes

    private func applySeasonalTheme(to image: NSImage, theme: IconVariant.SeasonalTheme) -> NSImage {
        // Apply theme-specific tint
        let tint = theme.tintColor
        return applyTint(to: image, color: tint, intensity: 0.2)
    }
}
