import SwiftUI

// MARK: - Project Locations Settings View

/// Configuration view for managing where Icon Creator looks for Xcode projects
///
/// Supports:
/// - Local directories
/// - Git repositories (GitHub, GitLab, Bitbucket)
/// - Cloud storage (iCloud, Dropbox, Google Drive, OneDrive)
/// - Spotlight search
/// - Xcode recent projects
/// - Recent projects history
///
/// **Author**: Jordan Koch
struct ProjectLocationsView: View {
    @ObservedObject var locationManager = ProjectLocationManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var showingAddDirectory = false
    @State private var showingAddGit = false
    @State private var showingImport = false
    @State private var statusMessage = ""
    @State private var newGitURL = ""
    @State private var newGitName = ""
    @State private var newGitClonePath = NSHomeDirectory() + "/Developer/GitRepos"

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project Locations")
                            .font(.largeTitle)
                            .bold()

                        Text("Configure where Icon Creator searches for Xcode projects")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 30)

                    Divider()

                    // Quick Actions
                    HStack(spacing: 15) {
                        Button(action: { showingAddDirectory = true }) {
                            Label("Add Directory", systemImage: "folder.badge.plus")
                        }
                        .buttonStyle(.bordered)

                        Button(action: { showingAddGit = true }) {
                            Label("Clone from Git", systemImage: "arrow.down.doc")
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Menu("More") {
                            Button("Import Configuration") {
                                showingImport = true
                            }

                            Button("Export Configuration") {
                                exportConfiguration()
                            }

                            Divider()

                            Button("Remove Invalid", role: .destructive) {
                                locationManager.removeInvalidLocations()
                            }

                            Button("Validate All") {
                                validateAll()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal, 40)

                    // Status Message
                    if !statusMessage.isEmpty {
                        HStack {
                            Image(systemName: "info.circle")
                            Text(statusMessage)
                                .font(.callout)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 40)
                    }

                    // Locations List
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Configured Locations (\(locationManager.locations.count))")
                            .font(.headline)
                            .padding(.horizontal, 40)

                        ForEach(locationManager.locations) { location in
                            LocationRow(location: location, locationManager: locationManager)
                        }

                        if locationManager.locations.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "folder.badge.questionmark")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)

                                Text("No Locations Configured")
                                    .font(.headline)

                                Text("Add a directory or clone a Git repository to get started")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    }

                    Divider()

                    // Recent Projects
                    if !locationManager.recentProjects.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Recent Projects")
                                    .font(.headline)

                                Spacer()

                                Button("Clear") {
                                    locationManager.clearRecentProjects()
                                }
                                .buttonStyle(.borderless)
                                .foregroundColor(.red)
                            }
                            .padding(.horizontal, 40)

                            ForEach(locationManager.recentProjects, id: \.self) { projectPath in
                                RecentProjectRow(path: projectPath)
                            }
                        }

                        Divider()
                    }

                    // Scan Status
                    if locationManager.isScanning {
                        HStack {
                            ProgressView()
                            Text(locationManager.scanProgress)
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 40)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .frame(minWidth: 900, minHeight: 700)
        .sheet(isPresented: $showingAddDirectory) {
            AddDirectorySheet(locationManager: locationManager, isPresented: $showingAddDirectory)
        }
        .sheet(isPresented: $showingAddGit) {
            AddGitRepositorySheet(
                locationManager: locationManager,
                isPresented: $showingAddGit,
                gitURL: $newGitURL,
                gitName: $newGitName,
                clonePath: $newGitClonePath
            )
        }
        .fileImporter(
            isPresented: $showingImport,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importConfiguration(from: url)
                }
            case .failure(let error):
                statusMessage = "Import failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Actions

    private func exportConfiguration() {
        do {
            let url = try locationManager.exportLocations()
            NSWorkspace.shared.activateFileViewerSelecting([url])
            statusMessage = "Configuration exported to Documents"
        } catch {
            statusMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    private func importConfiguration(from url: URL) {
        do {
            let count = try locationManager.importLocations(from: url)
            statusMessage = "Imported \(count) location(s)"
        } catch {
            statusMessage = "Import failed: \(error.localizedDescription)"
        }
    }

    private func validateAll() {
        let invalid = locationManager.validateLocations()
        if invalid.isEmpty {
            statusMessage = "All locations are valid ✓"
        } else {
            statusMessage = "\(invalid.count) invalid location(s) found"
        }
    }
}

// MARK: - Location Row

struct LocationRow: View {
    let location: ProjectLocation
    @ObservedObject var locationManager: ProjectLocationManager

    @State private var showingDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 15) {
                // Icon and toggle
                HStack(spacing: 12) {
                    Image(systemName: location.type.icon)
                        .font(.system(size: 24))
                        .foregroundColor(location.isEnabled ? .blue : .secondary)
                        .frame(width: 32)

                    Toggle("", isOn: Binding(
                        get: { location.isEnabled },
                        set: { _ in locationManager.toggleLocation(location) }
                    ))
                    .labelsHidden()
                }

                // Location info
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.headline)

                    HStack(spacing: 8) {
                        Text(location.type.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if !location.isValid {
                            Label("Invalid", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    Text(location.displayPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                // Stats
                if let count = location.projectCount {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(count)")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.blue)

                        Text("projects")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Actions
                HStack(spacing: 8) {
                    Button(action: { showingDetails.toggle() }) {
                        Image(systemName: "info.circle")
                    }
                    .buttonStyle(.borderless)

                    if location.type == .gitRepository {
                        Button(action: { pullGitRepository() }) {
                            Image(systemName: "arrow.down.circle")
                        }
                        .buttonStyle(.borderless)
                        .help("Pull latest changes")
                    }

                    Button(action: { locationManager.removeLocation(location) }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                }
            }

            // Details (expanded)
            if showingDetails {
                VStack(alignment: .leading, spacing: 8) {
                    if let lastScanned = location.lastScanned {
                        HStack {
                            Text("Last scanned:")
                            Text(relativeDateString(lastScanned))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    if let gitURL = location.gitURL {
                        HStack {
                            Text("Repository:")
                            Text(gitURL)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    Text("Added: \(location.dateAdded.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal, 40)
    }

    private func pullGitRepository() {
        guard let path = location.path else { return }

        Task {
            do {
                try await locationManager.pullRepository(at: path) { progress in
                    print(progress)
                }
            } catch {
                print("Pull failed: \(error)")
            }
        }
    }

    private func relativeDateString(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Recent Project Row

struct RecentProjectRow: View {
    let path: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundColor(.secondary)

            Text((path as NSString).lastPathComponent)
                .font(.body)

            Spacer()

            Text((path as NSString).deletingLastPathComponent)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Button(action: {
                NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: (path as NSString).deletingLastPathComponent)
            }) {
                Image(systemName: "arrow.up.right.square")
            }
            .buttonStyle(.borderless)
            .help("Reveal in Finder")
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal, 40)
    }
}

// MARK: - Add Directory Sheet

struct AddDirectorySheet: View {
    @ObservedObject var locationManager: ProjectLocationManager
    @Binding var isPresented: Bool

    @State private var selectedPath: String?
    @State private var locationName: String = ""
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(spacing: 25) {
            Text("Add Directory")
                .font(.title)
                .bold()

            VStack(alignment: .leading, spacing: 12) {
                Text("Directory Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("e.g., My Projects", text: $locationName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 400)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Directory Path")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Text(selectedPath ?? "No directory selected")
                        .font(.body)
                        .foregroundColor(selectedPath != nil ? .primary : .secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(width: 300, alignment: .leading)

                    Button("Browse...") {
                        if let path = locationManager.selectDirectory() {
                            selectedPath = path
                            if locationName.isEmpty {
                                locationName = (path as NSString).lastPathComponent
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }

            if !errorMessage.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text(errorMessage)
                }
                .font(.callout)
                .foregroundColor(.red)
            }

            Spacer()

            HStack(spacing: 15) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Add") {
                    addDirectory()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedPath == nil)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(40)
        .frame(width: 600, height: 400)
    }

    private func addDirectory() {
        guard let path = selectedPath else {
            errorMessage = "Please select a directory"
            return
        }

        let name = locationName.isEmpty ? (path as NSString).lastPathComponent : locationName

        if locationManager.addLocalDirectory(path: path, name: name) != nil {
            isPresented = false
        } else {
            errorMessage = "Directory already exists or is invalid"
        }
    }
}

// MARK: - Add Git Repository Sheet

struct AddGitRepositorySheet: View {
    @ObservedObject var locationManager: ProjectLocationManager
    @Binding var isPresented: Bool
    @Binding var gitURL: String
    @Binding var gitName: String
    @Binding var clonePath: String

    @State private var isCloning = false
    @State private var cloneProgress = ""
    @State private var errorMessage = ""

    // Common repository examples
    let exampleRepos = [
        ("My GitHub Repo", "https://github.com/username/repo.git"),
        ("GitLab Project", "https://gitlab.com/username/project.git"),
        ("Bitbucket Repo", "https://bitbucket.org/username/repo.git")
    ]

    var body: some View {
        VStack(spacing: 25) {
            Text("Clone Git Repository")
                .font(.title)
                .bold()

            VStack(alignment: .leading, spacing: 12) {
                Text("Repository URL")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("https://github.com/username/repo.git", text: $gitURL)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 500)

                // Examples
                DisclosureGroup("Examples") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(exampleRepos, id: \.0) { example in
                            Button(action: { gitURL = example.1 }) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(example.0)
                                        .font(.caption)
                                        .bold()
                                    Text(example.1)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)
                }
                .font(.caption)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Repository Name (Optional)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("Auto-detected from URL", text: $gitName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 500)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Clone Destination")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    TextField("Local path", text: $clonePath)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 400)

                    Button("Browse...") {
                        if let path = locationManager.selectDirectory(title: "Select Clone Destination") {
                            clonePath = path
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }

            if !errorMessage.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text(errorMessage)
                }
                .font(.callout)
                .foregroundColor(.red)
            }

            if isCloning {
                VStack(spacing: 8) {
                    ProgressView()
                    Text(cloneProgress)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            Spacer()

            HStack(spacing: 15) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                .disabled(isCloning)

                Button(isCloning ? "Cloning..." : "Clone") {
                    cloneRepository()
                }
                .buttonStyle(.borderedProminent)
                .disabled(gitURL.isEmpty || isCloning)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(40)
        .frame(width: 700, height: 550)
    }

    private func cloneRepository() {
        errorMessage = ""

        // Create location
        guard let location = locationManager.addGitRepository(
            url: gitURL,
            name: gitName.isEmpty ? nil : gitName,
            clonePath: clonePath
        ) else {
            errorMessage = "Invalid repository URL or already exists"
            return
        }

        isCloning = true

        Task {
            do {
                let path = try await locationManager.cloneRepository(location) { progress in
                    cloneProgress = progress
                }
                await MainActor.run {
                    isCloning = false
                    cloneProgress = "Successfully cloned to \(path)"
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    isCloning = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProjectLocationsView()
}
