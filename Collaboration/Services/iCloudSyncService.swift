import Foundation
import CloudKit

//
//  iCloudSyncService.swift
//  Icon Creator
//
//  iCloud Drive sync for presets and collaborative features
//  Author: Jordan Koch
//  Date: 2026-01-21
//

/// Manages iCloud synchronization for shared presets and projects
class iCloudSyncService: ObservableObject {

    // MARK: - Published Properties

    @Published var syncStatus: SyncStatus = SyncStatus(isSyncing: false, pendingChanges: 0, errors: [])
    @Published var isAvailable = false

    // MARK: - Properties

    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase

    private let ubiquityURL: URL?

    // MARK: - Initialization

    init() {
        // Initialize CloudKit
        self.container = CKContainer.default()
        self.privateDatabase = container.privateCloudDatabase
        self.sharedDatabase = container.sharedCloudDatabase

        // Initialize iCloud Drive
        self.ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)

        checkAvailability()
        setupNotifications()
    }

    // MARK: - Availability

    private func checkAvailability() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.isAvailable = (status == .available)

                if let error = error {
                    print("⚠️ iCloud not available: \(error.localizedDescription)")
                }
            }
        }
    }

    private func setupNotifications() {
        // Listen for iCloud changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleiCloudChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
    }

    @objc private func handleiCloudChange() {
        // Reload data when iCloud changes detected
        Task {
            await syncFromCloud()
        }
    }

    // MARK: - Preset Sync

    /// Save preset to iCloud
    func savePreset(_ preset: SharedPreset) async throws {
        guard isAvailable else {
            throw SyncError.iCloudNotAvailable
        }

        // Save to CloudKit
        let record = CKRecord(recordType: "SharedPreset", recordID: CKRecord.ID(recordName: preset.recordName))

        record["name"] = preset.name
        record["author"] = preset.author
        record["createdAt"] = preset.createdAt
        record["modifiedAt"] = preset.modifiedAt
        record["isPublic"] = preset.isPublic ? 1 : 0
        record["tags"] = preset.tags
        record["settings"] = try JSONEncoder().encode(preset.settings)

        do {
            _ = try await privateDatabase.save(record)

            // Also save to iCloud Drive for backup
            try saveToiCloudDrive(preset)

            print("✅ Preset saved to iCloud: \(preset.name)")
        } catch {
            throw SyncError.saveFailed(error.localizedDescription)
        }
    }

    /// Load all presets from iCloud
    func loadPresets() async throws -> [SharedPreset] {
        guard isAvailable else {
            throw SyncError.iCloudNotAvailable
        }

        let query = CKQuery(recordType: "SharedPreset", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]

        do {
            let (results, _) = try await privateDatabase.records(matching: query)

            var presets: [SharedPreset] = []

            for (_, result) in results {
                switch result {
                case .success(let record):
                    if let preset = try? parsePresetRecord(record) {
                        presets.append(preset)
                    }
                case .failure(let error):
                    print("⚠️ Failed to load preset: \(error)")
                }
            }

            return presets
        } catch {
            throw SyncError.loadFailed(error.localizedDescription)
        }
    }

    /// Delete preset from iCloud
    func deletePreset(_ preset: SharedPreset) async throws {
        let recordID = CKRecord.ID(recordName: preset.recordName)

        do {
            _ = try await privateDatabase.deleteRecord(withID: recordID)

            // Also delete from iCloud Drive
            try deleteFromiCloudDrive(preset)

            print("✅ Preset deleted from iCloud: \(preset.name)")
        } catch {
            throw SyncError.deleteFailed(error.localizedDescription)
        }
    }

    private func parsePresetRecord(_ record: CKRecord) throws -> SharedPreset {
        guard let name = record["name"] as? String,
              let author = record["author"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let modifiedAt = record["modifiedAt"] as? Date,
              let isPublic = record["isPublic"] as? Int,
              let tags = record["tags"] as? [String],
              let settingsData = record["settings"] as? Data else {
            throw SyncError.parseError
        }

        let settings = try JSONDecoder().decode(IconSettings.self, from: settingsData)

        let idString = record.recordID.recordName.replacingOccurrences(of: "SharedPreset_", with: "")
        let id = UUID(uuidString: idString) ?? UUID()

        return SharedPreset(
            id: id,
            name: name,
            settings: settings,
            author: author,
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            isPublic: isPublic == 1,
            tags: tags
        )
    }

    // MARK: - Project Sync

    /// Save project to iCloud
    func saveProject(_ project: IconProject) async throws {
        guard isAvailable else {
            throw SyncError.iCloudNotAvailable
        }

        let recordName = "IconProject_\(project.id.uuidString)"
        let record = CKRecord(recordType: "IconProject", recordID: CKRecord.ID(recordName: recordName))

        record["name"] = project.name
        record["description"] = project.description
        record["owner"] = project.owner
        record["status"] = project.status.rawValue
        record["createdAt"] = project.createdAt
        record["modifiedAt"] = project.modifiedAt
        record["projectData"] = try JSONEncoder().encode(project)

        do {
            _ = try await privateDatabase.save(record)

            try saveToiCloudDrive(project)

            print("✅ Project saved to iCloud: \(project.name)")
        } catch {
            throw SyncError.saveFailed(error.localizedDescription)
        }
    }

    /// Load all projects from iCloud
    func loadProjects() async throws -> [IconProject] {
        guard isAvailable else {
            throw SyncError.iCloudNotAvailable
        }

        let query = CKQuery(recordType: "IconProject", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]

        do {
            let (results, _) = try await privateDatabase.records(matching: query)

            var projects: [IconProject] = []

            for (_, result) in results {
                switch result {
                case .success(let record):
                    if let projectData = record["projectData"] as? Data,
                       let project = try? JSONDecoder().decode(IconProject.self, from: projectData) {
                        projects.append(project)
                    }
                case .failure(let error):
                    print("⚠️ Failed to load project: \(error)")
                }
            }

            return projects
        } catch {
            throw SyncError.loadFailed(error.localizedDescription)
        }
    }

    // MARK: - iCloud Drive File Operations

    private func saveToiCloudDrive<T: Codable>(_ item: T) throws {
        guard let ubiquityURL = ubiquityURL else {
            throw SyncError.iCloudDriveNotAvailable
        }

        let documentsURL = ubiquityURL.appendingPathComponent("Documents")

        try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)

        let fileName: String
        if let preset = item as? SharedPreset {
            fileName = "preset_\(preset.id.uuidString).json"
        } else if let project = item as? IconProject {
            fileName = "project_\(project.id.uuidString).json"
        } else {
            throw SyncError.unsupportedType
        }

        let fileURL = documentsURL.appendingPathComponent(fileName)
        let data = try JSONEncoder().encode(item)
        try data.write(to: fileURL)
    }

    private func deleteFromiCloudDrive(_ preset: SharedPreset) throws {
        guard let ubiquityURL = ubiquityURL else { return }

        let fileName = "preset_\(preset.id.uuidString).json"
        let fileURL = ubiquityURL.appendingPathComponent("Documents").appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    // MARK: - Sync Operations

    /// Sync local changes to iCloud
    func syncToCloud() async {
        guard isAvailable else { return }

        await MainActor.run {
            syncStatus.isSyncing = true
        }

        defer {
            Task { @MainActor in
                syncStatus.isSyncing = false
                syncStatus.lastSyncDate = Date()
            }
        }

        // Implementation would sync pending local changes
        print("☁️ Syncing to iCloud...")
    }

    /// Sync iCloud changes to local
    func syncFromCloud() async {
        guard isAvailable else { return }

        await MainActor.run {
            syncStatus.isSyncing = true
        }

        defer {
            Task { @MainActor in
                syncStatus.isSyncing = false
                syncStatus.lastSyncDate = Date()
            }
        }

        // Implementation would download remote changes
        print("☁️ Syncing from iCloud...")
    }

    /// Force full sync
    func forceSync() async {
        await syncToCloud()
        await syncFromCloud()
    }
}

// MARK: - Errors

enum SyncError: LocalizedError {
    case iCloudNotAvailable
    case iCloudDriveNotAvailable
    case saveFailed(String)
    case loadFailed(String)
    case deleteFailed(String)
    case parseError
    case unsupportedType

    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud is not available. Please sign in to iCloud in System Settings."
        case .iCloudDriveNotAvailable:
            return "iCloud Drive is not available."
        case .saveFailed(let message):
            return "Failed to save to iCloud: \(message)"
        case .loadFailed(let message):
            return "Failed to load from iCloud: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete from iCloud: \(message)"
        case .parseError:
            return "Failed to parse iCloud data"
        case .unsupportedType:
            return "Unsupported data type for iCloud sync"
        }
    }
}
