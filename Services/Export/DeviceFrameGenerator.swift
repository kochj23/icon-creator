import Foundation
import AppKit
import SwiftUI

// MARK: - Device Frame Generator

/// Generates App Store preview screenshots with device frames
/// Supports iPhone, iPad, Apple Watch, Mac, and Apple TV device frames
class DeviceFrameGenerator {

    // MARK: - Device Frame Configuration

    struct DeviceFrame {
        let device: DeviceType
        let frameColor: FrameColor
        let screenSize: NSSize
        let frameSize: NSSize
        let screenInset: NSEdgeInsets
        let cornerRadius: CGFloat
    }

    // MARK: - Device Types

    enum DeviceType: String, CaseIterable {
        case iPhone16ProMax = "iPhone 16 Pro Max"
        case iPhone15Plus = "iPhone 15 Plus"
        case iPhone14ProMax = "iPhone 14 Pro Max"
        case iPhone13ProMax = "iPhone 13 Pro Max"
        case iPhone8Plus = "iPhone 8 Plus"
        case iPadPro13 = "iPad Pro 13\""
        case iPadPro129 = "iPad Pro 12.9\""
        case iPadPro11 = "iPad Pro 11\""
        case macBookPro16 = "MacBook Pro 16\""
        case macBookPro14 = "MacBook Pro 14\""
        case appleTV4K = "Apple TV 4K"
        case appleWatchUltra = "Apple Watch Ultra"
        case appleWatch45mm = "Apple Watch 45mm"

        var platform: ScreenshotPlatform {
            switch self {
            case .iPhone16ProMax, .iPhone15Plus, .iPhone14ProMax, .iPhone13ProMax, .iPhone8Plus:
                return .iPhone
            case .iPadPro13, .iPadPro129, .iPadPro11:
                return .iPad
            case .macBookPro16, .macBookPro14:
                return .mac
            case .appleTV4K:
                return .appleTV
            case .appleWatchUltra, .appleWatch45mm:
                return .appleWatch
            }
        }

        var iconName: String {
            switch self {
            case .iPhone16ProMax, .iPhone15Plus, .iPhone14ProMax, .iPhone13ProMax, .iPhone8Plus:
                return "iphone"
            case .iPadPro13, .iPadPro129, .iPadPro11:
                return "ipad"
            case .macBookPro16, .macBookPro14:
                return "laptopcomputer"
            case .appleTV4K:
                return "appletv"
            case .appleWatchUltra, .appleWatch45mm:
                return "applewatch"
            }
        }
    }

    // MARK: - Frame Colors

    enum FrameColor: String, CaseIterable {
        case black = "Black"
        case white = "White"
        case silver = "Silver"
        case gold = "Gold"
        case spaceGray = "Space Gray"
        case midnightGreen = "Midnight Green"
        case pacificBlue = "Pacific Blue"
        case graphite = "Graphite"
        case sierraBlue = "Sierra Blue"
        case productRed = "Product Red"

        var color: NSColor {
            switch self {
            case .black:
                return NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
            case .white:
                return NSColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
            case .silver:
                return NSColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
            case .gold:
                return NSColor(red: 0.98, green: 0.87, blue: 0.71, alpha: 1.0)
            case .spaceGray:
                return NSColor(red: 0.35, green: 0.35, blue: 0.38, alpha: 1.0)
            case .midnightGreen:
                return NSColor(red: 0.26, green: 0.35, blue: 0.36, alpha: 1.0)
            case .pacificBlue:
                return NSColor(red: 0.29, green: 0.44, blue: 0.57, alpha: 1.0)
            case .graphite:
                return NSColor(red: 0.33, green: 0.34, blue: 0.36, alpha: 1.0)
            case .sierraBlue:
                return NSColor(red: 0.67, green: 0.78, blue: 0.92, alpha: 1.0)
            case .productRed:
                return NSColor(red: 0.72, green: 0.0, blue: 0.08, alpha: 1.0)
            }
        }
    }

    // MARK: - Background Style

    enum BackgroundStyle {
        case solid(NSColor)
        case gradient(start: NSColor, end: NSColor, angle: CGFloat)
        case transparent

        var displayName: String {
            switch self {
            case .solid: return "Solid Color"
            case .gradient: return "Gradient"
            case .transparent: return "Transparent"
            }
        }
    }

    // MARK: - Public Methods

    /// Generates a device frame around a screenshot
    /// - Parameters:
    ///   - screenshot: The screenshot image to frame
    ///   - deviceType: Type of device frame to generate
    ///   - frameColor: Color of the device frame
    ///   - background: Background style
    ///   - shadowEnabled: Whether to add drop shadow
    /// - Returns: Composed image with device frame, or nil if generation fails
    func generateFrame(
        for screenshot: NSImage,
        deviceType: DeviceType,
        frameColor: FrameColor,
        background: BackgroundStyle = .solid(NSColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)),
        shadowEnabled: Bool = true
    ) -> NSImage? {
        // Get device frame configuration
        let frame = getDeviceFrame(for: deviceType, color: frameColor)

        // Calculate output size (frame + padding for shadow)
        let shadowPadding: CGFloat = shadowEnabled ? 100 : 20
        let outputSize = NSSize(
            width: frame.frameSize.width + shadowPadding * 2,
            height: frame.frameSize.height + shadowPadding * 2
        )

        let outputImage = NSImage(size: outputSize)

        autoreleasepool {
            outputImage.lockFocus()
            defer { outputImage.unlockFocus() }

            // Draw background
            drawBackground(background, in: NSRect(origin: .zero, size: outputSize))

            // Calculate frame position (centered with shadow padding)
            let frameRect = NSRect(
                x: shadowPadding,
                y: shadowPadding,
                width: frame.frameSize.width,
                height: frame.frameSize.height
            )

            // Draw device frame with shadow
            if shadowEnabled {
                let shadow = NSShadow()
                shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
                shadow.shadowBlurRadius = 40
                shadow.shadowOffset = NSSize(width: 0, height: -10)

                NSGraphicsContext.saveGraphicsState()
                shadow.set()
            }

            // Draw device frame background
            frameColor.color.setFill()
            let framePath = NSBezierPath(roundedRect: frameRect, xRadius: frame.cornerRadius, yRadius: frame.cornerRadius)
            framePath.fill()

            if shadowEnabled {
                NSGraphicsContext.restoreGraphicsState()
            }

            // Calculate screen position within frame
            let screenRect = NSRect(
                x: frameRect.origin.x + frame.screenInset.left,
                y: frameRect.origin.y + frame.screenInset.bottom,
                width: frame.screenSize.width,
                height: frame.screenSize.height
            )

            // Draw screenshot with clipping to screen area (with rounded corners)
            NSGraphicsContext.saveGraphicsState()

            let screenPath = NSBezierPath(
                roundedRect: screenRect,
                xRadius: frame.cornerRadius * 0.8,  // Slightly smaller radius for screen
                yRadius: frame.cornerRadius * 0.8
            )
            screenPath.addClip()

            // Scale and draw screenshot
            let sourceRect = NSRect(origin: .zero, size: screenshot.size)
            NSGraphicsContext.current?.imageInterpolation = .high
            screenshot.draw(in: screenRect, from: sourceRect, operation: .sourceOver, fraction: 1.0)

            NSGraphicsContext.restoreGraphicsState()

            // Draw device frame bezel/notch details
            drawDeviceDetails(for: deviceType, in: frameRect, screenInset: frame.screenInset, cornerRadius: frame.cornerRadius)
        }

        return outputImage
    }

    /// Generates multiple frame styles for the same screenshot
    /// - Parameters:
    ///   - screenshot: The screenshot to frame
    ///   - deviceType: Device type
    ///   - colors: Array of frame colors to generate
    ///   - background: Background style
    /// - Returns: Dictionary mapping frame color to generated image
    func generateMultipleFrames(
        for screenshot: NSImage,
        deviceType: DeviceType,
        colors: [FrameColor],
        background: BackgroundStyle = .solid(NSColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0))
    ) -> [FrameColor: NSImage] {
        var results: [FrameColor: NSImage] = [:]

        for color in colors {
            if let framed = generateFrame(for: screenshot, deviceType: deviceType, frameColor: color, background: background) {
                results[color] = framed
            }
        }

        return results
    }

    // MARK: - Private Methods

    /// Gets device frame configuration
    private func getDeviceFrame(for deviceType: DeviceType, color: FrameColor) -> DeviceFrame {
        switch deviceType {
        case .iPhone16ProMax, .iPhone15Plus:
            return DeviceFrame(
                device: deviceType,
                frameColor: color,
                screenSize: NSSize(width: 1290, height: 2796),
                frameSize: NSSize(width: 1400, height: 2950),
                screenInset: NSEdgeInsets(top: 77, left: 55, bottom: 77, right: 55),
                cornerRadius: 55
            )

        case .iPhone14ProMax, .iPhone13ProMax:
            return DeviceFrame(
                device: deviceType,
                frameColor: color,
                screenSize: NSSize(width: 1284, height: 2778),
                frameSize: NSSize(width: 1394, height: 2932),
                screenInset: NSEdgeInsets(top: 77, left: 55, bottom: 77, right: 55),
                cornerRadius: 55
            )

        case .iPhone8Plus:
            return DeviceFrame(
                device: deviceType,
                frameColor: color,
                screenSize: NSSize(width: 1242, height: 2208),
                frameSize: NSSize(width: 1352, height: 2396),
                screenInset: NSEdgeInsets(top: 94, left: 55, bottom: 94, right: 55),
                cornerRadius: 40
            )

        case .iPadPro13:
            return DeviceFrame(
                device: deviceType,
                frameColor: color,
                screenSize: NSSize(width: 2064, height: 2752),
                frameSize: NSSize(width: 2224, height: 2912),
                screenInset: NSEdgeInsets(top: 80, left: 80, bottom: 80, right: 80),
                cornerRadius: 40
            )

        case .iPadPro129:
            return DeviceFrame(
                device: deviceType,
                frameColor: color,
                screenSize: NSSize(width: 2048, height: 2732),
                frameSize: NSSize(width: 2208, height: 2892),
                screenInset: NSEdgeInsets(top: 80, left: 80, bottom: 80, right: 80),
                cornerRadius: 40
            )

        case .iPadPro11:
            return DeviceFrame(
                device: deviceType,
                frameColor: color,
                screenSize: NSSize(width: 1668, height: 2388),
                frameSize: NSSize(width: 1828, height: 2548),
                screenInset: NSEdgeInsets(top: 80, left: 80, bottom: 80, right: 80),
                cornerRadius: 35
            )

        case .macBookPro16:
            return DeviceFrame(
                device: deviceType,
                frameColor: color,
                screenSize: NSSize(width: 2880, height: 1800),
                frameSize: NSSize(width: 3100, height: 1950),
                screenInset: NSEdgeInsets(top: 75, left: 110, bottom: 75, right: 110),
                cornerRadius: 12
            )

        case .macBookPro14:
            return DeviceFrame(
                device: deviceType,
                frameColor: color,
                screenSize: NSSize(width: 2560, height: 1600),
                frameSize: NSSize(width: 2780, height: 1750),
                screenInset: NSEdgeInsets(top: 75, left: 110, bottom: 75, right: 110),
                cornerRadius: 12
            )

        case .appleTV4K:
            return DeviceFrame(
                device: deviceType,
                frameColor: color,
                screenSize: NSSize(width: 3840, height: 2160),
                frameSize: NSSize(width: 3840, height: 2160),
                screenInset: NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
                cornerRadius: 0
            )

        case .appleWatchUltra:
            return DeviceFrame(
                device: deviceType,
                frameColor: color,
                screenSize: NSSize(width: 410, height: 502),
                frameSize: NSSize(width: 510, height: 602),
                screenInset: NSEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
                cornerRadius: 60
            )

        case .appleWatch45mm:
            return DeviceFrame(
                device: deviceType,
                frameColor: color,
                screenSize: NSSize(width: 396, height: 484),
                frameSize: NSSize(width: 496, height: 584),
                screenInset: NSEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
                cornerRadius: 55
            )
        }
    }

    /// Draws background
    private func drawBackground(_ style: BackgroundStyle, in rect: NSRect) {
        switch style {
        case .solid(let color):
            color.setFill()
            rect.fill()

        case .gradient(let start, let end, let angle):
            guard let context = NSGraphicsContext.current?.cgContext else { return }

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [start.cgColor, end.cgColor] as CFArray
            let locations: [CGFloat] = [0.0, 1.0]

            guard let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: colors,
                locations: locations
            ) else { return }

            let radians = angle * .pi / 180.0
            let centerPoint = CGPoint(x: rect.midX, y: rect.midY)
            let radius = max(rect.width, rect.height) / 2

            let startPoint = CGPoint(
                x: centerPoint.x - cos(radians) * radius,
                y: centerPoint.y - sin(radians) * radius
            )
            let endPoint = CGPoint(
                x: centerPoint.x + cos(radians) * radius,
                y: centerPoint.y + sin(radians) * radius
            )

            context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])

        case .transparent:
            // No background - leave transparent
            break
        }
    }

    /// Draws device-specific details (notch, bezels, etc.)
    private func drawDeviceDetails(for deviceType: DeviceType, in frameRect: NSRect, screenInset: NSEdgeInsets, cornerRadius: CGFloat) {
        switch deviceType {
        case .iPhone16ProMax, .iPhone15Plus, .iPhone14ProMax, .iPhone13ProMax:
            // Draw notch/Dynamic Island
            let notchWidth: CGFloat = 200
            let notchHeight: CGFloat = 35
            let notchRect = NSRect(
                x: frameRect.midX - notchWidth / 2,
                y: frameRect.maxY - screenInset.top + 10,
                width: notchWidth,
                height: notchHeight
            )

            NSColor.black.setFill()
            let notchPath = NSBezierPath(roundedRect: notchRect, xRadius: 17, yRadius: 17)
            notchPath.fill()

        case .appleWatchUltra, .appleWatch45mm:
            // Draw Digital Crown indicator
            let crownSize: CGFloat = 30
            let crownRect = NSRect(
                x: frameRect.maxX - 5,
                y: frameRect.midY + 50,
                width: crownSize,
                height: crownSize
            )

            NSColor.darkGray.setFill()
            NSBezierPath(ovalIn: crownRect).fill()

        case .macBookPro16, .macBookPro14:
            // Draw notch at top
            let notchWidth: CGFloat = 200
            let notchHeight: CGFloat = 30
            let notchRect = NSRect(
                x: frameRect.midX - notchWidth / 2,
                y: frameRect.maxY - screenInset.top + 5,
                width: notchWidth,
                height: notchHeight
            )

            NSColor.black.setFill()
            let notchPath = NSBezierPath(roundedRect: notchRect, xRadius: 12, yRadius: 12)
            notchPath.fill()

        default:
            break
        }
    }

    /// Exports framed screenshot to file
    /// - Parameters:
    ///   - framedImage: The framed screenshot
    ///   - url: Destination URL
    /// - Throws: Error if export fails
    func exportFramedScreenshot(_ framedImage: NSImage, to url: URL) throws {
        guard let tiffData = framedImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            throw NSError(
                domain: "DeviceFrameGenerator",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to convert framed image to PNG"]
            )
        }

        try pngData.write(to: url)
    }
}
