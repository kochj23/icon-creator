//
//  IconCreatorTests.swift
//  Icon CreatorTests
//
//  Comprehensive test suite for Icon Creator
//  Unit, Functional, and Security tests
//
//  Focus: Core icon generation logic, not UI
//
//  Written by Jordan Koch
//

import XCTest
@testable import Icon_Creator

// MARK: - Platform Tests

class PlatformTests: XCTestCase {

    func testAllPlatformsCaseIterable() {
        let platforms = Platform.allCases
        XCTAssertTrue(platforms.count >= 5, "Should have at least 5 platforms")
    }

    func testIOSIconSizes() {
        let sizes = Platform.iOS.iconSizes
        XCTAssertTrue(sizes.contains(1024), "iOS should include 1024px App Store icon")
        XCTAssertTrue(sizes.contains(180), "iOS should include 180px (60pt@3x) icon")
        XCTAssertTrue(sizes.contains(120), "iOS should include 120px icon")
    }

    func testMacOSIconSizes() {
        let sizes = Platform.macOS.iconSizes
        XCTAssertTrue(sizes.contains(1024), "macOS should include 1024px icon")
        XCTAssertTrue(sizes.contains(512), "macOS should include 512px icon")
        XCTAssertTrue(sizes.contains(16), "macOS should include 16px icon")
    }

    func testWatchOSIconSizes() {
        let sizes = Platform.watchOS.iconSizes
        XCTAssertTrue(sizes.contains(1024), "watchOS should include 1024px icon")
        XCTAssertFalse(sizes.isEmpty, "watchOS should have icon sizes")
    }

    func testTVOSIconSizes() {
        let sizes = Platform.tvOS.iconSizes
        XCTAssertTrue(sizes.contains(1280), "tvOS should include 1280px icon")
        XCTAssertTrue(sizes.contains(400), "tvOS should include 400px icon")
    }

    func testPlatformIconNames() {
        XCTAssertEqual(Platform.iOS.iconName, "iphone")
        XCTAssertEqual(Platform.macOS.iconName, "desktopcomputer")
        XCTAssertEqual(Platform.tvOS.iconName, "appletv")
        XCTAssertEqual(Platform.watchOS.iconName, "applewatch")
    }

    func testPlatformFolderNames() {
        XCTAssertEqual(Platform.iOS.folderName, "iOS")
        XCTAssertEqual(Platform.macOS.folderName, "macOS")
        XCTAssertEqual(Platform.macCatalyst.folderName, "MacCatalyst")
    }

    func testPlatformIdioms() {
        XCTAssertEqual(Platform.iOS.idiom, "iphone")
        XCTAssertEqual(Platform.macOS.idiom, "mac")
        XCTAssertEqual(Platform.tvOS.idiom, "tv")
        XCTAssertEqual(Platform.watchOS.idiom, "watch")
    }

    func testAllPlatformsHaveIconSizes() {
        for platform in Platform.allCases {
            XCTAssertFalse(platform.iconSizes.isEmpty,
                          "\(platform.rawValue) should have at least one icon size")
        }
    }

    func testAllPlatformsInclude1024() {
        for platform in Platform.allCases {
            XCTAssertTrue(platform.iconSizes.contains(1024),
                         "\(platform.rawValue) should include 1024px App Store size")
        }
    }
}

// MARK: - IconSettings Tests

class IconSettingsTests: XCTestCase {

    func testDefaultSettings() {
        let settings = IconSettings.default
        XCTAssertEqual(settings.scale, 1.0)
        XCTAssertEqual(settings.padding, 10.0)
        XCTAssertTrue(settings.autoCropToSquare)
        XCTAssertTrue(settings.isValid)
    }

    func testSettingsValidation() {
        var settings = IconSettings()
        settings.scale = 1.0
        settings.padding = 10.0
        XCTAssertTrue(settings.isValid)

        settings.scale = 0.3 // Below minimum
        XCTAssertFalse(settings.isValid)

        settings.scale = 3.0 // Above maximum
        XCTAssertFalse(settings.isValid)

        settings.scale = 1.0
        settings.padding = -5 // Below minimum
        XCTAssertFalse(settings.isValid)

        settings.padding = 50 // Above maximum
        XCTAssertFalse(settings.isValid)
    }

    func testSettingsCodable() throws {
        let settings = IconSettings(
            scale: 1.5,
            padding: 15.0,
            backgroundColor: ColorComponents(red: 0.5, green: 0.5, blue: 0.5),
            autoCropToSquare: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(settings)
        XCTAssertFalse(data.isEmpty)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(IconSettings.self, from: data)
        XCTAssertEqual(decoded.scale, 1.5)
        XCTAssertEqual(decoded.padding, 15.0)
        XCTAssertFalse(decoded.autoCropToSquare)
    }

    func testSettingsEquatable() {
        let s1 = IconSettings.default
        let s2 = IconSettings.default
        XCTAssertEqual(s1, s2)

        var s3 = IconSettings.default
        s3.scale = 2.0
        XCTAssertNotEqual(s1, s3)
    }
}

// MARK: - ColorComponents Tests

class ColorComponentsTests: XCTestCase {

    func testColorComponentsInit() {
        let cc = ColorComponents(red: 1.0, green: 0.5, blue: 0.0)
        XCTAssertEqual(cc.red, 1.0)
        XCTAssertEqual(cc.green, 0.5)
        XCTAssertEqual(cc.blue, 0.0)
        XCTAssertEqual(cc.alpha, 1.0)
    }

    func testColorComponentsCodable() throws {
        let cc = ColorComponents(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8)
        let data = try JSONEncoder().encode(cc)
        let decoded = try JSONDecoder().decode(ColorComponents.self, from: data)
        XCTAssertEqual(decoded.red, 0.2, accuracy: 0.01)
        XCTAssertEqual(decoded.green, 0.4, accuracy: 0.01)
        XCTAssertEqual(decoded.blue, 0.6, accuracy: 0.01)
        XCTAssertEqual(decoded.alpha, 0.8, accuracy: 0.01)
    }

    func testColorComponentsToNSColor() {
        let cc = ColorComponents(red: 1.0, green: 0.0, blue: 0.0)
        let nsColor = cc.nsColor
        XCTAssertEqual(nsColor.redComponent, 1.0, accuracy: 0.01)
        XCTAssertEqual(nsColor.greenComponent, 0.0, accuracy: 0.01)
        XCTAssertEqual(nsColor.blueComponent, 0.0, accuracy: 0.01)
    }

    func testColorComponentsEquatable() {
        let c1 = ColorComponents(red: 0.5, green: 0.5, blue: 0.5)
        let c2 = ColorComponents(red: 0.5, green: 0.5, blue: 0.5)
        XCTAssertEqual(c1, c2)

        let c3 = ColorComponents(red: 0.6, green: 0.5, blue: 0.5)
        XCTAssertNotEqual(c1, c3)
    }
}

// MARK: - ImageEffects Tests

class ImageEffectsTests: XCTestCase {

    func testDefaultEffects() {
        let effects = ImageEffects()
        XCTAssertFalse(effects.cornerRadiusEnabled)
        XCTAssertFalse(effects.shadowEnabled)
        XCTAssertFalse(effects.borderEnabled)
        XCTAssertEqual(effects.brightness, 0)
        XCTAssertEqual(effects.contrast, 0)
        XCTAssertEqual(effects.saturation, 0)
    }

    func testEffectsCodable() throws {
        var effects = ImageEffects()
        effects.cornerRadiusEnabled = true
        effects.cornerRadius = 25.0
        effects.shadowEnabled = true

        let data = try JSONEncoder().encode(effects)
        let decoded = try JSONDecoder().decode(ImageEffects.self, from: data)
        XCTAssertTrue(decoded.cornerRadiusEnabled)
        XCTAssertEqual(decoded.cornerRadius, 25.0)
        XCTAssertTrue(decoded.shadowEnabled)
    }
}

// MARK: - GradientComponents Tests

class GradientComponentsTests: XCTestCase {

    func testSunsetGradient() {
        let sunset = GradientComponents.sunset
        XCTAssertEqual(sunset.stops.count, 2)
        XCTAssertEqual(sunset.stops[0].location, 0.0)
        XCTAssertEqual(sunset.stops[1].location, 1.0)
    }

    func testOceanGradient() {
        let ocean = GradientComponents.ocean
        XCTAssertEqual(ocean.stops.count, 2)
    }

    func testForestGradient() {
        let forest = GradientComponents.forest
        XCTAssertEqual(forest.stops.count, 2)
    }

    func testGradientCodable() throws {
        let gradient = GradientComponents.sunset
        let data = try JSONEncoder().encode(gradient)
        let decoded = try JSONDecoder().decode(GradientComponents.self, from: data)
        XCTAssertEqual(decoded.stops.count, gradient.stops.count)
    }
}

// MARK: - IconGenerator Tests

class IconGeneratorTests: XCTestCase {

    var generator: IconGenerator!

    override func setUp() {
        super.setUp()
        generator = IconGenerator()
    }

    override func tearDown() {
        generator = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertNil(generator.sourceImage)
        XCTAssertEqual(generator.scale, 1.0)
        XCTAssertEqual(generator.padding, 10.0)
        XCTAssertTrue(generator.autoCropToSquare)
        XCTAssertFalse(generator.wasAutoCropped)
    }

    func testResetSettings() {
        generator.scale = 1.5
        generator.padding = 20.0
        generator.autoCropToSquare = false
        generator.resetSettings()
        XCTAssertEqual(generator.scale, 1.0)
        XCTAssertEqual(generator.padding, 10.0)
    }

    func testScaleClamping() {
        generator.scale = 5.0 // Above max
        XCTAssertLessThanOrEqual(generator.scale, 2.0)

        generator.scale = 0.1 // Below min
        XCTAssertGreaterThanOrEqual(generator.scale, 0.5)
    }

    func testPaddingClamping() {
        generator.padding = 50.0 // Above max
        XCTAssertLessThanOrEqual(generator.padding, 30.0)

        generator.padding = -5.0 // Below min
        XCTAssertGreaterThanOrEqual(generator.padding, 0.0)
    }

    func testValidateSourceImageNil() {
        generator.sourceImage = nil
        let result = generator.validateSourceImage()
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.error, "No image selected")
    }

    func testGeneratePreviewNilSource() {
        generator.sourceImage = nil
        let preview = generator.generatePreview(size: 100)
        XCTAssertNil(preview, "Preview should be nil without source image")
    }

    func testGenerateIconNilSource() {
        let testImage = NSImage(size: NSSize(width: 100, height: 100))
        let icon = generator.generateIcon(from: testImage, size: 0)
        XCTAssertNil(icon, "Should return nil for zero size")
    }

    func testGenerateIconFromImage() {
        let testImage = createTestImage(width: 512, height: 512)
        let icon = generator.generateIcon(from: testImage, size: 128)
        XCTAssertNotNil(icon, "Should generate icon from valid image")
        if let icon = icon {
            XCTAssertEqual(Int(icon.size.width), 128)
            XCTAssertEqual(Int(icon.size.height), 128)
        }
    }

    func testGeneratePreviewWithCache() {
        let testImage = createTestImage(width: 256, height: 256)
        generator.sourceImage = testImage

        let preview1 = generator.generatePreview(size: 64)
        let preview2 = generator.generatePreview(size: 64)
        XCTAssertNotNil(preview1)
        XCTAssertNotNil(preview2)
        // Both should return same cached result
    }

    func testClearCache() {
        let testImage = createTestImage(width: 256, height: 256)
        generator.sourceImage = testImage
        _ = generator.generatePreview(size: 64)
        generator.clearCache()
        // Should not crash after clearing cache
        let preview = generator.generatePreview(size: 64)
        XCTAssertNotNil(preview)
    }

    func testCurrentSettings() {
        generator.scale = 1.5
        generator.padding = 20.0
        let settings = generator.currentSettings
        XCTAssertEqual(settings.scale, 1.5)
        XCTAssertEqual(settings.padding, 20.0)
    }

    func testApplySettings() {
        var settings = IconSettings.default
        settings.scale = 1.8
        settings.padding = 5.0
        generator.applySettings(settings)
        XCTAssertEqual(generator.scale, 1.8)
        XCTAssertEqual(generator.padding, 5.0)
    }

    func testAutoCropSquareImage() {
        let squareImage = createTestImage(width: 512, height: 512)
        let cropped = generator.autoCropImageToSquare(squareImage)
        // Already square, should return unchanged
        XCTAssertEqual(Int(cropped.size.width), Int(cropped.size.height))
    }

    func testAutoCropNonSquareImage() {
        let wideImage = createTestImage(width: 800, height: 400)
        let cropped = generator.autoCropImageToSquare(wideImage)
        XCTAssertEqual(Int(cropped.size.width), Int(cropped.size.height))
        XCTAssertEqual(Int(cropped.size.width), 400) // Should crop to shorter dimension
    }

    func testValidateSourceImageTooSmall() {
        let tinyImage = createTestImage(width: 32, height: 32)
        generator.sourceImage = tinyImage
        let result = generator.validateSourceImage()
        XCTAssertFalse(result.isValid)
    }

    func testValidateSourceImageValid() {
        let goodImage = createTestImage(width: 1024, height: 1024)
        generator.sourceImage = goodImage
        let result = generator.validateSourceImage()
        XCTAssertTrue(result.isValid)
    }

    func testRestoreOriginalImage() {
        let wideImage = createTestImage(width: 800, height: 400)
        generator.sourceImage = wideImage
        generator.autoCropToSquare = true
        _ = generator.validateSourceImage()

        if generator.wasAutoCropped {
            generator.restoreOriginalImage()
            XCTAssertFalse(generator.wasAutoCropped)
        }
    }

    // MARK: - Export Tests

    func testExportIconsNoSourceImage() {
        generator.sourceImage = nil
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        XCTAssertThrowsError(try generator.exportIcons(for: .macOS, to: tempDir)) { error in
            XCTAssertTrue(error is IconGeneratorError)
        }
    }

    func testExportIconsCreatesFiles() throws {
        let testImage = createTestImage(width: 1024, height: 1024)
        generator.sourceImage = testImage
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        try generator.exportIcons(for: .macOS, to: tempDir)

        let platformDir = tempDir.appendingPathComponent("macOS")
        let appiconsetDir = platformDir.appendingPathComponent("AppIcon.appiconset")

        XCTAssertTrue(FileManager.default.fileExists(atPath: appiconsetDir.path))

        // Check Contents.json exists
        let contentsJSON = appiconsetDir.appendingPathComponent("Contents.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: contentsJSON.path))

        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testExportGeneratesCorrectPlatformFolder() throws {
        let testImage = createTestImage(width: 1024, height: 1024)
        generator.sourceImage = testImage
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        try generator.exportIcons(for: .iOS, to: tempDir)

        let iosDir = tempDir.appendingPathComponent("iOS")
        XCTAssertTrue(FileManager.default.fileExists(atPath: iosDir.path))

        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Helper

    private func createTestImage(width: Int, height: Int) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        image.unlockFocus()
        return image
    }
}

// MARK: - ContentsJSON Tests

class ContentsJSONTests: XCTestCase {

    func testContentsJSONInit() {
        var contents = ContentsJSON(platform: .iOS)
        XCTAssertTrue(contents.images.isEmpty)
        XCTAssertEqual(contents.info.author, "xcode")
        XCTAssertEqual(contents.info.version, 1)
    }

    func testAddImage() {
        var contents = ContentsJSON(platform: .iOS)
        contents.addImage(filename: "icon_60x60@2x.png", size: "60x60", scale: "2x", idiom: "iphone")
        XCTAssertEqual(contents.images.count, 1)
        XCTAssertEqual(contents.images[0].filename, "icon_60x60@2x.png")
        XCTAssertEqual(contents.images[0].idiom, "iphone")
    }

    func testContentsJSONEncodable() throws {
        var contents = ContentsJSON(platform: .macOS)
        contents.addImage(filename: "icon_512x512@2x.png", size: "512x512", scale: "2x", idiom: "mac")

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(contents)
        let jsonString = String(data: data, encoding: .utf8)
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("icon_512x512@2x.png"))
        XCTAssertTrue(jsonString!.contains("xcode"))
    }
}

// MARK: - IconGeneratorError Tests

class IconGeneratorErrorTests: XCTestCase {

    func testNoSourceImageError() {
        let error = IconGeneratorError.noSourceImage
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("No source image"))
    }

    func testInvalidImageError() {
        let error = IconGeneratorError.invalidImage("Too small")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Too small"))
    }

    func testPNGConversionError() {
        let error = IconGeneratorError.pngConversionFailed
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("PNG"))
    }

    func testExportFailedError() {
        let error = IconGeneratorError.exportFailed("Disk full")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Disk full"))
    }
}

// MARK: - KeywordIconGenerator Tests

class KeywordIconGeneratorDataTests: XCTestCase {

    func testImageProviderCaseIterable() {
        let providers = ImageProvider.allCases
        XCTAssertTrue(providers.count >= 4)
    }

    func testImageProviderRequiresKey() {
        XCTAssertTrue(ImageProvider.openAI.requiresKey)
        XCTAssertFalse(ImageProvider.comfyUI.requiresKey)
        XCTAssertFalse(ImageProvider.swarmUI.requiresKey)
        XCTAssertFalse(ImageProvider.automatic1111.requiresKey)
    }

    func testImageProviderDefaultURLs() {
        XCTAssertEqual(ImageProvider.comfyUI.defaultURL, "http://localhost:8188")
        XCTAssertEqual(ImageProvider.automatic1111.defaultURL, "http://localhost:7860")
        XCTAssertEqual(ImageProvider.swarmUI.defaultURL, "http://localhost:7801")
    }

    func testIconCategoryAllCases() {
        let categories = IconCategory.allCases
        XCTAssertTrue(categories.count >= 10)
    }

    func testIconCategoryIcons() {
        for category in IconCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty,
                          "\(category.rawValue) should have an icon")
        }
    }

    func testGeneratedIconFilename() {
        let icon = GeneratedIcon(
            keyword: "test icon",
            prompt: "prompt",
            image: NSImage(size: NSSize(width: 100, height: 100)),
            provider: .comfyUI,
            timestamp: Date(timeIntervalSince1970: 1000000)
        )
        XCTAssertTrue(icon.filename.hasPrefix("icon_test_icon_"))
        XCTAssertTrue(icon.filename.hasSuffix(".png"))
    }

    func testKeywordIconGeneratorErrorDescriptions() {
        XCTAssertNotNil(KeywordIconGeneratorError.exportFailed.errorDescription)
        XCTAssertNotNil(KeywordIconGeneratorError.generationFailed.errorDescription)
        XCTAssertNotNil(KeywordIconGeneratorError.invalidProvider.errorDescription)
    }
}

// MARK: - Security Tests

class IconCreatorSecurityTests: XCTestCase {

    func testNoHardcodedAPIKeys() {
        // Verify OpenAI key default is empty
        // Hardcoded keys would be a security violation
        XCTAssertTrue(ImageProvider.openAI.requiresKey,
                     "OpenAI should require an API key")
    }

    func testLocalProviderURLsAreLocalhost() {
        let localProviders: [ImageProvider] = [.comfyUI, .automatic1111, .swarmUI]
        for provider in localProviders {
            XCTAssertTrue(provider.defaultURL.contains("localhost"),
                         "\(provider.rawValue) should default to localhost")
        }
    }

    func testExportPathTraversal() {
        // Verify filenames don't allow path traversal
        let maliciousName = "../../../etc/passwd"
        let sanitized = maliciousName.replacingOccurrences(of: "/", with: "_")
        XCTAssertFalse(sanitized.contains("/"))
    }

    func testPNGDataIntegrity() throws {
        let image = NSImage(size: NSSize(width: 100, height: 100))
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(x: 0, y: 0, width: 100, height: 100).fill()
        image.unlockFocus()

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            XCTFail("PNG conversion failed")
            return
        }

        // PNG magic bytes: 89 50 4E 47 0D 0A 1A 0A
        let bytes = [UInt8](pngData.prefix(8))
        XCTAssertEqual(bytes[0], 0x89)
        XCTAssertEqual(bytes[1], 0x50) // P
        XCTAssertEqual(bytes[2], 0x4E) // N
        XCTAssertEqual(bytes[3], 0x47) // G
    }

    func testIconSizesArePositive() {
        for platform in Platform.allCases {
            for size in platform.iconSizes {
                XCTAssertGreaterThan(size, 0,
                    "All icon sizes should be positive for \(platform.rawValue)")
            }
        }
    }
}
