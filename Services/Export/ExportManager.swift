import Foundation
import AppKit

/// Manages export operations for various formats
class ExportManager {

    // MARK: - Export Formats

    enum ExportFormat {
        case xcode // Standard .appiconset format
        case png(sizes: [Int]) // Custom PNG sizes
        case android // Android adaptive icons
        case web // Web app manifest + favicons
        case windows // Windows ICO format
        case electron // Electron app icons
        case documentation(format: DocFormat)
    }

    enum DocFormat {
        case html
        case pdf
        case markdown
    }

    // MARK: - Export Operations

    func export(
        icon: NSImage,
        format: ExportFormat,
        to url: URL,
        settings: IconSettings
    ) async throws {
        switch format {
        case .xcode:
            // Handled by IconGenerator
            break

        case .png(let sizes):
            try exportPNGSizes(icon: icon, sizes: sizes, to: url, settings: settings)

        case .android:
            try exportAndroidIcons(icon: icon, to: url, settings: settings)

        case .web:
            try exportWebIcons(icon: icon, to: url, settings: settings)

        case .windows:
            try exportWindowsIcon(icon: icon, to: url, settings: settings)

        case .electron:
            try exportElectronIcons(icon: icon, to: url, settings: settings)

        case .documentation(let docFormat):
            try exportDocumentation(icon: icon, format: docFormat, to: url, settings: settings)
        }
    }

    // MARK: - PNG Export

    private func exportPNGSizes(icon: NSImage, sizes: [Int], to baseURL: URL, settings: IconSettings) throws {
        let processor = ImageProcessor()

        for size in sizes {
            if let processed = processor.processImage(icon, with: settings, targetSize: size) {
                let filename = "icon_\(size)x\(size).png"
                let fileURL = baseURL.appendingPathComponent(filename)

                if let tiffData = processed.tiffRepresentation,
                   let bitmapImage = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                    try pngData.write(to: fileURL)
                }
            }
        }
    }

    // MARK: - Android Export

    private func exportAndroidIcons(icon: NSImage, to baseURL: URL, settings: IconSettings) throws {
        let processor = ImageProcessor()

        // Android densities and their sizes
        let densities: [(name: String, size: Int)] = [
            ("mdpi", 48),
            ("hdpi", 72),
            ("xhdpi", 96),
            ("xxhdpi", 144),
            ("xxxhdpi", 192)
        ]

        // Create res directory structure
        for (density, size) in densities {
            let mipmapDir = baseURL.appendingPathComponent("res/mipmap-\(density)")
            try FileManager.default.createDirectory(at: mipmapDir, withIntermediateDirectories: true)

            if let processed = processor.processImage(icon, with: settings, targetSize: size) {
                let fileURL = mipmapDir.appendingPathComponent("ic_launcher.png")

                if let tiffData = processed.tiffRepresentation,
                   let bitmapImage = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                    try pngData.write(to: fileURL)
                }
            }
        }

        // Also export adaptive icon (foreground + background)
        try exportAndroidAdaptiveIcon(icon: icon, to: baseURL, settings: settings)
    }

    private func exportAndroidAdaptiveIcon(icon: NSImage, to baseURL: URL, settings: IconSettings) throws {
        // For adaptive icons, we need foreground and background layers
        let processor = ImageProcessor()

        let densities: [(name: String, size: Int)] = [
            ("mdpi", 108),
            ("hdpi", 162),
            ("xhdpi", 216),
            ("xxhdpi", 324),
            ("xxxhdpi", 432)
        ]

        for (density, size) in densities {
            let mipmapDir = baseURL.appendingPathComponent("res/mipmap-\(density)")
            try FileManager.default.createDirectory(at: mipmapDir, withIntermediateDirectories: true)

            // Foreground (the icon)
            if let foreground = processor.processImage(icon, with: settings, targetSize: size) {
                let fgURL = mipmapDir.appendingPathComponent("ic_launcher_foreground.png")
                if let tiffData = foreground.tiffRepresentation,
                   let bitmapImage = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                    try pngData.write(to: fgURL)
                }
            }

            // Background (solid color or gradient)
            let backgroundImage = NSImage(size: NSSize(width: size, height: size))
            backgroundImage.lockFocus()
            settings.backgroundColor.nsColor.setFill()
            NSRect(x: 0, y: 0, width: size, height: size).fill()
            backgroundImage.unlockFocus()

            let bgURL = mipmapDir.appendingPathComponent("ic_launcher_background.png")
            if let tiffData = backgroundImage.tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                try pngData.write(to: bgURL)
            }
        }

        // Generate adaptive-icon.xml
        let xmlContent = """
        <?xml version="1.0" encoding="utf-8"?>
        <adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
            <background android:drawable="@mipmap/ic_launcher_background" />
            <foreground android:drawable="@mipmap/ic_launcher_foreground" />
        </adaptive-icon>
        """

        let xmlURL = baseURL.appendingPathComponent("res/mipmap-anydpi-v26/ic_launcher.xml")
        try FileManager.default.createDirectory(at: xmlURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try xmlContent.write(to: xmlURL, atomically: true, encoding: .utf8)
    }

    // MARK: - Web Export

    private func exportWebIcons(icon: NSImage, to baseURL: URL, settings: IconSettings) throws {
        let processor = ImageProcessor()

        // Favicon (16, 32, 48)
        let faviconSizes = [16, 32, 48]
        for size in faviconSizes {
            if let processed = processor.processImage(icon, with: settings, targetSize: size) {
                let filename = "favicon-\(size)x\(size).png"
                let fileURL = baseURL.appendingPathComponent(filename)

                if let tiffData = processed.tiffRepresentation,
                   let bitmapImage = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                    try pngData.write(to: fileURL)
                }
            }
        }

        // Apple touch icon
        if let appleIcon = processor.processImage(icon, with: settings, targetSize: 180) {
            let fileURL = baseURL.appendingPathComponent("apple-touch-icon.png")
            if let tiffData = appleIcon.tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                try pngData.write(to: fileURL)
            }
        }

        // Manifest icons
        for size in [192, 512] {
            if let processed = processor.processImage(icon, with: settings, targetSize: size) {
                let filename = "icon-\(size)x\(size).png"
                let fileURL = baseURL.appendingPathComponent(filename)

                if let tiffData = processed.tiffRepresentation,
                   let bitmapImage = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                    try pngData.write(to: fileURL)
                }
            }
        }

        // Generate manifest.json
        let manifest = """
        {
          "name": "My App",
          "short_name": "App",
          "icons": [
            {
              "src": "icon-192x192.png",
              "sizes": "192x192",
              "type": "image/png"
            },
            {
              "src": "icon-512x512.png",
              "sizes": "512x512",
              "type": "image/png"
            }
          ],
          "theme_color": "#ffffff",
          "background_color": "#ffffff",
          "display": "standalone"
        }
        """

        let manifestURL = baseURL.appendingPathComponent("manifest.json")
        try manifest.write(to: manifestURL, atomically: true, encoding: .utf8)
    }

    // MARK: - Windows Export

    private func exportWindowsIcon(icon: NSImage, to baseURL: URL, settings: IconSettings) throws {
        // Windows ICO format supports multiple sizes in one file
        // For now, export as PNGs (ICO generation requires additional library)
        let sizes = [16, 32, 48, 64, 128, 256]
        try exportPNGSizes(icon: icon, sizes: sizes, to: baseURL, settings: settings)

        // TODO: Combine into .ico file
    }

    // MARK: - Electron Export

    private func exportElectronIcons(icon: NSImage, to baseURL: URL, settings: IconSettings) throws {
        let processor = ImageProcessor()

        // Electron icon sizes
        let sizes = [16, 24, 32, 48, 64, 128, 256, 512, 1024]

        for size in sizes {
            if let processed = processor.processImage(icon, with: settings, targetSize: size) {
                let filename = "icon_\(size)x\(size).png"
                let fileURL = baseURL.appendingPathComponent(filename)

                if let tiffData = processed.tiffRepresentation,
                   let bitmapImage = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                    try pngData.write(to: fileURL)
                }
            }
        }
    }

    // MARK: - Documentation Export

    private func exportDocumentation(icon: NSImage, format: DocFormat, to baseURL: URL, settings: IconSettings) throws {
        switch format {
        case .markdown:
            try exportMarkdownDocs(icon: icon, to: baseURL, settings: settings)
        case .html:
            try exportHTMLDocs(icon: icon, to: baseURL, settings: settings)
        case .pdf:
            // PDF generation would require additional frameworks
            throw ExportError.unsupportedFormat("PDF export not yet implemented")
        }
    }

    private func exportMarkdownDocs(icon: NSImage, to baseURL: URL, settings: IconSettings) throws {
        let markdown = """
        # App Icon Documentation

        Generated on: \(Date().formatted())

        ## Settings Used

        - **Scale**: \(Int(settings.scale * 100))%
        - **Padding**: \(Int(settings.padding))%
        - **Background**: Custom
        - **Auto-crop**: \(settings.autoCropToSquare ? "Yes" : "No")

        ## Effects Applied

        \(settings.effects.cornerRadiusEnabled ? "- Corner Radius: \(Int(settings.effects.cornerRadius))%" : "")
        \(settings.effects.shadowEnabled ? "- Drop Shadow: Blur \(Int(settings.effects.shadowBlur))px" : "")
        \(settings.effects.borderEnabled ? "- Border: \(Int(settings.effects.borderWidth))px" : "")

        ## Sizes Generated

        All standard Apple platform sizes have been generated and are included in this export.

        ---

        *Generated by Icon Creator v2.0.0*
        """

        let markdownURL = baseURL.appendingPathComponent("ICON_DOCUMENTATION.md")
        try markdown.write(to: markdownURL, atomically: true, encoding: .utf8)
    }

    private func exportHTMLDocs(icon: NSImage, to baseURL: URL, settings: IconSettings) throws {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>App Icon Documentation</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; padding: 40px; }
                .icon { border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
                .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(120px, 1fr)); gap: 20px; }
                .card { text-align: center; }
            </style>
        </head>
        <body>
            <h1>App Icon Documentation</h1>
            <p>Generated on: \(Date().formatted())</p>

            <h2>Settings</h2>
            <ul>
                <li>Scale: \(Int(settings.scale * 100))%</li>
                <li>Padding: \(Int(settings.padding))%</li>
                <li>Auto-crop: \(settings.autoCropToSquare ? "Yes" : "No")</li>
            </ul>

            <h2>Generated Icons</h2>
            <div class="grid">
                <!-- Icons would be embedded here -->
                <div class="card">
                    <p>See exported files for all icon sizes</p>
                </div>
            </div>

            <hr>
            <p><em>Generated by Icon Creator v2.0.0</em></p>
        </body>
        </html>
        """

        let htmlURL = baseURL.appendingPathComponent("icon_documentation.html")
        try html.write(to: htmlURL, atomically: true, encoding: .utf8)
    }

    // MARK: - Error Handling

    enum ExportError: LocalizedError {
        case unsupportedFormat(String)
        case exportFailed(String)

        var errorDescription: String? {
            switch self {
            case .unsupportedFormat(let message):
                return "Unsupported format: \(message)"
            case .exportFailed(let message):
                return "Export failed: \(message)"
            }
        }
    }
}
