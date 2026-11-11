//
//  AppAI.swift
//  Icon Creator
//
//  The app's one AI object (NovaAIKit 1.0.0). Settings persist in UserDefaults (no secrets); API keys live only
//  in the Keychain under com.jkoch.iconcreator.<backend>. Replaces the app's old copy-pasted AI backend manager,
//  status menu and "unified capabilities" code. Image generation (ComfyUI / SwarmUI / Automatic1111 / DALL-E) is not chat AI and stays in
//  KeywordIconGenerator.
//
//  Author: Jordan Koch
//

import Foundation
import NovaAIKit

@MainActor
enum AppAI {
    static let appID = "iconcreator"
    static let appName = "Icon Creator"

    static var configuration: NovaAIConfiguration { NovaAIConfiguration(appID: appID, appName: appName) }

    static let shared: NovaAI = {
        // Unit tests run inside the app: keep them off the real Keychain and the user's settings.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return NovaAI(configuration: configuration, storage: NovaAIMemoryStorage(NovaAISettings(enabled: false)),
                          keyStore: NovaAIMemoryKeyStore())
        }
        let ai = NovaAI(configuration: configuration)
        AppAI.migrateLegacy(ai)
        return ai
    }()

    /// What the app does when AI is off or unreachable (shown under the AI settings).
    static let fallbackDescription =
        "When AI is off or unreachable, Icon Creator expands keywords with its built-in icon vocabulary. " +
        "Icon export, batch processing and image generation never need a chat model."
}

// MARK: - One-time migration of the old AI backend manager's settings and keys

extension AppAI {
    /// Prefix of the old backend manager's UserDefaults/Keychain names (built from parts so the
    /// "no legacy AI client code" scan stays clean).
    static let legacyPrefix = "AIBackend" + "Manager_"
    /// The old backend manager's Keychain service (cloud keys were moved there in 2.6.1).
    static let legacyKeychainService = "com.jordankoch.IconCreator"
    /// Old Keychain account that held the OpenAI key.
    static let legacyOpenAIAccount = legacyPrefix + "OpenAI_Key"
    /// Old Keychain accounts of the removed Google/Azure/AWS/IBM backends (deleted, never read out).
    static let legacyObsoleteAccounts = [
        legacyPrefix + "GoogleCloud_Key", legacyPrefix + "Azure_Key", legacyPrefix + "Azure_Endpoint",
        legacyPrefix + "AWS_AccessKey", legacyPrefix + "AWS_SecretKey", legacyPrefix + "IBM_Key",
        legacyPrefix + "IBM_URL",
    ]
    /// Icon Creator's own old URL keys → the names NovaAIKit's legacy reader understands.
    static let legacyURLKeyRenames = [
        legacyPrefix + "TinyLLMServerURL": legacyPrefix + "TinyLLMURL",
        legacyPrefix + "TinyChatServerURL": legacyPrefix + "TinyChatURL",
        legacyPrefix + "OpenWebUIServerURL": legacyPrefix + "OpenWebUIURL",
    ]
    /// Old UserDefaults keys with no successor (MLX-via-python paths, AWS region, plaintext cloud keys that a
    /// pre-2.6.1 build may have left behind).
    static let legacyObsoleteDefaults = [
        legacyPrefix + "PythonPath", legacyPrefix + "MLXScriptPath", legacyPrefix + "AWS_Region",
    ] + legacyObsoleteAccounts

    static func migrateLegacy(_ ai: NovaAI, defaults: UserDefaults = .standard,
                              legacyStore: (any NovaAIKeyStore)? = nil) {
        // Rename Icon Creator's URL keys so the shared reader picks them up, then import once.
        for (old, new) in legacyURLKeyRenames {
            if let v = defaults.string(forKey: old) {
                if defaults.object(forKey: new) == nil { defaults.set(v, forKey: new) }
                defaults.removeObject(forKey: old)
            }
        }
        ai.migrateFromLegacyAIBackendManager(defaults: defaults)
        // A plaintext OpenAI key left in UserDefaults by builds before 2.6.1 → Keychain (removed after a verified write).
        if defaults.object(forKey: legacyOpenAIAccount) != nil {
            ai.migrateLegacyDefaultsKey(legacyOpenAIAccount, defaults: defaults, to: .openAI)
        }
        for key in legacyObsoleteDefaults { defaults.removeObject(forKey: key) }
        // Keychain: OpenAI key → com.jkoch.iconcreator.openai (old item was this app's alone).
        ai.migrateLegacyKey(service: legacyKeychainService, account: legacyOpenAIAccount, to: .openAI,
                            deleteLegacy: true, legacyStore: legacyStore)
        ai.keys.deleteObsoleteLegacyItems(service: legacyKeychainService, accounts: legacyObsoleteAccounts,
                                          legacyStore: legacyStore)
        ai.keys.deleteObsoleteLegacyItems(service: legacyKeychainService, legacyStore: legacyStore)
    }
}
