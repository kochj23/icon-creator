//
//  AIAssistantView.swift
//  Icon Creator
//
//  AI Assistant UI for icon generation
//  Author: Jordan Koch
//  Date: 2025-01-17
//

import SwiftUI

struct AIAssistantView: View {
    @ObservedObject var assistant: AIIconAssistant
    @Binding var selectedImage: NSImage?
    @State private var conceptDescription = ""
    @State private var selectedPlatform = "iOS"
    @State private var selectedMood = "Professional"
    @State private var selectedTab = 0

    let platforms = ["iOS", "macOS", "tvOS", "watchOS", "All"]
    let moods = ["Professional", "Playful", "Elegant", "Bold", "Minimal", "Vibrant"]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🤖 AI Design Assistant")
                        .font(.title2)
                        .bold()

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
                            Text("AI Not Available")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }

                Spacer()

                Button("⚙️ AI Settings") {
                    openAISettings()
                }
                .buttonStyle(.borderless)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Tab selector
            Picker("Feature", selection: $selectedTab) {
                Text("💡 Generate Ideas").tag(0)
                Text("🎨 Colors").tag(1)
                Text("✍️ Feedback").tag(2)
                Text("✅ Compliance").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case 0: conceptGeneratorView
                    case 1: colorPaletteView
                    case 2: designFeedbackView
                    case 3: complianceView
                    default: Text("Unknown")
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 700)
    }

    // MARK: - Concept Generator

    private var conceptGeneratorView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("💡 AI Icon Concept Generator")
                .font(.headline)

            Text("Describe your app or desired icon style, and AI will generate design concepts.")
                .font(.caption)
                .foregroundColor(.secondary)

            // Input area
            VStack(alignment: .leading, spacing: 12) {
                TextField("Describe your icon (e.g., 'A fitness app with blue gradient and running symbol')", text: $conceptDescription)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                HStack {
                    Picker("Platform", selection: $selectedPlatform) {
                        ForEach(platforms, id: \.self) { platform in
                            Text(platform).tag(platform)
                        }
                    }
                    .frame(width: 150)

                    Picker("Mood", selection: $selectedMood) {
                        ForEach(moods, id: \.self) { mood in
                            Text(mood).tag(mood)
                        }
                    }
                    .frame(width: 150)

                    Spacer()

                    Button("Generate Concepts") {
                        generateConcepts()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(conceptDescription.isEmpty || assistant.isAnalyzing)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            // Concepts display
            if !assistant.iconConcepts.isEmpty {
                ForEach(assistant.iconConcepts) { concept in
                    conceptCard(concept)
                }
            } else if !assistant.isAnalyzing {
                emptyStateView(
                    icon: "lightbulb",
                    title: "No concepts yet",
                    message: "Enter a description and generate AI design concepts"
                )
            }

            if assistant.isAnalyzing {
                HStack {
                    ProgressView()
                    Text("AI is generating concepts...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func conceptCard(_ concept: IconConcept) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(concept.name)
                .font(.headline)

            Text(concept.description)
                .font(.body)
                .foregroundColor(.secondary)

            // Color swatches
            HStack(spacing: 8) {
                Text("Colors:")
                    .font(.subheadline)
                    .bold()

                ForEach(concept.colors, id: \.self) { hexColor in
                    if let color = Color(hex: hexColor) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: 40, height: 30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .help(hexColor)
                    }
                }
            }

            // Elements
            VStack(alignment: .leading, spacing: 4) {
                Text("Elements:")
                    .font(.subheadline)
                    .bold()

                ForEach(concept.elements, id: \.self) { element in
                    Text("• \(element)")
                        .font(.caption)
                }
            }

            // Rationale
            Text("Why this works:")
                .font(.subheadline)
                .bold()
            Text(concept.rationale)
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()

            Button("Use This Concept") {
                applyConcept(concept)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .textBackgroundColor))
                .shadow(radius: 2)
        )
    }

    // MARK: - Color Palette View

    private var colorPaletteView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎨 AI Color Palette Suggestions")
                .font(.headline)

            Button("Generate Palettes") {
                generatePalettes()
            }
            .buttonStyle(.borderedProminent)
            .disabled(assistant.isAnalyzing)

            if !assistant.colorPalettes.isEmpty {
                ForEach(assistant.colorPalettes) { palette in
                    paletteCard(palette)
                }
            } else if !assistant.isAnalyzing {
                emptyStateView(
                    icon: "paintpalette",
                    title: "No palettes yet",
                    message: "Generate AI color palette suggestions"
                )
            }
        }
    }

    private func paletteCard(_ palette: ColorPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(palette.name)
                .font(.headline)

            // Color swatches (larger)
            HStack(spacing: 12) {
                ForEach(palette.colors, id: \.self) { hexColor in
                    if let color = Color(hex: hexColor) {
                        VStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(color)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )

                            Text(hexColor)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Text(palette.description)
                .font(.body)

            Text("💭 \(palette.psychology)")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()

            Button("Copy Hex Codes") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(palette.colors.joined(separator: ", "), forType: .string)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .textBackgroundColor))
                .shadow(radius: 2)
        )
    }

    // MARK: - Design Feedback View

    private var designFeedbackView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("✍️ AI Design Feedback")
                .font(.headline)

            if let image = selectedImage {
                Button("Analyze Current Icon") {
                    analyzeFeedback()
                }
                .buttonStyle(.borderedProminent)
                .disabled(assistant.isAnalyzing)

                if let feedback = assistant.designFeedback {
                    feedbackCard(feedback)
                } else if !assistant.isAnalyzing {
                    emptyStateView(
                        icon: "checkmark.seal",
                        title: "No feedback yet",
                        message: "Click analyze to get AI design feedback"
                    )
                }
            } else {
                emptyStateView(
                    icon: "photo",
                    title: "No icon loaded",
                    message: "Load an icon to get AI design feedback"
                )
            }
        }
    }

    private func feedbackCard(_ feedback: DesignFeedback) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Score
            HStack {
                Text("Overall Score:")
                    .font(.headline)
                Text("\(feedback.overallScore)/100")
                    .font(.system(.title, design: .rounded))
                    .bold()
                    .foregroundColor(scoreColor(feedback.overallScore))
            }

            // Readiness
            HStack {
                Text("App Store:")
                    .font(.headline)
                Text(feedback.appStoreReadiness.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(feedback.appStoreReadiness.color)
                    .cornerRadius(6)
            }

            Divider()

            // Strengths
            if !feedback.strengths.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("✅ Strengths:")
                        .font(.subheadline)
                        .bold()

                    ForEach(feedback.strengths, id: \.self) { strength in
                        Text("• \(strength)")
                            .font(.body)
                            .foregroundColor(.green)
                    }
                }
            }

            // Weaknesses
            if !feedback.weaknesses.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("⚠️ Areas to Improve:")
                        .font(.subheadline)
                        .bold()

                    ForEach(feedback.weaknesses, id: \.self) { weakness in
                        Text("• \(weakness)")
                            .font(.body)
                            .foregroundColor(.orange)
                    }
                }
            }

            // Recommendations
            if !feedback.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 Recommendations:")
                        .font(.subheadline)
                        .bold()

                    ForEach(feedback.recommendations, id: \.self) { recommendation in
                        Text("• \(recommendation)")
                            .font(.body)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .textBackgroundColor))
                .shadow(radius: 2)
        )
    }

    // MARK: - Compliance View

    private var complianceView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("✅ App Store Compliance Check")
                .font(.headline)

            if let image = selectedImage {
                Button("Check Compliance") {
                    checkCompliance()
                }
                .buttonStyle(.borderedProminent)
                .disabled(assistant.isAnalyzing)

                if let compliance = assistant.complianceFeedback {
                    complianceCard(compliance)
                } else if !assistant.isAnalyzing {
                    emptyStateView(
                        icon: "checkmark.shield",
                        title: "No compliance check yet",
                        message: "Check your icon against App Store guidelines"
                    )
                }
            } else {
                emptyStateView(
                    icon: "photo",
                    title: "No icon loaded",
                    message: "Load an icon to check App Store compliance"
                )
            }
        }
    }

    private func complianceCard(_ compliance: ComplianceFeedback) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Compliance status
            HStack {
                Text(compliance.compliant ? "✅ Compliant" : "❌ Not Compliant")
                    .font(.headline)
                    .foregroundColor(compliance.compliant ? .green : .red)

                Spacer()

                Text(compliance.severity.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(compliance.severity.color)
                    .cornerRadius(6)
            }

            Divider()

            // Issues
            if !compliance.issues.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🚫 Issues:")
                        .font(.subheadline)
                        .bold()

                    ForEach(compliance.issues, id: \.self) { issue in
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text(issue)
                                .font(.body)
                        }
                    }
                }
            }

            // Warnings
            if !compliance.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("⚠️ Warnings:")
                        .font(.subheadline)
                        .bold()

                    ForEach(compliance.warnings, id: \.self) { warning in
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(warning)
                                .font(.body)
                        }
                    }
                }
            }

            // Recommendations
            if !compliance.recommendations.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 How to Fix:")
                        .font(.subheadline)
                        .bold()

                    ForEach(compliance.recommendations, id: \.self) { recommendation in
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(.blue)
                            Text(recommendation)
                                .font(.body)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .textBackgroundColor))
                .shadow(radius: 2)
        )
    }

    // MARK: - Helper Views

    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .yellow }
        if score >= 40 { return .orange }
        return .red
    }

    // MARK: - Actions

    private func generateConcepts() {
        Task {
            _ = await assistant.generateIconConcepts(
                from: conceptDescription,
                platform: selectedPlatform,
                style: selectedMood
            )
        }
    }

    private func generatePalettes() {
        let concept = conceptDescription.isEmpty ? "app icon" : conceptDescription

        Task {
            _ = await assistant.suggestColorPalettes(
                for: concept,
                mood: selectedMood
            )
        }
    }

    private func analyzeFeedback() {
        guard let image = selectedImage else { return }

        Task {
            _ = await assistant.analyzeIconDesign(
                image: image,
                description: conceptDescription.isEmpty ? "Generic app icon" : conceptDescription,
                platform: selectedPlatform
            )
        }
    }

    private func checkCompliance() {
        guard let image = selectedImage else { return }

        Task {
            _ = await assistant.checkAppStoreCompliance(
                image: image,
                platform: selectedPlatform,
                iconPurpose: "App Store icon"
            )
        }
    }

    private func applyConcept(_ concept: IconConcept) {
        // Copy colors to clipboard for now
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(concept.colors.joined(separator: ", "), forType: .string)

        // Show notification
        print("✓ Concept colors copied to clipboard: \(concept.colors.joined(separator: ", "))")
    }

    private func openAISettings() {
        let settingsView = AIBackendSettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "AI Backend Settings"
        window.styleMask = [.titled, .closable, .resizable]
        window.setContentSize(NSSize(width: 600, height: 700))
        window.center()
        window.makeKeyAndOrderFront(NSApp.mainWindow)
    }
}
