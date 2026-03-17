import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Provider

struct IconCreatorProvider: AppIntentTimelineProvider {

    typealias Entry = IconCreatorEntry
    typealias Intent = ConfigurationAppIntent

    func placeholder(in context: Context) -> IconCreatorEntry {
        IconCreatorEntry.placeholder
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> IconCreatorEntry {
        let data = SharedDataManager.shared.loadWidgetData()
        return IconCreatorEntry(date: Date(), data: data, configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<IconCreatorEntry> {
        let data = SharedDataManager.shared.loadWidgetData()
        let entry = IconCreatorEntry(date: Date(), data: data, configuration: configuration)

        // Update every 15 minutes for status changes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

// MARK: - Widget Entry Views

struct IconCreatorWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: IconCreatorEntry

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: IconCreatorEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "app.badge.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Spacer()
                statusIndicator
            }

            Spacer()

            // Quick action or recent project
            if let lastImage = entry.data.lastUsedImage {
                quickCreateButton(lastImage: lastImage)
            } else if let recentProject = entry.data.recentProjects.first {
                recentProjectButton(project: recentProject)
            } else {
                newProjectButton
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch entry.data.generationStatus {
        case .idle:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .generating(let progress, _):
            CircularProgressView(progress: progress)
                .frame(width: 20, height: 20)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
        }
    }

    private func quickCreateButton(lastImage: LastUsedImage) -> some View {
        Link(destination: WidgetDeepLink.createFromLastImage()) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick Create")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(lastImage.name)
                    .font(.headline)
                    .lineLimit(1)
            }
        }
    }

    private func recentProjectButton(project: WidgetProject) -> some View {
        Link(destination: WidgetDeepLink.openProject(id: project.id)) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recent")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(project.name)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(project.iconCount) icons")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var newProjectButton: some View {
        Link(destination: WidgetDeepLink.newProject()) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Get Started")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("New Project")
                    .font(.headline)
            }
        }
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: IconCreatorEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left side - Status and Quick Create
            VStack(alignment: .leading, spacing: 12) {
                headerView
                statusView

                Spacer()

                if let lastImage = entry.data.lastUsedImage {
                    quickCreateView(lastImage: lastImage)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Right side - Recent Projects
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Projects")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if entry.data.recentProjects.isEmpty {
                    Spacer()
                    Text("No recent projects")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                } else {
                    ForEach(entry.data.recentProjects.prefix(3)) { project in
                        recentProjectRow(project: project)
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "app.badge.fill")
                .font(.title2)
                .foregroundStyle(.blue)
            Text("Icon Creator")
                .font(.headline)
        }
    }

    @ViewBuilder
    private var statusView: some View {
        HStack(spacing: 6) {
            switch entry.data.generationStatus {
            case .idle:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Ready")
                    .font(.caption)
            case .generating(let progress, let currentSize):
                CircularProgressView(progress: progress)
                    .frame(width: 16, height: 16)
                Text(currentSize)
                    .font(.caption)
            case .completed(let count, _):
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("\(count) icons generated")
                    .font(.caption)
            case .failed(let error):
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                Text(error)
                    .font(.caption)
                    .lineLimit(1)
            }
        }
    }

    private func quickCreateView(lastImage: LastUsedImage) -> some View {
        Link(destination: WidgetDeepLink.createFromLastImage()) {
            HStack {
                if let thumbnailData = lastImage.thumbnailData,
                   let nsImage = NSImage(data: thumbnailData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: "photo")
                        .frame(width: 32, height: 32)
                }

                VStack(alignment: .leading) {
                    Text("Quick Create")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(lastImage.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func recentProjectRow(project: WidgetProject) -> some View {
        Link(destination: WidgetDeepLink.openProject(id: project.id)) {
            HStack(spacing: 8) {
                if let thumbnailData = project.thumbnailData,
                   let nsImage = NSImage(data: thumbnailData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Image(systemName: "app.fill")
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text("\(project.iconCount) icons")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: IconCreatorEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            headerView

            // Status Bar
            statusBar

            Divider()

            // Quick Actions
            Text("Quick Actions")
                .font(.caption)
                .foregroundStyle(.secondary)

            quickActionsGrid

            Divider()

            // Recent Projects
            Text("Recent Projects")
                .font(.caption)
                .foregroundStyle(.secondary)

            recentProjectsList

            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "app.badge.fill")
                .font(.title)
                .foregroundStyle(.blue)
            VStack(alignment: .leading) {
                Text("Icon Creator")
                    .font(.headline)
                Text("App Icon Generator")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Link(destination: WidgetDeepLink.newProject()) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
        }
    }

    @ViewBuilder
    private var statusBar: some View {
        HStack {
            switch entry.data.generationStatus {
            case .idle:
                Label("Ready to create", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            case .generating(let progress, let currentSize):
                HStack(spacing: 8) {
                    CircularProgressView(progress: progress)
                        .frame(width: 20, height: 20)
                    Text("Generating \(currentSize)...")
                        .font(.caption)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            case .completed(let count, let duration):
                Label("\(count) icons in \(String(format: "%.1f", duration))s", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            case .failed(let error):
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            }

            Spacer()

            if let lastUpdate = SharedDataManager.shared.getLastUpdateDate() {
                Text(lastUpdate, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var quickActionsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            // Quick Create from Last Image
            if let lastImage = entry.data.lastUsedImage {
                quickActionButton(
                    title: "Last Image",
                    icon: "photo.fill",
                    destination: WidgetDeepLink.createFromLastImage()
                )
            }

            // Preset shortcuts
            ForEach(entry.data.favoritePresets.prefix(lastImageCount)) { preset in
                quickActionButton(
                    title: preset.name,
                    icon: preset.iconName,
                    destination: WidgetDeepLink.createWithPreset(presetName: preset.name)
                )
            }
        }
    }

    private var lastImageCount: Int {
        entry.data.lastUsedImage != nil ? 5 : 6
    }

    private func quickActionButton(title: String, icon: String, destination: URL) -> some View {
        Link(destination: destination) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var recentProjectsList: some View {
        VStack(spacing: 6) {
            if entry.data.recentProjects.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("No recent projects")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
            } else {
                ForEach(entry.data.recentProjects.prefix(4)) { project in
                    recentProjectRow(project: project)
                }
            }
        }
    }

    private func recentProjectRow(project: WidgetProject) -> some View {
        Link(destination: WidgetDeepLink.openProject(id: project.id)) {
            HStack(spacing: 12) {
                // Thumbnail
                if let thumbnailData = project.thumbnailData,
                   let nsImage = NSImage(data: thumbnailData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: "app.fill")
                                .foregroundStyle(.secondary)
                        }
                }

                // Project Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text("\(project.iconCount) icons")
                        Text("-")
                        Text(project.platforms.joined(separator: ", "))
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Timestamp
                Text(project.lastModified, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Helper Views

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 2)
                .opacity(0.3)
                .foregroundStyle(.blue)

            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .foregroundStyle(.blue)
                .rotationEffect(Angle(degrees: -90))
        }
    }
}

// MARK: - Widget Definition

@main
struct IconCreatorWidget: Widget {
    let kind: String = "IconCreatorWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: IconCreatorProvider()
        ) { entry in
            IconCreatorWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Icon Creator")
        .description("Quick access to recent projects and icon generation.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview Provider

#Preview("Small Widget", as: .systemSmall) {
    IconCreatorWidget()
} timeline: {
    IconCreatorEntry.placeholder
}

#Preview("Medium Widget", as: .systemMedium) {
    IconCreatorWidget()
} timeline: {
    IconCreatorEntry.placeholder
}

#Preview("Large Widget", as: .systemLarge) {
    IconCreatorWidget()
} timeline: {
    IconCreatorEntry.placeholder
}
