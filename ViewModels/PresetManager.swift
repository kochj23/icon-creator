import SwiftUI
import AppKit

/// Manages icon presets (built-in and user-created)
@MainActor
class PresetManager: ObservableObject {
    @Published var userPresets: [IconPreset] = []
    @Published var selectedPreset: IconPreset?

    private let userDefaultsKey = "user_icon_presets"
    private let presetsDirectory: URL

    init() {
        // Set up presets directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        presetsDirectory = appSupport.appendingPathComponent("Icon Creator/Presets", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: presetsDirectory, withIntermediateDirectories: true)

        // Load user presets
        loadPresets()
    }

    // MARK: - Built-in Presets

    var builtInPresets: [IconPreset] {
        IconPreset.allBuiltIn
    }

    var allPresets: [IconPreset] {
        builtInPresets + userPresets
    }

    // MARK: - Preset Management

    func savePreset(_ preset: IconPreset) {
        if let index = userPresets.firstIndex(where: { $0.id == preset.id }) {
            // Update existing
            userPresets[index] = preset
        } else {
            // Add new
            userPresets.append(preset)
        }
        persistPresets()
    }

    func deletePreset(id: UUID) {
        userPresets.removeAll { $0.id == id }
        persistPresets()
    }

    func duplicatePreset(_ preset: IconPreset) -> IconPreset {
        IconPreset(
            id: UUID(),
            name: "\(preset.name) Copy",
            settings: preset.settings,
            thumbnail: preset.thumbnail,
            isBuiltIn: false
        )
    }

    // MARK: - Import/Export

    func exportPreset(_ preset: IconPreset) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(preset)
    }

    func importPreset(from data: Data) throws -> IconPreset {
        let decoder = JSONDecoder()
        var preset = try decoder.decode(IconPreset.self, from: data)
        preset.id = UUID() // New ID to avoid conflicts
        preset.isBuiltIn = false
        return preset
    }

    func exportPresetToFile(_ preset: IconPreset) {
        guard let data = exportPreset(preset) else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(preset.name).json"

        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }

    func importPresetFromFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            if let data = try? Data(contentsOf: url),
               let preset = try? importPreset(from: data) {
                savePreset(preset)
            }
        }
    }

    // MARK: - Persistence

    private func loadPresets() {
        // Try loading from UserDefaults first (legacy)
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let presets = try? JSONDecoder().decode([IconPreset].self, from: data) {
            userPresets = presets
            // Migrate to file-based storage
            persistPresets()
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            return
        }

        // Load from files
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: presetsDirectory,
                includingPropertiesForKeys: nil
            )

            userPresets = fileURLs.compactMap { url in
                guard url.pathExtension == "json" else { return nil }
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(IconPreset.self, from: data)
            }
        } catch {
            print("⚠️ Failed to load presets: \(error)")
        }
    }

    private func persistPresets() {
        // Save each preset as a separate file
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        // Clear existing files
        try? FileManager.default.contentsOfDirectory(at: presetsDirectory, includingPropertiesForKeys: nil).forEach { url in
            try? FileManager.default.removeItem(at: url)
        }

        // Save all presets
        for preset in userPresets {
            let filename = "\(preset.id.uuidString).json"
            let fileURL = presetsDirectory.appendingPathComponent(filename)

            if let data = try? encoder.encode(preset) {
                try? data.write(to: fileURL)
            }
        }
    }

    // MARK: - Apply Preset

    func applyPreset(_ preset: IconPreset, to generator: IconGenerator) {
        generator.scale = preset.settings.scale
        generator.padding = preset.settings.padding
        generator.backgroundColor = preset.settings.backgroundColor.color
        generator.autoCropToSquare = preset.settings.autoCropToSquare
        selectedPreset = preset
    }

    // MARK: - Create Preset from Current Settings

    func createPresetFromSettings(
        name: String,
        settings: IconSettings,
        thumbnail: NSImage? = nil
    ) {
        var thumbnailData: Data?
        if let thumbnail = thumbnail,
           let tiffData = thumbnail.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapImage.representation(using: .png, properties: [:]) {
            thumbnailData = pngData
        }

        let preset = IconPreset(
            name: name,
            settings: settings,
            thumbnail: thumbnailData,
            isBuiltIn: false
        )

        savePreset(preset)
    }
}
