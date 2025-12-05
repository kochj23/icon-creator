import SwiftUI
import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Core image processing engine for applying effects to icons
class ImageProcessor {

    // MARK: - Core Operations

    /// Applies all effects from IconSettings to an image
    func processImage(_ image: NSImage, with settings: IconSettings, targetSize: Int) -> NSImage? {
        var result = image
        let effects = settings.effects

        // Apply image adjustments first
        if effects.brightness != 0 || effects.contrast != 0 || effects.saturation != 0 {
            result = applyAdjustments(to: result, effects: effects) ?? result
        }

        // Generate the icon at target size with scale and padding
        guard let sized = generateSizedIcon(from: result, targetSize: targetSize, settings: settings) else {
            return nil
        }

        result = sized

        // Apply corner radius
        if effects.cornerRadiusEnabled && effects.cornerRadius > 0 {
            result = applyRoundedCorners(to: result, radiusPercent: effects.cornerRadius)
        }

        // Apply border
        if effects.borderEnabled {
            result = applyBorder(to: result, width: effects.borderWidth, color: effects.borderColor.nsColor)
        }

        // Apply shadow
        if effects.shadowEnabled {
            result = applyDropShadow(
                to: result,
                blur: effects.shadowBlur,
                offset: CGSize(width: effects.shadowOffsetX, height: effects.shadowOffsetY),
                color: effects.shadowColor.nsColor
            )
        }

        return result
    }

    // MARK: - Sized Icon Generation

    private func generateSizedIcon(from image: NSImage, targetSize: Int, settings: IconSettings) -> NSImage? {
        let size = CGFloat(targetSize)

        // Calculate padding
        let paddingAmount = size * (settings.padding / 100.0)
        let contentSize = size - (paddingAmount * 2)

        // Calculate scaled size
        let scaledSize = contentSize * settings.scale

        guard scaledSize > 0 && scaledSize <= size else { return nil }

        // Create output image
        let outputImage = NSImage(size: NSSize(width: size, height: size))

        autoreleasepool {
            outputImage.lockFocus()
            defer { outputImage.unlockFocus() }

            // Draw background
            drawBackground(settings: settings, size: size)

            // Calculate position to center the scaled image
            let x = (size - scaledSize) / 2
            let y = (size - scaledSize) / 2

            // Draw source image with high quality
            let sourceRect = NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            let destRect = NSRect(x: x, y: y, width: scaledSize, height: scaledSize)

            NSGraphicsContext.current?.imageInterpolation = .high
            image.draw(in: destRect, from: sourceRect, operation: .sourceOver, fraction: 1.0)
        }

        return outputImage
    }

    private func drawBackground(settings: IconSettings, size: CGFloat) {
        let rect = NSRect(x: 0, y: 0, width: size, height: size)

        switch settings.effects.backgroundType {
        case .solid:
            settings.backgroundColor.nsColor.setFill()
            rect.fill()

        case .gradient(let gradientComponents, let direction):
            drawGradientBackground(
                gradient: gradientComponents.gradient,
                direction: direction,
                in: rect
            )

        case .transparent:
            // No background - leave transparent
            break
        }
    }

    private func drawGradientBackground(gradient: Gradient, direction: ImageEffects.GradientDirection, in rect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = gradient.stops.map { $0.color }.map { Color(nsColor: NSColor($0)) }
        let nsColors = colors.map { NSColor($0) }
        let cgColors = nsColors.compactMap { $0.cgColor } as CFArray
        let locations = gradient.stops.map { CGFloat($0.location) }

        guard let cgGradient = CGGradient(
            colorsSpace: colorSpace,
            colors: cgColors,
            locations: locations
        ) else { return }

        let startPoint: CGPoint
        let endPoint: CGPoint

        switch direction {
        case .vertical:
            startPoint = CGPoint(x: rect.midX, y: rect.minY)
            endPoint = CGPoint(x: rect.midX, y: rect.maxY)
        case .horizontal:
            startPoint = CGPoint(x: rect.minX, y: rect.midY)
            endPoint = CGPoint(x: rect.maxX, y: rect.midY)
        case .diagonal:
            startPoint = CGPoint(x: rect.minX, y: rect.minY)
            endPoint = CGPoint(x: rect.maxX, y: rect.maxY)
        case .radial:
            startPoint = CGPoint(x: rect.midX, y: rect.midY)
            endPoint = startPoint
        }

        if direction == .radial {
            context.drawRadialGradient(
                cgGradient,
                startCenter: startPoint,
                startRadius: 0,
                endCenter: endPoint,
                endRadius: rect.width / 2,
                options: []
            )
        } else {
            context.drawLinearGradient(cgGradient, start: startPoint, end: endPoint, options: [])
        }
    }

    // MARK: - Corner Radius

    func applyRoundedCorners(to image: NSImage, radiusPercent: Double) -> NSImage {
        let size = image.size
        let cornerRadius = min(size.width, size.height) * (radiusPercent / 100.0)

        let rounded = NSImage(size: size)
        rounded.lockFocus()
        defer { rounded.unlockFocus() }

        let rect = NSRect(origin: .zero, size: size)
        let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        path.addClip()

        image.draw(in: rect)

        return rounded
    }

    // MARK: - Drop Shadow

    func applyDropShadow(to image: NSImage, blur: Double, offset: CGSize, color: NSColor) -> NSImage {
        let size = image.size
        let shadowPadding: CGFloat = max(abs(offset.width), abs(offset.height)) + CGFloat(blur) * 2

        let expandedSize = NSSize(
            width: size.width + shadowPadding * 2,
            height: size.height + shadowPadding * 2
        )

        let result = NSImage(size: expandedSize)
        result.lockFocus()
        defer { result.unlockFocus() }

        // Configure shadow
        let shadow = NSShadow()
        shadow.shadowColor = color
        shadow.shadowBlurRadius = blur
        shadow.shadowOffset = offset

        // Draw with shadow
        NSGraphicsContext.saveGraphicsState()
        shadow.set()

        let drawRect = NSRect(
            x: shadowPadding,
            y: shadowPadding,
            width: size.width,
            height: size.height
        )
        image.draw(in: drawRect)

        NSGraphicsContext.restoreGraphicsState()

        return result
    }

    // MARK: - Border

    func applyBorder(to image: NSImage, width: Double, color: NSColor) -> NSImage {
        let size = image.size
        let bordered = NSImage(size: size)

        bordered.lockFocus()
        defer { bordered.unlockFocus() }

        let rect = NSRect(origin: .zero, size: size)

        // Draw image
        image.draw(in: rect)

        // Draw border
        color.setStroke()
        let path = NSBezierPath(rect: rect.insetBy(dx: width / 2, dy: width / 2))
        path.lineWidth = width
        path.stroke()

        return bordered
    }

    // MARK: - Image Adjustments

    func applyAdjustments(to image: NSImage, effects: ImageEffects) -> NSImage? {
        guard let ciImage = CIImage(data: image.tiffRepresentation!) else { return nil }

        var result = ciImage

        // Brightness
        if effects.brightness != 0 {
            let filter = CIFilter.colorControls()
            filter.inputImage = result
            filter.brightness = Float(effects.brightness)
            result = filter.outputImage ?? result
        }

        // Contrast
        if effects.contrast != 0 {
            let filter = CIFilter.colorControls()
            filter.inputImage = result
            filter.contrast = Float(1.0 + effects.contrast)
            result = filter.outputImage ?? result
        }

        // Saturation
        if effects.saturation != 0 {
            let filter = CIFilter.colorControls()
            filter.inputImage = result
            filter.saturation = Float(1.0 + effects.saturation)
            result = filter.outputImage ?? result
        }

        // Convert back to NSImage
        let rep = NSCIImageRep(ciImage: result)
        let nsImage = NSImage(size: image.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }

    // MARK: - Crop Modes

    enum CropMode {
        case center
        case smart // Would use Vision framework for face/object detection
        case manual(CGRect)
    }

    func crop(_ image: NSImage, mode: CropMode) -> NSImage {
        switch mode {
        case .center:
            return cropCenter(image)
        case .smart:
            return cropSmart(image)
        case .manual(let rect):
            return cropManual(image, rect: rect)
        }
    }

    private func cropCenter(_ image: NSImage) -> NSImage {
        let size = image.size
        let cropSize = min(size.width, size.height)
        let xOffset = (size.width - cropSize) / 2
        let yOffset = (size.height - cropSize) / 2

        let cropped = NSImage(size: NSSize(width: cropSize, height: cropSize))
        cropped.lockFocus()
        defer { cropped.unlockFocus() }

        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let sourceRect = CGRect(x: xOffset, y: yOffset, width: cropSize, height: cropSize)
            if let croppedCG = cgImage.cropping(to: sourceRect) {
                let nsImage = NSImage(cgImage: croppedCG, size: NSSize(width: cropSize, height: cropSize))
                nsImage.draw(in: NSRect(x: 0, y: 0, width: cropSize, height: cropSize))
            }
        }

        return cropped
    }

    private func cropSmart(_ image: NSImage) -> NSImage {
        // TODO: Implement smart cropping using Vision framework
        // For now, fall back to center crop
        return cropCenter(image)
    }

    private func cropManual(_ image: NSImage, rect: CGRect) -> NSImage {
        let cropped = NSImage(size: rect.size)
        cropped.lockFocus()
        defer { cropped.unlockFocus() }

        let sourceRect = rect
        let destRect = NSRect(origin: .zero, size: rect.size)
        image.draw(in: destRect, from: sourceRect, operation: .copy, fraction: 1.0)

        return cropped
    }

    // MARK: - Multi-layer Composition

    func composeImage(background: NSImage?, icon: NSImage, overlay: NSImage?) -> NSImage {
        let size = icon.size
        let composed = NSImage(size: size)

        composed.lockFocus()
        defer { composed.unlockFocus() }

        // Draw background
        if let background = background {
            background.draw(in: NSRect(origin: .zero, size: size))
        }

        // Draw icon
        icon.draw(in: NSRect(origin: .zero, size: size))

        // Draw overlay
        if let overlay = overlay {
            overlay.draw(in: NSRect(origin: .zero, size: size))
        }

        return composed
    }
}
