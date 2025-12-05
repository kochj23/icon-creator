import SwiftUI
import UniformTypeIdentifiers

// MARK: - Main Content View

/// Main application view that coordinates image selection, editing, and export
struct ContentView: View {
    @StateObject private var iconGenerator = IconGenerator()
    @StateObject private var projectManager = XcodeProjectManager()
    @State private var selectedPlatforms: Set<Platform> = []
    @State private var showingPreview = false
    @State private var isExporting = false
    @State private var exportMessage = ""
    @State private var exportProgress: Double = 0.0
    @State private var validationWarning: String? = nil
    @State private var autoInstallEnabled = true
    @State private var showingProjectSelector = false
    @State private var pendingImage: NSImage? = nil

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header Section
            VStack(spacing: 8) {
                Text("Icon Creator")
                    .font(.largeTitle)
                    .bold()
                Text("Create app icons for all Apple platforms")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 30)
            .padding(.bottom, 20)

            Divider()

            // MARK: - Main Content
            ScrollView {
                VStack(spacing: 30) {
                    // Drop Zone for image selection
                    DropZoneView(
                        iconGenerator: iconGenerator,
                        validationWarning: $validationWarning,
                        projectManager: projectManager,
                        pendingImage: $pendingImage,
                        showingProjectSelector: $showingProjectSelector
                    )
                    .padding(.horizontal, 40)
                    .padding(.top, 30)

                    // Show validation warning if present
                    if let warning = validationWarning {
                        HStack {
                            Image(systemName: warning.contains("✂️") ? "scissors" : "exclamationmark.triangle.fill")
                                .foregroundColor(warning.contains("✂️") ? .blue : .orange)
                            Text(warning)
                                .font(.callout)
                                .foregroundColor(warning.contains("✂️") ? .blue : .orange)

                            // Show restore button if auto-cropped
                            if iconGenerator.wasAutoCropped {
                                Spacer()
                                Button("Restore Original") {
                                    iconGenerator.restoreOriginalImage()
                                    let validation = iconGenerator.validateSourceImage()
                                    validationWarning = validation.error
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding(.horizontal, 40)
                    }

                    if iconGenerator.sourceImage != nil {
                        // Image adjustment controls
                        ImageEditorView(iconGenerator: iconGenerator)
                            .padding(.horizontal, 40)

                        Divider()
                            .padding(.vertical, 10)

                        // Platform selection grid
                        PlatformSelectionView(selectedPlatforms: $selectedPlatforms)
                            .padding(.horizontal, 40)

                        Divider()
                            .padding(.vertical, 10)

                        // Xcode project selection
                        XcodeProjectSelectionView(
                            projectManager: projectManager,
                            autoInstallEnabled: $autoInstallEnabled
                        )
                        .padding(.horizontal, 40)

                        Divider()
                            .padding(.vertical, 10)

                        // Action buttons
                        VStack(spacing: 15) {
                            HStack(spacing: 20) {
                                Button(action: {
                                    showingPreview = true
                                }) {
                                    Label("Preview Icons", systemImage: "eye.fill")
                                        .frame(minWidth: 150)
                                }
                                .disabled(selectedPlatforms.isEmpty || isExporting)

                                Button(action: {
                                    Task {
                                        await exportIcons()
                                    }
                                }) {
                                    Label(isExporting ? "Exporting..." : "Export Icons",
                                          systemImage: isExporting ? "arrow.down.circle" : "square.and.arrow.down.fill")
                                        .frame(minWidth: 150)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(selectedPlatforms.isEmpty || isExporting)
                            }

                            // Progress indicator during export
                            if isExporting {
                                VStack(spacing: 8) {
                                    ProgressView(value: exportProgress, total: 1.0)
                                        .frame(width: 300)
                                    Text("\(Int(exportProgress * 100))% Complete")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Export status message
                            if !exportMessage.isEmpty {
                                Text(exportMessage)
                                    .font(.callout)
                                    .foregroundColor(exportMessage.contains("Success") ? .green : .red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .frame(minWidth: 800, minHeight: 700)
        .sheet(isPresented: $showingPreview) {
            PreviewView(iconGenerator: iconGenerator, platforms: Array(selectedPlatforms))
        }
        .sheet(isPresented: $showingProjectSelector) {
            ProjectSelectorSheet(
                projectManager: projectManager,
                pendingImage: $pendingImage,
                selectedPlatforms: $selectedPlatforms,
                onConfirm: { project in
                    // Apply the pending image
                    if let image = pendingImage {
                        iconGenerator.sourceImage = image
                        projectManager.selectedProject = project
                        autoInstallEnabled = true

                        // Auto-select platform based on project
                        if let platform = project.primaryPlatform {
                            selectedPlatforms = [platform]
                        }
                    }
                    showingProjectSelector = false
                    pendingImage = nil
                },
                onCancel: {
                    showingProjectSelector = false
                    pendingImage = nil
                }
            )
        }
        .onChange(of: iconGenerator.sourceImage) { newImage in
            // Validate image when it changes
            if newImage != nil {
                let validation = iconGenerator.validateSourceImage()
                validationWarning = validation.error
            } else {
                validationWarning = nil
            }
        }
    }

    // MARK: - Export Function

    /// Exports icons for all selected platforms
    /// Runs asynchronously with progress updates
    @MainActor
    private func exportIcons() async {
        isExporting = true
        exportMessage = ""
        exportProgress = 0.0

        // Determine export location based on whether auto-install is enabled
        let exportURL: URL
        let shouldInstall = autoInstallEnabled && projectManager.selectedProject != nil

        if shouldInstall {
            // Export to temporary directory for installation
            exportURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("IconCreator-\(UUID().uuidString)")
        } else {
            // Export to Pictures directory
            guard let picturesURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first else {
                exportMessage = "✗ Error: Cannot access Pictures directory"
                isExporting = false
                return
            }
            let timestamp = Int(Date().timeIntervalSince1970)
            exportURL = picturesURL.appendingPathComponent("IconCreator-\(timestamp)")
        }

        do {
            // Create export directory
            try FileManager.default.createDirectory(at: exportURL, withIntermediateDirectories: true)

            // Export icons for each platform
            let platformCount = Double(selectedPlatforms.count)
            var completedPlatforms = 0.0

            for platform in selectedPlatforms {
                let platformStart = completedPlatforms / platformCount

                // Export with progress tracking (capture generator reference to avoid actor isolation issues)
                let generator = self.iconGenerator
                try await Task.detached {
                    try generator.exportIcons(for: platform, to: exportURL) { progress in
                        let platformProgress = platformStart + (progress / platformCount)
                        Task { @MainActor in
                            self.exportProgress = platformProgress
                        }
                    }
                }.value

                completedPlatforms += 1.0
                exportProgress = completedPlatforms / platformCount
            }

            // If auto-install is enabled and a project is selected, install the icons
            if shouldInstall, let project = projectManager.selectedProject {
                // Only install the first selected platform (typically there should only be one when auto-installing)
                if let platform = selectedPlatforms.first {
                    let platformURL = exportURL.appendingPathComponent(platform.folderName)
                    let appiconsetURL = platformURL.appendingPathComponent("AppIcon.appiconset")

                    do {
                        try projectManager.installIcons(from: appiconsetURL, to: project, platform: platform)
                        exportMessage = "✓ Success! Icons installed to '\(project.displayName)' project"

                        // Optionally open the project
                        // projectManager.openInXcode(project)

                        // Clean up temporary files
                        try? FileManager.default.removeItem(at: exportURL)
                    } catch {
                        exportMessage = "✗ Installation Error: \(error.localizedDescription)"
                        print("❌ Installation failed: \(error)")
                    }
                }
            } else {
                // Success! (manual export)
                exportMessage = "✓ Success! Icons saved to: \(exportURL.path)"

                // Open the export folder
                NSWorkspace.shared.open(exportURL)
            }

            // Clear the message after 10 seconds
            Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                await MainActor.run { [self] in
                    // Note: ContentView is a struct (value type), so capturing self is safe
                    exportMessage = ""
                }
            }

        } catch {
            // Handle errors
            exportMessage = "✗ Error: \(error.localizedDescription)"
            print("❌ Export failed: \(error)")
        }

        isExporting = false
    }
}

// MARK: - Drop Zone View

/// View that handles drag & drop and image selection
struct DropZoneView: View {
    @ObservedObject var iconGenerator: IconGenerator
    @Binding var validationWarning: String?
    @ObservedObject var projectManager: XcodeProjectManager
    @Binding var pendingImage: NSImage?
    @Binding var showingProjectSelector: Bool
    @State private var isDragOver = false

    var body: some View {
        VStack(spacing: 20) {
            if let image = iconGenerator.sourceImage {
                // Show selected image
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 300, maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            } else {
                // Show drop zone placeholder
                VStack(spacing: 15) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(isDragOver ? .accentColor : .secondary)

                    Text("Drag & Drop Image Here")
                        .font(.title2)
                        .foregroundColor(isDragOver ? .accentColor : .primary)

                    Text("Or click to select")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Supports: PNG, JPG, HEIC, and more")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Recommended: 1024×1024 pixels or larger")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 350)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [10]))
                .foregroundColor(isDragOver ? .accentColor : .secondary)
        )
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDragOver ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.05))
        )
        .onDrop(of: [.image, .fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
        }
        .onTapGesture {
            selectImage()
        }
    }

    // MARK: - Drag & Drop Handling

    /// Handles dropped items (images or file URLs)
    /// - Parameter providers: Item providers from the drop
    /// - Returns: True if drop was handled successfully
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        // Try to load as image data
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
                if let error = error {
                    print("⚠️ Error loading image: \(error.localizedDescription)")
                    return
                }

                if let url = item as? URL {
                    loadImage(from: url)
                } else if let data = item as? Data, let image = NSImage(data: data) {
                    DispatchQueue.main.async {
                        iconGenerator.sourceImage = image
                    }
                }
            }
            return true
        }

        // Try to load as file URL
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let error = error {
                    print("⚠️ Error loading file: \(error.localizedDescription)")
                    return
                }

                if let url = item as? URL {
                    loadImage(from: url)
                }
            }
            return true
        }

        return false
    }

    /// Loads an image from a file URL
    /// - Parameter url: File URL to load from
    private func loadImage(from url: URL) {
        // Ensure we have read access
        guard url.startAccessingSecurityScopedResource() else {
            print("⚠️ Cannot access file: \(url.path)")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        if let image = NSImage(contentsOf: url) {
            DispatchQueue.main.async {
                // Show project selector if projects are available
                if !projectManager.projects.isEmpty {
                    pendingImage = image
                    showingProjectSelector = true
                } else {
                    // No projects found, load directly
                    iconGenerator.sourceImage = image
                }
            }
        } else {
            print("⚠️ Failed to load image from: \(url.path)")
        }
    }

    /// Shows a file picker dialog for image selection
    private func selectImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image, .png, .jpeg, .heic, .tiff, .bmp, .gif]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select an image file for your app icon"

        if panel.runModal() == .OK, let url = panel.url {
            loadImage(from: url)
        }
    }
}

// MARK: - Image Editor View

/// View for adjusting icon settings (scale, padding, background color)
struct ImageEditorView: View {
    @ObservedObject var iconGenerator: IconGenerator

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Adjust Icon")
                .font(.headline)

            HStack(spacing: 30) {
                // Left side: Controls
                VStack(alignment: .leading, spacing: 15) {
                    // Auto-crop toggle
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Auto-crop to square", isOn: $iconGenerator.autoCropToSquare)
                            .font(.subheadline)
                        Text("Automatically trim non-square images to square")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Scale slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Scale: \(Int(iconGenerator.scale * 100))%")
                            .font(.subheadline)
                        Slider(value: $iconGenerator.scale, in: 0.5...2.0)
                            .frame(width: 200)
                        Text("Adjust the size of your icon within the bounds")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Padding slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Padding: \(Int(iconGenerator.padding))%")
                            .font(.subheadline)
                        Slider(value: $iconGenerator.padding, in: 0...30)
                            .frame(width: 200)
                        Text("Add space around the icon")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Background color picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Background Color")
                            .font(.subheadline)
                        ColorPicker("", selection: $iconGenerator.backgroundColor)
                            .frame(width: 200)
                        Text("Choose a background color for the icon")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Right side: Live preview
                VStack {
                    Text("Preview")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let preview = iconGenerator.generatePreview(size: 128) {
                        Image(nsImage: preview)
                            .resizable()
                            .frame(width: 128, height: 128)
                            .cornerRadius(12)
                            .shadow(radius: 3)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 128, height: 128)
                            .overlay(
                                Text("Preview\nUnavailable")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            )
                    }
                }
            }

            // Clear button
            Button(action: {
                iconGenerator.sourceImage = nil
                iconGenerator.resetSettings()
            }) {
                Label("Clear Image", systemImage: "trash")
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Platform Selection View

/// View for selecting target platforms
struct PlatformSelectionView: View {
    @Binding var selectedPlatforms: Set<Platform>

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header with action buttons
            HStack {
                Text("Select Platforms")
                    .font(.headline)

                Spacer()

                Button("Select All") {
                    selectedPlatforms = Set(Platform.allCases)
                }
                .buttonStyle(.bordered)

                Button("Clear All") {
                    selectedPlatforms.removeAll()
                }
                .buttonStyle(.bordered)
            }

            // Platform grid
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(Platform.allCases, id: \.self) { platform in
                    PlatformButton(
                        platform: platform,
                        isSelected: selectedPlatforms.contains(platform)
                    ) {
                        togglePlatform(platform)
                    }
                }
            }

            // Selection info
            if !selectedPlatforms.isEmpty {
                Text("\(selectedPlatforms.count) platform\(selectedPlatforms.count == 1 ? "" : "s") selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    /// Toggles platform selection
    private func togglePlatform(_ platform: Platform) {
        if selectedPlatforms.contains(platform) {
            selectedPlatforms.remove(platform)
        } else {
            selectedPlatforms.insert(platform)
        }
    }
}

// MARK: - Platform Button

/// Individual platform selection button
struct PlatformButton: View {
    let platform: Platform
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: platform.iconName)
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .accentColor : .primary)

                Text(platform.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview View

/// Modal view for previewing all icon sizes
struct PreviewView: View {
    @ObservedObject var iconGenerator: IconGenerator
    let platforms: [Platform]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Icon Preview")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            // Preview content
            ScrollView {
                VStack(spacing: 30) {
                    ForEach(platforms, id: \.self) { platform in
                        PlatformPreviewSection(
                            iconGenerator: iconGenerator,
                            platform: platform
                        )
                    }
                }
                .padding()
            }
        }
        .frame(width: 700, height: 600)
    }
}

// MARK: - Platform Preview Section

/// Preview section for a single platform showing all icon sizes
struct PlatformPreviewSection: View {
    @ObservedObject var iconGenerator: IconGenerator
    let platform: Platform

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Platform header
            HStack {
                Image(systemName: platform.iconName)
                Text(platform.rawValue)
                    .font(.headline)
                Spacer()
                Text("\(platform.iconSizes.count) sizes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Icon grid
            let sizes = platform.iconSizes
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                ForEach(sizes, id: \.self) { size in
                    if let preview = iconGenerator.generatePreview(size: size) {
                        VStack(spacing: 5) {
                            Image(nsImage: preview)
                                .resizable()
                                .frame(width: CGFloat(min(size, 64)), height: CGFloat(min(size, 64)))
                                .cornerRadius(8)
                                .shadow(radius: 2)

                            Text("\(size)×\(size)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Project Selector Sheet

/// Modal sheet for selecting which Xcode project to target when adding an image
struct ProjectSelectorSheet: View {
    @ObservedObject var projectManager: XcodeProjectManager
    @Binding var pendingImage: NSImage?
    @Binding var selectedPlatforms: Set<Platform>
    let onConfirm: (XcodeProject) -> Void
    let onCancel: () -> Void

    @State private var selectedProject: XcodeProject?

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)

                Text("Select Xcode Project")
                    .font(.title)
                    .bold()

                Text("Which project is this icon for?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 30)

            // Image preview
            if let image = pendingImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .cornerRadius(12)
                    .shadow(radius: 3)
            }

            Divider()
                .padding(.horizontal, 40)

            // Project list
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Available Projects:")
                        .font(.headline)
                    Spacer()
                    if !projectManager.scannedDirectories.isEmpty {
                        Text("\(projectManager.projects.count) found in \(projectManager.scannedDirectories.count) location\(projectManager.scannedDirectories.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 40)

                ScrollView {
                    VStack(spacing: 8) {
                        if projectManager.projects.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "folder.badge.questionmark")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("No Xcode Projects Found")
                                    .font(.headline)
                                Text("Scanned \(projectManager.scannedDirectories.count) location\(projectManager.scannedDirectories.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 40)
                        } else {
                            ForEach(projectManager.projects) { project in
                                ProjectSelectionRow(
                                    project: project,
                                    isSelected: selectedProject?.id == project.id,
                                    onSelect: {
                                        selectedProject = project
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                }
                .frame(maxHeight: 300)
            }

            // Selected project info
            if let project = selectedProject {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto-detected platform: \(project.platformDescription)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let primary = project.primaryPlatform {
                            Text("Icons will be optimized for \(primary.rawValue)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal, 40)
            }

            Spacer()

            // Action buttons
            HStack(spacing: 15) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Continue") {
                    if let project = selectedProject {
                        onConfirm(project)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedProject == nil)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.bottom, 30)
        }
        .frame(width: 600, height: 650)
    }
}

// MARK: - Project Selection Row

/// Individual row for project selection
struct ProjectSelectionRow: View {
    let project: XcodeProject
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 15) {
                // Platform icon
                if let platform = project.primaryPlatform {
                    Image(systemName: platform.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                        .frame(width: 32)
                } else {
                    Image(systemName: "questionmark.app")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                        .frame(width: 32)
                }

                // Project info
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(project.platformDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 20))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Xcode Project Selection View

/// View for selecting an Xcode project for automatic icon installation
struct XcodeProjectSelectionView: View {
    @ObservedObject var projectManager: XcodeProjectManager
    @Binding var autoInstallEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header
            HStack {
                Text("Xcode Project Integration")
                    .font(.headline)

                Spacer()

                Button("Refresh Projects") {
                    projectManager.discoverProjects()
                }
                .buttonStyle(.bordered)
            }

            // Auto-install toggle
            Toggle("Automatically install icons into selected project", isOn: $autoInstallEnabled)
                .font(.subheadline)

            // Project picker
            if autoInstallEnabled {
                HStack {
                    Text("Target Project:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Picker("", selection: $projectManager.selectedProject) {
                        Text("Select a project...").tag(nil as XcodeProject?)
                        ForEach(projectManager.projects) { project in
                            Text(project.displayName).tag(project as XcodeProject?)
                        }
                    }
                    .frame(width: 300)

                    if let project = projectManager.selectedProject {
                        Button(action: {
                            projectManager.openInXcode(project)
                        }) {
                            Image(systemName: "arrow.up.right.square")
                        }
                        .buttonStyle(.borderless)
                        .help("Open in Xcode")
                    }
                }

                // Info text
                if projectManager.selectedProject != nil {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Icons will be installed directly into the project's Assets.xcassets folder")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if projectManager.projects.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("No Xcode projects found in /Users/kochj/Desktop/xcode/")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                } else {
                    HStack {
                        Image(systemName: "hand.point.up.left")
                            .foregroundColor(.secondary)
                        Text("Select a project to automatically install icons")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Project count and scanned directories info
            if !autoInstallEnabled || (!projectManager.projects.isEmpty && projectManager.selectedProject == nil) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(projectManager.projects.count) Xcode project\(projectManager.projects.count == 1 ? "" : "s") available")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !projectManager.scannedDirectories.isEmpty {
                        DisclosureGroup("Scanned \(projectManager.scannedDirectories.count) location\(projectManager.scannedDirectories.count == 1 ? "" : "s")") {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(projectManager.scannedDirectories, id: \.self) { directory in
                                    Text("• \(directory)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                            .padding(.top, 4)
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Previews

#Preview {
    ContentView()
}
