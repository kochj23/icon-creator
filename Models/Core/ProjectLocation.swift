import Foundation
import SwiftUI

// MARK: - Project Location

/// Represents a configured location where Xcode projects can be found
///
/// Supports multiple source types:
/// - Local filesystem directories
/// - Git repositories (GitHub, GitLab, Bitbucket)
/// - Cloud storage (iCloud Drive, Dropbox, Google Drive)
/// - Spotlight search
///
/// **Author**: Jordan Koch
struct ProjectLocation: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let type: LocationType
    let path: String?  // For filesystem locations
    let gitURL: String?  // For git repositories
    var isEnabled: Bool
    let dateAdded: Date
    var lastScanned: Date?
    var projectCount: Int?

    enum LocationType: String, Codable, CaseIterable {
        case localDirectory = "Local Directory"
        case gitRepository = "Git Repository"
        case iCloudDrive = "iCloud Drive"
        case dropbox = "Dropbox"
        case googleDrive = "Google Drive"
        case oneDrive = "OneDrive"
        case networkVolume = "Network Volume"
        case spotlight = "Spotlight Search"
        case xcodeRecents = "Xcode Recents"

        var icon: String {
            switch self {
            case .localDirectory:
                return "folder.fill"
            case .gitRepository:
                return "arrow.down.doc.fill"
            case .iCloudDrive:
                return "icloud.fill"
            case .dropbox:
                return "cloud.fill"
            case .googleDrive:
                return "globe"
            case .oneDrive:
                return "cloud.fill"
            case .networkVolume:
                return "network"
            case .spotlight:
                return "magnifyingglass"
            case .xcodeRecents:
                return "clock.arrow.circlepath"
            }
        }

        var supportsCustomPath: Bool {
            switch self {
            case .localDirectory, .networkVolume:
                return true
            default:
                return false
            }
        }

        var requiresAuthentication: Bool {
            return self == .gitRepository
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        type: LocationType,
        path: String? = nil,
        gitURL: String? = nil,
        isEnabled: Bool = true,
        dateAdded: Date = Date(),
        lastScanned: Date? = nil,
        projectCount: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.path = path
        self.gitURL = gitURL
        self.isEnabled = isEnabled
        self.dateAdded = dateAdded
        self.lastScanned = lastScanned
        self.projectCount = projectCount
    }

    /// Display path for UI
    var displayPath: String {
        if let path = path {
            return (path as NSString).abbreviatingWithTildeInPath
        } else if let gitURL = gitURL {
            return gitURL
        }
        return type.rawValue
    }

    /// Validation check
    var isValid: Bool {
        switch type {
        case .localDirectory, .networkVolume:
            guard let path = path else { return false }
            return FileManager.default.fileExists(atPath: path)

        case .gitRepository:
            guard let gitURL = gitURL else { return false }
            return isValidGitURL(gitURL)

        case .iCloudDrive:
            let iCloudPath = FileManager.default.url(forUbiquityContainerIdentifier: nil)
            return iCloudPath != nil

        case .dropbox:
            let dropboxPath = NSHomeDirectory() + "/Dropbox"
            return FileManager.default.fileExists(atPath: dropboxPath)

        case .googleDrive:
            let gdrivePath = NSHomeDirectory() + "/Google Drive"
            return FileManager.default.fileExists(atPath: gdrivePath)

        case .oneDrive:
            let onedrivePath = NSHomeDirectory() + "/OneDrive"
            return FileManager.default.fileExists(atPath: onedrivePath)

        case .spotlight, .xcodeRecents:
            return true  // Always available
        }
    }

    /// Validates a git URL
    private func isValidGitURL(_ url: String) -> Bool {
        // Check for common git URL patterns
        let patterns = [
            "^https://github\\.com/[^/]+/[^/]+(\\.git)?$",
            "^git@github\\.com:[^/]+/[^/]+(\\.git)?$",
            "^https://gitlab\\.com/[^/]+/[^/]+(\\.git)?$",
            "^git@gitlab\\.com:[^/]+/[^/]+(\\.git)?$",
            "^https://bitbucket\\.org/[^/]+/[^/]+(\\.git)?$",
            "^git@bitbucket\\.org:[^/]+/[^/]+(\\.git)?$"
        ]

        for pattern in patterns {
            if url.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }

        // Check for generic git URL
        return url.hasSuffix(".git") || url.hasPrefix("git@") || url.contains("://")
    }

    /// Gets the actual filesystem path to scan
    func getFileSystemPath() -> String? {
        switch type {
        case .localDirectory, .networkVolume:
            return path

        case .iCloudDrive:
            guard let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
                return nil
            }
            return iCloudURL.path

        case .dropbox:
            return NSHomeDirectory() + "/Dropbox"

        case .googleDrive:
            return NSHomeDirectory() + "/Google Drive"

        case .oneDrive:
            return NSHomeDirectory() + "/OneDrive"

        case .gitRepository:
            // For git repos, return the local clone path if it exists
            if let path = path {
                return path
            }
            return nil

        case .spotlight, .xcodeRecents:
            return nil  // These use different discovery methods
        }
    }
}

// MARK: - Predefined Locations

extension ProjectLocation {
    /// Common default locations for Xcode projects
    /// Uses stable UUIDs so they can be tracked across app launches
    static let defaultLocations: [ProjectLocation] = [
        ProjectLocation(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Desktop Xcode",
            type: .localDirectory,
            path: NSHomeDirectory() + "/Desktop/xcode"
        ),
        ProjectLocation(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Documents Projects",
            type: .localDirectory,
            path: NSHomeDirectory() + "/Documents/Projects"
        ),
        ProjectLocation(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "Developer Folder",
            type: .localDirectory,
            path: NSHomeDirectory() + "/Developer"
        ),
        ProjectLocation(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            name: "Data Volume Xcode",
            type: .localDirectory,
            path: "/Volumes/Data/xcode"
        ),
        ProjectLocation(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            name: "iCloud Drive",
            type: .iCloudDrive
        ),
        ProjectLocation(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            name: "Spotlight Search",
            type: .spotlight,
            isEnabled: false  // Disabled by default (can be slow)
        ),
        ProjectLocation(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
            name: "Xcode Recent Projects",
            type: .xcodeRecents
        )
    ]

    /// Cloud storage locations
    static let cloudLocations: [ProjectLocation] = [
        ProjectLocation(name: "Dropbox", type: .dropbox, isEnabled: false),
        ProjectLocation(name: "Google Drive", type: .googleDrive, isEnabled: false),
        ProjectLocation(name: "OneDrive", type: .oneDrive, isEnabled: false)
    ]
}

// MARK: - Git Repository Info

/// Information about a Git repository
struct GitRepositoryInfo: Codable {
    let url: String
    let branch: String
    let localPath: String
    let lastCloned: Date
    var lastPulled: Date?

    enum AuthType: String, Codable {
        case https = "HTTPS"
        case ssh = "SSH"
        case token = "Personal Access Token"
    }

    var authType: AuthType {
        if url.hasPrefix("git@") {
            return .ssh
        } else if url.hasPrefix("https://") {
            return .https
        }
        return .https
    }

    var displayName: String {
        // Extract repo name from URL
        if let lastComponent = url.components(separatedBy: "/").last {
            return lastComponent.replacingOccurrences(of: ".git", with: "")
        }
        return url
    }
}
