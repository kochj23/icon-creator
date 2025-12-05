import Foundation
import AppKit
import CoreImage

/// Analyzes images to extract color information
class ColorAnalyzer {

    // MARK: - Color Extraction

    /// Extracts dominant colors from an image using k-means clustering
    func extractDominantColors(from image: NSImage, count: Int = 5) -> [NSColor] {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return []
        }

        // Sample pixels from the image
        let pixels = samplePixels(from: cgImage, sampleSize: 1000)

        // Perform k-means clustering
        let clusters = kMeansClustering(pixels: pixels, k: count)

        // Convert to NSColor
        return clusters.map { pixel in
            NSColor(red: pixel.r, green: pixel.g, blue: pixel.b, alpha: 1.0)
        }
    }

    /// Generates a complete color palette from an image
    func generatePalette(from image: NSImage) -> ColorPalette {
        let colors = extractDominantColors(from: image, count: 5)

        guard colors.count >= 3 else {
            // Fallback palette
            return ColorPalette(
                name: "Default",
                primary: .systemBlue,
                secondary: .systemGray,
                accent: .systemOrange,
                background: .white,
                isDark: false
            )
        }

        let isDark = isDarkImage(image)
        let suggestedBG = suggestBackgroundColor(for: colors, isDark: isDark)

        return ColorPalette(
            name: "From Image",
            primary: colors[0],
            secondary: colors[1],
            accent: colors[2],
            background: suggestedBG,
            isDark: isDark
        )
    }

    /// Suggests an appropriate background color based on icon colors
    func suggestBackgroundColor(for iconColors: [NSColor], isDark: Bool) -> NSColor {
        // Calculate average brightness of icon colors
        let avgBrightness = iconColors.reduce(0.0) { sum, color in
            sum + color.brightnessComponent
        } / Double(iconColors.count)

        // Suggest contrasting background
        if avgBrightness > 0.6 {
            // Light icon -> dark background
            return isDark ? NSColor(white: 0.15, alpha: 1.0) : NSColor(white: 0.2, alpha: 1.0)
        } else if avgBrightness < 0.4 {
            // Dark icon -> light background
            return NSColor(white: 0.95, alpha: 1.0)
        } else {
            // Medium icon -> white background
            return .white
        }
    }

    /// Determines if an image is predominantly dark
    func isDarkImage(_ image: NSImage) -> Bool {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return false
        }

        let pixels = samplePixels(from: cgImage, sampleSize: 100)
        let avgBrightness = pixels.reduce(0.0) { sum, pixel in
            sum + (pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114)
        } / Double(pixels.count)

        return avgBrightness < 0.5
    }

    // MARK: - Contrast Calculation

    /// Calculates WCAG contrast ratio between two colors
    func calculateContrast(between color1: NSColor, and color2: NSColor) -> Double {
        let l1 = relativeLuminance(color1)
        let l2 = relativeLuminance(color2)

        let lighter = max(l1, l2)
        let darker = min(l1, l2)

        return (lighter + 0.05) / (darker + 0.05)
    }

    private func relativeLuminance(_ color: NSColor) -> Double {
        let r = linearize(color.redComponent)
        let g = linearize(color.greenComponent)
        let b = linearize(color.blueComponent)

        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    private func linearize(_ component: CGFloat) -> Double {
        let c = Double(component)
        return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }

    // MARK: - Pixel Sampling

    private struct Pixel {
        var r: Double
        var g: Double
        var b: Double
    }

    private func samplePixels(from cgImage: CGImage, sampleSize: Int) -> [Pixel] {
        let width = cgImage.width
        let height = cgImage.height

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return []
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return [] }

        let buffer = data.bindMemory(to: UInt8.self, capacity: width * height * 4)

        var pixels: [Pixel] = []
        let step = max(1, (width * height) / sampleSize)

        for i in stride(from: 0, to: width * height, by: step) {
            let offset = i * 4
            let r = Double(buffer[offset]) / 255.0
            let g = Double(buffer[offset + 1]) / 255.0
            let b = Double(buffer[offset + 2]) / 255.0

            pixels.append(Pixel(r: r, g: g, b: b))
        }

        return pixels
    }

    // MARK: - K-Means Clustering

    private func kMeansClustering(pixels: [Pixel], k: Int, maxIterations: Int = 20) -> [Pixel] {
        guard !pixels.isEmpty, k > 0 else { return [] }

        // Initialize centroids randomly
        var centroids = (0..<k).map { _ in pixels.randomElement()! }

        for _ in 0..<maxIterations {
            // Assign pixels to nearest centroid
            var clusters: [[Pixel]] = Array(repeating: [], count: k)

            for pixel in pixels {
                let nearestIndex = findNearestCentroid(pixel, centroids: centroids)
                clusters[nearestIndex].append(pixel)
            }

            // Update centroids
            var newCentroids: [Pixel] = []
            for cluster in clusters {
                if cluster.isEmpty {
                    newCentroids.append(centroids[newCentroids.count])
                } else {
                    let avgR = cluster.reduce(0.0) { $0 + $1.r } / Double(cluster.count)
                    let avgG = cluster.reduce(0.0) { $0 + $1.g } / Double(cluster.count)
                    let avgB = cluster.reduce(0.0) { $0 + $1.b } / Double(cluster.count)
                    newCentroids.append(Pixel(r: avgR, g: avgG, b: avgB))
                }
            }

            // Check convergence
            if centroids == newCentroids {
                break
            }

            centroids = newCentroids
        }

        return centroids
    }

    private func findNearestCentroid(_ pixel: Pixel, centroids: [Pixel]) -> Int {
        var minDistance = Double.infinity
        var nearestIndex = 0

        for (index, centroid) in centroids.enumerated() {
            let distance = colorDistance(pixel, centroid)
            if distance < minDistance {
                minDistance = distance
                nearestIndex = index
            }
        }

        return nearestIndex
    }

    private func colorDistance(_ p1: Pixel, _ p2: Pixel) -> Double {
        let dr = p1.r - p2.r
        let dg = p1.g - p2.g
        let db = p1.b - p2.b
        return sqrt(dr * dr + dg * dg + db * db)
    }
}

// MARK: - Pixel Equatable

extension ColorAnalyzer.Pixel: Equatable {
    static func == (lhs: ColorAnalyzer.Pixel, rhs: ColorAnalyzer.Pixel) -> Bool {
        abs(lhs.r - rhs.r) < 0.01 &&
        abs(lhs.g - rhs.g) < 0.01 &&
        abs(lhs.b - rhs.b) < 0.01
    }
}

// MARK: - NSColor Extension

extension NSColor {
    var brightnessComponent: CGFloat {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return brightness
    }
}
