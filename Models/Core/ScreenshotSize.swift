import Foundation
import SwiftUI

// MARK: - Screenshot Size Configuration

/// Represents all App Store Connect screenshot size requirements
/// Source: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications
struct ScreenshotSize: Hashable, Identifiable {
    let id = UUID()
    let name: String
    let device: String
    let width: Int
    let height: Int
    let platform: ScreenshotPlatform
    let orientation: ScreenshotOrientation

    /// Display name for UI
    var displayName: String {
        "\(device) - \(width)×\(height) (\(orientation.rawValue))"
    }

    /// CGSize representation
    var size: CGSize {
        CGSize(width: width, height: height)
    }

    /// NSSize representation
    var nsSize: NSSize {
        NSSize(width: width, height: height)
    }

    /// Aspect ratio (width/height)
    var aspectRatio: Double {
        Double(width) / Double(height)
    }

    /// Returns the landscape variant of this size
    var landscapeVariant: ScreenshotSize {
        if orientation == .landscape {
            return self
        }
        return ScreenshotSize(
            name: name,
            device: device,
            width: height,
            height: width,
            platform: platform,
            orientation: .landscape
        )
    }

    /// Returns the portrait variant of this size
    var portraitVariant: ScreenshotSize {
        if orientation == .portrait {
            return self
        }
        return ScreenshotSize(
            name: name,
            device: device,
            width: height,
            height: width,
            platform: platform,
            orientation: .portrait
        )
    }
}

// MARK: - Screenshot Platform

enum ScreenshotPlatform: String, CaseIterable {
    case iPhone = "iPhone"
    case iPad = "iPad"
    case mac = "Mac"
    case appleTV = "Apple TV"
    case appleWatch = "Apple Watch"
    case appleVisionPro = "Apple Vision Pro"

    var iconName: String {
        switch self {
        case .iPhone: return "iphone"
        case .iPad: return "ipad"
        case .mac: return "desktopcomputer"
        case .appleTV: return "appletv"
        case .appleWatch: return "applewatch"
        case .appleVisionPro: return "vision.pro"
        }
    }
}

// MARK: - Screenshot Orientation

enum ScreenshotOrientation: String, CaseIterable {
    case portrait = "Portrait"
    case landscape = "Landscape"
}

// MARK: - Predefined Screenshot Sizes

extension ScreenshotSize {

    // MARK: - iPhone Sizes

    static let iPhone69 = ScreenshotSize(
        name: "iPhone 6.9\" Display",
        device: "iPhone 16 Pro Max",
        width: 1320,
        height: 2868,
        platform: .iPhone,
        orientation: .portrait
    )

    static let iPhone67 = ScreenshotSize(
        name: "iPhone 6.7\" Display",
        device: "iPhone 15 Plus, iPhone 14 Pro Max",
        width: 1290,
        height: 2796,
        platform: .iPhone,
        orientation: .portrait
    )

    static let iPhone65 = ScreenshotSize(
        name: "iPhone 6.5\" Display",
        device: "iPhone 13 Pro Max, iPhone 11 Pro Max",
        width: 1284,
        height: 2778,
        platform: .iPhone,
        orientation: .portrait
    )

    static let iPhone61 = ScreenshotSize(
        name: "iPhone 6.1\" Display",
        device: "iPhone 14 Pro, iPhone 13",
        width: 1179,
        height: 2556,
        platform: .iPhone,
        orientation: .portrait
    )

    static let iPhone58 = ScreenshotSize(
        name: "iPhone 5.8\" Display",
        device: "iPhone X, iPhone XS",
        width: 1125,
        height: 2436,
        platform: .iPhone,
        orientation: .portrait
    )

    static let iPhone55 = ScreenshotSize(
        name: "iPhone 5.5\" Display",
        device: "iPhone 8 Plus, iPhone 7 Plus",
        width: 1242,
        height: 2208,
        platform: .iPhone,
        orientation: .portrait
    )

    static let iPhone47 = ScreenshotSize(
        name: "iPhone 4.7\" Display",
        device: "iPhone SE (2nd gen), iPhone 8",
        width: 750,
        height: 1334,
        platform: .iPhone,
        orientation: .portrait
    )

    static let iPhone40 = ScreenshotSize(
        name: "iPhone 4.0\" Display",
        device: "iPhone SE (1st gen)",
        width: 640,
        height: 1136,
        platform: .iPhone,
        orientation: .portrait
    )

    // MARK: - iPad Sizes

    static let iPadPro13 = ScreenshotSize(
        name: "iPad Pro 13\" Display",
        device: "iPad Pro 13\" (M4)",
        width: 2064,
        height: 2752,
        platform: .iPad,
        orientation: .portrait
    )

    static let iPadPro129 = ScreenshotSize(
        name: "iPad Pro 12.9\" Display",
        device: "iPad Pro 12.9\" (2nd-6th gen)",
        width: 2048,
        height: 2732,
        platform: .iPad,
        orientation: .portrait
    )

    static let iPadPro11 = ScreenshotSize(
        name: "iPad Pro 11\" Display",
        device: "iPad Pro 11\", iPad Air",
        width: 1668,
        height: 2388,
        platform: .iPad,
        orientation: .portrait
    )

    static let iPad105 = ScreenshotSize(
        name: "iPad 10.5\" Display",
        device: "iPad Pro 10.5\"",
        width: 1668,
        height: 2224,
        platform: .iPad,
        orientation: .portrait
    )

    static let iPad97 = ScreenshotSize(
        name: "iPad 9.7\" Display",
        device: "iPad (5th-9th gen)",
        width: 1536,
        height: 2048,
        platform: .iPad,
        orientation: .portrait
    )

    // MARK: - Mac Sizes

    static let mac2880 = ScreenshotSize(
        name: "Mac 2880×1800",
        device: "MacBook Pro 16\" (Retina)",
        width: 2880,
        height: 1800,
        platform: .mac,
        orientation: .landscape
    )

    static let mac2560 = ScreenshotSize(
        name: "Mac 2560×1600",
        device: "MacBook Pro 13\" (Retina)",
        width: 2560,
        height: 1600,
        platform: .mac,
        orientation: .landscape
    )

    static let mac1440 = ScreenshotSize(
        name: "Mac 1440×900",
        device: "MacBook Air",
        width: 1440,
        height: 900,
        platform: .mac,
        orientation: .landscape
    )

    static let mac1280 = ScreenshotSize(
        name: "Mac 1280×800",
        device: "MacBook (non-Retina)",
        width: 1280,
        height: 800,
        platform: .mac,
        orientation: .landscape
    )

    // MARK: - Apple TV Sizes

    static let appleTV4K = ScreenshotSize(
        name: "Apple TV 4K",
        device: "Apple TV 4K",
        width: 3840,
        height: 2160,
        platform: .appleTV,
        orientation: .landscape
    )

    static let appleTV1080p = ScreenshotSize(
        name: "Apple TV 1080p",
        device: "Apple TV HD",
        width: 1920,
        height: 1080,
        platform: .appleTV,
        orientation: .landscape
    )

    // MARK: - Apple Watch Sizes

    static let watch49mm = ScreenshotSize(
        name: "Apple Watch 49mm",
        device: "Apple Watch Ultra 2",
        width: 410,
        height: 502,
        platform: .appleWatch,
        orientation: .portrait
    )

    static let watch45mm = ScreenshotSize(
        name: "Apple Watch 45mm",
        device: "Apple Watch Series 9",
        width: 396,
        height: 484,
        platform: .appleWatch,
        orientation: .portrait
    )

    static let watch41mm = ScreenshotSize(
        name: "Apple Watch 41mm",
        device: "Apple Watch Series 9",
        width: 368,
        height: 448,
        platform: .appleWatch,
        orientation: .portrait
    )

    static let watch40mm = ScreenshotSize(
        name: "Apple Watch 40mm",
        device: "Apple Watch Series 6",
        width: 368,
        height: 448,
        platform: .appleWatch,
        orientation: .portrait
    )

    static let watch44mm = ScreenshotSize(
        name: "Apple Watch 44mm",
        device: "Apple Watch Series 6",
        width: 396,
        height: 484,
        platform: .appleWatch,
        orientation: .portrait
    )

    static let watch38mm = ScreenshotSize(
        name: "Apple Watch 38mm",
        device: "Apple Watch Series 3",
        width: 312,
        height: 390,
        platform: .appleWatch,
        orientation: .portrait
    )

    static let watch42mm = ScreenshotSize(
        name: "Apple Watch 42mm",
        device: "Apple Watch Series 3",
        width: 360,
        height: 450,
        platform: .appleWatch,
        orientation: .portrait
    )

    // MARK: - Apple Vision Pro

    static let visionPro = ScreenshotSize(
        name: "Apple Vision Pro",
        device: "Apple Vision Pro",
        width: 2712,
        height: 1536,
        platform: .appleVisionPro,
        orientation: .landscape
    )

    // MARK: - All Sizes Collection

    static let allSizes: [ScreenshotSize] = [
        // iPhone
        iPhone69, iPhone67, iPhone65, iPhone61, iPhone58, iPhone55, iPhone47, iPhone40,
        // iPad
        iPadPro13, iPadPro129, iPadPro11, iPad105, iPad97,
        // Mac
        mac2880, mac2560, mac1440, mac1280,
        // Apple TV
        appleTV4K, appleTV1080p,
        // Apple Watch
        watch49mm, watch45mm, watch41mm, watch40mm, watch44mm, watch38mm, watch42mm,
        // Vision Pro
        visionPro
    ]

    /// Returns all sizes for a specific platform
    static func sizes(for platform: ScreenshotPlatform) -> [ScreenshotSize] {
        allSizes.filter { $0.platform == platform }
    }

    /// Returns all sizes grouped by platform
    static var sizesByPlatform: [ScreenshotPlatform: [ScreenshotSize]] {
        Dictionary(grouping: allSizes, by: { $0.platform })
    }

    /// Most commonly used sizes (primary requirement for App Store Connect)
    static let primarySizes: [ScreenshotSize] = [
        iPhone69,        // Latest iPhone
        iPadPro129,      // Latest iPad Pro
        mac2880,         // MacBook Pro 16"
        appleTV1080p,    // Apple TV HD
        watch45mm        // Apple Watch Series 9
    ]
}
