import Foundation
import CloudKit

//
//  CollaborationModels.swift
//  Icon Creator
//
//  Data models for collaborative features
//  Author: Jordan Koch
//  Date: 2026-01-21
//

// MARK: - Shared Preset Library

/// Preset that can be shared across team members
struct SharedPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var settings: IconSettings
    var author: String
    var createdAt: Date
    var modifiedAt: Date
    var isPublic: Bool
    var tags: [String]

    var recordName: String {
        "SharedPreset_\(id.uuidString)"
    }
}

// MARK: - Icon Project

/// Collaborative icon project
struct IconProject: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var owner: String
    var collaborators: [Collaborator]
    var createdAt: Date
    var modifiedAt: Date
    var status: ProjectStatus
    var versions: [IconVersion]

    enum ProjectStatus: String, Codable {
        case draft
        case inReview
        case approved
        case archived
    }

    var currentVersion: IconVersion? {
        versions.max(by: { $0.versionNumber < $1.versionNumber })
    }
}

struct Collaborator: Identifiable, Codable {
    let id: UUID
    var userID: String
    var displayName: String
    var email: String
    var role: CollaboratorRole
    var joinedAt: Date

    enum CollaboratorRole: String, Codable {
        case owner
        case editor
        case reviewer
        case viewer
    }

    var canEdit: Bool {
        role == .owner || role == .editor
    }

    var canReview: Bool {
        role == .owner || role == .reviewer || role == .editor
    }
}

// MARK: - Icon Version

/// Version of an icon within a project
struct IconVersion: Identifiable, Codable {
    let id: UUID
    var versionNumber: Int
    var iconDataURL: URL? // Local or CloudKit URL
    var author: String
    var createdAt: Date
    var changeDescription: String
    var status: VersionStatus
    var comments: [Comment]
    var approvals: [Approval]

    enum VersionStatus: String, Codable {
        case draft
        case pendingReview
        case changesRequested
        case approved
        case rejected
    }

    var isApproved: Bool {
        status == .approved
    }

    var requiresChanges: Bool {
        status == .changesRequested
    }
}

// MARK: - Comment & Annotation

/// Comment on an icon version
struct Comment: Identifiable, Codable {
    let id: UUID
    var author: String
    var authorEmail: String
    var text: String
    var createdAt: Date
    var modifiedAt: Date?
    var annotation: Annotation?
    var replies: [CommentReply]

    /// Visual annotation (e.g., pointing to specific area of icon)
    struct Annotation: Codable {
        var x: Double // 0-1, relative position
        var y: Double // 0-1, relative position
        var type: AnnotationType

        enum AnnotationType: String, Codable {
            case point
            case circle
            case arrow
        }
    }
}

struct CommentReply: Identifiable, Codable {
    let id: UUID
    var author: String
    var text: String
    var createdAt: Date
}

// MARK: - Approval

/// Approval or rejection of an icon version
struct Approval: Identifiable, Codable {
    let id: UUID
    var reviewer: String
    var reviewerEmail: String
    var decision: ApprovalDecision
    var feedback: String?
    var createdAt: Date

    enum ApprovalDecision: String, Codable {
        case approved
        case rejected
        case requestChanges
    }
}

// MARK: - Change History

/// History entry for tracking who changed what
struct ChangeHistoryEntry: Identifiable, Codable {
    let id: UUID
    var timestamp: Date
    var author: String
    var authorEmail: String
    var changeType: ChangeType
    var description: String
    var beforeValue: String?
    var afterValue: String?

    enum ChangeType: String, Codable {
        case created
        case modified
        case deleted
        case statusChanged
        case collaboratorAdded
        case collaboratorRemoved
        case commented
        case approved
        case rejected
    }

    var displayDescription: String {
        switch changeType {
        case .created:
            return "\(author) created this project"
        case .modified:
            return "\(author) modified \(description)"
        case .deleted:
            return "\(author) deleted \(description)"
        case .statusChanged:
            return "\(author) changed status from \(beforeValue ?? "unknown") to \(afterValue ?? "unknown")"
        case .collaboratorAdded:
            return "\(author) added \(description) as collaborator"
        case .collaboratorRemoved:
            return "\(author) removed \(description) from collaborators"
        case .commented:
            return "\(author) commented"
        case .approved:
            return "\(author) approved this version"
        case .rejected:
            return "\(author) rejected this version"
        }
    }
}

// MARK: - Notification

/// Notification for collaboration events
struct CollaborationNotification: Identifiable, Codable {
    let id: UUID
    var type: NotificationType
    var projectID: UUID
    var projectName: String
    var fromUser: String
    var message: String
    var timestamp: Date
    var isRead: Bool

    enum NotificationType: String, Codable {
        case mentioned
        case statusChanged
        case commentAdded
        case approvalRequested
        case approved
        case rejected
        case collaboratorAdded
    }
}

// MARK: - Sync Status

/// iCloud sync status tracking
struct SyncStatus: Codable {
    var lastSyncDate: Date?
    var isSyncing: Bool
    var pendingChanges: Int
    var errors: [SyncError]

    struct SyncError: Codable {
        var timestamp: Date
        var errorDescription: String
        var recordID: String?
    }
}

// MARK: - Team Settings

/// Team-wide settings
struct TeamSettings: Codable {
    var teamName: String
    var approvalRequired: Bool
    var minimumApprovers: Int
    var allowPublicPresets: Bool
    var notificationPreferences: NotificationPreferences

    struct NotificationPreferences: Codable {
        var emailOnComment: Bool
        var emailOnApproval: Bool
        var emailOnStatusChange: Bool
        var pushNotifications: Bool
    }

    static let `default` = TeamSettings(
        teamName: "My Team",
        approvalRequired: true,
        minimumApprovers: 1,
        allowPublicPresets: true,
        notificationPreferences: .init(
            emailOnComment: true,
            emailOnApproval: true,
            emailOnStatusChange: true,
            pushNotifications: true
        )
    )
}
