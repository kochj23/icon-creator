//
//  IconScalingTests.swift
//  Icon CreatorTests
//
//  Regression + full-grid coverage for the scale / padding render path.
//
//  Root cause locked by this suite (GitHub issue #1, reporter MadMacMad, v2.5.2):
//
//  PRIMARY (the crash): the `scale` and `padding` @Published property observers
//  reassigned themselves unconditionally inside their own didSet. Writing back to
//  a @Published property from within its didSet re-enters the setter on EVERY set,
//  recursing without bound — the crash reports show padding.didSet -> setter ->
//  didSet nested 43,000+ deep, a stack overflow (SIGSEGV). So the instant the
//  scale or padding slider moved, the app crashed. Fixed by guarding the write-back
//  (`if value != clamped { value = clamped }`) which bounds recursion to depth 2.
//
//  SECONDARY (a blank preview, not the crash): generateIcon(from:size:) rejected
//  ALL upscaling with an upper-bound guard `scaledSize <= targetSize`, so scale>1.0
//  at low padding returned nil and blanked the preview. The render canvas is always
//  targetSize×targetSize and drawing a larger destRect legally clips, so the upper
//  bound was wrong; it now only rejects non-positive / non-finite geometry.
//
//  These tests reproduce both and lock the fixes.
//
//  Categories: Unit, Integration, Functional, Security, Performance, Retry, Frame
//
//  Written by Jordan Koch
//

import XCTest
@testable import Icon_Creator
import AppKit

// =============================================================================
// MARK: - Shared Helpers
// =============================================================================

private enum ScalingTestSupport {
    /// The full slider grid exercised across the suite.
    static let scales: [Double]   = [0.5, 1.0, 1.5, 2.0]
    static let paddings: [Double] = [0.0, 10.0, 20.0, 30.0]
    static let sizes: [Int]       = [16, 512, 1024]

    /// A synthetic opaque square image, standing in for a user-supplied PNG.
    static func makeImage(width: Int, height: Int, color: NSColor = .systemBlue) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        color.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        image.unlockFocus()
        return image
    }

    /// A 1024×1024 image — exactly the input from the bug report.
    static func make1024() -> NSImage {
        return makeImage(width: 1024, height: 1024)
    }
}

// =============================================================================
// MARK: - Unit Tests: Scaling / Padding Grid (Regression Lock)
// =============================================================================

class IconScalingUnitTests: XCTestCase {

    var generator: IconGenerator!
    let source = ScalingTestSupport.make1024()

    override func setUp() {
        super.setUp()
        generator = IconGenerator()
    }

    override func tearDown() {
        generator = nil
        super.tearDown()
    }

    /// THE regression lock. Every scale×padding×size combination must produce a
    /// valid image of the requested pixel size. Fails against the old
    /// `scaledSize <= targetSize` guard for every scale>1.0 / low-padding cell,
    /// which returned nil.
    func testFullGridReturnsValidImages() {
        for scale in ScalingTestSupport.scales {
            for padding in ScalingTestSupport.paddings {
                generator.scale = scale
                generator.padding = padding
                for size in ScalingTestSupport.sizes {
                    let icon = generator.generateIcon(from: source, size: size)
                    XCTAssertNotNil(icon,
                        "generateIcon returned nil for scale=\(scale) padding=\(padding) size=\(size)")
                    if let icon = icon {
                        XCTAssertEqual(Int(icon.size.width), size,
                            "Wrong width for scale=\(scale) padding=\(padding) size=\(size)")
                        XCTAssertEqual(Int(icon.size.height), size,
                            "Wrong height for scale=\(scale) padding=\(padding) size=\(size)")
                    }
                }
            }
        }
    }

    /// The exact reporter repro reduced to one assertion: a 1024 image, zero
    /// padding, scale pushed to 2.0. Old guard: scaledSize=2048 > 1024 -> nil.
    func testUpscaleAtZeroPaddingProducesIcon() {
        generator.padding = 0.0
        generator.scale = 2.0
        let icon = generator.generateIcon(from: source, size: 1024)
        XCTAssertNotNil(icon, "Upscaling to 2.0x at zero padding must render, not blank")
        XCTAssertEqual(Int(icon?.size.width ?? 0), 1024)
    }

    /// Output canvas is always the requested size regardless of scale.
    func testOutputPixelSizeMatchesRequestedAcrossScales() {
        generator.padding = 0.0
        for scale in ScalingTestSupport.scales {
            generator.scale = scale
            let icon = generator.generateIcon(from: source, size: 512)
            XCTAssertEqual(Int(icon?.size.width ?? -1), 512, "scale=\(scale)")
            XCTAssertEqual(Int(icon?.size.height ?? -1), 512, "scale=\(scale)")
        }
    }

    /// scale didSet clamps out-of-range inputs to [0.5, 2.0].
    func testScaleClampsOutOfRange() {
        generator.scale = 99.0
        XCTAssertEqual(generator.scale, 2.0, "Scale above max must clamp to 2.0")
        generator.scale = -3.0
        XCTAssertEqual(generator.scale, 0.5, "Scale below min must clamp to 0.5")
    }

    /// padding didSet clamps out-of-range inputs to [0, 30].
    func testPaddingClampsOutOfRange() {
        generator.padding = 500.0
        XCTAssertEqual(generator.padding, 30.0, "Padding above max must clamp to 30")
        generator.padding = -50.0
        XCTAssertEqual(generator.padding, 0.0, "Padding below min must clamp to 0")
    }

    /// Invariant: across the whole clamped grid the internal scaled size stays
    /// strictly positive, so a valid image is always produced (proxy assertion:
    /// non-nil result implies the `scaledSize > 0` guard passed).
    func testScaledSizePositiveInvariantAtExtremes() {
        // Max padding (smallest content) combined with min scale is the worst case.
        generator.padding = 30.0
        generator.scale = 0.5
        for size in ScalingTestSupport.sizes {
            XCTAssertNotNil(generator.generateIcon(from: source, size: size),
                "scaledSize must stay > 0 at max padding / min scale for size=\(size)")
        }
    }

    /// Zero requested size is genuinely invalid geometry and must return nil.
    func testZeroSizeReturnsNil() {
        XCTAssertNil(generator.generateIcon(from: source, size: 0))
    }

    /// THE recursion regression lock. Assigning a far out-of-range value to the
    /// scale / padding @Published properties must clamp to range WITHOUT crashing.
    /// Against the old unconditional `value = clamped` write-back inside didSet,
    /// each of these assignments re-entered the setter without bound and overflowed
    /// the stack (SIGSEGV) — this was the actual "move the slider -> crash" defect.
    func testExtremeScaleAndPaddingClampWithoutCrash() {
        generator.scale = 100.0
        generator.padding = -50.0
        XCTAssertEqual(generator.scale, 2.0, "Scale 100 must clamp to 2.0, not crash")
        XCTAssertEqual(generator.padding, 0.0, "Padding -50 must clamp to 0, not crash")

        generator.scale = -50.0
        generator.padding = 100.0
        XCTAssertEqual(generator.scale, 0.5, "Scale -50 must clamp to 0.5, not crash")
        XCTAssertEqual(generator.padding, 30.0, "Padding 100 must clamp to 30, not crash")

        // Repeated in-range assignments must also stay bounded (didSet still fires).
        for _ in 0..<1000 {
            generator.scale = 1.5
            generator.padding = 12.0
        }
        XCTAssertEqual(generator.scale, 1.5)
        XCTAssertEqual(generator.padding, 12.0)
    }
}

// =============================================================================
// MARK: - Integration Tests: Preview Cache + Settings
// =============================================================================

class IconScalingIntegrationTests: XCTestCase {

    var generator: IconGenerator!

    override func setUp() {
        super.setUp()
        generator = IconGenerator()
        generator.sourceImage = ScalingTestSupport.make1024()
    }

    override func tearDown() {
        generator = nil
        super.tearDown()
    }

    /// Repeated identical calls return a consistent (cached) result.
    func testPreviewCacheConsistentAcrossRepeatedCalls() {
        let a = generator.generatePreview(size: 128)
        let b = generator.generatePreview(size: 128)
        XCTAssertNotNil(a)
        XCTAssertNotNil(b)
        XCTAssertEqual(Int(a?.size.width ?? -1), Int(b?.size.width ?? -2),
                       "Repeated preview calls must be consistent")
    }

    /// Changing the scale must yield a fresh render (cache key includes scale),
    /// not a stale cached image from the previous slider position.
    func testCacheKeyVariesWithScale() {
        generator.scale = 1.0
        let atOne = generator.generatePreview(size: 128)
        generator.scale = 2.0
        let atTwo = generator.generatePreview(size: 128)
        XCTAssertNotNil(atOne)
        XCTAssertNotNil(atTwo, "A scale change must produce a valid fresh preview, not blank")
        // Distinct render instances — a stale cache hit would return the same object.
        XCTAssertFalse(atOne === atTwo, "Scale change must not return the stale cached image")
    }

    /// Changing the padding must likewise yield a fresh render.
    func testCacheKeyVariesWithPadding() {
        generator.padding = 0.0
        let atZero = generator.generatePreview(size: 128)
        generator.padding = 30.0
        let atThirty = generator.generatePreview(size: 128)
        XCTAssertNotNil(atZero)
        XCTAssertNotNil(atThirty)
        XCTAssertFalse(atZero === atThirty, "Padding change must not return the stale cached image")
    }

    /// resetSettings restores documented defaults and leaves rendering working.
    func testResetSettingsRestoresDefaults() {
        generator.scale = 2.0
        generator.padding = 30.0
        _ = generator.generatePreview(size: 64)
        generator.resetSettings()
        XCTAssertEqual(generator.scale, 1.0)
        XCTAssertEqual(generator.padding, 10.0)
        XCTAssertNotNil(generator.generatePreview(size: 64), "Rendering must still work after reset")
    }
}

// =============================================================================
// MARK: - Functional Tests: End-to-End Slider Sweep (Reporter Repro)
// =============================================================================

class IconScalingFunctionalTests: XCTestCase {

    var generator: IconGenerator!

    override func setUp() {
        super.setUp()
        generator = IconGenerator()
        // User loads a 1024 png.
        generator.sourceImage = ScalingTestSupport.make1024()
    }

    override func tearDown() {
        generator = nil
        super.tearDown()
    }

    /// User drags the scale slider 0.5 -> 2.0. Every step must show a preview.
    /// This is the precise action MadMacMad reported as an immediate crash.
    func testUserSweepsScaleSlider() {
        var value = 0.5
        while value <= 2.0 + 0.0001 {
            generator.scale = value
            let preview = generator.generatePreview(size: 256)
            XCTAssertNotNil(preview, "Preview blanked while sweeping scale at \(value)")
            value += 0.1
        }
    }

    /// User drags the padding slider 0 -> 30. Every step must show a preview.
    func testUserSweepsPaddingSlider() {
        var value = 0.0
        while value <= 30.0 + 0.0001 {
            generator.padding = value
            let preview = generator.generatePreview(size: 256)
            XCTAssertNotNil(preview, "Preview blanked while sweeping padding at \(value)")
            value += 1.0
        }
    }

    /// Full functional grid via the public preview path.
    func testUserSweepsBothSlidersGrid() {
        for scale in ScalingTestSupport.scales {
            for padding in ScalingTestSupport.paddings {
                generator.scale = scale
                generator.padding = padding
                XCTAssertNotNil(generator.generatePreview(size: 256),
                    "Preview failed at scale=\(scale) padding=\(padding)")
            }
        }
    }
}

// =============================================================================
// MARK: - Security Tests: Hostile / Degenerate Input + Export Containment
// =============================================================================

class IconScalingSecurityTests: XCTestCase {

    var generator: IconGenerator!

    override func setUp() {
        super.setUp()
        generator = IconGenerator()
    }

    override func tearDown() {
        generator = nil
        super.tearDown()
    }

    /// A zero-size source must not crash and must not force-unwrap.
    func testZeroSizeSourceImageDoesNotCrash() {
        let empty = NSImage(size: .zero)
        generator.scale = 2.0
        generator.padding = 0.0
        // The canvas is target-sized, so this yields a blank icon rather than crashing.
        XCTAssertNoThrow(_ = generator.generateIcon(from: empty, size: 128))
    }

    /// Extreme aspect ratio must not crash (canvas stays target-sized).
    func testExtremeAspectRatioDoesNotCrash() {
        let sliver = ScalingTestSupport.makeImage(width: 4096, height: 1)
        XCTAssertNoThrow(_ = generator.generateIcon(from: sliver, size: 256))
    }

    /// Huge declared dimensions must not trigger unbounded allocation — the
    /// bitmap canvas is bounded by the requested icon size, not the source.
    func testHugeSourceDimensionsBounded() {
        let huge = NSImage(size: NSSize(width: 20000, height: 20000))
        let icon = generator.generateIcon(from: huge, size: 128)
        XCTAssertEqual(Int(icon?.size.width ?? -1), 128,
                       "Canvas must stay bounded at the requested size, not the source size")
    }

    /// Export must write only inside the caller-chosen directory (no traversal).
    func testExportStaysWithinChosenDirectory() throws {
        generator.sourceImage = ScalingTestSupport.make1024()
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("iconscaling-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try generator.exportIcons(for: .macOS, to: root)

        let rootPath = root.standardizedFileURL.path
        let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        var fileCount = 0
        while let url = enumerator?.nextObject() as? URL {
            fileCount += 1
            XCTAssertTrue(url.standardizedFileURL.path.hasPrefix(rootPath),
                          "Export escaped the chosen directory: \(url.path)")
        }
        XCTAssertGreaterThan(fileCount, 0, "Export should have written files")
    }
}

// =============================================================================
// MARK: - Performance Tests
// =============================================================================

class IconScalingPerformanceTests: XCTestCase {

    var generator: IconGenerator!

    override func setUp() {
        super.setUp()
        generator = IconGenerator()
        generator.sourceImage = ScalingTestSupport.make1024()
    }

    override func tearDown() {
        generator = nil
        super.tearDown()
    }

    /// Rendering the full macOS icon set (16..1024) stays within a sane bound.
    func testFullIconSetRenderWithinTimeBound() {
        let sizes = Platform.macOS.iconSizes
        let source = generator.sourceImage!
        let start = Date()
        for size in sizes {
            XCTAssertNotNil(generator.generateIcon(from: source, size: size))
        }
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 10.0,
            "Full icon set render took \(elapsed)s — expected well under 10s")
    }

    /// A second identical preview call must hit the cache and be cheap — much
    /// faster than the initial render.
    func testCacheHitIsCheaperThanFirstRender() {
        generator.clearCache()
        let t0 = Date()
        _ = generator.generatePreview(size: 1024)
        let firstRender = Date().timeIntervalSince(t0)

        let t1 = Date()
        let cached = generator.generatePreview(size: 1024)
        let secondRender = Date().timeIntervalSince(t1)

        XCTAssertNotNil(cached)
        XCTAssertLessThanOrEqual(secondRender, firstRender + 0.001,
            "Cache hit (\(secondRender)s) should not exceed a fresh render (\(firstRender)s)")
    }

    /// Standard XCTest performance baseline for a representative large render.
    func testLargeRenderPerformanceBaseline() {
        let source = generator.sourceImage!
        measure {
            _ = generator.generateIcon(from: source, size: 512)
        }
    }
}

// =============================================================================
// MARK: - Retry Tests
// =============================================================================
//
// NOTE: This local CPU render path performs NO network call — unlike the
// AI-backed generation covered by the project's 3-retry-with-delay policy.
// There is therefore nothing to retry here. Instead these tests assert the
// honest equivalent: genuinely invalid geometry fails *gracefully* (nil, not a
// crash), and the export path surfaces the error to the caller rather than
// aborting the batch silently.
// =============================================================================

class IconScalingRetryTests: XCTestCase {

    var generator: IconGenerator!

    override func setUp() {
        super.setUp()
        generator = IconGenerator()
    }

    override func tearDown() {
        generator = nil
        super.tearDown()
    }

    /// Truly invalid geometry returns nil rather than crashing.
    func testInvalidGeometryReturnsNilNotCrash() {
        let source = ScalingTestSupport.make1024()
        XCTAssertNil(generator.generateIcon(from: source, size: 0),
                     "Zero size is invalid geometry and must fail gracefully")
        XCTAssertNil(generator.generateIcon(from: source, size: -10),
                     "Negative size is invalid geometry and must fail gracefully")
    }

    /// Export with no source image surfaces a typed error instead of crashing.
    func testExportSurfacesErrorWithoutSource() {
        generator.sourceImage = nil
        XCTAssertThrowsError(try generator.exportIcons(for: .macOS, to: FileManager.default.temporaryDirectory)) { error in
            XCTAssertTrue(error is IconGeneratorError, "Should surface a typed IconGeneratorError")
        }
    }

    /// Export with an unusable (too-small, non-croppable) source surfaces an
    /// error rather than writing a broken icon set.
    func testExportSurfacesErrorForInvalidSource() {
        generator.autoCropToSquare = false
        generator.sourceImage = ScalingTestSupport.makeImage(width: 10, height: 10)
        XCTAssertThrowsError(try generator.exportIcons(for: .macOS, to: FileManager.default.temporaryDirectory)) { error in
            XCTAssertTrue(error is IconGeneratorError)
        }
    }
}

// =============================================================================
// MARK: - Frame Tests (Smoke)
// =============================================================================

class IconScalingFrameTests: XCTestCase {

    /// The generator constructs with valid defaults.
    func testGeneratorConstructsWithValidDefaults() {
        let generator = IconGenerator()
        XCTAssertEqual(generator.scale, 1.0)
        XCTAssertEqual(generator.padding, 10.0)
        XCTAssertTrue(generator.currentSettings.isValid, "Default settings must be valid")
    }

    /// A preview at default settings renders without crashing.
    func testDefaultPreviewRenders() {
        let generator = IconGenerator()
        generator.sourceImage = ScalingTestSupport.make1024()
        XCTAssertNotNil(generator.generatePreview(size: 128),
                        "Default-settings preview must render")
    }

    /// The test bundle itself loaded and can reach the app module.
    func testBundleLaunches() {
        XCTAssertNotNil(IconGenerator())
    }
}
