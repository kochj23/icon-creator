import Foundation
import AppKit

// MARK: - Project Location Manager

/// Manages configured locations where Xcode projects can be found
///
/// Supports multiple source types:
/// - Local directories with custom paths
/// - Git repositories (GitHub, GitLab, Bitbucket)
/// - Cloud storage (iCloud, Dropbox, Google Drive, OneDrive)
/// - Spotlight system-wide search
/// - Xcode recent projects
///
/// **Persistence**: Saves custom locations to UserDefaults
/// **Thread Safety**: All operations on main thread
///
/// **Author**: Jordan Koch
class ProjectLocationManager: ObservableObject {

    // MARK: - Published Properties

    @Published var locations: [ProjectLocation] = []
    @Published var customLocations: [ProjectLocation] = []
    @Published var recentProjects: [String] = []  // Paths
    @Published var isScanning: Bool = false
    @Published var scanProgress: String = ""

    // MARK: - Private Properties

    private let userDefaultsKey = "com.iconcreator.projectLocations"
    private let recentProjectsKey = "com.iconcreator.recentProjects"
    private let maxRecentProjects = 10

    // MARK: - Initialization

    init() {
        loadLocations()
        loadRecentProjects()
    }

    // MARK: - Location Management

    /// Adds a custom local directory
    func addLocalDirectory(path: String, name: String? = nil) -> ProjectLocation? {
        // Validate path exists
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return nil
        }

        // Check if already exists
        if locations.contains(where: { $0.path == path }) {
            return nil
        }

        let location = ProjectLocation(
            name: name ?? (path as NSString).lastPathComponent,
            type: .localDirectory,
            path: path
        )

        customLocations.append(location)
        rebuildLocationsList()
        saveLocations()

        return location
    }

    /// Adds a Git repository for cloning
    func addGitRepository(url: String, name: String? = nil, clonePath: String) -> ProjectLocation? {
        // Validate git URL
        guard isValidGitURL(url) else {
            return nil
        }

        // Check if already exists
        if locations.contains(where: { $0.gitURL == url }) {
            return nil
        }

        let location = ProjectLocation(
            name: name ?? extractRepoName(from: url),
            type: .gitRepository,
            path: clonePath,
            gitURL: url
        )

        customLocations.append(location)
        rebuildLocationsList()
        saveLocations()

        return location
    }

    /// Removes a custom location
    func removeLocation(_ location: ProjectLocation) {
        customLocations.removeAll { $0.id == location.id }
        rebuildLocationsList()
        saveLocations()
    }

    /// Toggles a location's enabled state
    func toggleLocation(_ location: ProjectLocation) {
        if let index = customLocations.firstIndex(where: { $0.id == location.id }) {
            customLocations[index].isEnabled.toggle()
            rebuildLocationsList()
            saveLocations()
        }
    }

    /// Enables a default location
    func enableDefaultLocation(_ type: ProjectLocation.LocationType) {
        // Find or create default location for this type
        if let existing = locations.first(where: { $0.type == type && $0.path == nil && $0.gitURL == nil }) {
            if let index = locations.firstIndex(where: { $0.id == existing.id }) {
                var updated = existing
                updated.isEnabled = true
                locations[index] = updated
                saveLocations()
            }
        }
    }

    // MARK: - Scanning

    /// Gets all valid paths to scan for projects
    func getEnabledPaths() -> [String] {
        var paths: Set<String> = []

        for location in locations where location.isEnabled {
            if let path = location.getFileSystemPath() {
                paths.insert(path)
            }
        }

        return Array(paths)
    }

    /// Scans all enabled locations for Xcode projects
    func scanForProjects() async -> [String] {
        await MainActor.run {
            isScanning = true
            scanProgress = "Initializing scan..."
        }

        var foundProjects: Set<String> = []

        for location in locations where location.isEnabled {
            await MainActor.run {
                scanProgress = "Scanning: \(location.name)"
            }

            let projects = await scanLocation(location)
            foundProjects.formUnion(projects)
        }

        await MainActor.run {
            isScanning = false
            scanProgress = ""
        }

        return Array(foundProjects)
    }

    /// Scans a specific location
    private func scanLocation(_ location: ProjectLocation) async -> Set<String> {
        var projects: Set<String> = []

        switch location.type {
        case .localDirectory, .networkVolume, .iCloudDrive, .dropbox, .googleDrive, .oneDrive:
            if let path = location.getFileSystemPath() {
                projects = findXcodeProjects(in: path, recursive: true, maxDepth: 3)
            }

        case .gitRepository:
            // For git repos, scan the local clone path if it exists
            if let path = location.path {
                projects = findXcodeProjects(in: path, recursive: true, maxDepth: 2)
            }

        case .spotlight:
            projects = await spotlightSearch()

        case .xcodeRecents:
            projects = Set(getXcodeRecentProjects())
        }

        // Update scan timestamp
        updateLastScanned(location, projectCount: projects.count)

        return projects
    }

    /// Finds .xcodeproj files in a directory
    private func findXcodeProjects(in directory: String, recursive: Bool, maxDepth: Int) -> Set<String> {
        var projects: Set<String> = []
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: directory),
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return projects
        }

        for case let fileURL as URL in enumerator {
            // Check depth
            let depth = fileURL.pathComponents.count - URL(fileURLWithPath: directory).pathComponents.count
            if depth > maxDepth {
                enumerator.skipDescendants()
                continue
            }

            // Check if it's an .xcodeproj
            if fileURL.pathExtension == "xcodeproj" {
                projects.insert(fileURL.path)

                // Don't descend into .xcodeproj bundles
                enumerator.skipDescendants()
            }
        }

        return projects
    }

    /// Spotlight search for .xcodeproj files
    private func spotlightSearch() async -> Set<String> {
        // Use mdfind (Spotlight command-line)
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        task.arguments = ["kMDItemContentType == 'com.apple.xcode.project'"]

        let pipe = Pipe()
        task.standardOutput = pipe

        var projects: Set<String> = []

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                for line in lines where !line.isEmpty {
                    projects.insert(line)
                }
            }
        } catch {
            print("Spotlight search failed: \(error)")
        }

        return projects
    }

    /// Gets Xcode's recent projects from preferences
    private func getXcodeRecentProjects() -> [String] {
        // Xcode stores recent projects in ~/Library/Developer/Xcode/UserData/IDERecentProjects.plist
        let recentProjectsPath = NSHomeDirectory() + "/Library/Developer/Xcode/UserData/IDERecentProjects.plist"

        guard let plistData = FileManager.default.contents(atPath: recentProjectsPath),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [[String: Any]] else {
            return []
        }

        var projects: [String] = []
        for item in plist {
            if let pathData = item["ProjectPath"] as? Data,
               let path = String(data: pathData, encoding: .utf8) {
                projects.append(path)
            }
        }

        return projects
    }

    // MARK: - Recent Projects

    /// Adds a project to recent list
    func addRecentProject(_ path: String) {
        // Remove if already exists
        recentProjects.removeAll { $0 == path }

        // Add to beginning
        recentProjects.insert(path, at: 0)

        // Limit size
        if recentProjects.count > maxRecentProjects {
            recentProjects = Array(recentProjects.prefix(maxRecentProjects))
        }

        saveRecentProjects()
    }

    /// Clears recent projects
    func clearRecentProjects() {
        recentProjects.removeAll()
        saveRecentProjects()
    }

    // MARK: - Git Operations

    /// Clones a Git repository
    func cloneRepository(_ location: ProjectLocation, progress: @escaping (String) -> Void) async throws -> String {
        guard location.type == .gitRepository,
              let gitURL = location.gitURL,
              let clonePath = location.path else {
            throw NSError(domain: "ProjectLocationManager", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid git repository configuration"
            ])
        }

        // Create clone directory if needed
        let cloneDirectory = (clonePath as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(atPath: cloneDirectory, withIntermediateDirectories: true)

        // Execute git clone
        progress("Cloning \(extractRepoName(from: gitURL))...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["clone", gitURL, clonePath]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            progress("Clone complete!")
            return clonePath
        } else {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectLocationManager", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Git clone failed: \(output)"
            ])
        }
    }

    /// Pulls latest changes from a Git repository
    func pullRepository(at path: String, progress: @escaping (String) -> Void) async throws {
        progress("Pulling latest changes...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["pull"]
        process.currentDirectoryURL = URL(fileURLWithPath: path)

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            progress("Pull complete!")
        } else {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ProjectLocationManager", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Git pull failed: \(output)"
            ])
        }
    }

    // MARK: - Persistence

    private func saveLocations() {
        if let encoded = try? JSONEncoder().encode(customLocations) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadLocations() {
        // Load custom locations
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([ProjectLocation].self, from: data) {
            customLocations = decoded
        }

        // Rebuild combined list
        rebuildLocationsList()
    }

    private func rebuildLocationsList() {
        // Combine default locations + custom locations
        var combined = ProjectLocation.defaultLocations

        // Check which defaults are overridden by custom
        for custom in customLocations {
            // Remove default with same path if custom exists
            if let path = custom.path {
                combined.removeAll { $0.path == path && $0.type == custom.type }
            }
        }

        combined.append(contentsOf: customLocations)
        locations = combined
    }

    private func saveRecentProjects() {
        UserDefaults.standard.set(recentProjects, forKey: recentProjectsKey)
    }

    private func loadRecentProjects() {
        recentProjects = UserDefaults.standard.stringArray(forKey: recentProjectsKey) ?? []
    }

    private func updateLastScanned(_ location: ProjectLocation, projectCount: Int) {
        if let index = customLocations.firstIndex(where: { $0.id == location.id }) {
            customLocations[index].lastScanned = Date()
            customLocations[index].projectCount = projectCount
            saveLocations()
            rebuildLocationsList()
        }
    }

    // MARK: - Helpers

    private func isValidGitURL(_ url: String) -> Bool {
        // Check for common git URL patterns
        let patterns = [
            "^https://github\\.com/",
            "^git@github\\.com:",
            "^https://gitlab\\.com/",
            "^git@gitlab\\.com:",
            "^https://bitbucket\\.org/",
            "^git@bitbucket\\.org:"
        ]

        for pattern in patterns {
            if url.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }

        return url.hasSuffix(".git") || url.hasPrefix("git@")
    }

    private func extractRepoName(from url: String) -> String {
        let components = url.components(separatedBy: "/")
        if let last = components.last {
            return last.replacingOccurrences(of: ".git", with: "")
        }
        return url
    }

    // MARK: - Import/Export

    /// Exports locations to JSON file
    func exportLocations() throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(customLocations)

        let documentsURL = FileManager.default.urls(for: .documentsDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent("IconCreator-Locations.json")

        try data.write(to: fileURL)
        return fileURL
    }

    /// Imports locations from JSON file
    func importLocations(from url: URL) throws -> Int {
        let data = try Data(contentsOf: url)
        let imported = try JSONDecoder().decode([ProjectLocation].self, from: data)

        var addedCount = 0
        for location in imported {
            // Check if not already present
            if !customLocations.contains(where: { $0.path == location.path || $0.gitURL == location.gitURL }) {
                customLocations.append(location)
                addedCount += 1
            }
        }

        rebuildLocationsList()
        saveLocations()

        return addedCount
    }

    // MARK: - Validation

    /// Validates all locations and returns invalid ones
    func validateLocations() -> [ProjectLocation] {
        return locations.filter { !$0.isValid }
    }

    /// Removes invalid locations
    func removeInvalidLocations() {
        let invalid = validateLocations()
        for location in invalid {
            removeLocation(location)
        }
    }
}

// MARK: - Directory Picker Helper

extension ProjectLocationManager {
    /// Shows native directory picker
    func selectDirectory(title: String = "Select Xcode Projects Directory") -> String? {
        let panel = NSOpenPanel()
        panel.title = title
        panel.message = "Choose a directory containing Xcode projects"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.showsHiddenFiles = false

        if panel.runModal() == .OK, let url = panel.url {
            return url.path
        }

        return nil
    }
}
