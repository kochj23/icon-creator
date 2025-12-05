import Foundation
import AppKit
import CoreImage

/// Platform-specific optimizations for icons
class PlatformOptimizer {

    // MARK: - Main Optimization

    func optimize(icon: NSImage, for platform: Platform, size: Int) -> NSImage {
        switch platform {
        case .iOS:
            return optimizeForIOS(icon, size: size)
        case .macOS:
            return optimizeForMac(icon, size: size)
        case .tvOS:
            return optimizeForTVOS(icon, size: size)
        case .watchOS:
            return optimizeForWatch(icon, size: size)
        case .iMessage, .macCatalyst:
            return optimizeForIOS(icon, size: size)
        }
    }

    // MARK: - iOS Optimization

    private func optimizeForIOS(_ icon: NSImage, size: Int) -> NSImage {
        var result = icon

        // iOS icons are rounded by system - ensure good edge quality
        result = enhanceEdges(result, intensity: 0.1)

        // Optimize for both light and dark mode
        result = ensureDarkModeCompatibility(result)

        return result
    }

    // MARK: - macOS Optimization

    private func optimizeForMac(_ icon: NSImage, size: Int) -> NSImage {
        var result = icon

        // macOS Big Sur style: subtle perspective and shadow
        if size >= 512 {
            result = applyBigSurStyle(result)
        }

        // Enhance for retina displays
        result = enhanceForRetina(result)

        return result
    }

    private func applyBigSurStyle(_ icon: NSImage) -> NSImage {
        // Big Sur icons have a subtle 3D effect
        // This is a simplified version
        let sized = icon

        let enhanced = NSImage(size: icon.size)
        enhanced.lockFocus()
        defer { enhanced.unlockFocus() }

        // Draw with subtle shadow
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.15)
        shadow.shadowBlurRadius = icon.size.width * 0.02
        shadow.shadowOffset = NSSize(width: 0, height: -icon.size.height * 0.01)

        NSGraphicsContext.saveGraphicsState()
        shadow.set()
        sized.draw(in: NSRect(origin: .zero, size: icon.size))
        NSGraphicsContext.restoreGraphicsState()

        return enhanced
    }

    // MARK: - tvOS Optimization

    private func optimizeForTVOS(_ icon: NSImage, size: Int) -> NSImage {
        var result = icon

        // tvOS icons need high visibility from distance
        result = increaseContrast(result, amount: 0.15)
        result = increaseSaturation(result, amount: 0.1)
        result = enhanceEdges(result, intensity: 0.15)

        return result
    }

    // MARK: - watchOS Optimization

    private func optimizeForWatch(_ icon: NSImage, size: Int) -> NSImage {
        var result = icon

        // watchOS icons are very small - maximize clarity
        result = increaseContrast(result, amount: 0.2)
        result = increaseSaturation(result, amount: 0.15)
        result = sharpenImage(result, intensity: 0.3)

        // Ensure simple, bold design
        if size <= 44 {
            result = simplifyDetails(result)
        }

        return result
    }

    // MARK: - Enhancement Filters

    private func enhanceEdges(_ image: NSImage, intensity: Double) -> NSImage {
        guard let ciImage = CIImage(data: image.tiffRepresentation!) else { return image }

        let filter = CIFilter.sharpenLuminance()
        filter.inputImage = ciImage
        filter.sharpness = Float(intensity)

        guard let output = filter.outputImage else { return image }

        let rep = NSCIImageRep(ciImage: output)
        let result = NSImage(size: image.size)
        result.addRepresentation(rep)
        return result
    }

    private func increaseContrast(_ image: NSImage, amount: Double) -> NSImage {
        guard let ciImage = CIImage(data: image.tiffRepresentation!) else { return image }

        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.contrast = Float(1.0 + amount)

        guard let output = filter.outputImage else { return image }

        let rep = NSCIImageRep(ciImage: output)
        let result = NSImage(size: image.size)
        result.addRepresentation(rep)
        return result
    }

    private func increaseSaturation(_ image: NSImage, amount: Double) -> NSImage {
        guard let ciImage = CIImage(data: image.tiffRepresentation!) else { return image }

        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.saturation = Float(1.0 + amount)

        guard let output = filter.outputImage else { return image }

        let rep = NSCIImageRep(ciImage: output)
        let result = NSImage(size: image.size)
        result.addRepresentation(rep)
        return result
    }

    private func sharpenImage(_ image: NSImage, intensity: Double) -> NSImage {
        return enhanceEdges(image, intensity: intensity)
    }

    private func simplifyDetails(_ image: NSImage) -> NSImage {
        // For very small sizes, apply slight blur to remove fine details
        // that won't be visible anyway
        guard let ciImage = CIImage(data: image.tiffRepresentation!) else { return image }

        let filter = CIFilter.gaussianBlur()
        filter.inputImage = ciImage
        filter.radius = 0.5

        guard let output = filter.outputImage else { return image }

        let rep = NSCIImageRep(ciImage: output)
        let result = NSImage(size: image.size)
        result.addRepresentation(rep)
        return result
    }

    private func enhanceForRetina(_ image: NSImage) -> NSImage {
        // Ensure crisp rendering on retina displays
        return enhanceEdges(image, intensity: 0.08)
    }

    private func ensureDarkModeCompatibility(_ image: NSImage) -> NSImage {
        // Ensure icon has good contrast on both light and dark backgrounds
        // This is a placeholder - full implementation would analyze edge pixels
        return image
    }
}
