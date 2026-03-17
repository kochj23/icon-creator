import Foundation

// MARK: - Widget Data Models (Shared between App and Widget)

/// App Group identifier for data sharing
enum AppGroupConstants {
    static let identifier = "group.com.jkoch.iconcreator"
    static let widgetDataKey = "widgetData"
    static let lastUpdateKey = "lastUpdate"
}

/// Represents a recent icon project for widget display
struct WidgetProject: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let thumbnailData: Data?
    let lastModified: Date
    let iconCount: Int
    let platforms: [String]
    let outputPath: String?

    init(id: UUID = UUID(),
         name: String,
         thumbnailData: Data? = nil,
         lastModified: Date = Date(),
         iconCount: Int = 0,
         platforms: [String] = [],
         outputPath: String? = nil) {
        self.id = id
        self.name = name
        self.thumbnailData = thumbnailData
        self.lastModified = lastModified
        self.iconCount = iconCount
        self.platforms = platforms
        self.outputPath = outputPath
    }
}

/// Represents the current generation status
enum GenerationStatus: Codable, Equatable {
    case idle
    case generating(progress: Double, currentSize: String)
    case completed(iconCount: Int, duration: TimeInterval)
    case failed(error: String)

    var displayText: String {
        switch self {
        case .idle:
            return "Ready"
        case .generating(let progress, let currentSize):
            return "Generating \(currentSize)... \(Int(progress * 100))%"
        case .completed(let iconCount, _):
            return "Completed: \(iconCount) icons"
        case .failed(let error):
            return "Error: \(error)"
        }
    }

    var isActive: Bool {
        if case .generating = self {
            return true
        }
        return false
    }
}

/// Preset shortcut for quick access from widget
struct WidgetPreset: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let iconName: String // SF Symbol name
    let platforms: [String]
    let isBuiltIn: Bool

    init(id: UUID = UUID(),
         name: String,
         iconName: String,
         platforms: [String] = ["iOS", "macOS"],
         isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.platforms = platforms
        self.isBuiltIn = isBuiltIn
    }

    // Built-in presets for widget
    static let minimalist = WidgetPreset(
        name: "Minimalist",
        iconName: "square",
        platforms: ["iOS", "macOS"],
        isBuiltIn: true
    )

    static let fullBleed = WidgetPreset(
        name: "Full Bleed",
        iconName: "square.fill",
        platforms: ["iOS", "macOS"],
        isBuiltIn: true
    )

    static let rounded = WidgetPreset(
        name: "Rounded",
        iconName: "app",
        platforms: ["iOS"],
        isBuiltIn: true
    )

    static let shadowed = WidgetPreset(
        name: "Shadowed",
        iconName: "shadow",
        platforms: ["iOS", "macOS"],
        isBuiltIn: true
    )

    static let allPlatforms = WidgetPreset(
        name: "All Platforms",
        iconName: "square.stack.3d.up.fill",
        platforms: ["iOS", "macOS", "watchOS", "tvOS"],
        isBuiltIn: true
    )

    static let builtInPresets: [WidgetPreset] = [
        minimalist, fullBleed, rounded, shadowed, allPlatforms
    ]
}

/// Last used image for quick create
struct LastUsedImage: Codable, Equatable {
    let id: UUID
    let name: String
    let thumbnailData: Data?
    let originalPath: String
    let dateUsed: Date

    init(id: UUID = UUID(),
         name: String,
         thumbnailData: Data? = nil,
         originalPath: String,
         dateUsed: Date = Date()) {
        self.id = id
        self.name = name
        self.thumbnailData = thumbnailData
        self.originalPath = originalPath
        self.dateUsed = dateUsed
    }
}

/// Complete widget data container
struct IconCreatorWidgetData: Codable, Equatable {
    var recentProjects: [WidgetProject]
    var generationStatus: GenerationStatus
    var lastUsedImage: LastUsedImage?
    var favoritePresets: [WidgetPreset]
    var lastUpdated: Date

    init(recentProjects: [WidgetProject] = [],
         generationStatus: GenerationStatus = .idle,
         lastUsedImage: LastUsedImage? = nil,
         favoritePresets: [WidgetPreset] = WidgetPreset.builtInPresets,
         lastUpdated: Date = Date()) {
        self.recentProjects = recentProjects
        self.generationStatus = generationStatus
        self.lastUsedImage = lastUsedImage
        self.favoritePresets = favoritePresets
        self.lastUpdated = lastUpdated
    }

    // Placeholder data for widget preview
    static var placeholder: IconCreatorWidgetData {
        IconCreatorWidgetData(
            recentProjects: [
                WidgetProject(name: "My App Icon", iconCount: 47, platforms: ["iOS", "macOS"]),
                WidgetProject(name: "Watch App", iconCount: 12, platforms: ["watchOS"]),
                WidgetProject(name: "Safari Extension", iconCount: 8, platforms: ["macOS"])
            ],
            generationStatus: .idle,
            lastUsedImage: LastUsedImage(name: "logo.png", originalPath: "/path/to/logo.png"),
            favoritePresets: WidgetPreset.builtInPresets
        )
    }
}

// MARK: - Deep Link URLs

enum WidgetDeepLink {
    static let scheme = "iconcreator"

    static func openApp() -> URL {
        URL(string: "\(scheme)://open")!
    }

    static func openProject(id: UUID) -> URL {
        URL(string: "\(scheme)://project/\(id.uuidString)")!
    }

    static func createWithPreset(presetName: String) -> URL {
        URL(string: "\(scheme)://create/preset/\(presetName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? presetName)")!
    }

    static func createFromLastImage() -> URL {
        URL(string: "\(scheme)://create/last-image")!
    }

    static func newProject() -> URL {
        URL(string: "\(scheme)://new")!
    }
}
