import SwiftUI
import AppKit

/// Manages batch processing of multiple icons
@MainActor
class BatchProcessingManager: ObservableObject {
    @Published var queue: [BatchItem] = []
    @Published var isProcessing = false
    @Published var currentItem: BatchItem?
    @Published var totalProgress: Double = 0.0

    private var iconGenerator = IconGenerator()

    // MARK: - Queue Management

    func add(
        image: NSImage,
        project: XcodeProject? = nil,
        platforms: Set<Platform> = [.iOS],
        settings: IconSettings = .default
    ) {
        let item = BatchItem(
            image: image,
            targetProject: project,
            platforms: platforms,
            settings: settings
        )
        queue.append(item)
    }

    func addMultiple(images: [NSImage], defaultSettings: IconSettings = .default) {
        for image in images {
            add(image: image, settings: defaultSettings)
        }
    }

    func remove(itemID: UUID) {
        queue.removeAll { $0.id == itemID }
    }

    func removeCompleted() {
        queue.removeAll { item in
            if case .completed = item.status {
                return true
            }
            return false
        }
    }

    func clearAll() {
        queue.removeAll()
    }

    func moveItem(from source: IndexSet, to destination: Int) {
        queue.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Batch Processing

    func processQueue() async {
        guard !isProcessing, !queue.isEmpty else { return }

        isProcessing = true
        totalProgress = 0.0

        let pendingItems = queue.filter { item in
            if case .pending = item.status {
                return true
            }
            return false
        }

        let totalItems = Double(pendingItems.count)

        for (index, item) in pendingItems.enumerated() {
            currentItem = item
            await processItem(item)

            totalProgress = Double(index + 1) / totalItems
        }

        currentItem = nil
        isProcessing = false
    }

    private func processItem(_ item: BatchItem) async {
        // Update status to processing
        if let index = queue.firstIndex(where: { $0.id == item.id }) {
            queue[index].status = .processing
            queue[index].progress = 0.0
        }

        // Apply settings to icon generator
        iconGenerator.sourceImage = item.image
        applySettings(item.settings, to: iconGenerator)

        // Determine export location
        let exportURL: URL
        let shouldInstall = item.targetProject != nil

        if shouldInstall {
            exportURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("IconCreator-Batch-\(item.id.uuidString)")
        } else {
            guard let picturesURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first else {
                updateItemStatus(itemID: item.id, status: .failed("Cannot access Pictures directory"))
                return
            }
            let timestamp = Int(Date().timeIntervalSince1970)
            exportURL = picturesURL.appendingPathComponent("IconCreator-Batch-\(timestamp)-\(item.id.uuidString)")
        }

        do {
            // Create export directory
            try FileManager.default.createDirectory(at: exportURL, withIntermediateDirectories: true)

            // Export icons for each platform
            let platformCount = Double(item.platforms.count)
            var completedPlatforms = 0.0

            for platform in item.platforms {
                let platformStart = completedPlatforms / platformCount

                try await iconGenerator.exportIcons(for: platform, to: exportURL) { progress in
                    let itemProgress = platformStart + (progress / platformCount)
                    self.updateItemProgress(itemID: item.id, progress: itemProgress)
                }

                completedPlatforms += 1.0
            }

            // If auto-install is enabled and a project is selected, install the icons
            if shouldInstall, let project = item.targetProject {
                // Install for all platforms
                for platform in item.platforms {
                    let platformURL = exportURL.appendingPathComponent(platform.folderName)
                    let appiconsetURL = platformURL.appendingPathComponent("AppIcon.appiconset")

                    let projectManager = XcodeProjectManager()
                    try projectManager.installIcons(from: appiconsetURL, to: project, platform: platform)
                }

                // Clean up temporary files
                try? FileManager.default.removeItem(at: exportURL)
            }

            // Success
            updateItemStatus(itemID: item.id, status: .completed)

        } catch {
            // Failure
            updateItemStatus(itemID: item.id, status: .failed(error.localizedDescription))
        }
    }

    private func applySettings(_ settings: IconSettings, to generator: IconGenerator) {
        generator.scale = settings.scale
        generator.padding = settings.padding
        generator.backgroundColor = settings.backgroundColor.color
        generator.autoCropToSquare = settings.autoCropToSquare
        // Effects will be applied in image processor
    }

    private func updateItemStatus(itemID: UUID, status: BatchStatus) {
        if let index = queue.firstIndex(where: { $0.id == itemID }) {
            queue[index].status = status
        }
    }

    private func updateItemProgress(itemID: UUID, progress: Double) {
        if let index = queue.firstIndex(where: { $0.id == itemID }) {
            queue[index].progress = progress
        }
    }

    // MARK: - Statistics

    var completedCount: Int {
        queue.filter { item in
            if case .completed = item.status {
                return true
            }
            return false
        }.count
    }

    var failedCount: Int {
        queue.filter { item in
            if case .failed = item.status {
                return true
            }
            return false
        }.count
    }

    var pendingCount: Int {
        queue.filter { item in
            if case .pending = item.status {
                return true
            }
            return false
        }.count
    }

    var processingCount: Int {
        queue.filter { item in
            if case .processing = item.status {
                return true
            }
            return false
        }.count
    }
}
