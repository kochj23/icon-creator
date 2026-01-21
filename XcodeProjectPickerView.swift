//
//  XcodeProjectPickerView.swift
//  Icon Creator
//
//  Xcode project picker for installing AI-generated icons
//  Author: Jordan Koch
//  Date: 2026-01-20
//

import SwiftUI

struct XcodeProjectPickerView: View {
    @Binding var selectedIcon: GeneratedIcon?
    @ObservedObject var iconProcessor: IconGenerator
    @Binding var isInstalling: Bool
    @Binding var installMessage: String
    var onComplete: () -> Void

    @StateObject private var projectManager = XcodeProjectManager()
    @State private var selectedPlatforms: Set<Platform> = [.iOS, .macOS, .watchOS, .tvOS]

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Install Icon to Xcode Project")
                .font(.title)
                .bold()

            // Selected icon preview
            if let icon = selectedIcon {
                HStack(spacing: 12) {
                    Image(nsImage: icon.image)
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue, lineWidth: 2)
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Selected Icon:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(icon.keyword.capitalized)
                            .font(.title3)
                            .bold()
                        Text("Generated with \(icon.provider.rawValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )
            }

            Divider()

            // Platform selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Target Platforms:")
                    .font(.headline)

                HStack(spacing: 12) {
                    ForEach(Platform.allCases, id: \.self) { platform in
                        Button {
                            if selectedPlatforms.contains(platform) {
                                selectedPlatforms.remove(platform)
                            } else {
                                selectedPlatforms.insert(platform)
                            }
                        } label: {
                            HStack {
                                Image(systemName: selectedPlatforms.contains(platform) ? "checkmark.circle.fill" : "circle")
                                Text(platform.rawValue)
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(selectedPlatforms.contains(platform) ? .blue : .gray)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
            )

            Divider()

            // Project list
            Text("Select Xcode Project:")
                .font(.headline)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(projectManager.projects) { project in
                        projectButton(project: project)
                    }

                    if projectManager.projects.isEmpty {
                        VStack(spacing: 12) {
                            Text("No Xcode projects found")
                                .foregroundColor(.secondary)

                            Button("Scan for Projects") {
                                projectManager.discoverProjects()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
            }
            .frame(height: 300)

            // Install status
            if isInstalling {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Installing icons...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if !installMessage.isEmpty {
                Text(installMessage)
                    .font(.system(size: 14))
                    .foregroundColor(installMessage.contains("✓") ? .green : .orange)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill((installMessage.contains("✓") ? Color.green : Color.orange).opacity(0.1))
                    )
                    .textSelection(.enabled)
            }

            Spacer()

            // Bottom buttons
            HStack {
                Button("Cancel") {
                    onComplete()
                }
                .buttonStyle(.bordered)
                .disabled(isInstalling)

                Spacer()

                Button("Refresh Projects") {
                    projectManager.discoverProjects()
                }
                .buttonStyle(.bordered)
                .disabled(isInstalling)
            }
        }
        .padding()
        .frame(width: 700, height: 800)
        .onAppear {
            projectManager.discoverProjects()
        }
    }

    // MARK: - Project Button

    private func projectButton(project: XcodeProject) -> some View {
        Button {
            installIconToProject(project: project)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(project.pathString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    if let platform = project.primaryPlatform {
                        HStack(spacing: 4) {
                            Image(systemName: platform == .iOS ? "iphone" : platform == .macOS ? "laptopcomputer" : "applewatch")
                                .font(.caption2)
                            Text(platform.rawValue)
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                    }
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .disabled(isInstalling)
    }

    // MARK: - Install to Project

    private func installIconToProject(project: XcodeProject) {
        guard let icon = selectedIcon else { return }

        isInstalling = true
        installMessage = "Installing icons to \(project.name)..."

        Task {
            do {
                // Set the generated icon as the source
                await MainActor.run {
                    iconProcessor.sourceImage = icon.image
                }

                // Export icons to temporary directory
                let tempDir = FileManager.default.temporaryDirectory
                    .appendingPathComponent("IconCreator-\(UUID().uuidString)")

                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

                // Export all platform sizes using IconGenerator
                for platform in selectedPlatforms {
                    try iconProcessor.exportIcons(for: platform, to: tempDir)
                }

                // Install to Xcode project
                let results = try await projectManager.installMultiplePlatforms(
                    from: tempDir,
                    platforms: selectedPlatforms,
                    to: project
                )

                // Success!
                await MainActor.run {
                    installMessage = "✓ Icons installed to \(project.name)!\n\nCreated \(selectedPlatforms.count) platform sets:\n" +
                        selectedPlatforms.map { "• \($0.rawValue)" }.sorted().joined(separator: "\n") +
                        "\n\nOpen Xcode to see your new icons!"
                    isInstalling = false
                    selectedIcon = nil
                }

                // Clean up temp directory
                try? FileManager.default.removeItem(at: tempDir)

                // Auto-close after 3 seconds
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    onComplete()
                }

            } catch {
                await MainActor.run {
                    installMessage = "❌ Installation failed: \(error.localizedDescription)\n\nTry saving to Desktop and dragging to Xcode manually."
                    isInstalling = false
                }
            }
        }
    }
}

// MARK: - Xcode Project Picker View (Standalone)

#Preview {
    XcodeProjectPickerView(
        selectedIcon: .constant(nil),
        iconProcessor: IconGenerator(),
        isInstalling: .constant(false),
        installMessage: .constant(""),
        onComplete: {}
    )
}
