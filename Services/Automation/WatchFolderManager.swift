import Foundation
import AppKit

/// Monitors a folder for new images and automatically processes them
class WatchFolderManager: ObservableObject {
    @Published var isWatching = false
    @Published var watchedFolder: URL?
    @Published var processedCount = 0
    @Published var lastProcessedFile: String?

    private var fileMonitor: DispatchSourceFileSystemObject?
    private var processingRules: [ProcessingRule] = []

    // MARK: - Watch Folder Management

    func startWatching(folder: URL, rules: [ProcessingRule]) {
        stopWatching()

        guard FileManager.default.fileExists(atPath: folder.path) else {
            print("❌ Folder does not exist: \(folder.path)")
            return
        }

        self.watchedFolder = folder
        self.processingRules = rules

        // Open folder for monitoring
        let fileDescriptor = open(folder.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            print("❌ Cannot open folder for monitoring: \(folder.path)")
            return
        }

        // Create dispatch source
        fileMonitor = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend, .rename],
            queue: .main
        )

        fileMonitor?.setEventHandler { [weak self] in
            self?.handleFileSystemEvent()
        }

        fileMonitor?.setCancelHandler {
            close(fileDescriptor)
        }

        fileMonitor?.resume()
        isWatching = true

        print("👁️ Watching folder: \(folder.path)")
    }

    func stopWatching() {
        fileMonitor?.cancel()
        fileMonitor = nil
        isWatching = false
        print("🛑 Stopped watching folder")
    }

    // MARK: - File System Events

    private func handleFileSystemEvent() {
        guard let folder = watchedFolder else { return }

        // Scan for new images
        let newImages = scanForNewImages(in: folder)

        // Process each new image
        for imageURL in newImages {
            Task {
                await processImage(imageURL)
            }
        }
    }

    private func scanForNewImages(in folder: URL) -> [URL] {
        let imageExtensions = ["png", "jpg", "jpeg", "heic", "tiff", "bmp", "gif"]
        var images: [URL] = []

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )

            // Filter to images only
            images = contents.filter { url in
                imageExtensions.contains(url.pathExtension.lowercased())
            }

            // Sort by creation date (newest first)
            images.sort { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }

        } catch {
            print("⚠️ Error scanning folder: \(error)")
        }

        return images
    }

    private func processImage(_ imageURL: URL) async {
        guard let image = NSImage(contentsOf: imageURL) else {
            print("⚠️ Cannot load image: \(imageURL.path)")
            return
        }

        print("🎨 Processing: \(imageURL.lastPathComponent)")

        // Apply processing rules
        for rule in processingRules {
            do {
                try await applyRule(rule, to: image, sourceURL: imageURL)
            } catch {
                print("❌ Rule '\(rule.name)' failed: \(error)")
            }
        }

        DispatchQueue.main.async {
            self.processedCount += 1
            self.lastProcessedFile = imageURL.lastPathComponent
        }
    }

    private func applyRule(_ rule: ProcessingRule, to image: NSImage, sourceURL: URL) async throws {
        let generator = IconGenerator()
        generator.sourceImage = image

        for action in rule.actions {
            switch action {
            case .generateIcons(let platforms, let settings):
                generator.applySettings(settings)

                // Determine output location
                let outputURL = rule.outputDirectory ?? sourceURL.deletingLastPathComponent()
                let imageName = sourceURL.deletingPathExtension().lastPathComponent
                let imageOutputURL = outputURL.appendingPathComponent(imageName)

                // Create output directory
                try FileManager.default.createDirectory(at: imageOutputURL, withIntermediateDirectories: true)

                // Generate for each platform
                for platform in platforms {
                    try generator.exportIcons(for: platform, to: imageOutputURL)
                }

                print("✅ Generated icons for \(imageName)")

            case .applyPreset(let preset):
                generator.applySettings(preset.settings)

            case .validate:
                let validator = IconValidator()
                let result = validator.validate(image: image, for: .iOS)
                if !result.isValid {
                    print("⚠️ Validation failed for \(sourceURL.lastPathComponent)")
                }

            case .moveToFolder(let destination):
                try FileManager.default.moveItem(at: sourceURL, to: destination.appendingPathComponent(sourceURL.lastPathComponent))

            case .notify(let message):
                sendNotification(message.replacingOccurrences(of: "{filename}", with: sourceURL.lastPathComponent))
            }
        }
    }

    // MARK: - Notifications

    private func sendNotification(_ message: String) {
        let notification = UNMutableNotificationContent()
        notification.title = "Icon Creator"
        notification.body = message
        notification.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: notification,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Processing Rule

struct ProcessingRule: Identifiable, Codable {
    let id: UUID
    var name: String
    var actions: [Action]
    var outputDirectory: URL?
    var isEnabled: Bool

    init(id: UUID = UUID(), name: String, actions: [Action] = [], outputDirectory: URL? = nil) {
        self.id = id
        self.name = name
        self.actions = actions
        self.outputDirectory = outputDirectory
        self.isEnabled = true
    }

    enum Action: Codable {
        case generateIcons(platforms: Set<Platform>, settings: IconSettings)
        case applyPreset(IconPreset)
        case validate
        case moveToFolder(URL)
        case notify(String)
    }
}

import UserNotifications

extension WatchFolderManager {
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else if let error = error {
                print("❌ Notification permission denied: \(error)")
            }
        }
    }
}
