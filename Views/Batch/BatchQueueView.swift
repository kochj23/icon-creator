import SwiftUI

/// UI for managing the batch processing queue
struct BatchQueueView: View {
    @ObservedObject var batchManager: BatchProcessingManager
    @ObservedObject var projectManager: XcodeProjectManager
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Batch Queue")
                    .font(.headline)

                Spacer()

                // Statistics
                HStack(spacing: 15) {
                    StatusBadge(count: batchManager.pendingCount, color: .secondary, label: "Pending")
                    StatusBadge(count: batchManager.processingCount, color: .blue, label: "Processing")
                    StatusBadge(count: batchManager.completedCount, color: .green, label: "Done")
                    if batchManager.failedCount > 0 {
                        StatusBadge(count: batchManager.failedCount, color: .red, label: "Failed")
                    }
                }

                Spacer()

                // Actions
                HStack(spacing: 8) {
                    Button(action: { batchManager.removeCompleted() }) {
                        Label("Clear Completed", systemImage: "trash")
                    }
                    .disabled(batchManager.completedCount == 0)

                    Button(action: { batchManager.clearAll() }) {
                        Label("Clear All", systemImage: "trash.fill")
                    }
                    .disabled(batchManager.queue.isEmpty)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()

            Divider()

            // Queue list
            if batchManager.queue.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(batchManager.queue) { item in
                            BatchItemCard(item: item, projectManager: projectManager)
                                .contextMenu {
                                    Button("Remove", role: .destructive) {
                                        batchManager.remove(itemID: item.id)
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }

            Divider()

            // Footer with action button
            HStack {
                if batchManager.isProcessing {
                    ProgressView(value: batchManager.totalProgress, total: 1.0)
                        .frame(width: 200)

                    Text("\(Int(batchManager.totalProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    Task {
                        await batchManager.processQueue()
                    }
                }) {
                    Label(
                        batchManager.isProcessing ? "Processing..." : "Process Queue",
                        systemImage: batchManager.isProcessing ? "arrow.triangle.2.circlepath" : "play.fill"
                    )
                    .frame(minWidth: 150)
                }
                .buttonStyle(.borderedProminent)
                .disabled(batchManager.pendingCount == 0 || batchManager.isProcessing)
            }
            .padding()
        }
        .frame(minWidth: 700, minHeight: 400)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Items in Queue")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Drag multiple images to add them to the batch queue")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let count: Int
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Batch Item Card

struct BatchItemCard: View {
    let item: BatchItem
    let projectManager: XcodeProjectManager

    var body: some View {
        HStack(spacing: 15) {
            // Thumbnail
            Image(nsImage: item.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(item.displayName)
                    .font(.headline)

                HStack(spacing: 12) {
                    // Platforms
                    HStack(spacing: 4) {
                        ForEach(Array(item.platforms), id: \.self) { platform in
                            Image(systemName: platform.iconName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text("•")
                        .foregroundColor(.secondary)

                    // Project
                    if let project = item.targetProject {
                        Text(project.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Export to Pictures")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Status
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: item.status.icon)
                        .foregroundColor(item.status.color)

                    Text(item.status.displayText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(item.status.color)
                }

                // Progress bar for processing items
                if case .processing = item.status {
                    ProgressView(value: item.progress, total: 1.0)
                        .frame(width: 120)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(item.status.color.opacity(0.3), lineWidth: 1)
        )
    }
}
