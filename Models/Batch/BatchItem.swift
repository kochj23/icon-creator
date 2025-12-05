import SwiftUI
import AppKit

/// Represents a single item in the batch processing queue
struct BatchItem: Identifiable, Equatable {
    let id: UUID
    var image: NSImage
    var targetProject: XcodeProject?
    var platforms: Set<Platform>
    var settings: IconSettings
    var status: BatchStatus
    var errorMessage: String?
    var progress: Double = 0.0

    init(
        id: UUID = UUID(),
        image: NSImage,
        targetProject: XcodeProject? = nil,
        platforms: Set<Platform> = [.iOS],
        settings: IconSettings = .default
    ) {
        self.id = id
        self.image = image
        self.targetProject = targetProject
        self.platforms = platforms
        self.settings = settings
        self.status = .pending
    }

    static func == (lhs: BatchItem, rhs: BatchItem) -> Bool {
        lhs.id == rhs.id
    }

    var displayName: String {
        targetProject?.displayName ?? "Untitled \(id.uuidString.prefix(8))"
    }

    var thumbnailSize: CGSize {
        CGSize(width: 64, height: 64)
    }
}

/// Status of a batch item
enum BatchStatus: Equatable {
    case pending
    case processing
    case completed
    case failed(String)

    var displayText: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed(let error): return "Failed: \(error)"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .processing: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .secondary
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
}
