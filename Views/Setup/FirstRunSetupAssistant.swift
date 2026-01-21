import SwiftUI

//
//  FirstRunSetupAssistant.swift
//  Icon Creator
//
//  First-run setup wizard that automatically configures the environment
//  Author: Jordan Koch
//  Date: 2026-01-21
//

struct FirstRunSetupAssistant: View {
    @Binding var isPresented: Bool
    @StateObject private var setupManager = SetupManager()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Welcome to Icon Creator v3.0!")
                    .font(.title)
                    .bold()

                Text("Let's set up your advanced features automatically")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 30)

            Divider()

            // Setup Options
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // CLI Tool Installation
                    SetupOptionView(
                        icon: "terminal.fill",
                        title: "Install Command-Line Tool",
                        description: "Add 'icon-creator' CLI to /usr/local/bin for automation",
                        isInstalled: setupManager.cliInstalled,
                        isInstalling: setupManager.isInstallingCLI,
                        action: {
                            Task {
                                await setupManager.installCLI()
                            }
                        }
                    )

                    // GitHub Actions
                    SetupOptionView(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Deploy GitHub Actions Workflows",
                        description: "Automatically generate icons on git push",
                        isInstalled: setupManager.githubWorkflowsDeployed,
                        isInstalling: setupManager.isDeployingWorkflows,
                        action: {
                            Task {
                                await setupManager.deployGitHubWorkflows()
                            }
                        }
                    )

                    // Firebase Setup
                    SetupOptionView(
                        icon: "flame.fill",
                        title: "Configure Firebase Integration",
                        description: "Enable A/B testing with Firebase Remote Config",
                        isInstalled: setupManager.firebaseConfigured,
                        isInstalling: setupManager.isConfiguringFirebase,
                        optional: true,
                        action: {
                            Task {
                                await setupManager.configureFirebase()
                            }
                        }
                    )

                    // iCloud Sync
                    SetupOptionView(
                        icon: "icloud.fill",
                        title: "Enable iCloud Sync",
                        description: "Sync presets and projects across your devices",
                        isInstalled: setupManager.iCloudEnabled,
                        isInstalling: setupManager.isEnablingCloud,
                        optional: true,
                        action: {
                            Task {
                                await setupManager.enableiCloud()
                            }
                        }
                    )
                }
                .padding(24)
            }

            Divider()

            // Bottom actions
            HStack {
                Button("Skip Setup") {
                    setupManager.markSetupComplete(skipped: true)
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Spacer()

                if setupManager.hasErrors {
                    Text("⚠️ Some installations failed")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                Button(setupManager.allCompleted ? "Done" : "Complete Setup") {
                    if setupManager.allCompleted || setupManager.hasErrors {
                        setupManager.markSetupComplete(skipped: false)
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!setupManager.allCompleted && !setupManager.hasErrors)
            }
            .padding()
        }
        .frame(width: 700, height: 600)
        .onAppear {
            setupManager.checkCurrentState()
        }
    }
}

// MARK: - Setup Option View

struct SetupOptionView: View {
    let icon: String
    let title: String
    let description: String
    var isInstalled: Bool
    var isInstalling: Bool
    var optional: Bool = false
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.blue)
                .frame(width: 50)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)

                    if optional {
                        Text("(Optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Status/Action
            if isInstalling {
                ProgressView()
                    .scaleEffect(0.8)
            } else if isInstalled {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            } else {
                Button(optional ? "Install" : "Install Now") {
                    action()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - Setup Manager

class SetupManager: ObservableObject {
    @Published var cliInstalled = false
    @Published var githubWorkflowsDeployed = false
    @Published var firebaseConfigured = false
    @Published var iCloudEnabled = false

    @Published var isInstallingCLI = false
    @Published var isDeployingWorkflows = false
    @Published var isConfiguringFirebase = false
    @Published var isEnablingCloud = false

    @Published var hasErrors = false

    var allCompleted: Bool {
        cliInstalled && githubWorkflowsDeployed
    }

    private let configPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".icon-creator/config.json")

    // MARK: - Check Current State

    func checkCurrentState() {
        // Check if CLI is already installed
        cliInstalled = FileManager.default.fileExists(atPath: "/usr/local/bin/icon-creator")

        // Check if in a git repo with .github/workflows
        if let projectPath = findGitRepository() {
            let workflowsPath = projectPath.appendingPathComponent(".github/workflows")
            githubWorkflowsDeployed = FileManager.default.fileExists(atPath: workflowsPath.path) &&
                (try? FileManager.default.contentsOfDirectory(atPath: workflowsPath.path).contains { $0.contains("icon") }) == true
        }

        // Check if Firebase is configured
        if let bundlePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            firebaseConfigured = FileManager.default.fileExists(atPath: bundlePath)
        }

        // Check iCloud availability
        iCloudEnabled = FileManager.default.ubiquityIdentityToken != nil
    }

    // MARK: - Installation Methods

    /// Install CLI tool to /usr/local/bin
    func installCLI() async {
        await MainActor.run {
            isInstallingCLI = true
        }

        defer {
            Task { @MainActor in
                isInstallingCLI = false
            }
        }

        do {
            // Find CLI in app bundle
            guard let cliPath = Bundle.main.path(forResource: "icon-creator", ofType: nil, inDirectory: "CLI") else {
                throw SetupError.cliNotFound
            }

            // Create AppleScript to request admin privileges
            let script = """
            do shell script "mkdir -p /usr/local/bin && cp '\(cliPath)' /usr/local/bin/icon-creator && chmod +x /usr/local/bin/icon-creator" with administrator privileges
            """

            let appleScript = NSAppleScript(source: script)
            var error: NSDictionary?
            appleScript?.executeAndReturnError(&error)

            if let error = error {
                throw SetupError.installationFailed("AppleScript error: \(error)")
            }

            // Verify installation
            if FileManager.default.fileExists(atPath: "/usr/local/bin/icon-creator") {
                await MainActor.run {
                    cliInstalled = true
                }
                print("✅ CLI installed successfully")
            } else {
                throw SetupError.installationFailed("Installation succeeded but CLI not found")
            }

        } catch {
            print("❌ CLI installation failed: \(error)")
            await MainActor.run {
                hasErrors = true
            }
        }
    }

    /// Deploy GitHub Actions workflows to current git repository
    func deployGitHubWorkflows() async {
        await MainActor.run {
            isDeployingWorkflows = true
        }

        defer {
            Task { @MainActor in
                isDeployingWorkflows = false
            }
        }

        do {
            // Find git repository
            guard let projectPath = findGitRepository() else {
                throw SetupError.notGitRepository
            }

            // Create .github/workflows directory
            let workflowsPath = projectPath.appendingPathComponent(".github/workflows")
            try FileManager.default.createDirectory(at: workflowsPath, withIntermediateDirectories: true)

            // Copy workflow files from app bundle
            guard let resourcePath = Bundle.main.resourcePath else {
                throw SetupError.resourcesNotFound
            }

            let automationPath = URL(fileURLWithPath: resourcePath).appendingPathComponent("Automation/GitHub")

            // Find workflow YAML files
            let workflowFiles = ["icon-generator.yml", "icon-variants-ab-test.yml"]

            for workflowFile in workflowFiles {
                let sourceURL = automationPath.appendingPathComponent(workflowFile)
                let destURL = workflowsPath.appendingPathComponent(workflowFile)

                if FileManager.default.fileExists(atPath: sourceURL.path) {
                    try FileManager.default.copyItem(at: sourceURL, to: destURL)
                    print("✅ Deployed: \(workflowFile)")
                }
            }

            await MainActor.run {
                githubWorkflowsDeployed = true
            }

            // Show success message with git commands
            print("\n✅ GitHub Actions workflows deployed!")
            print("\nNext steps:")
            print("  cd '\(projectPath.path)'")
            print("  git add .github/workflows/")
            print("  git commit -m 'Add Icon Creator workflows'")
            print("  git push")

        } catch {
            print("❌ GitHub Actions deployment failed: \(error)")
            await MainActor.run {
                hasErrors = true
            }
        }
    }

    /// Configure Firebase integration
    func configureFirebase() async {
        await MainActor.run {
            isConfiguringFirebase = true
        }

        defer {
            Task { @MainActor in
                isConfiguringFirebase = false
            }
        }

        // Open Firebase setup guide
        let guideURL = Bundle.main.url(forResource: "ADVANCED_FEATURES_DOCUMENTATION", withExtension: "md")

        if let url = guideURL {
            NSWorkspace.shared.open(url)
        }

        // Check if GoogleService-Info.plist exists
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            await MainActor.run {
                firebaseConfigured = true
            }
            print("✅ Firebase already configured")
        } else {
            print("ℹ️  Please follow the Firebase setup guide:")
            print("   1. Create Firebase project at https://console.firebase.google.com")
            print("   2. Download GoogleService-Info.plist")
            print("   3. Add to Icon Creator Xcode project")
            print("   4. Add Firebase SDK via Swift Package Manager")
        }
    }

    /// Enable iCloud sync
    func enableiCloud() async {
        await MainActor.run {
            isEnablingCloud = true
        }

        defer {
            Task { @MainActor in
                isEnablingCloud = false
            }
        }

        // Check if iCloud is available
        if FileManager.default.ubiquityIdentityToken != nil {
            await MainActor.run {
                iCloudEnabled = true
            }
            print("✅ iCloud is enabled")
        } else {
            print("ℹ️  To enable iCloud:")
            print("   1. Sign in to iCloud in System Settings")
            print("   2. Enable iCloud Drive")
            print("   3. In Xcode: Target → Capabilities → iCloud")
            print("   4. Enable CloudKit and iCloud Documents")

            // Open System Settings to iCloud
            if let url = URL(string: "x-apple.systempreferences:com.apple.preferences.internetaccounts") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    // MARK: - Completion

    func markSetupComplete(skipped: Bool) {
        let config: [String: Any] = [
            "version": "3.0.0",
            "first_run": false,
            "setup_skipped": skipped,
            "cli_installed": cliInstalled,
            "github_workflows_deployed": githubWorkflowsDeployed,
            "firebase_configured": firebaseConfigured,
            "icloud_enabled": iCloudEnabled,
            "completed_at": ISO8601DateFormatter().string(from: Date())
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: config, options: .prettyPrinted)
            let configDir = configPath.deletingLastPathComponent()

            try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
            try data.write(to: configPath)

            print("✅ Setup configuration saved")
        } catch {
            print("⚠️ Could not save setup configuration: \(error)")
        }
    }

    // MARK: - Helpers

    private func findGitRepository() -> URL? {
        let fileManager = FileManager.default
        var currentPath = fileManager.currentDirectoryPath

        // Try to find .git directory by walking up the tree
        for _ in 0..<10 {
            let gitPath = URL(fileURLWithPath: currentPath).appendingPathComponent(".git")

            if fileManager.fileExists(atPath: gitPath.path) {
                return URL(fileURLWithPath: currentPath)
            }

            // Go up one level
            let parentPath = (currentPath as NSString).deletingLastPathComponent
            if parentPath == currentPath {
                break
            }
            currentPath = parentPath
        }

        // Also check common project locations
        let commonPaths = [
            "/Volumes/Data/xcode",
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Developer"),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Projects")
        ]

        for path in commonPaths {
            if let enumerator = fileManager.enumerator(atPath: path) {
                for case let item as String in enumerator where item.hasSuffix(".git") {
                    let gitURL = URL(fileURLWithPath: path).appendingPathComponent(item)
                    return gitURL.deletingLastPathComponent()
                }
            }
        }

        return nil
    }
}

// MARK: - Setup Errors

enum SetupError: LocalizedError {
    case cliNotFound
    case installationFailed(String)
    case notGitRepository
    case resourcesNotFound

    var errorDescription: String? {
        switch self {
        case .cliNotFound:
            return "CLI tool not found in app bundle. Rebuild the app."
        case .installationFailed(let message):
            return "Installation failed: \(message)"
        case .notGitRepository:
            return "Not in a git repository. Initialize git first or open a project with git."
        case .resourcesNotFound:
            return "Required resources not found in app bundle"
        }
    }
}

// MARK: - Preview

#Preview {
    FirstRunSetupAssistant(isPresented: .constant(true))
}
