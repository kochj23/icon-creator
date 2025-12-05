import SwiftUI

/// Library view for browsing and managing presets
struct PresetLibraryView: View {
    @ObservedObject var presetManager: PresetManager
    @ObservedObject var iconGenerator: IconGenerator
    @Environment(\.dismiss) var dismiss
    @State private var showingPresetEditor = false
    @State private var editingPreset: IconPreset?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Icon Presets")
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

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // Built-in presets
                    PresetSection(
                        title: "Built-in Presets",
                        presets: presetManager.builtInPresets,
                        selectedPreset: $presetManager.selectedPreset,
                        onApply: { preset in
                            presetManager.applyPreset(preset, to: iconGenerator)
                            dismiss()
                        },
                        onEdit: nil
                    )

                    if !presetManager.userPresets.isEmpty {
                        Divider()
                            .padding(.horizontal)

                        // User presets
                        PresetSection(
                            title: "My Presets",
                            presets: presetManager.userPresets,
                            selectedPreset: $presetManager.selectedPreset,
                            onApply: { preset in
                                presetManager.applyPreset(preset, to: iconGenerator)
                                dismiss()
                            },
                            onEdit: { preset in
                                editingPreset = preset
                                showingPresetEditor = true
                            },
                            onDelete: { preset in
                                presetManager.deletePreset(id: preset.id)
                            },
                            onDuplicate: { preset in
                                let duplicate = presetManager.duplicatePreset(preset)
                                presetManager.savePreset(duplicate)
                            }
                        )
                    }
                }
                .padding()
            }

            Divider()

            // Footer actions
            HStack {
                Button(action: {
                    editingPreset = nil
                    showingPresetEditor = true
                }) {
                    Label("New Preset", systemImage: "plus")
                }

                Button(action: {
                    presetManager.importPresetFromFile()
                }) {
                    Label("Import", systemImage: "square.and.arrow.down")
                }

                Spacer()
            }
            .padding()
        }
        .frame(width: 700, height: 600)
        .sheet(isPresented: $showingPresetEditor) {
            PresetEditorSheet(
                preset: editingPreset,
                iconGenerator: iconGenerator,
                onSave: { preset in
                    presetManager.savePreset(preset)
                    showingPresetEditor = false
                }
            )
        }
    }
}

// MARK: - Preset Section

struct PresetSection: View {
    let title: String
    let presets: [IconPreset]
    @Binding var selectedPreset: IconPreset?
    let onApply: (IconPreset) -> Void
    let onEdit: ((IconPreset) -> Void)?
    var onDelete: ((IconPreset) -> Void)? = nil
    var onDuplicate: ((IconPreset) -> Void)? = nil

    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 15)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(presets) { preset in
                    PresetCard(
                        preset: preset,
                        isSelected: selectedPreset?.id == preset.id,
                        onApply: { onApply(preset) },
                        onEdit: onEdit != nil ? { onEdit?(preset) } : nil,
                        onDelete: onDelete != nil ? { onDelete?(preset) } : nil,
                        onDuplicate: onDuplicate != nil ? { onDuplicate?(preset) } : nil
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Preset Card

struct PresetCard: View {
    let preset: IconPreset
    let isSelected: Bool
    let onApply: () -> Void
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?
    let onDuplicate: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            // Preview
            if let thumbnailData = preset.thumbnail,
               let nsImage = NSImage(data: thumbnailData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)
            } else {
                // Placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(preset.settings.backgroundColor.color)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundColor(.secondary)
                    )
            }

            // Name
            Text(preset.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            // Apply button
            Button("Apply") {
                onApply()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(width: 150, height: 160)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .contextMenu {
            if let onEdit = onEdit {
                Button("Edit", action: onEdit)
            }

            if let onDuplicate = onDuplicate {
                Button("Duplicate", action: onDuplicate)
            }

            if let onDelete = onDelete {
                Divider()
                Button("Delete", role: .destructive, action: onDelete)
            }
        }
    }
}

// MARK: - Preset Editor Sheet

struct PresetEditorSheet: View {
    let preset: IconPreset?
    @ObservedObject var iconGenerator: IconGenerator
    let onSave: (IconPreset) -> Void

    @State private var name: String
    @State private var settings: IconSettings

    @Environment(\.dismiss) var dismiss

    init(preset: IconPreset?, iconGenerator: IconGenerator, onSave: @escaping (IconPreset) -> Void) {
        self.preset = preset
        self.iconGenerator = iconGenerator
        self.onSave = onSave

        // Initialize state
        _name = State(initialValue: preset?.name ?? "New Preset")
        _settings = State(initialValue: preset?.settings ?? IconSettings.default)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(preset == nil ? "New Preset" : "Edit Preset")
                .font(.title2)
                .bold()

            // Name field
            TextField("Preset Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)

            // Settings preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Settings")
                    .font(.headline)

                HStack {
                    Text("Scale:")
                    Slider(value: $settings.scale, in: 0.5...2.0)
                        .frame(width: 200)
                    Text("\(Int(settings.scale * 100))%")
                        .font(.caption)
                }

                HStack {
                    Text("Padding:")
                    Slider(value: $settings.padding, in: 0...30)
                        .frame(width: 200)
                    Text("\(Int(settings.padding))%")
                        .font(.caption)
                }

                ColorPicker("Background", selection: Binding(
                    get: { settings.backgroundColor.color },
                    set: { settings.backgroundColor = ColorComponents($0) }
                ))
                .frame(width: 300)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(10)

            // Actions
            HStack(spacing: 15) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    let savedPreset = IconPreset(
                        id: preset?.id ?? UUID(),
                        name: name,
                        settings: settings,
                        thumbnail: generateThumbnail(),
                        isBuiltIn: false
                    )
                    onSave(savedPreset)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 500, height: 400)
    }

    private func generateThumbnail() -> Data? {
        guard let source = iconGenerator.sourceImage else { return nil }

        // Apply settings to generate preview
        let processor = ImageProcessor()
        if let processed = processor.processImage(source, with: settings, targetSize: 128),
           let tiffData = processed.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapImage.representation(using: .png, properties: [:]) {
            return pngData
        }
        return nil
    }
}
