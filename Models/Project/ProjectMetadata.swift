import Foundation
import AppKit

/// Metadata associated with an Xcode project
struct ProjectMetadata: Codable, Identifiable {
    let id: UUID
    var projectPath: String // Store path for identification
    var lastIconUpdate: Date?
    var notes: String
    var isFavorite: Bool
    var iconHistory: [IconHistoryEntry]
    var customName: String? // User can override display name
    var tags: [String]
    var lastUsed: Date

    init(projectPath: String) {
        self.id = UUID()
        self.projectPath = projectPath
        self.lastIconUpdate = nil
        self.notes = ""
        self.isFavorite = false
        self.iconHistory = []
        self.customName = nil
        self.tags = []
        self.lastUsed = Date()
    }

    /// Entry in the icon history
    struct IconHistoryEntry: Codable, Identifiable {
        let id: UUID
        let date: Date
        let platforms: [String] // Platform raw values
        let thumbnailData: Data? // Small preview image
        let settings: IconSettings
        let note: String?

        init(platforms: Set<Platform>, thumbnail: NSImage?, settings: IconSettings, note: String? = nil) {
            self.id = UUID()
            self.date = Date()
            self.platforms = platforms.map { $0.rawValue }
            self.settings = settings
            self.note = note

            // Generate thumbnail data
            if let thumbnail = thumbnail,
               let tiffData = thumbnail.tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                self.thumbnailData = pngData
            } else {
                self.thumbnailData = nil
            }
        }
    }

    mutating func recordIconUpdate(platforms: Set<Platform>, thumbnail: NSImage?, settings: IconSettings, note: String? = nil) {
        let entry = IconHistoryEntry(platforms: platforms, thumbnail: thumbnail, settings: settings, note: note)
        iconHistory.insert(entry, at: 0) // Most recent first
        lastIconUpdate = Date()
        lastUsed = Date()

        // Keep only last 50 entries
        if iconHistory.count > 50 {
            iconHistory = Array(iconHistory.prefix(50))
        }
    }

    mutating func addTag(_ tag: String) {
        if !tags.contains(tag) {
            tags.append(tag)
        }
    }

    mutating func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}
