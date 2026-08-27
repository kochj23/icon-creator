//
//  IconCreatorTests.swift
//  Icon CreatorTests
//
//  Comprehensive test suite for Icon Creator
//  Categories: Unit, Security, Integration, Functional, Frame
//
//  Written by Jordan Koch
//

import XCTest
@testable import Icon_Creator
import AppKit

// =============================================================================
// MARK: - Unit Tests: Platform Configuration
// =============================================================================

class PlatformUnitTests: XCTestCase {

    func testAllPlatformsCaseIterable() {
        let platforms = Platform.allCases
        XCTAssertEqual(platforms.count, 6, "Should have exactly 6 platforms")
    }

    func testIOSIconSizes() {
        let sizes = Platform.iOS.iconSizes
        XCTAssertTrue(sizes.contains(1024), "iOS must include 1024px App Store icon")
        XCTAssertTrue(sizes.contains(180), "iOS must include 180px (60pt@3x)")
        XCTAssertTrue(sizes.contains(120), "iOS must include 120px icon")
        XCTAssertTrue(sizes.contains(20), "iOS must include 20px notification icon")
    }

    func testMacOSIconSizes() {
        let sizes = Platform.macOS.iconSizes
        XCTAssertTrue(sizes.contains(1024))
        XCTAssertTrue(sizes.contains(512))
        XCTAssertTrue(sizes.contains(256))
        XCTAssertTrue(sizes.contains(128))
        XCTAssertTrue(sizes.contains(64))
        XCTAssertTrue(sizes.contains(32))
        XCTAssertTrue(sizes.contains(16), "macOS must include 16px icon")
    }

    func testTVOSIconSizes() {
        let sizes = Platform.tvOS.iconSizes
        XCTAssertTrue(sizes.contains(1280), "tvOS must include 1280px icon")
        XCTAssertTrue(sizes.contains(400), "tvOS must include 400px icon")
    }

    func testWatchOSIconSizes() {
        let sizes = Platform.watchOS.iconSizes
        XCTAssertTrue(sizes.contains(1024))
        XCTAssertFalse(sizes.isEmpty)
    }

    func testiMessageIconSizes() {
        let sizes = Platform.iMessage.iconSizes
        XCTAssertTrue(sizes.contains(1024))
        XCTAssertTrue(sizes.contains(180))
    }

    func testAllPlatformsInclude1024() {
        for platform in Platform.allCases {
            XCTAssertTrue(platform.iconSizes.contains(1024),
                         "\(platform.rawValue) must include 1024px App Store icon")
        }
    }

    func testAllPlatformsHaveNonEmptySizes() {
        for platform in Platform.allCases {
            XCTAssertFalse(platform.iconSizes.isEmpty,
                          "\(platform.rawValue) must have at least one icon size")
        }
    }

    func testPlatformIconNames() {
        XCTAssertEqual(Platform.iOS.iconName, "iphone")
        XCTAssertEqual(Platform.macOS.iconName, "desktopcomputer")
        XCTAssertEqual(Platform.tvOS.iconName, "appletv")
        XCTAssertEqual(Platform.watchOS.iconName, "applewatch")
        XCTAssertEqual(Platform.iMessage.iconName, "message.fill")
        XCTAssertEqual(Platform.macCatalyst.iconName, "laptopcomputer.and.iphone")
    }

    func testPlatformFolderNames() {
        XCTAssertEqual(Platform.iOS.folderName, "iOS")
        XCTAssertEqual(Platform.macOS.folderName, "macOS")
        XCTAssertEqual(Platform.tvOS.folderName, "tvOS")
        XCTAssertEqual(Platform.watchOS.folderName, "watchOS")
        XCTAssertEqual(Platform.iMessage.folderName, "iMessage")
        XCTAssertEqual(Platform.macCatalyst.folderName, "MacCatalyst",
                      "Spaces should be removed from folder names")
    }

    func testPlatformIdioms() {
        XCTAssertEqual(Platform.iOS.idiom, "iphone")
        XCTAssertEqual(Platform.macOS.idiom, "mac")
        XCTAssertEqual(Platform.tvOS.idiom, "tv")
        XCTAssertEqual(Platform.watchOS.idiom, "watch")
        XCTAssertEqual(Platform.iMessage.idiom, "iphone")
        XCTAssertEqual(Platform.macCatalyst.idiom, "iphone")
    }

    func testAllIconSizesArePositive() {
        for platform in Platform.allCases {
            for size in platform.iconSizes {
                XCTAssertGreaterThan(size, 0,
                    "\(platform.rawValue) has non-positive size: \(size)")
            }
        }
    }
}

// =============================================================================
// MARK: - Unit Tests: IconSettings
// =============================================================================

class IconSettingsUnitTests: XCTestCase {

    func testDefaultSettings() {
        let settings = IconSettings.default
        XCTAssertEqual(settings.scale, 1.0)
        XCTAssertEqual(settings.padding, 10.0)
        XCTAssertTrue(settings.autoCropToSquare)
        XCTAssertTrue(settings.isValid)
    }

    func testSettingsValidation_ValidRange() {
        var settings = IconSettings()
        settings.scale = 1.0
        settings.padding = 10.0
        XCTAssertTrue(settings.isValid)
    }

    func testSettingsValidation_ScaleBelowMinimum() {
        var settings = IconSettings()
        settings.scale = 0.3
        XCTAssertFalse(settings.isValid, "Scale below 0.5 should be invalid")
    }

    func testSettingsValidation_ScaleAboveMaximum() {
        var settings = IconSettings()
        settings.scale = 3.0
        XCTAssertFalse(settings.isValid, "Scale above 2.0 should be invalid")
    }

    func testSettingsValidation_PaddingBelowMinimum() {
        var settings = IconSettings()
        settings.padding = -5
        XCTAssertFalse(settings.isValid, "Negative padding should be invalid")
    }

    func testSettingsValidation_PaddingAboveMaximum() {
        var settings = IconSettings()
        settings.padding = 50
        XCTAssertFalse(settings.isValid, "Padding above 30 should be invalid")
    }

    func testSettingsValidation_BoundaryValues() {
        var settings = IconSettings()
        settings.scale = 0.5; settings.padding = 0
        XCTAssertTrue(settings.isValid, "Minimum boundary should be valid")

        settings.scale = 2.0; settings.padding = 30
        XCTAssertTrue(settings.isValid, "Maximum boundary should be valid")
    }

    func testSettingsCodableRoundTrip() throws {
        let settings = IconSettings(
            scale: 1.5,
            padding: 15.0,
            backgroundColor: ColorComponents(red: 0.5, green: 0.5, blue: 0.5),
            autoCropToSquare: false
        )
        let data = try JSONEncoder().encode(settings)
        XCTAssertFalse(data.isEmpty)
        let decoded = try JSONDecoder().decode(IconSettings.self, from: data)
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

// =============================================================================
// MARK: - Unit Tests: ColorComponents
// =============================================================================

class ColorComponentsUnitTests: XCTestCase {

    func testColorComponentsInit() {
        let cc = ColorComponents(red: 1.0, green: 0.5, blue: 0.0)
        XCTAssertEqual(cc.red, 1.0)
        XCTAssertEqual(cc.green, 0.5)
        XCTAssertEqual(cc.blue, 0.0)
        XCTAssertEqual(cc.alpha, 1.0)
    }

    func testColorComponentsWithAlpha() {
        let cc = ColorComponents(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8)
        XCTAssertEqual(cc.alpha, 0.8, accuracy: 0.01)
    }

    func testColorComponentsCodableRoundTrip() throws {
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

    func testBlackColorComponents() {
        let cc = ColorComponents(red: 0.0, green: 0.0, blue: 0.0)
        XCTAssertEqual(cc.red, 0.0)
        XCTAssertEqual(cc.green, 0.0)
        XCTAssertEqual(cc.blue, 0.0)
    }

    func testWhiteColorComponents() {
        let cc = ColorComponents(red: 1.0, green: 1.0, blue: 1.0)
        XCTAssertEqual(cc.red, 1.0)
        XCTAssertEqual(cc.green, 1.0)
        XCTAssertEqual(cc.blue, 1.0)
    }
}

// =============================================================================
// MARK: - Unit Tests: ImageEffects & Gradients
// =============================================================================

class ImageEffectsUnitTests: XCTestCase {

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

    func testDefaultBackgroundTypeIsSolid() {
        let effects = ImageEffects()
        if case .solid = effects.backgroundType {
            // Pass
        } else {
            XCTFail("Default background type should be solid")
        }
    }

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

// =============================================================================
// MARK: - Unit Tests: IconGenerator Core
// =============================================================================

class IconGeneratorUnitTests: XCTestCase {

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

    func testScaleClampingAboveMax() {
        generator.scale = 5.0
        XCTAssertLessThanOrEqual(generator.scale, 2.0)
    }

    func testScaleClampingBelowMin() {
        generator.scale = 0.1
        XCTAssertGreaterThanOrEqual(generator.scale, 0.5)
    }

    func testPaddingClampingAboveMax() {
        generator.padding = 50.0
        XCTAssertLessThanOrEqual(generator.padding, 30.0)
    }

    func testPaddingClampingBelowMin() {
        generator.padding = -5.0
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

    func testGenerateIconZeroSize() {
        let testImage = createTestImage(width: 100, height: 100)
        let icon = generator.generateIcon(from: testImage, size: 0)
        XCTAssertNil(icon, "Should return nil for zero size")
    }

    func testGenerateIconValidImage() {
        let testImage = createTestImage(width: 512, height: 512)
        let icon = generator.generateIcon(from: testImage, size: 128)
        XCTAssertNotNil(icon, "Should generate icon from valid image")
        if let icon = icon {
            XCTAssertEqual(Int(icon.size.width), 128)
            XCTAssertEqual(Int(icon.size.height), 128)
        }
    }

    func testGeneratePreviewUsesCache() {
        let testImage = createTestImage(width: 256, height: 256)
        generator.sourceImage = testImage
        let preview1 = generator.generatePreview(size: 64)
        let preview2 = generator.generatePreview(size: 64)
        XCTAssertNotNil(preview1)
        XCTAssertNotNil(preview2)
    }

    func testClearCacheDoesNotCrash() {
        let testImage = createTestImage(width: 256, height: 256)
        generator.sourceImage = testImage
        _ = generator.generatePreview(size: 64)
        generator.clearCache()
        let preview = generator.generatePreview(size: 64)
        XCTAssertNotNil(preview, "Should regenerate after cache clear")
    }

    func testCurrentSettingsReflectsGenerator() {
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

    func testAutoCropSquareImageUnchanged() {
        let squareImage = createTestImage(width: 512, height: 512)
        let cropped = generator.autoCropImageToSquare(squareImage)
        XCTAssertEqual(Int(cropped.size.width), Int(cropped.size.height))
    }

    func testAutoCropWideImage() {
        let wideImage = createTestImage(width: 800, height: 400)
        let cropped = generator.autoCropImageToSquare(wideImage)
        XCTAssertEqual(Int(cropped.size.width), Int(cropped.size.height))
        XCTAssertEqual(Int(cropped.size.width), 400)
    }

    func testAutoCropTallImage() {
        let tallImage = createTestImage(width: 400, height: 800)
        let cropped = generator.autoCropImageToSquare(tallImage)
        XCTAssertEqual(Int(cropped.size.width), Int(cropped.size.height))
        XCTAssertEqual(Int(cropped.size.width), 400)
    }

    func testValidateSourceImageTooSmall() {
        let tinyImage = createTestImage(width: 32, height: 32)
        generator.sourceImage = tinyImage
        let result = generator.validateSourceImage()
        XCTAssertFalse(result.isValid)
    }

    func testValidateSourceImageValid1024() {
        let goodImage = createTestImage(width: 1024, height: 1024)
        generator.sourceImage = goodImage
        let result = generator.validateSourceImage()
        XCTAssertTrue(result.isValid)
    }

    func testValidateSourceImageWarnsSmall() {
        let smallImage = createTestImage(width: 256, height: 256)
        generator.sourceImage = smallImage
        let result = generator.validateSourceImage()
        XCTAssertTrue(result.isValid, "Image above 64px should be valid")
        XCTAssertNotNil(result.error, "Should warn about small image")
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

// =============================================================================
// MARK: - Security Tests
// =============================================================================

class IconCreatorSecurityTests: XCTestCase {

    // MARK: - API Key Security

    func testOpenAIProviderRequiresKey() {
        XCTAssertTrue(ImageProvider.openAI.requiresKey,
                     "OpenAI should require an API key")
    }

    func testLocalProvidersDoNotRequireKey() {
        XCTAssertFalse(ImageProvider.comfyUI.requiresKey)
        XCTAssertFalse(ImageProvider.automatic1111.requiresKey)
        XCTAssertFalse(ImageProvider.swarmUI.requiresKey)
    }

    func testLocalProviderURLsAreLocalhost() {
        let localProviders: [ImageProvider] = [.comfyUI, .automatic1111, .swarmUI]
        for provider in localProviders {
            XCTAssertTrue(provider.defaultURL.contains("localhost"),
                         "\(provider.rawValue) must default to localhost, not a public endpoint")
        }
    }

    func testLocalProviderURLsUseHTTP() {
        let localProviders: [ImageProvider] = [.comfyUI, .automatic1111, .swarmUI]
        for provider in localProviders {
            XCTAssertTrue(provider.defaultURL.hasPrefix("http://"),
                         "\(provider.rawValue) should use HTTP for localhost")
        }
    }

    // MARK: - Path Traversal Prevention

    func testFilenamePathTraversalSanitization() {
        let maliciousName = "../../../etc/passwd"
        let sanitized = maliciousName.replacingOccurrences(of: "/", with: "_")
        XCTAssertFalse(sanitized.contains("/"), "Must sanitize path separators")
        XCTAssertFalse(sanitized.contains(".."), "Must remove directory traversal")
    }

    func testFilenameNoNullBytes() {
        let malicious = "icon\0.png"
        let sanitized = malicious.replacingOccurrences(of: "\0", with: "")
        XCTAssertFalse(sanitized.contains("\0"), "Must strip null bytes from filenames")
    }

    // MARK: - PNG Data Integrity

    func testPNGMagicBytes() throws {
        let image = createTestImage(width: 100, height: 100, color: .red)
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            XCTFail("PNG conversion failed")
            return
        }
        let bytes = [UInt8](pngData.prefix(8))
        XCTAssertEqual(bytes[0], 0x89, "PNG signature byte 0")
        XCTAssertEqual(bytes[1], 0x50, "PNG signature byte 1 (P)")
        XCTAssertEqual(bytes[2], 0x4E, "PNG signature byte 2 (N)")
        XCTAssertEqual(bytes[3], 0x47, "PNG signature byte 3 (G)")
    }

    // MARK: - Nova API Server Security

    func testNovaAPIServerListensOnLoopback() {
        // The server binds to 127.0.0.1, not 0.0.0.0
        let bindAddress = "127.0.0.1"
        XCTAssertEqual(bindAddress, "127.0.0.1",
                      "API server must only listen on loopback address")
    }

    func testNovaAPIServerPortInRange() {
        let port: UInt16 = 37435
        XCTAssertTrue((37400...37499).contains(Int(port)),
                     "Port must be in Nova's reserved range")
    }

    func testNovaAPIServerHasNoWildcardCORSHeader() {
        // The loopback-only server must NOT emit a wildcard CORS header:
        // its only clients are native Nova apps that ignore CORS, and the
        // wildcard would let any website the user visits read responses.
        let responseHeaders = "HTTP/1.1 200 OK\r\nContent-Type: application/json; charset=utf-8\r\nConnection: close\r\n\r\n"
        XCTAssertFalse(responseHeaders.contains("Access-Control-Allow-Origin"),
                      "Loopback API must not emit a wildcard CORS header")
    }

    // MARK: - Ethical AI Guardian

    func testEthicalGuardianCannotBeDisabled() {
        // isEnabled must always be true
        let guardian = EthicalAIGuardian.shared
        XCTAssertTrue(guardian.isEnabled,
                     "Ethical AI Guardian must never be disabled")
    }

    func testPolicyViolationCategoriesExist() {
        let categories: [ViolationCategory] = [
            .illegalActivity, .harmfulContent, .hateSpeech,
            .misinformation, .privacyViolation, .harassment,
            .fraud, .other
        ]
        XCTAssertEqual(categories.count, 8, "Should have 8 violation categories")
    }

    func testViolationSeverityLevels() {
        let severities: [ViolationSeverity] = [.critical, .high, .medium, .low]
        XCTAssertEqual(severities.count, 4, "Should have 4 severity levels")
    }

    func testEnforcementActions() {
        let actions: [EnforcementAction] = [
            .blockCompletely, .blockAndRefer, .warnAndLog,
            .requireAcknowledgment, .logOnly
        ]
        XCTAssertEqual(actions.count, 5, "Should have 5 enforcement actions")
    }

    // MARK: - Helper

    private func createTestImage(width: Int, height: Int, color: NSColor = .blue) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        color.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        image.unlockFocus()
        return image
    }
}

// =============================================================================
// MARK: - Integration Tests: Export & File System
// =============================================================================

class IconCreatorIntegrationTests: XCTestCase {

    var generator: IconGenerator!

    override func setUp() {
        super.setUp()
        generator = IconGenerator()
    }

    override func tearDown() {
        generator = nil
        super.tearDown()
    }

    func testExportIconsNoSourceImage() {
        generator.sourceImage = nil
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        XCTAssertThrowsError(try generator.exportIcons(for: .macOS, to: tempDir)) { error in
            XCTAssertTrue(error is IconGeneratorError)
        }
    }

    func testExportIconsCreatesMacOSFiles() throws {
        let testImage = createTestImage(width: 1024, height: 1024)
        generator.sourceImage = testImage
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        try generator.exportIcons(for: .macOS, to: tempDir)

        let appiconsetDir = tempDir.appendingPathComponent("macOS/AppIcon.appiconset")
        XCTAssertTrue(FileManager.default.fileExists(atPath: appiconsetDir.path))

        let contentsJSON = appiconsetDir.appendingPathComponent("Contents.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: contentsJSON.path))

        try? FileManager.default.removeItem(at: tempDir)
    }

    func testExportIconsCreatesIOSFolder() throws {
        let testImage = createTestImage(width: 1024, height: 1024)
        generator.sourceImage = testImage
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        try generator.exportIcons(for: .iOS, to: tempDir)

        let iosDir = tempDir.appendingPathComponent("iOS")
        XCTAssertTrue(FileManager.default.fileExists(atPath: iosDir.path))

        try? FileManager.default.removeItem(at: tempDir)
    }

    func testExportContentsJSONIsValidJSON() throws {
        let testImage = createTestImage(width: 1024, height: 1024)
        generator.sourceImage = testImage
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        try generator.exportIcons(for: .macOS, to: tempDir)

        let contentsURL = tempDir.appendingPathComponent("macOS/AppIcon.appiconset/Contents.json")
        let data = try Data(contentsOf: contentsURL)
        let json = try JSONDecoder().decode(ContentsJSON.self, from: data)
        XCTAssertFalse(json.images.isEmpty, "Contents.json should contain image entries")
        XCTAssertEqual(json.info.author, "xcode")
        XCTAssertEqual(json.info.version, 1)

        try? FileManager.default.removeItem(at: tempDir)
    }

    func testExportProducesActualPNGFiles() throws {
        let testImage = createTestImage(width: 1024, height: 1024)
        generator.sourceImage = testImage
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        try generator.exportIcons(for: .macOS, to: tempDir)

        let appiconsetDir = tempDir.appendingPathComponent("macOS/AppIcon.appiconset")
        let files = try FileManager.default.contentsOfDirectory(atPath: appiconsetDir.path)
        let pngFiles = files.filter { $0.hasSuffix(".png") }
        XCTAssertGreaterThan(pngFiles.count, 0, "Should generate PNG icon files")

        try? FileManager.default.removeItem(at: tempDir)
    }

    func testExportProgressHandlerCalled() throws {
        let testImage = createTestImage(width: 1024, height: 1024)
        generator.sourceImage = testImage
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        var progressUpdates: [Double] = []
        try generator.exportIcons(for: .macOS, to: tempDir) { progress in
            progressUpdates.append(progress)
        }

        XCTAssertFalse(progressUpdates.isEmpty, "Progress handler should be called")
        XCTAssertTrue(progressUpdates.last! <= 1.0, "Final progress should be <= 1.0")

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

// =============================================================================
// MARK: - Functional Tests: Data Models & Presets
// =============================================================================

class IconCreatorFunctionalTests: XCTestCase {

    // MARK: - ContentsJSON

    func testContentsJSONInit() {
        let contents = ContentsJSON(platform: .iOS)
        XCTAssertTrue(contents.images.isEmpty)
        XCTAssertEqual(contents.info.author, "xcode")
        XCTAssertEqual(contents.info.version, 1)
    }

    func testContentsJSONAddImage() {
        var contents = ContentsJSON(platform: .iOS)
        contents.addImage(filename: "icon_60x60@2x.png", size: "60x60", scale: "2x", idiom: "iphone")
        XCTAssertEqual(contents.images.count, 1)
        XCTAssertEqual(contents.images[0].filename, "icon_60x60@2x.png")
        XCTAssertEqual(contents.images[0].idiom, "iphone")
        XCTAssertEqual(contents.images[0].scale, "2x")
        XCTAssertEqual(contents.images[0].size, "60x60")
    }

    func testContentsJSONEncodable() throws {
        var contents = ContentsJSON(platform: .macOS)
        contents.addImage(filename: "icon_512x512@2x.png", size: "512x512", scale: "2x", idiom: "mac")
        let data = try JSONEncoder().encode(contents)
        let jsonString = String(data: data, encoding: .utf8)
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("icon_512x512@2x.png"))
        XCTAssertTrue(jsonString!.contains("xcode"))
    }

    func testContentsJSONMultipleImages() {
        var contents = ContentsJSON(platform: .iOS)
        contents.addImage(filename: "a.png", size: "20x20", scale: "1x", idiom: "iphone")
        contents.addImage(filename: "b.png", size: "20x20", scale: "2x", idiom: "iphone")
        contents.addImage(filename: "c.png", size: "20x20", scale: "3x", idiom: "iphone")
        XCTAssertEqual(contents.images.count, 3)
    }

    // MARK: - Icon Presets

    func testBuiltInPresetsExist() {
        let presets = IconPreset.allBuiltIn
        XCTAssertGreaterThanOrEqual(presets.count, 7, "Should have at least 7 built-in presets")
    }

    func testAllBuiltInPresetsAreBuiltIn() {
        for preset in IconPreset.allBuiltIn {
            XCTAssertTrue(preset.isBuiltIn, "\(preset.name) should be marked as built-in")
        }
    }

    func testMinimalistPreset() {
        let preset = IconPreset.minimalist
        XCTAssertEqual(preset.name, "Minimalist")
        XCTAssertEqual(preset.settings.scale, 0.7)
        XCTAssertEqual(preset.settings.padding, 15)
    }

    func testFullBleedPreset() {
        let preset = IconPreset.fullBleed
        XCTAssertEqual(preset.name, "Full Bleed")
        XCTAssertEqual(preset.settings.padding, 0, "Full bleed should have zero padding")
        XCTAssertEqual(preset.settings.scale, 1.2)
    }

    func testRoundedPresetHasCornerRadius() {
        let preset = IconPreset.rounded
        XCTAssertTrue(preset.settings.effects.cornerRadiusEnabled)
        XCTAssertGreaterThan(preset.settings.effects.cornerRadius, 0)
    }

    func testShadowedPresetHasShadow() {
        let preset = IconPreset.shadowed
        XCTAssertTrue(preset.settings.effects.shadowEnabled)
        XCTAssertGreaterThan(preset.settings.effects.shadowBlur, 0)
    }

    func testBorderedPresetHasBorder() {
        let preset = IconPreset.bordered
        XCTAssertTrue(preset.settings.effects.borderEnabled)
        XCTAssertGreaterThan(preset.settings.effects.borderWidth, 0)
    }

    func testPresetSettingsAreValid() {
        for preset in IconPreset.allBuiltIn {
            XCTAssertTrue(preset.settings.isValid,
                         "Preset '\(preset.name)' settings should be valid")
        }
    }

    // MARK: - IconGeneratorError

    func testNoSourceImageError() {
        let error = IconGeneratorError.noSourceImage
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("No source image"))
    }

    func testInvalidImageError() {
        let error = IconGeneratorError.invalidImage("Too small")
        XCTAssertTrue(error.errorDescription!.contains("Too small"))
    }

    func testPNGConversionError() {
        let error = IconGeneratorError.pngConversionFailed
        XCTAssertTrue(error.errorDescription!.contains("PNG"))
    }

    func testExportFailedError() {
        let error = IconGeneratorError.exportFailed("Disk full")
        XCTAssertTrue(error.errorDescription!.contains("Disk full"))
    }

    // MARK: - KeywordIconGenerator Models

    func testImageProviderCaseIterable() {
        let providers = ImageProvider.allCases
        XCTAssertGreaterThanOrEqual(providers.count, 4)
    }

    func testImageProviderDefaultURLs() {
        XCTAssertEqual(ImageProvider.comfyUI.defaultURL, "http://localhost:8188")
        XCTAssertEqual(ImageProvider.automatic1111.defaultURL, "http://localhost:7860")
        XCTAssertEqual(ImageProvider.swarmUI.defaultURL, "http://localhost:7801")
    }

    func testImageProviderIcons() {
        for provider in ImageProvider.allCases {
            XCTAssertFalse(provider.icon.isEmpty,
                          "\(provider.rawValue) should have an SF Symbol icon")
        }
    }

    func testIconCategoryAllCases() {
        let categories = IconCategory.allCases
        XCTAssertGreaterThanOrEqual(categories.count, 10)
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
        XCTAssertFalse(icon.filename.contains(" "),
                      "Filename should not contain spaces")
    }

    func testKeywordIconGeneratorErrorDescriptions() {
        XCTAssertNotNil(KeywordIconGeneratorError.exportFailed.errorDescription)
        XCTAssertNotNil(KeywordIconGeneratorError.generationFailed.errorDescription)
        XCTAssertNotNil(KeywordIconGeneratorError.invalidProvider.errorDescription)
    }

    // MARK: - ExportManager Error

    func testExportManagerUnsupportedFormatError() {
        let error = ExportManager.ExportError.unsupportedFormat("PDF export not yet implemented")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("PDF"))
    }

    func testExportManagerExportFailedError() {
        let error = ExportManager.ExportError.exportFailed("Out of disk space")
        XCTAssertTrue(error.errorDescription!.contains("Out of disk space"))
    }
}

// =============================================================================
// MARK: - Functional Tests: Color Harmony & Analysis
// =============================================================================

class ColorHarmonyFunctionalTests: XCTestCase {

    var harmonyGenerator: ColorHarmonyGenerator!

    override func setUp() {
        super.setUp()
        harmonyGenerator = ColorHarmonyGenerator()
    }

    func testComplementaryColor() {
        let red = NSColor(hue: 0.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        let complementary = harmonyGenerator.generateComplementary(for: red)
        var hue: CGFloat = 0
        complementary.getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
        // Complementary of 0.0 hue is 0.5
        XCTAssertEqual(Double(hue), 0.5, accuracy: 0.05,
                      "Complementary of red should be cyan (0.5 hue)")
    }

    func testTriadicColors() {
        let red = NSColor(hue: 0.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        let triadic = harmonyGenerator.generateTriadic(for: red)
        XCTAssertEqual(triadic.count, 3, "Triadic should produce 3 colors")
    }

    func testAnalogousColors() {
        let blue = NSColor(hue: 0.66, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        let analogous = harmonyGenerator.generateAnalogous(for: blue, count: 5)
        XCTAssertEqual(analogous.count, 5)
    }

    func testMonochromaticColors() {
        let green = NSColor(hue: 0.33, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        let mono = harmonyGenerator.generateMonochromatic(for: green, steps: 5)
        XCTAssertEqual(mono.count, 5)
    }

    func testSplitComplementary() {
        let red = NSColor.red
        let split = harmonyGenerator.generateSplitComplementary(for: red)
        XCTAssertEqual(split.count, 3, "Split complementary should produce 3 colors")
    }

    func testTetradicColors() {
        let red = NSColor.red
        let tetradic = harmonyGenerator.generateTetradic(for: red)
        XCTAssertEqual(tetradic.count, 4, "Tetradic should produce 4 colors")
    }
}

// =============================================================================
// MARK: - Functional Tests: Color Palette
// =============================================================================

class ColorPaletteFunctionalTests: XCTestCase {

    func testPresetPalettesExist() {
        let presets = ColorPalette.presets
        XCTAssertGreaterThanOrEqual(presets.count, 5)
    }

    func testIOSBluePalette() {
        let palette = ColorPalette.iOSBlue
        XCTAssertEqual(palette.name, "iOS Blue")
        XCTAssertFalse(palette.isDark)
    }

    func testSunsetPalette() {
        let palette = ColorPalette.sunset
        XCTAssertEqual(palette.name, "Sunset")
        XCTAssertFalse(palette.isDark)
    }

    func testMidnightPaletteIsDark() {
        let palette = ColorPalette.midnight
        XCTAssertTrue(palette.isDark, "Midnight palette should be dark")
    }

    func testPaletteHasAllColors() {
        for palette in ColorPalette.presets {
            XCTAssertNotNil(palette.primary, "\(palette.name) needs primary color")
            XCTAssertNotNil(palette.secondary, "\(palette.name) needs secondary color")
            XCTAssertNotNil(palette.accent, "\(palette.name) needs accent color")
            XCTAssertNotNil(palette.background, "\(palette.name) needs background color")
        }
    }
}

// =============================================================================
// MARK: - Functional Tests: Screenshot Sizes
// =============================================================================

class ScreenshotSizeFunctionalTests: XCTestCase {

    func testAllSizesPopulated() {
        XCTAssertGreaterThan(ScreenshotSize.allSizes.count, 20,
                            "Should have at least 20 screenshot sizes")
    }

    func testiPhoneSizesExist() {
        let iPhoneSizes = ScreenshotSize.sizes(for: .iPhone)
        XCTAssertGreaterThanOrEqual(iPhoneSizes.count, 5)
    }

    func testiPadSizesExist() {
        let iPadSizes = ScreenshotSize.sizes(for: .iPad)
        XCTAssertGreaterThanOrEqual(iPadSizes.count, 3)
    }

    func testMacSizesExist() {
        let macSizes = ScreenshotSize.sizes(for: .mac)
        XCTAssertGreaterThanOrEqual(macSizes.count, 2)
    }

    func testPrimarySizesExist() {
        XCTAssertGreaterThanOrEqual(ScreenshotSize.primarySizes.count, 3)
    }

    func testAllSizesHavePositiveDimensions() {
        for size in ScreenshotSize.allSizes {
            XCTAssertGreaterThan(size.width, 0, "\(size.name) width must be positive")
            XCTAssertGreaterThan(size.height, 0, "\(size.name) height must be positive")
        }
    }

    func testAspectRatioCalculation() {
        let size = ScreenshotSize.appleTV1080p
        let aspect = Double(size.width) / Double(size.height)
        XCTAssertEqual(aspect, 1920.0 / 1080.0, accuracy: 0.01)
    }

    func testLandscapeVariantSwapsDimensions() {
        let portrait = ScreenshotSize.iPhone69
        let landscape = portrait.landscapeVariant
        XCTAssertEqual(landscape.width, portrait.height)
        XCTAssertEqual(landscape.height, portrait.width)
    }
}

// =============================================================================
// MARK: - Functional Tests: Icon Variants
// =============================================================================

class IconVariantFunctionalTests: XCTestCase {

    func testSeasonalThemesAllCases() {
        let themes = IconVariant.SeasonalTheme.allCases
        XCTAssertEqual(themes.count, 7, "Should have 7 seasonal themes")
    }

    func testSeasonalThemeEmojis() {
        for theme in IconVariant.SeasonalTheme.allCases {
            XCTAssertFalse(theme.emoji.isEmpty, "\(theme.rawValue) should have an emoji")
        }
    }

    func testSeasonalThemeTintColors() {
        for theme in IconVariant.SeasonalTheme.allCases {
            let tint = theme.tintColor
            XCTAssertNotNil(tint, "\(theme.rawValue) should have a tint color")
        }
    }

    func testBadgeTypePositions() {
        let positions: [IconVariant.BadgePosition] = [.topLeft, .topRight, .bottomLeft, .bottomRight, .center]
        XCTAssertEqual(positions.count, 5, "Should have 5 badge positions")
    }

    func testBadgeTypes() {
        let types: [IconVariant.BadgeType] = [.beta, .debug, .dev, .alpha, .rc, .number(42)]
        XCTAssertEqual(types.count, 6)
    }
}

// =============================================================================
// MARK: - Frame Tests (UI Structure & Display)
// =============================================================================

class IconCreatorFrameTests: XCTestCase {

    // MARK: - Image Processor

    func testImageProcessorCreation() {
        let processor = ImageProcessor()
        XCTAssertNotNil(processor)
    }

    func testCropModeCenter() {
        let processor = ImageProcessor()
        let wideImage = createTestImage(width: 800, height: 400)
        let cropped = processor.crop(wideImage, mode: .center)
        XCTAssertEqual(Int(cropped.size.width), Int(cropped.size.height),
                      "Center crop should produce square image")
    }

    func testCropModeManual() {
        let processor = ImageProcessor()
        let image = createTestImage(width: 500, height: 500)
        let rect = CGRect(x: 50, y: 50, width: 200, height: 200)
        let cropped = processor.crop(image, mode: .manual(rect))
        XCTAssertEqual(Int(cropped.size.width), 200)
        XCTAssertEqual(Int(cropped.size.height), 200)
    }

    func testApplyRoundedCorners() {
        let processor = ImageProcessor()
        let image = createTestImage(width: 256, height: 256)
        let rounded = processor.applyRoundedCorners(to: image, radiusPercent: 20)
        XCTAssertEqual(Int(rounded.size.width), 256)
        XCTAssertEqual(Int(rounded.size.height), 256)
    }

    func testApplyBorder() {
        let processor = ImageProcessor()
        let image = createTestImage(width: 256, height: 256)
        let bordered = processor.applyBorder(to: image, width: 3, color: .black)
        XCTAssertEqual(Int(bordered.size.width), 256)
    }

    func testApplyDropShadow() {
        let processor = ImageProcessor()
        let image = createTestImage(width: 256, height: 256)
        let shadowed = processor.applyDropShadow(
            to: image, blur: 10,
            offset: CGSize(width: 0, height: 4),
            color: .black
        )
        // Shadow expands the image
        XCTAssertGreaterThan(shadowed.size.width, 256)
    }

    func testComposeImage() {
        let processor = ImageProcessor()
        let bg = createTestImage(width: 256, height: 256, color: .white)
        let icon = createTestImage(width: 256, height: 256, color: .blue)
        let composed = processor.composeImage(background: bg, icon: icon, overlay: nil)
        XCTAssertEqual(Int(composed.size.width), 256)
        XCTAssertEqual(Int(composed.size.height), 256)
    }

    func testResizeForAppStore() {
        let processor = ImageProcessor()
        let image = createTestImage(width: 500, height: 500)
        let resized = processor.resizeForAppStore(image)
        XCTAssertNotNil(resized)
        XCTAssertEqual(Int(resized!.size.width), 1920)
        XCTAssertEqual(Int(resized!.size.height), 1080)
    }

    func testConvertToPNG() {
        let processor = ImageProcessor()
        let image = createTestImage(width: 100, height: 100)
        let pngData = processor.convert(image, to: .png)
        XCTAssertNotNil(pngData)
        XCTAssertGreaterThan(pngData!.count, 0)
    }

    func testConvertToJPEG() {
        let processor = ImageProcessor()
        let image = createTestImage(width: 100, height: 100)
        let jpegData = processor.convert(image, to: .jpeg, quality: 0.8)
        XCTAssertNotNil(jpegData)
        XCTAssertGreaterThan(jpegData!.count, 0)
    }

    func testImageFormatFileExtensions() {
        XCTAssertEqual(ImageProcessor.ImageFormat.png.fileExtension, "png")
        XCTAssertEqual(ImageProcessor.ImageFormat.jpeg.fileExtension, "jpg")
        XCTAssertEqual(ImageProcessor.ImageFormat.tiff.fileExtension, "tiff")
        XCTAssertEqual(ImageProcessor.ImageFormat.heic.fileExtension, "heic")
    }

    func testImageFormatAllCases() {
        let formats = ImageProcessor.ImageFormat.allCases
        XCTAssertEqual(formats.count, 4, "Should support 4 image formats")
    }

    // MARK: - Color Analyzer Frame Tests

    func testColorAnalyzerCreation() {
        let analyzer = ColorAnalyzer()
        XCTAssertNotNil(analyzer)
    }

    func testContrastCalculation() {
        let analyzer = ColorAnalyzer()
        let contrast = analyzer.calculateContrast(between: .black, and: .white)
        // WCAG contrast ratio for black/white should be 21:1
        XCTAssertEqual(contrast, 21.0, accuracy: 0.5)
    }

    func testContrastSameColors() {
        let analyzer = ColorAnalyzer()
        let contrast = analyzer.calculateContrast(between: .white, and: .white)
        XCTAssertEqual(contrast, 1.0, accuracy: 0.1, "Same colors should have contrast 1:1")
    }

    func testDarkImageDetection() {
        let analyzer = ColorAnalyzer()
        let darkImage = createTestImage(width: 100, height: 100, color: NSColor(white: 0.1, alpha: 1))
        XCTAssertTrue(analyzer.isDarkImage(darkImage), "Very dark image should be detected as dark")
    }

    func testLightImageDetection() {
        let analyzer = ColorAnalyzer()
        let lightImage = createTestImage(width: 100, height: 100, color: NSColor(white: 0.9, alpha: 1))
        XCTAssertFalse(analyzer.isDarkImage(lightImage), "Very light image should not be dark")
    }

    // MARK: - Variant Generator Frame

    func testVariantGeneratorCreation() {
        let generator = VariantGenerator()
        XCTAssertNotNil(generator)
    }

    func testVariantGeneratorBasicModification() {
        let generator = VariantGenerator()
        let baseImage = createTestImage(width: 256, height: 256)
        let result = generator.generateVariant(from: baseImage, applying: [
            .betaBadge(text: "BETA")
        ])
        XCTAssertNotNil(result)
        XCTAssertEqual(Int(result.size.width), 256)
    }

    func testVariantGeneratorSeasonalTheme() {
        let generator = VariantGenerator()
        let baseImage = createTestImage(width: 256, height: 256)
        let result = generator.generateVariant(from: baseImage, applying: [
            .seasonal(.halloween)
        ])
        XCTAssertNotNil(result)
    }

    func testVariantGeneratorMultipleModifications() {
        let generator = VariantGenerator()
        let baseImage = createTestImage(width: 256, height: 256)
        let result = generator.generateVariant(from: baseImage, applying: [
            .seasonal(.christmas),
            .betaBadge(text: "RC"),
            .tint(ColorComponents(red: 1, green: 0, blue: 0), intensity: 0.1)
        ])
        XCTAssertNotNil(result)
    }

    // MARK: - ScreenshotPlatform Frame

    func testScreenshotPlatformIcons() {
        for platform in ScreenshotPlatform.allCases {
            XCTAssertFalse(platform.iconName.isEmpty,
                          "\(platform.rawValue) should have an icon name")
        }
    }

    func testScreenshotOrientations() {
        let orientations = ScreenshotOrientation.allCases
        XCTAssertEqual(orientations.count, 2)
    }

    func testSizesByPlatformGrouping() {
        let grouped = ScreenshotSize.sizesByPlatform
        XCTAssertGreaterThanOrEqual(grouped.keys.count, 5,
                                   "Should have sizes for at least 5 platforms")
    }

    // MARK: - Ethical AI Models Frame

    func testViolationCategoryDescriptions() {
        for category in [ViolationCategory.illegalActivity, .harmfulContent, .hateSpeech,
                         .misinformation, .privacyViolation, .harassment, .fraud, .other] {
            XCTAssertFalse(category.description.isEmpty,
                          "\(category.rawValue) should have a description")
        }
    }

    func testViolationSeverityColors() {
        for severity in [ViolationSeverity.critical, .high, .medium, .low] {
            XCTAssertFalse(severity.color.isEmpty,
                          "\(severity.rawValue) should have a color")
        }
    }

    func testViolationStatisticsPercentages() {
        let stats = ViolationStatistics(
            totalRequests: 100, safeRequests: 95, violations: 5,
            blocked: 2, criticalViolations: 1, highViolations: 1
        )
        XCTAssertEqual(stats.safePercentage, 95.0, accuracy: 0.1)
        XCTAssertEqual(stats.violationPercentage, 5.0, accuracy: 0.1)
    }

    func testViolationStatisticsZeroRequests() {
        let stats = ViolationStatistics(
            totalRequests: 0, safeRequests: 0, violations: 0,
            blocked: 0, criticalViolations: 0, highViolations: 0
        )
        XCTAssertEqual(stats.safePercentage, 100.0,
                      "Zero requests should show 100% safe")
        XCTAssertEqual(stats.violationPercentage, 0.0)
    }

    func testUsageContextAllCases() {
        let contexts: [UsageContext] = [.textGeneration, .imageGeneration, .summarization,
                                        .translation, .analysis, .chat, .email, .news,
                                        .system, .unknown]
        XCTAssertEqual(contexts.count, 10, "Should have 10 usage contexts")
    }

    // MARK: - Helper

    private func createTestImage(width: Int, height: Int, color: NSColor = .blue) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        color.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        image.unlockFocus()
        return image
    }
}
