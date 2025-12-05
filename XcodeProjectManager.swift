import Foundation
import AppKit

// MARK: - Xcode Project Model

/// Represents a discovered Xcode project
struct XcodeProject: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: URL
    let detectedPlatforms: Set<Platform>

    /// Project display name (without .xcodeproj extension)
    var displayName: String {
        name.replacingOccurrences(of: ".xcodeproj", with: "")
    }

    /// Full path as string
    var pathString: String {
        path.path
    }

    /// Primary platform (the most likely target)
    var primaryPlatform: Platform? {
        // Priority order: iOS > macOS > tvOS > watchOS > iMessage > Mac Catalyst
        if detectedPlatforms.contains(.iOS) { return .iOS }
        if detectedPlatforms.contains(.macOS) { return .macOS }
        if detectedPlatforms.contains(.tvOS) { return .tvOS }
        if detectedPlatforms.contains(.watchOS) { return .watchOS }
        if detectedPlatforms.contains(.iMessage) { return .iMessage }
        if detectedPlatforms.contains(.macCatalyst) { return .macCatalyst }
        return nil
    }

    /// Human-readable platform description
    var platformDescription: String {
        if detectedPlatforms.isEmpty {
            return "Unknown platform"
        }
        let platformNames = detectedPlatforms.map { $0.rawValue }.sorted()
        return platformNames.joined(separator: ", ")
    }
}

// MARK: - Xcode Project Manager

/// Manages discovery and manipulation of Xcode projects
class XcodeProjectManager: ObservableObject {
    // MARK: - Published Properties

    /// List of discovered Xcode projects
    @Published var projects: [XcodeProject] = []

    /// Currently selected project
    @Published var selectedProject: XcodeProject?

    /// Directories being scanned
    @Published var scannedDirectories: [String] = []

    /// List of search directories to scan for Xcode projects
    private var searchDirectories: [URL] = []

    // MARK: - Initialization

    init() {
        self.searchDirectories = Self.getCommonProjectLocations()
        discoverProjects()
    }

    // MARK: - Common Project Locations

    /// Returns common locations where Xcode projects are typically stored
    private static func getCommonProjectLocations() -> [URL] {
        var locations: [URL] = []
        let fileManager = FileManager.default
        let homeDirectory = fileManager.homeDirectoryForCurrentUser

        // Common Xcode project locations
        let potentialLocations = [
            // Desktop
            homeDirectory.appendingPathComponent("Desktop/xcode"),
            homeDirectory.appendingPathComponent("Desktop"),

            // Documents
            homeDirectory.appendingPathComponent("Documents/Xcode"),
            homeDirectory.appendingPathComponent("Documents/Projects"),
            homeDirectory.appendingPathComponent("Documents"),

            // Developer
            homeDirectory.appendingPathComponent("Developer"),
            homeDirectory.appendingPathComponent("Developer/Projects"),

            // Common project folders
            homeDirectory.appendingPathComponent("Projects"),
            homeDirectory.appendingPathComponent("Code"),
            homeDirectory.appendingPathComponent("Development"),
            homeDirectory.appendingPathComponent("workspace"),
            homeDirectory.appendingPathComponent("Workspace"),

            // iCloud Drive
            homeDirectory.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/Projects"),
            homeDirectory.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/Xcode"),
        ]

        // Filter to only existing directories
        for location in potentialLocations {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: location.path, isDirectory: &isDirectory), isDirectory.boolValue {
                locations.append(location)
            }
        }

        print("📁 Found \(locations.count) potential project directories:")
        for location in locations {
            print("   - \(location.path)")
        }

        return locations
    }

    // MARK: - Project Discovery

    /// Discovers all Xcode projects in all search directories
    func discoverProjects() {
        var discoveredProjects: [XcodeProject] = []
        var scannedPaths: [String] = []

        print("🔍 Scanning for Xcode projects in \(searchDirectories.count) locations...")

        for directory in searchDirectories {
            scannedPaths.append(directory.path)

            guard let enumerator = FileManager.default.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else {
                print("⚠️ Failed to create directory enumerator for: \(directory.path)")
                continue
            }

            for case let fileURL as URL in enumerator {
                // Check if this is an .xcodeproj directory
                if fileURL.pathExtension == "xcodeproj" {
                    let projectName = fileURL.lastPathComponent

                    // Skip if already discovered (avoid duplicates)
                    if discoveredProjects.contains(where: { $0.path == fileURL }) {
                        enumerator.skipDescendants()
                        continue
                    }

                    let platforms = detectPlatforms(in: fileURL)
                    let project = XcodeProject(name: projectName, path: fileURL, detectedPlatforms: platforms)
                    discoveredProjects.append(project)

                    // Skip descending into the .xcodeproj bundle
                    enumerator.skipDescendants()
                }
            }
        }

        // Sort projects alphabetically by display name
        discoveredProjects.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }

        DispatchQueue.main.async {
            self.projects = discoveredProjects
            self.scannedDirectories = scannedPaths
        }

        print("✅ Discovered \(discoveredProjects.count) Xcode projects across \(scannedPaths.count) directories")
        if discoveredProjects.isEmpty {
            print("⚠️ No projects found. Scanned locations:")
            for path in scannedPaths {
                print("   - \(path)")
            }
        }
    }

    // MARK: - Platform Detection

    /// Detects the target platforms for an Xcode project by parsing project.pbxproj
    /// - Parameter projectURL: URL to the .xcodeproj bundle
    /// - Returns: Set of detected platforms
    private func detectPlatforms(in projectURL: URL) -> Set<Platform> {
        var platforms = Set<Platform>()

        // Read the project.pbxproj file
        let pbxprojURL = projectURL.appendingPathComponent("project.pbxproj")

        guard let content = try? String(contentsOf: pbxprojURL, encoding: .utf8) else {
            print("⚠️ Could not read project.pbxproj for: \(projectURL.lastPathComponent)")
            return platforms
        }

        // Detect platforms based on SDKROOT and SUPPORTED_PLATFORMS settings
        if content.contains("SDKROOT = iphoneos") ||
           content.contains("\"iphoneos\"") ||
           content.contains("TARGETED_DEVICE_FAMILY = \"1,2\"") {
            platforms.insert(.iOS)
        }

        if content.contains("SDKROOT = macosx") ||
           content.contains("\"macosx\"") ||
           content.contains("platform:macOS") {
            platforms.insert(.macOS)
        }

        if content.contains("SDKROOT = appletvos") ||
           content.contains("\"appletvos\"") ||
           content.contains("platform:tvOS") {
            platforms.insert(.tvOS)
        }

        if content.contains("SDKROOT = watchos") ||
           content.contains("\"watchos\"") ||
           content.contains("platform:watchOS") {
            platforms.insert(.watchOS)
        }

        // Check for Mac Catalyst
        if content.contains("SUPPORTS_MACCATALYST = YES") ||
           content.contains("UIApplicationSceneManifest") && platforms.contains(.iOS) {
            platforms.insert(.macCatalyst)
        }

        // Check for iMessage extension
        if content.contains("com.apple.messages") ||
           content.contains("MessagesExtension") {
            platforms.insert(.iMessage)
        }

        // If no platforms detected, try to infer from Info.plist or project name
        if platforms.isEmpty {
            let projectName = projectURL.lastPathComponent.lowercased()
            if projectName.contains("ios") || projectName.contains("iphone") || projectName.contains("ipad") {
                platforms.insert(.iOS)
            } else if projectName.contains("macos") || projectName.contains("mac") {
                platforms.insert(.macOS)
            } else if projectName.contains("tvos") || projectName.contains("tv") {
                platforms.insert(.tvOS)
            } else if projectName.contains("watchos") || projectName.contains("watch") {
                platforms.insert(.watchOS)
            }
        }

        print("✅ Detected platforms for \(projectURL.lastPathComponent): \(platforms.map { $0.rawValue }.joined(separator: ", "))")
        return platforms
    }

    // MARK: - Icon Installation

    /// Installs generated icons into the selected Xcode project
    /// - Parameters:
    ///   - sourceURL: URL of the generated AppIcon.appiconset folder
    ///   - project: Target Xcode project
    ///   - platform: Platform type (iOS, macOS, etc.)
    /// - Returns: True if installation was successful
    func installIcons(from sourceURL: URL, to project: XcodeProject, platform: Platform) throws {
        // Find or create the Assets.xcassets folder in the project
        let assetsURL = try findOrCreateAssetsFolder(in: project)

        // Create destination path: Assets.xcassets/AppIcon.appiconset
        let destinationURL = assetsURL.appendingPathComponent("AppIcon.appiconset")

        // Remove existing AppIcon.appiconset if it exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            print("ℹ️ Removing existing AppIcon.appiconset at: \(destinationURL.path)")
            try FileManager.default.removeItem(at: destinationURL)
        }

        // Copy the new AppIcon.appiconset folder
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        print("✅ Successfully installed icons to: \(destinationURL.path)")
    }

    /// Finds or creates the Assets.xcassets folder within an Xcode project
    /// - Parameter project: Xcode project to search
    /// - Returns: URL of Assets.xcassets folder (existing or newly created)
    /// - Throws: Error if creation fails
    private func findOrCreateAssetsFolder(in project: XcodeProject) throws -> URL {
        let projectDirectory = project.path.deletingLastPathComponent()

        // First, try to find existing Assets.xcassets
        if let existingURL = findAssetsFolder(in: project) {
            return existingURL
        }

        // Not found, so create it
        print("📁 No Assets.xcassets found. Creating new asset catalog for: \(project.displayName)")

        // Create Assets.xcassets in the project directory (next to .xcodeproj)
        let assetsURL = projectDirectory.appendingPathComponent("Assets.xcassets")

        // Security: Ensure assetsURL is within project directory (prevent path traversal)
        guard assetsURL.path.hasPrefix(projectDirectory.path) else {
            throw XcodeProjectError.installationFailed(reason: "Invalid path - potential security issue")
        }

        // Create the Assets.xcassets directory
        try FileManager.default.createDirectory(at: assetsURL, withIntermediateDirectories: true)

        // Create the Contents.json file for the asset catalog
        let contentsJSON = """
        {
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """

        let contentsURL = assetsURL.appendingPathComponent("Contents.json")
        try contentsJSON.write(to: contentsURL, atomically: true, encoding: .utf8)

        print("✅ Created Assets.xcassets at: \(assetsURL.path)")

        // Try to add it to the Xcode project automatically
        do {
            try addAssetsCatalogToProject(project: project, assetsURL: assetsURL)
            print("✅ Added Assets.xcassets to Xcode project file")
        } catch {
            print("⚠️ Could not add to project file automatically: \(error.localizedDescription)")
            print("ℹ️ Note: You may need to add Assets.xcassets to your Xcode project manually")
            print("ℹ️ Instructions: Right-click project → Add Files → Select Assets.xcassets")
        }

        return assetsURL
    }

    /// Adds Assets.xcassets to the Xcode project file (project.pbxproj)
    /// - Parameters:
    ///   - project: Xcode project
    ///   - assetsURL: URL to the Assets.xcassets folder
    /// - Throws: Error if modification fails
    private func addAssetsCatalogToProject(project: XcodeProject, assetsURL: URL) throws {
        let pbxprojURL = project.path.appendingPathComponent("project.pbxproj")

        // Read the project file
        guard let content = try? String(contentsOf: pbxprojURL, encoding: .utf8) else {
            throw XcodeProjectError.installationFailed(reason: "Cannot read project.pbxproj")
        }

        // Check if Assets.xcassets is already in the project
        if content.contains("Assets.xcassets") {
            print("ℹ️ Assets.xcassets already in project file")
            return
        }

        // Generate unique IDs for the new entries
        let fileRef = generateUniqueID()
        let buildFile = generateUniqueID()

        var modifiedContent = content

        // 1. Add file reference in PBXFileReference section
        if findSection(in: content, named: "PBXFileReference") != nil {
            let fileRefEntry = """
            \t\t\(fileRef) /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };
            """
            modifiedContent = insertBeforeEndOfSection(modifiedContent, section: "PBXFileReference", entry: fileRefEntry)
        }

        // 2. Add to PBXBuildFile section for resources
        if findSection(in: content, named: "PBXBuildFile") != nil {
            let buildFileEntry = """
            \t\t\(buildFile) /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = \(fileRef) /* Assets.xcassets */; };
            """
            modifiedContent = insertBeforeEndOfSection(modifiedContent, section: "PBXBuildFile", entry: buildFileEntry)
        }

        // 3. Add to main group (file list)
        if let groupMatch = modifiedContent.range(of: #"(/\* Icon Creator \*/.*?children = \()"#, options: .regularExpression) {
            let insertPoint = modifiedContent.index(groupMatch.upperBound, offsetBy: 0)
            let groupEntry = "\n\t\t\t\t\(fileRef) /* Assets.xcassets */,"
            modifiedContent.insert(contentsOf: groupEntry, at: insertPoint)
        }

        // 4. Add to Resources build phase
        if let resourcesMatch = modifiedContent.range(of: #"(/\* Resources \*/.*?files = \()"#, options: .regularExpression) {
            let insertPoint = modifiedContent.index(resourcesMatch.upperBound, offsetBy: 0)
            let resourceEntry = "\n\t\t\t\t\(buildFile) /* Assets.xcassets in Resources */,"
            modifiedContent.insert(contentsOf: resourceEntry, at: insertPoint)
        }

        // Write the modified project file
        try modifiedContent.write(to: pbxprojURL, atomically: true, encoding: .utf8)

        print("✅ Successfully modified project.pbxproj")
    }

    /// Generates a unique ID for Xcode project file entries
    private func generateUniqueID() -> String {
        let chars = "ABCDEF0123456789"
        return String((0..<24).map { _ in chars.randomElement()! })
    }

    /// Finds a section in the project file
    /// - Parameters:
    ///   - content: Project file content
    ///   - section: Section name (sanitized to prevent injection)
    /// - Returns: Range of the section, or nil if not found
    private func findSection(in content: String, named section: String) -> Range<String.Index>? {
        // Sanitize section name to prevent regex injection
        // Only allow alphanumeric characters and underscores
        let sanitized = section.filter { $0.isLetter || $0.isNumber || $0 == "_" }

        guard !sanitized.isEmpty else {
            print("⚠️ Invalid section name after sanitization: '\(section)'")
            return nil
        }

        return content.range(of: #"/\* Begin \#(sanitized) section \*/"#, options: .regularExpression)
    }

    /// Inserts an entry before the end of a section
    /// - Parameters:
    ///   - content: Project file content
    ///   - section: Section name (sanitized to prevent injection)
    ///   - entry: Entry to insert
    /// - Returns: Modified content with entry inserted
    private func insertBeforeEndOfSection(_ content: String, section: String, entry: String) -> String {
        // Sanitize section name to prevent regex injection
        let sanitized = section.filter { $0.isLetter || $0.isNumber || $0 == "_" }

        guard !sanitized.isEmpty else {
            print("⚠️ Invalid section name after sanitization: '\(section)'")
            return content
        }

        guard let endRange = content.range(of: #"/\* End \#(sanitized) section \*/"#, options: .regularExpression) else {
            return content
        }

        var modified = content
        modified.insert(contentsOf: entry + "\n", at: endRange.lowerBound)
        return modified
    }

    /// Finds the Assets.xcassets folder within an Xcode project
    /// - Parameter project: Xcode project to search
    /// - Returns: URL of Assets.xcassets folder, or nil if not found
    private func findAssetsFolder(in project: XcodeProject) -> URL? {
        let projectDirectory = project.path.deletingLastPathComponent()

        // Search for Assets.xcassets in the project directory
        guard let enumerator = FileManager.default.enumerator(
            at: projectDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        for case let fileURL as URL in enumerator {
            if fileURL.lastPathComponent == "Assets.xcassets" {
                print("✅ Found Assets.xcassets at: \(fileURL.path)")
                return fileURL
            }

            // Skip .xcodeproj bundles and other build directories
            if fileURL.pathExtension == "xcodeproj" ||
               fileURL.lastPathComponent == "build" ||
               fileURL.lastPathComponent == "DerivedData" {
                enumerator.skipDescendants()
            }
        }

        return nil
    }

    /// Opens the Xcode project in Xcode
    /// - Parameter project: Project to open
    func openInXcode(_ project: XcodeProject) {
        NSWorkspace.shared.open(project.path)
    }

    // MARK: - Multi-Platform Installation

    /// Installs icons for multiple platforms simultaneously
    /// - Parameters:
    ///   - baseURL: Base directory containing exported icons for all platforms
    ///   - platforms: Set of platforms to install
    ///   - project: Target Xcode project
    /// - Returns: Dictionary mapping each platform to its installation result
    func installMultiplePlatforms(
        from baseURL: URL,
        platforms: Set<Platform>,
        to project: XcodeProject
    ) async throws -> [Platform: Result<Void, Error>] {
        var results: [Platform: Result<Void, Error>] = [:]

        for platform in platforms {
            let platformURL = baseURL.appendingPathComponent(platform.folderName)
            let appiconsetURL = platformURL.appendingPathComponent("AppIcon.appiconset")

            do {
                try installIcons(from: appiconsetURL, to: project, platform: platform)
                results[platform] = .success(())
                print("✅ Successfully installed \(platform.rawValue) icons")
            } catch {
                results[platform] = .failure(error)
                print("❌ Failed to install \(platform.rawValue) icons: \(error)")
            }
        }

        return results
    }
}

// MARK: - Error Handling

enum XcodeProjectError: LocalizedError {
    case assetCreationFailed(project: String, reason: String)
    case installationFailed(reason: String)

    var errorDescription: String? {
        switch self {
        case .assetCreationFailed(let project, let reason):
            return "Could not create Assets.xcassets in project '\(project)': \(reason)"
        case .installationFailed(let reason):
            return "Failed to install icons: \(reason)"
        }
    }
}
