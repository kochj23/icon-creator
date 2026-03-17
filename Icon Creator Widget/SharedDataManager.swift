import Foundation
import WidgetKit
#if canImport(AppKit)
import AppKit
#endif

// MARK: - Shared Data Manager

/// Manages data sharing between the main app and widget extension via App Group
final class SharedDataManager {

    // MARK: - Singleton

    static let shared = SharedDataManager()

    // MARK: - Properties

    private let userDefaults: UserDefaults?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Initialization

    private init() {
        self.userDefaults = UserDefaults(suiteName: AppGroupConstants.identifier)

        if userDefaults == nil {
            print("[SharedDataManager] Warning: Could not access App Group. Widget data sync disabled.")
        }
    }

    // MARK: - Widget Data Operations

    /// Saves widget data to App Group
    func saveWidgetData(_ data: IconCreatorWidgetData) {
        guard let userDefaults = userDefaults else {
            print("[SharedDataManager] Cannot save: App Group not available")
            return
        }

        do {
            let encoded = try encoder.encode(data)
            userDefaults.set(encoded, forKey: AppGroupConstants.widgetDataKey)
            userDefaults.set(Date(), forKey: AppGroupConstants.lastUpdateKey)
            userDefaults.synchronize()

            // Reload widget timelines
            WidgetCenter.shared.reloadAllTimelines()

            print("[SharedDataManager] Widget data saved successfully")
        } catch {
            print("[SharedDataManager] Failed to save widget data: \(error)")
        }
    }

    /// Loads widget data from App Group
    func loadWidgetData() -> IconCreatorWidgetData {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: AppGroupConstants.widgetDataKey) else {
            return IconCreatorWidgetData()
        }

        do {
            let decoded = try decoder.decode(IconCreatorWidgetData.self, from: data)
            return decoded
        } catch {
            print("[SharedDataManager] Failed to load widget data: \(error)")
            return IconCreatorWidgetData()
        }
    }

    /// Gets the last update timestamp
    func getLastUpdateDate() -> Date? {
        return userDefaults?.object(forKey: AppGroupConstants.lastUpdateKey) as? Date
    }

    // MARK: - Project Management

    /// Adds a recent project to widget data
    func addRecentProject(_ project: WidgetProject) {
        var data = loadWidgetData()

        // Remove existing project with same ID
        data.recentProjects.removeAll { $0.id == project.id }

        // Add to front of list
        data.recentProjects.insert(project, at: 0)

        // Keep only the most recent 10 projects
        if data.recentProjects.count > 10 {
            data.recentProjects = Array(data.recentProjects.prefix(10))
        }

        data.lastUpdated = Date()
        saveWidgetData(data)
    }

    /// Updates generation status
    func updateGenerationStatus(_ status: GenerationStatus) {
        var data = loadWidgetData()
        data.generationStatus = status
        data.lastUpdated = Date()
        saveWidgetData(data)
    }

    /// Sets the last used image for quick create
    func setLastUsedImage(_ image: LastUsedImage) {
        var data = loadWidgetData()
        data.lastUsedImage = image
        data.lastUpdated = Date()
        saveWidgetData(data)
    }

    /// Updates favorite presets
    func updateFavoritePresets(_ presets: [WidgetPreset]) {
        var data = loadWidgetData()
        data.favoritePresets = presets
        data.lastUpdated = Date()
        saveWidgetData(data)
    }

    // MARK: - Thumbnail Generation

    #if canImport(AppKit)
    /// Creates a thumbnail from an image file
    static func createThumbnail(from imagePath: String, maxSize: CGSize = CGSize(width: 128, height: 128)) -> Data? {
        guard let image = NSImage(contentsOfFile: imagePath) else {
            return nil
        }

        return createThumbnail(from: image, maxSize: maxSize)
    }

    /// Creates a thumbnail from an NSImage
    static func createThumbnail(from image: NSImage, maxSize: CGSize = CGSize(width: 128, height: 128)) -> Data? {
        let originalSize = image.size

        // Calculate aspect-fit size
        let widthRatio = maxSize.width / originalSize.width
        let heightRatio = maxSize.height / originalSize.height
        let ratio = min(widthRatio, heightRatio)

        let newSize = CGSize(
            width: originalSize.width * ratio,
            height: originalSize.height * ratio
        )

        // Create resized image
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: originalSize),
                  operation: .copy,
                  fraction: 1.0)
        resizedImage.unlockFocus()

        // Convert to PNG data
        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }

        return pngData
    }
    #endif

    // MARK: - Convenience Methods

    /// Creates a WidgetProject from icon generation results
    func createWidgetProject(name: String,
                            thumbnailPath: String?,
                            iconCount: Int,
                            platforms: [String],
                            outputPath: String?) -> WidgetProject {
        var thumbnailData: Data? = nil

        #if canImport(AppKit)
        if let path = thumbnailPath {
            thumbnailData = SharedDataManager.createThumbnail(from: path)
        }
        #endif

        return WidgetProject(
            name: name,
            thumbnailData: thumbnailData,
            lastModified: Date(),
            iconCount: iconCount,
            platforms: platforms,
            outputPath: outputPath
        )
    }

    /// Clears all widget data
    func clearAllData() {
        userDefaults?.removeObject(forKey: AppGroupConstants.widgetDataKey)
        userDefaults?.removeObject(forKey: AppGroupConstants.lastUpdateKey)
        userDefaults?.synchronize()

        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Widget Refresh Helper

extension SharedDataManager {

    /// Forces widget timeline refresh
    func refreshWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Gets current widget configurations
    func getCurrentWidgetConfigurations(completion: @escaping ([WidgetInfo]) -> Void) {
        WidgetCenter.shared.getCurrentConfigurations { result in
            switch result {
            case .success(let widgets):
                completion(widgets)
            case .failure(let error):
                print("[SharedDataManager] Failed to get widget configurations: \(error)")
                completion([])
            }
        }
    }
}
