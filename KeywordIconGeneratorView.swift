//
//  KeywordIconGeneratorView.swift
//  Icon Creator
//
//  UI for keyword-based icon generation
//  Inspired by VibeScape by Jason Cox (https://github.com/jasonacox/VibeScape)
//
//  Author: Jordan Koch
//  Date: 2026-01-20
//

import SwiftUI

struct KeywordIconGeneratorView: View {
    @StateObject private var generator = KeywordIconGenerator()
    @StateObject private var iconProcessor = IconGenerator()
    @State private var keywordInput: String = ""
    @State private var appNameInput: String = ""
    @State private var selectedCategory: IconCategory? = nil
    @State private var showingCategoryPicker = false
    @State private var selectedIcon: GeneratedIcon? = nil
    @State private var showingSavePicker = false
    @State private var showingProjectSelector = false
    @State private var installMessage: String = ""
    @State private var isInstalling = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerSection

            // Input section
            inputSection

            // Category presets
            categoryPresetsSection

            // Generation controls
            generationControlsSection

            // Results
            if !generator.generatedIcons.isEmpty {
                resultsSection
            }

            // Install message
            if !installMessage.isEmpty {
                Text(installMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.1))
                    )
            }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingProjectSelector) {
            XcodeProjectPickerView(
                selectedIcon: $selectedIcon,
                iconProcessor: iconProcessor,
                isInstalling: $isInstalling,
                installMessage: $installMessage,
                onComplete: {
                    showingProjectSelector = false
                }
            )
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("✨ Keyword Icon Generator")
                .font(.system(size: 28, weight: .bold))

            HStack(spacing: 4) {
                Text("Powered by")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Link("VibeScape", destination: URL(string: "https://github.com/jasonacox/VibeScape")!)
                    .font(.caption)

                Text("concept by Jason Cox")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                if let backend = AIBackendManager.shared.activeBackend {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("AI: \(backend.rawValue)")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("AI Not Configured - Click 'AI Config' button")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Text("Generate app icons from simple keywords using AI")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("App Details")
                .font(.headline)

            TextField("App Name (optional)", text: $appNameInput)
                .textFieldStyle(.roundedBorder)

            HStack {
                TextField("Enter keywords (e.g., music, chat, weather)...", text: $keywordInput)
                    .textFieldStyle(.roundedBorder)

                Button("Expand Keywords") {
                    expandKeywords()
                }
                .disabled(keywordInput.isEmpty || generator.isGenerating)
            }

            if !keywordInput.isEmpty {
                Text("Keywords: \(parseKeywords().joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }

    // MARK: - Category Presets

    private var categoryPresetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start - Pick a Category")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(IconCategory.allCases, id: \.self) { category in
                    Button {
                        selectCategory(category)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 24))
                            Text(category.rawValue)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedCategory == category ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedCategory == category ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }

    // MARK: - Generation Controls

    private var generationControlsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Picker("Provider", selection: $generator.selectedProvider) {
                    ForEach(ImageProvider.allCases, id: \.self) { provider in
                        HStack {
                            Image(systemName: provider.icon)
                            Text(provider.rawValue)
                        }
                        .tag(provider)
                    }
                }

                Picker("Variants", selection: $generator.numberOfVariants) {
                    Text("1").tag(1)
                    Text("3").tag(3)
                    Text("5").tag(5)
                    Text("10").tag(10)
                }
            }

            // Provider-specific configuration
            if generator.selectedProvider == .comfyUI {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("ComfyUI URL", text: $generator.comfyUIURL)
                        .textFieldStyle(.roundedBorder)

                    Link("Install ComfyUI", destination: URL(string: "https://github.com/comfyanonymous/ComfyUI")!)
                        .font(.caption)

                    Text("Default: http://localhost:8188 (ComfyUI)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)

                    Text("Start: cd ComfyUI && python main.py")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .textSelection(.enabled)
                }
            }

            if generator.selectedProvider == .automatic1111 {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Automatic1111 URL", text: $generator.automatic1111URL)
                        .textFieldStyle(.roundedBorder)

                    Link("Install Automatic1111", destination: URL(string: "https://github.com/AUTOMATIC1111/stable-diffusion-webui")!)
                        .font(.caption)

                    Text("Default: http://localhost:7860 (WebUI)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)

                    Text("Start: cd stable-diffusion-webui && ./webui.sh --api")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .textSelection(.enabled)
                }
            }

            if generator.selectedProvider == .swarmUI {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("SwarmUI URL", text: $generator.swarmUIURL)
                        .textFieldStyle(.roundedBorder)

                    Link("Install SwarmUI", destination: URL(string: "https://github.com/mcmonkeyprojects/SwarmUI")!)
                        .font(.caption)

                    Text("Default: http://localhost:7801")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if generator.selectedProvider == .openAI {
                VStack(alignment: .leading, spacing: 4) {
                    SecureField("OpenAI API Key", text: $generator.openAIKey)
                        .textFieldStyle(.roundedBorder)

                    Link("Get API Key", destination: URL(string: "https://platform.openai.com/api-keys")!)
                        .font(.caption)

                    Text("DALL-E 3: ~$0.04 per image")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if generator.selectedProvider == .stablediffusion {
                Text("⚠️ Stable Diffusion deprecated. Use ComfyUI or Automatic1111 instead.")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                    )
                    .textSelection(.enabled)
            }

            Button(generator.isGenerating ? "Generating..." : "Generate Icons") {
                generateIcons()
            }
            .buttonStyle(.borderedProminent)
            .disabled(keywordInput.isEmpty || generator.isGenerating || generator.selectedProvider == .stablediffusion)

            if generator.isGenerating {
                ProgressView(value: generator.generationProgress)
                    .progressViewStyle(.linear)

                Text("Generating icon \(Int(generator.generationProgress * Double(generator.numberOfVariants)) + 1) of \(generator.numberOfVariants)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let error = generator.lastError {
                Text("Error: \(error)")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                    .textSelection(.enabled)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Generated Icons (\(generator.generatedIcons.count))")
                    .font(.headline)

                Spacer()

                if selectedIcon != nil {
                    Button("Install to Xcode Project") {
                        showingProjectSelector = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(isInstalling)

                    Button("Save to Desktop") {
                        saveSelectedIcon()
                    }
                    .buttonStyle(.bordered)

                    Button("Choose Location") {
                        showingSavePicker = true
                    }
                    .buttonStyle(.bordered)
                }

                Button("Export All") {
                    exportAllIcons()
                }
                .buttonStyle(.bordered)

                Button("Clear") {
                    generator.generatedIcons.removeAll()
                    selectedIcon = nil
                    installMessage = ""
                }
                .buttonStyle(.bordered)
            }

            ScrollView(.horizontal) {
                HStack(spacing: 20) {
                    ForEach(generator.generatedIcons) { icon in
                        iconResultCard(icon: icon)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedIcon?.id == icon.id ? Color.blue : Color.clear, lineWidth: 3)
                            )
                            .onTapGesture {
                                selectedIcon = icon
                            }
                    }
                }
            }

            if let selected = selectedIcon {
                Text("Selected: \(selected.keyword.capitalized) - Click 'Use in Xcode Project' to install")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
    }

    private func iconResultCard(icon: GeneratedIcon) -> some View {
        VStack(spacing: 8) {
            Image(nsImage: icon.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            Text(icon.keyword.capitalized)
                .font(.caption)
                .fontWeight(.semibold)

            Text(icon.provider.rawValue)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Button("Save") {
                    saveIcon(icon)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Copy") {
                    copyIcon(icon)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.5))
        )
    }

    // MARK: - Actions

    private func selectCategory(_ category: IconCategory) {
        selectedCategory = category
        let keywords = generator.getPresetKeywords(category: category)
        keywordInput = keywords.prefix(5).joined(separator: ", ")
    }

    private func parseKeywords() -> [String] {
        keywordInput.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func expandKeywords() {
        Task {
            let keywords = parseKeywords()
            let expanded = await generator.expandKeywords(keywords)
            await MainActor.run {
                keywordInput = expanded.joined(separator: ", ")
            }
        }
    }

    private func generateIcons() {
        let keywords = parseKeywords()
        guard !keywords.isEmpty else { return }

        Task {
            let appName = appNameInput.isEmpty ? nil : appNameInput
            _ = await generator.generateIconsFromKeywords(keywords, appName: appName)
        }
    }

    private func saveIcon(_ icon: GeneratedIcon) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = icon.filename

        if panel.runModal() == .OK, let url = panel.url {
            try? generator.saveIcon(icon, to: url)
        }
    }

    private func copyIcon(_ icon: GeneratedIcon) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([icon.image])
    }

    private func saveSelectedIcon() {
        guard let icon = selectedIcon else { return }

        // Save to Desktop with descriptive name
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
        let filename = "AI_Icon_\(icon.keyword.replacingOccurrences(of: " ", with: "_"))_1024x1024.png"
        let fileURL = desktop.appendingPathComponent(filename)

        do {
            try generator.saveIcon(icon, to: fileURL)
            installMessage = "✓ Icon saved to Desktop: \(filename)"

            // Open Finder to show file
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        } catch {
            installMessage = "❌ Failed to save icon: \(error.localizedDescription)"
        }
    }

    private func exportAllIcons() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select folder to export all icons"

        if panel.runModal() == .OK, let url = panel.url {
            Task {
                try? await generator.exportAllIcons(to: url)

                // Open Finder to show folder
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    KeywordIconGeneratorView()
}
