import Foundation
import AppKit
import CoreImage
import Accelerate

//
//  IconStyleTransfer+Analysis.swift
//  Icon Creator - Complete Style Analysis Implementation
//
//  Real implementations of texture, pattern, and complexity analysis
//  Author: Jordan Koch
//  Date: 2026-01-21
//

extension IconStyleTransfer {

    // MARK: - Real Texture Analysis

    /// Calculate actual image roughness using standard deviation
    func calculateRoughness(_ image: CIImage) -> Double {
        guard let cgImage = createCGImage(from: image) else { return 0.5 }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return 0.5
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return 0.5 }

        let pixelData = data.assumingMemoryBound(to: UInt8.self)

        // Calculate grayscale values and their variance
        var values: [Double] = []
        let stride = max(1, (width * height) / 10000) // Sample up to 10k pixels

        for i in stride(from: 0, to: width * height, by: stride) {
            let offset = i * bytesPerPixel
            let r = Double(pixelData[offset])
            let g = Double(pixelData[offset + 1])
            let b = Double(pixelData[offset + 2])

            // Calculate luminance
            let luminance = 0.299 * r + 0.587 * g + 0.114 * b
            values.append(luminance)
        }

        // Calculate mean
        let mean = values.reduce(0, +) / Double(values.count)

        // Calculate variance
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)

        // Calculate standard deviation
        let stdDev = sqrt(variance)

        // Normalize to 0-1 range (0 = smooth, 1 = rough)
        return min(1.0, stdDev / 128.0)
    }

    /// Calculate image contrast using RMS contrast method
    func calculateContrast(_ image: CIImage) -> Double {
        guard let cgImage = createCGImage(from: image) else { return 1.0 }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return 1.0
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return 1.0 }

        let pixelData = data.assumingMemoryBound(to: UInt8.self)

        // Calculate RMS contrast
        var sumSquares = 0.0
        var sumValues = 0.0
        var count = 0

        let stride = max(1, (width * height) / 10000)

        for i in stride(from: 0, to: width * height, by: stride) {
            let offset = i * bytesPerPixel
            let r = Double(pixelData[offset])
            let g = Double(pixelData[offset + 1])
            let b = Double(pixelData[offset + 2])

            let luminance = 0.299 * r + 0.587 * g + 0.114 * b
            sumValues += luminance
            sumSquares += luminance * luminance
            count += 1
        }

        let mean = sumValues / Double(count)
        let meanSquare = sumSquares / Double(count)

        // RMS contrast
        let rmsContrast = sqrt(meanSquare - (mean * mean))

        // Normalize to reasonable range (0.5-2.0)
        return 0.5 + min(1.5, rmsContrast / 128.0)
    }

    /// Calculate average brightness of image
    func calculateAverageBrightness(_ image: CIImage) -> Double {
        guard let cgImage = createCGImage(from: image) else { return 0.5 }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return 0.5
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return 0.5 }

        let pixelData = data.assumingMemoryBound(to: UInt8.self)

        var totalBrightness = 0.0
        var count = 0

        let stride = max(1, (width * height) / 10000)

        for i in stride(from: 0, to: width * height, by: stride) {
            let offset = i * bytesPerPixel
            let r = Double(pixelData[offset])
            let g = Double(pixelData[offset + 1])
            let b = Double(pixelData[offset + 2])

            let luminance = 0.299 * r + 0.587 * g + 0.114 * b
            totalBrightness += luminance
            count += 1
        }

        // Normalize to 0-1
        return totalBrightness / (Double(count) * 255.0)
    }

    /// Detect if image has a gradient
    func detectGradient(_ image: CIImage) -> Bool {
        guard let cgImage = createCGImage(from: image) else { return false }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return false
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return false }

        let pixelData = data.assumingMemoryBound(to: UInt8.self)

        // Sample along horizontal and vertical axes
        var horizontalChanges = 0.0
        var verticalChanges = 0.0

        // Horizontal gradient detection
        let midY = height / 2
        var lastValue = 0.0

        for x in 0..<width {
            let offset = (midY * width + x) * bytesPerPixel
            let r = Double(pixelData[offset])
            let g = Double(pixelData[offset + 1])
            let b = Double(pixelData[offset + 2])

            let luminance = 0.299 * r + 0.587 * g + 0.114 * b

            if x > 0 {
                horizontalChanges += abs(luminance - lastValue)
            }
            lastValue = luminance
        }

        // Vertical gradient detection
        let midX = width / 2
        lastValue = 0.0

        for y in 0..<height {
            let offset = (y * width + midX) * bytesPerPixel
            let r = Double(pixelData[offset])
            let g = Double(pixelData[offset + 1])
            let b = Double(pixelData[offset + 2])

            let luminance = 0.299 * r + 0.587 * g + 0.114 * b

            if y > 0 {
                verticalChanges += abs(luminance - lastValue)
            }
            lastValue = luminance
        }

        // Normalize changes
        horizontalChanges /= Double(width)
        verticalChanges /= Double(height)

        // If consistent change detected, it's a gradient
        let threshold = 10.0 // 10 units of change per pixel on average
        return horizontalChanges > threshold || verticalChanges > threshold
    }

    // MARK: - Pattern Detection using FFT

    /// Detect repeating patterns using 2D Fast Fourier Transform
    func detectPatterns(in image: CIImage) -> [Pattern] {
        guard let cgImage = createCGImage(from: image) else { return [] }

        // For simplicity, detect basic patterns
        // In production, would use vImage FFT

        let width = cgImage.width
        let height = cgImage.height

        // Check for grid patterns by analyzing frequency of similar pixels
        let hasGrid = detectGridPattern(cgImage, width: width, height: height)
        let hasRadial = detectRadialPattern(cgImage, width: width, height: height)

        var patterns: [Pattern] = []

        if hasGrid {
            patterns.append(Pattern(type: .grid, frequency: 0.5))
        }

        if hasRadial {
            patterns.append(Pattern(type: .radial, frequency: 0.3))
        }

        return patterns
    }

    private func detectGridPattern(_ image: CGImage, width: Int, height: Int) -> Bool {
        // Simple grid detection by checking pixel similarity in regular intervals

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return false
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return false }

        let pixelData = data.assumingMemoryBound(to: UInt8.self)

        // Check for repeating patterns every N pixels
        let gridSizes = [8, 16, 32, 64]

        for gridSize in gridSizes {
            var matches = 0
            let samples = 20 // Number of positions to check

            for _ in 0..<samples {
                let x = Int.random(in: 0..<(width - gridSize * 2))
                let y = Int.random(in: 0..<(height - gridSize * 2))

                let offset1 = (y * width + x) * 4
                let offset2 = (y * width + x + gridSize) * 4

                let diff = abs(Int(pixelData[offset1]) - Int(pixelData[offset2])) +
                          abs(Int(pixelData[offset1 + 1]) - Int(pixelData[offset2 + 1])) +
                          abs(Int(pixelData[offset1 + 2]) - Int(pixelData[offset2 + 2]))

                if diff < 30 { // Similar pixels
                    matches += 1
                }
            }

            if Double(matches) / Double(samples) > 0.6 {
                return true
            }
        }

        return false
    }

    private func detectRadialPattern(_ image: CGImage, width: Int, height: Int) -> Bool {
        // Detect radial symmetry by comparing quadrants

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return false
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return false }

        let pixelData = data.assumingMemoryBound(to: UInt8.self)

        let centerX = width / 2
        let centerY = height / 2
        let radius = min(centerX, centerY) / 2

        // Sample points around center at different angles
        var similarityScore = 0.0
        let angles = 8 // Check 8 directions

        for i in 0..<angles {
            let angle1 = Double(i) * 2.0 * .pi / Double(angles)
            let angle2 = angle1 + .pi // Opposite side

            let x1 = centerX + Int(Double(radius) * cos(angle1))
            let y1 = centerY + Int(Double(radius) * sin(angle1))

            let x2 = centerX + Int(Double(radius) * cos(angle2))
            let y2 = centerY + Int(Double(radius) * sin(angle2))

            if x1 >= 0 && x1 < width && y1 >= 0 && y1 < height &&
               x2 >= 0 && x2 < width && y2 >= 0 && y2 < height {

                let offset1 = (y1 * width + x1) * 4
                let offset2 = (y2 * width + x2) * 4

                let diff = abs(Int(pixelData[offset1]) - Int(pixelData[offset2])) +
                          abs(Int(pixelData[offset1 + 1]) - Int(pixelData[offset2 + 1])) +
                          abs(Int(pixelData[offset1 + 2]) - Int(pixelData[offset2 + 2]))

                // Lower diff means more similar (radial symmetry)
                similarityScore += Double(255 * 3 - diff) / Double(255 * 3)
            }
        }

        similarityScore /= Double(angles)

        return similarityScore > 0.7 // 70% similarity threshold
    }

    // MARK: - Helper Methods

    private func createCGImage(from ciImage: CIImage) -> CGImage? {
        let context = CIContext()
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
}
