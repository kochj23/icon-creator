import SwiftUI

//
//  SetupCoordinator.swift
//  Icon Creator
//
//  Coordinates first-run setup and automated installation
//  Author: Jordan Koch
//  Date: 2026-01-21
//

/// Manages setup state and determines if wizard should be shown
class SetupCoordinator: ObservableObject {
    @Published var shouldShowSetupWizard = false
    @Published var setupConfig: SetupConfig?

    private let configURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".icon-creator/config.json")

    // MARK: - Initialization

    init() {
        checkSetupStatus()
    }

    // MARK: - Setup Status

    func checkSetupStatus() {
        loadConfig()

        // Show wizard if:
        // 1. First run (no config file)
        // 2. Config says first_run = true
        // 3. Not all critical features are installed

        if setupConfig == nil {
            // First run ever
            shouldShowSetupWizard = true
            setupConfig = SetupConfig.default
        } else if setupConfig?.firstRun == true {
            // Config exists but marked as first run
            shouldShowSetupWizard = true
        } else if !setupConfig!.cliInstalled || !setupConfig!.githubWorkflowsDeployed {
            // Critical features not installed
            shouldShowSetupWizard = true
        }
    }

    func loadConfig() {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: configURL)
            setupConfig = try JSONDecoder().decode(SetupConfig.self, from: data)
        } catch {
            print("⚠️ Could not load setup config: \(error)")
        }
    }

    func saveConfig() {
        guard let config = setupConfig else { return }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            let data = try encoder.encode(config)
            let configDir = configURL.deletingLastPathComponent()

            try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
            try data.write(to: configURL)
        } catch {
            print("⚠️ Could not save setup config: \(error)")
        }
    }

    func markSetupComplete() {
        setupConfig?.firstRun = false
        saveConfig()
        shouldShowSetupWizard = false
    }
}

// MARK: - Setup Config

struct SetupConfig: Codable {
    var version: String
    var firstRun: Bool
    var cliInstalled: Bool
    var githubWorkflowsDeployed: Bool
    var firebaseConfigured: Bool
    var icloudEnabled: Bool
    var setupCompletedAt: String?

    static let `default` = SetupConfig(
        version: "3.0.0",
        firstRun: true,
        cliInstalled: false,
        githubWorkflowsDeployed: false,
        firebaseConfigured: false,
        icloudEnabled: false,
        setupCompletedAt: nil
    )
}

// MARK: - App Integration

/// Add to your App struct or main ContentView:
///
/// @StateObject private var setupCoordinator = SetupCoordinator()
///
/// .sheet(isPresented: $setupCoordinator.shouldShowSetupWizard) {
///     FirstRunSetupAssistant(isPresented: $setupCoordinator.shouldShowSetupWizard)
///         .onDisappear {
///             setupCoordinator.markSetupComplete()
///         }
/// }
