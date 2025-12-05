import SwiftUI
import AppKit

/// Manages project metadata, favorites, and recent projects
@MainActor
class ProjectManagementManager: ObservableObject {
    @Published var metadata: [String: ProjectMetadata] = [:] // Key: project path
    @Published var recentProjects: [XcodeProject] = []
    @Published var favoriteProjects: [XcodeProject] = []
    @Published var searchQuery: String = ""

    private let maxRecentProjects = 20
    private let metadataDirectory: URL

    init() {
        // Set up metadata directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        metadataDirectory = appSupport.appendingPathComponent("Icon Creator/Projects", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: metadataDirectory, withIntermediateDirectories: true)

        // Load metadata
        loadMetadata()
    }

    // MARK: - Project Usage Tracking

    func recordProjectUse(_ project: XcodeProject, iconGenerator: IconGenerator? = nil, platforms: Set<Platform>? = nil) {
        let path = project.path.path
        var meta = metadata[path] ?? ProjectMetadata(projectPath: path)
        meta.lastUsed = Date()

        // Record icon update if generator provided
        if let generator = iconGenerator, let platforms = platforms {
            let thumbnail = generator.generatePreview(size: 128)
            meta.recordIconUpdate(platforms: platforms, thumbnail: thumbnail, settings: generator.currentSettings)
        }

        metadata[path] = meta
        updateRecentProjects()
        persistMetadata()
    }

    // MARK: - Favorites

    func toggleFavorite(_ project: XcodeProject) {
        let path = project.path.path
        var meta = metadata[path] ?? ProjectMetadata(projectPath: path)
        meta.isFavorite.toggle()
        metadata[path] = meta
        updateFavoriteProjects()
        persistMetadata()
    }

    func isFavorite(_ project: XcodeProject) -> Bool {
        metadata[project.path.path]?.isFavorite ?? false
    }

    // MARK: - Notes & Custom Names

    func addNote(to project: XcodeProject, note: String) {
        let path = project.path.path
        var meta = metadata[path] ?? ProjectMetadata(projectPath: path)
        meta.notes = note
        metadata[path] = meta
        persistMetadata()
    }

    func getNote(for project: XcodeProject) -> String {
        metadata[project.path.path]?.notes ?? ""
    }

    func setCustomName(for project: XcodeProject, name: String?) {
        let path = project.path.path
        var meta = metadata[path] ?? ProjectMetadata(projectPath: path)
        meta.customName = name
        metadata[path] = meta
        persistMetadata()
    }

    func getDisplayName(for project: XcodeProject) -> String {
        metadata[project.path.path]?.customName ?? project.displayName
    }

    // MARK: - Tags

    func addTag(_ tag: String, to project: XcodeProject) {
        let path = project.path.path
        var meta = metadata[path] ?? ProjectMetadata(projectPath: path)
        meta.addTag(tag)
        metadata[path] = meta
        persistMetadata()
    }

    func removeTag(_ tag: String, from project: XcodeProject) {
        let path = project.path.path
        var meta = metadata[path] ?? ProjectMetadata(projectPath: path)
        meta.removeTag(tag)
        metadata[path] = meta
        persistMetadata()
    }

    func getTags(for project: XcodeProject) -> [String] {
        metadata[project.path.path]?.tags ?? []
    }

    var allTags: [String] {
        let tags = Set(metadata.values.flatMap { $0.tags })
        return tags.sorted()
    }

    // MARK: - Icon History

    func getIconHistory(for project: XcodeProject) -> [ProjectMetadata.IconHistoryEntry] {
        metadata[project.path.path]?.iconHistory ?? []
    }

    // MARK: - Search & Filter

    func filterProjects(_ projects: [XcodeProject], by query: String) -> [XcodeProject] {
        guard !query.isEmpty else { return projects }

        return projects.filter { project in
            let displayName = getDisplayName(for: project).lowercased()
            let notes = getNote(for: project).lowercased()
            let tags = getTags(for: project).map { $0.lowercased() }
            let queryLower = query.lowercased()

            return displayName.contains(queryLower) ||
                   notes.contains(queryLower) ||
                   tags.contains(where: { $0.contains(queryLower) })
        }
    }

    func filterByTag(_ projects: [XcodeProject], tag: String) -> [XcodeProject] {
        projects.filter { project in
            getTags(for: project).contains(tag)
        }
    }

    // MARK: - Recent Projects

    private func updateRecentProjects() {
        // Sort by last used, take top N
        let sorted = metadata.values
            .sorted { $0.lastUsed > $1.lastUsed }
            .prefix(maxRecentProjects)

        // Convert paths back to projects (need project manager to resolve)
        // This will be called by XcodeProjectManager
    }

    func getRecentProjects(from allProjects: [XcodeProject]) -> [XcodeProject] {
        let sorted = metadata.values
            .sorted { $0.lastUsed > $1.lastUsed }
            .prefix(maxRecentProjects)

        return sorted.compactMap { meta in
            allProjects.first { $0.path.path == meta.projectPath }
        }
    }

    // MARK: - Favorite Projects

    private func updateFavoriteProjects() {
        // Will be resolved by XcodeProjectManager
    }

    func getFavoriteProjects(from allProjects: [XcodeProject]) -> [XcodeProject] {
        let favoritePaths = metadata.values
            .filter { $0.isFavorite }
            .map { $0.projectPath }

        return allProjects.filter { favoritePaths.contains($0.path.path) }
    }

    // MARK: - Persistence

    private func loadMetadata() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: metadataDirectory,
                includingPropertiesForKeys: nil
            )

            for fileURL in fileURLs where fileURL.pathExtension == "json" {
                if let data = try? Data(contentsOf: fileURL),
                   let meta = try? JSONDecoder().decode(ProjectMetadata.self, from: data) {
                    metadata[meta.projectPath] = meta
                }
            }

            print("✅ Loaded metadata for \(metadata.count) projects")
        } catch {
            print("⚠️ Failed to load project metadata: \(error)")
        }
    }

    private func persistMetadata() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        // Save each metadata as separate file
        for (_, meta) in metadata {
            let filename = "\(meta.id.uuidString).json"
            let fileURL = metadataDirectory.appendingPathComponent(filename)

            if let data = try? encoder.encode(meta) {
                try? data.write(to: fileURL)
            }
        }
    }

    // MARK: - Statistics

    func totalIconsGenerated() -> Int {
        metadata.values.reduce(0) { $0 + $1.iconHistory.count }
    }

    func mostUsedProjects(from allProjects: [XcodeProject], count: Int = 5) -> [XcodeProject] {
        let sorted = metadata.values
            .sorted { $0.iconHistory.count > $1.iconHistory.count }
            .prefix(count)

        return sorted.compactMap { meta in
            allProjects.first { $0.path.path == meta.projectPath }
        }
    }
}
