import Foundation
import AppKit

// MARK: - Launch Screen Generator

class LaunchScreenGenerator {

    enum LaunchScreenStyle {
        case iconOnly
        case iconWithName(String)
        case minimal
        case fullBranding(appName: String, tagline: String)
    }

    func generate(
        from icon: NSImage,
        style: LaunchScreenStyle,
        backgroundColor: NSColor = .white,
        size: CGSize = CGSize(width: 1170, height: 2532) // iPhone 14 Pro Max
    ) -> NSImage {
        let launchScreen = NSImage(size: size)

        launchScreen.lockFocus()
        defer { launchScreen.unlockFocus() }

        // Draw background
        backgroundColor.setFill()
        NSRect(origin: .zero, size: size).fill()

        // Draw content based on style
        switch style {
        case .iconOnly:
            let iconSize: CGFloat = min(size.width, size.height) * 0.3
            let iconRect = NSRect(
                x: (size.width - iconSize) / 2,
                y: (size.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
            icon.draw(in: iconRect)

        case .iconWithName(let name):
            let iconSize: CGFloat = min(size.width, size.height) * 0.25
            let iconRect = NSRect(
                x: (size.width - iconSize) / 2,
                y: size.height * 0.5,
                width: iconSize,
                height: iconSize
            )
            icon.draw(in: iconRect)

            // Draw app name
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: size.width * 0.06, weight: .medium),
                .foregroundColor: NSColor.label
            ]
            let textSize = name.size(withAttributes: attributes)
            let textRect = NSRect(
                x: (size.width - textSize.width) / 2,
                y: iconRect.minY - textSize.height - 20,
                width: textSize.width,
                height: textSize.height
            )
            name.draw(in: textRect, withAttributes: attributes)

        case .minimal:
            let iconSize: CGFloat = min(size.width, size.height) * 0.2
            let iconRect = NSRect(
                x: (size.width - iconSize) / 2,
                y: size.height * 0.45,
                width: iconSize,
                height: iconSize
            )
            icon.draw(in: iconRect)

        case .fullBranding(let appName, let tagline):
            let iconSize: CGFloat = min(size.width, size.height) * 0.25
            let iconRect = NSRect(
                x: (size.width - iconSize) / 2,
                y: size.height * 0.55,
                width: iconSize,
                height: iconSize
            )
            icon.draw(in: iconRect)

            // App name
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: size.width * 0.08, weight: .bold),
                .foregroundColor: NSColor.label
            ]
            let nameSize = appName.size(withAttributes: nameAttributes)
            let nameRect = NSRect(
                x: (size.width - nameSize.width) / 2,
                y: iconRect.minY - nameSize.height - 30,
                width: nameSize.width,
                height: nameSize.height
            )
            appName.draw(in: nameRect, withAttributes: nameAttributes)

            // Tagline
            let taglineAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: size.width * 0.04, weight: .regular),
                .foregroundColor: NSColor.secondaryLabel
            ]
            let taglineSize = tagline.size(withAttributes: taglineAttributes)
            let taglineRect = NSRect(
                x: (size.width - taglineSize.width) / 2,
                y: nameRect.minY - taglineSize.height - 15,
                width: taglineSize.width,
                height: taglineSize.height
            )
            tagline.draw(in: taglineRect, withAttributes: taglineAttributes)
        }

        launchScreen.unlockFocus()
        return launchScreen
    }
}

// MARK: - Complication Generator

class ComplicationGenerator {

    enum ComplicationType {
        case circular
        case modular
        case utilitarian
        case graphicCorner
        case graphicCircular
        case graphicBezel
        case graphicRectangular

        var recommendedSize: Int {
            switch self {
            case .circular: return 84
            case .modular: return 102
            case .utilitarian: return 84
            case .graphicCorner: return 84
            case .graphicCircular: return 84
            case .graphicBezel: return 84
            case .graphicRectangular: return 126
            }
        }
    }

    func generate(from icon: NSImage, type: ComplicationType) -> NSImage {
        let size = type.recommendedSize

        // Simplify icon for complication
        let simplified = simplifyForSmallSize(icon, targetSize: size)

        // Apply complication-specific styling
        let styled: NSImage
        switch type {
        case .circular, .graphicCircular:
            styled = applyCircularMask(simplified)
        case .graphicCorner:
            styled = applyCornerStyle(simplified)
        case .graphicBezel:
            styled = applyBezelStyle(simplified)
        case .graphicRectangular:
            styled = applyRectangularStyle(simplified)
        default:
            styled = simplified
        }

        return styled
    }

    private func simplifyForSmallSize(_ image: NSImage, targetSize: Int) -> NSImage {
        // Increase contrast and saturation for small displays
        guard let ciImage = CIImage(data: image.tiffRepresentation!) else { return image }

        var result = ciImage

        // Increase contrast
        let contrast = CIFilter.colorControls()
        contrast.inputImage = result
        contrast.contrast = 1.2
        result = contrast.outputImage ?? result

        // Increase saturation
        let saturation = CIFilter.colorControls()
        saturation.inputImage = result
        saturation.saturation = 1.15
        result = saturation.outputImage ?? result

        // Sharpen
        let sharpen = CIFilter.sharpenLuminance()
        sharpen.inputImage = result
        sharpen.sharpness = 0.7
        result = sharpen.outputImage ?? result

        let rep = NSCIImageRep(ciImage: result)
        let final = NSImage(size: NSSize(width: targetSize, height: targetSize))
        final.addRepresentation(rep)
        return final
    }

    private func applyCircularMask(_ image: NSImage) -> NSImage {
        let masked = NSImage(size: image.size)
        masked.lockFocus()
        defer { masked.unlockFocus() }

        let path = NSBezierPath(ovalIn: NSRect(origin: .zero, size: image.size))
        path.addClip()
        image.draw(in: NSRect(origin: .zero, size: image.size))

        return masked
    }

    private func applyCornerStyle(_ image: NSImage) -> NSImage {
        // watchOS corner complications have specific shape requirements
        return image
    }

    private func applyBezelStyle(_ image: NSImage) -> NSImage {
        // watchOS bezel complications
        return image
    }

    private func applyRectangularStyle(_ image: NSImage) -> NSImage {
        // watchOS rectangular complications
        return image
    }
}

// MARK: - Widget Icon Generator

class WidgetIconGenerator {

    enum WidgetSize {
        case small // 2x2
        case medium // 4x2
        case large // 4x4

        var dimensions: (width: Int, height: Int) {
            switch self {
            case .small: return (158, 158)
            case .medium: return (338, 158)
            case .large: return (338, 354)
            }
        }
    }

    func generate(from icon: NSImage, size: WidgetSize, style: WidgetStyle = .minimal) -> NSImage {
        let dims = size.dimensions
        let widgetImage = NSImage(size: NSSize(width: dims.width, height: dims.height))

        widgetImage.lockFocus()
        defer { widgetImage.unlockFocus() }

        // Draw background
        NSColor.systemGray.withAlphaComponent(0.1).setFill()
        NSRect(origin: .zero, size: widgetImage.size).fill()

        // Draw icon based on style
        switch style {
        case .minimal:
            let iconSize: CGFloat = 60
            let iconRect = NSRect(x: 20, y: CGFloat(dims.height) - iconSize - 20, width: iconSize, height: iconSize)
            icon.draw(in: iconRect)

        case .centered:
            let iconSize = min(CGFloat(dims.width), CGFloat(dims.height)) * 0.4
            let iconRect = NSRect(
                x: (CGFloat(dims.width) - iconSize) / 2,
                y: (CGFloat(dims.height) - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
            icon.draw(in: iconRect)

        case .header:
            let iconSize: CGFloat = 40
            let iconRect = NSRect(x: 16, y: CGFloat(dims.height) - iconSize - 16, width: iconSize, height: iconSize)
            icon.draw(in: iconRect)
        }

        return widgetImage
    }

    enum WidgetStyle {
        case minimal, centered, header
    }
}

// MARK: - Social Media Exporter

class SocialMediaExporter {

    enum SocialPlatform {
        case twitter
        case facebook
        case linkedin
        case instagram
        case appStore

        var dimensions: CGSize {
            switch self {
            case .twitter: return CGSize(width: 400, height: 400)
            case .facebook: return CGSize(width: 1200, height: 630)
            case .linkedin: return CGSize(width: 1200, height: 627)
            case .instagram: return CGSize(width: 1080, height: 1080)
            case .appStore: return CGSize(width: 1024, height: 1024)
            }
        }
    }

    func export(icon: NSImage, for platform: SocialPlatform, backgroundColor: NSColor = .white) -> NSImage {
        let size = platform.dimensions
        let social = NSImage(size: size)

        social.lockFocus()
        defer { social.unlockFocus() }

        // Draw background
        backgroundColor.setFill()
        NSRect(origin: .zero, size: size).fill()

        // Calculate icon size (varies by platform)
        let iconSize: CGSize
        switch platform {
        case .twitter, .instagram, .appStore:
            iconSize = CGSize(width: size.width * 0.8, height: size.height * 0.8)
        case .facebook, .linkedin:
            iconSize = CGSize(width: size.height * 0.8, height: size.height * 0.8) // Square icon on wide canvas
        }

        let iconRect = NSRect(
            x: (size.width - iconSize.width) / 2,
            y: (size.height - iconSize.height) / 2,
            width: iconSize.width,
            height: iconSize.height
        )

        icon.draw(in: iconRect)

        return social
    }
}
