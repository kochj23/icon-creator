import Foundation
import AppKit

/// Package format for sharing icon projects with team members
struct CollaborationPackage: Codable {
    let version: String
    let projectName: String
    let createdDate: Date
    let author: String

    var iconSettings: IconSettings
    var presets: [IconPreset]
    var variants: [IconVariant]
    var comments: [Comment]
    var sourceImageData: Data? // Optional: include source

    init(
        projectName: String,
        iconSettings: IconSettings,
        presets: [IconPreset] = [],
        variants: [IconVariant] = [],
        comments: [Comment] = [],
        sourceImage: NSImage? = nil
    ) {
        self.version = "2.0"
        self.projectName = projectName
        self.createdDate = Date()
        self.author = NSFullUserName()
        self.iconSettings = iconSettings
        self.presets = presets
        self.variants = variants
        self.comments = comments

        // Convert source image to data
        if let source = sourceImage,
           let tiffData = source.tiffRepresentation {
            self.sourceImageData = tiffData
        } else {
            self.sourceImageData = nil
        }
    }

    // MARK: - Comment

    struct Comment: Codable, Identifiable {
        let id: UUID
        let author: String
        let text: String
        let timestamp: Date
        let attachedTo: CommentTarget

        enum CommentTarget: Codable, Equatable {
            case general
            case variant(UUID)
            case platform(String) // Platform raw value
            case preset(UUID)
        }

        init(author: String = NSFullUserName(), text: String, attachedTo: CommentTarget = .general) {
            self.id = UUID()
            self.author = author
            self.text = text
            self.timestamp = Date()
            self.attachedTo = attachedTo
        }
    }

    // MARK: - Source Image

    func getSourceImage() -> NSImage? {
        guard let data = sourceImageData else { return nil }
        return NSImage(data: data)
    }
}

/// Manages export and import of collaboration packages
class CollaborationManager {

    func exportPackage(
        projectName: String,
        iconGenerator: IconGenerator,
        presetManager: PresetManager,
        variants: [IconVariant] = [],
        comments: [CollaborationPackage.Comment] = []
    ) throws -> Data {
        let package = CollaborationPackage(
            projectName: projectName,
            iconSettings: iconGenerator.currentSettings,
            presets: presetManager.userPresets,
            variants: variants,
            comments: comments,
            sourceImage: iconGenerator.sourceImage
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        return try encoder.encode(package)
    }

    func importPackage(from data: Data) throws -> CollaborationPackage {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(CollaborationPackage.self, from: data)
    }

    func exportToFile(
        projectName: String,
        iconGenerator: IconGenerator,
        presetManager: PresetManager
    ) {
        do {
            let data = try exportPackage(
                projectName: projectName,
                iconGenerator: iconGenerator,
                presetManager: presetManager
            )

            let panel = NSSavePanel()
            panel.nameFieldStringValue = "\(projectName).iconpackage"
            panel.allowedContentTypes = [.json]

            if panel.runModal() == .OK, let url = panel.url {
                try data.write(to: url)
                print("✅ Exported collaboration package: \(url.path)")
            }
        } catch {
            print("❌ Failed to export package: \(error)")
        }
    }

    func importFromFile() -> CollaborationPackage? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.message = "Select a collaboration package to import"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                let package = try importPackage(from: data)
                print("✅ Imported collaboration package: \(package.projectName)")
                return package
            } catch {
                print("❌ Failed to import package: \(error)")
            }
        }

        return nil
    }

    func applyPackage(
        _ package: CollaborationPackage,
        to iconGenerator: IconGenerator,
        presetManager: PresetManager
    ) {
        // Apply settings
        iconGenerator.applySettings(package.iconSettings)

        // Import presets
        for preset in package.presets {
            presetManager.savePreset(preset)
        }

        // Load source image if available
        if let sourceImage = package.getSourceImage() {
            iconGenerator.sourceImage = sourceImage
        }

        print("✅ Applied collaboration package: \(package.projectName)")
    }
}
