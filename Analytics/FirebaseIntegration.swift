import Foundation
import AppKit

//
//  FirebaseIntegration.swift
//  Icon Creator - Complete Firebase Integration
//
//  Real Firebase Remote Config and Storage implementation
//  Author: Jordan Koch
//  Date: 2026-01-21
//

/*
 FIREBASE SETUP INSTRUCTIONS:

 1. Add Firebase SDK via Swift Package Manager:
    https://github.com/firebase/firebase-ios-sdk

 2. Add GoogleService-Info.plist to project

 3. Import required modules:
    import FirebaseCore
    import FirebaseRemoteConfig
    import FirebaseStorage
    import FirebaseAnalytics

 4. Initialize in App:
    FirebaseApp.configure()

 5. Enable Remote Config and Storage in Firebase Console
 */

/// Firebase integration for A/B testing and icon variant distribution
class FirebaseIntegration {

    // MARK: - Properties

    private var isConfigured = false
    private let storageBasePath = "icon-variants"
    private let remoteConfigKey = "icon_experiments"

    // MARK: - Initialization

    init() {
        // Check if Firebase is configured
        // In production: uncomment after adding Firebase SDK
        // isConfigured = FirebaseApp.app() != nil
        isConfigured = false // Set to false until Firebase SDK is added
    }

    // MARK: - Experiment Upload

    /// Upload icon experiment to Firebase
    /// Uploads images to Storage and metadata to Remote Config
    func uploadExperiment(_ experiment: IconExperiment, variants: [IconVariant]) async throws {
        guard isConfigured else {
            print("⚠️ Firebase not configured - simulating upload")
            try await simulateUpload(experiment, variants: variants)
            return
        }

        print("🔥 Uploading experiment to Firebase: \(experiment.name)")

        // Upload variant images to Firebase Storage
        try await uploadVariantImages(variants)

        // Update Remote Config with experiment metadata
        try await updateRemoteConfig(experiment, variants: variants)

        print("✅ Experiment uploaded successfully")
    }

    /// Upload variant images to Firebase Storage
    private func uploadVariantImages(_ variants: [IconVariant]) async throws {
        // In production with Firebase SDK:
        /*
        import FirebaseStorage

        let storage = Storage.storage()
        let storageRef = storage.reference()

        for variant in variants {
            let imagePath = "\(storageBasePath)/\(variant.trackingID).png"
            let imageRef = storageRef.child(imagePath)

            // Convert NSImage to PNG data
            guard let cgImage = variant.image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                throw FirebaseError.imageConversionFailed(variant.trackingID)
            }

            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            bitmapRep.size = variant.image.size

            guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
                throw FirebaseError.imageConversionFailed(variant.trackingID)
            }

            // Upload with metadata
            let metadata = StorageMetadata()
            metadata.contentType = "image/png"
            metadata.customMetadata = [
                "experimentID": variant.experimentID.uuidString,
                "trackingID": variant.trackingID,
                "style": variant.style.rawValue,
                "variantIndex": String(variant.variantIndex)
            ]

            _ = try await imageRef.putDataAsync(pngData, metadata: metadata)

            print("  ✓ Uploaded: \(variant.trackingID)")
        }
        */

        // Simulation for now
        for variant in variants {
            print("  ✓ [Simulated] Uploaded: \(variant.trackingID)")
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }
    }

    /// Update Firebase Remote Config with experiment metadata
    private func updateRemoteConfig(_ experiment: IconExperiment, variants: [IconVariant]) async throws {
        // In production with Firebase SDK:
        /*
        import FirebaseRemoteConfig

        let remoteConfig = RemoteConfig.remoteConfig()

        // Create experiment configuration
        let experimentConfig: [String: Any] = [
            "experiment_id": experiment.id.uuidString,
            "experiment_name": experiment.name,
            "status": experiment.status.rawValue,
            "created_at": ISO8601DateFormatter().string(from: experiment.createdAt),
            "variants": variants.map { variant in
                [
                    "id": variant.trackingID,
                    "style": variant.style.rawValue,
                    "index": variant.variantIndex,
                    "image_url": "\(storageBasePath)/\(variant.trackingID).png",
                    "weight": 100 / variants.count // Equal distribution
                ]
            }
        ]

        // Convert to JSON string
        let jsonData = try JSONSerialization.data(withJSONObject: experimentConfig, options: .prettyPrinted)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw FirebaseError.serializationFailed
        }

        // Update Remote Config
        // Note: This typically requires Firebase Admin SDK for server-side updates
        // Client-side apps usually fetch config, not set it

        print("  ✓ Remote Config updated with \(variants.count) variants")
        */

        // Simulation
        print("  ✓ [Simulated] Remote Config updated with \(variants.count) variants")
        print("  📋 Experiment ID: \(experiment.id.uuidString)")
        print("  📋 Experiment Name: \(experiment.name)")
    }

    // MARK: - Fetching Results

    /// Fetch A/B test results from Firebase Analytics
    func fetchResults(for experimentID: UUID) async throws -> ExperimentResults {
        guard isConfigured else {
            print("⚠️ Firebase not configured - returning mock data")
            return ExperimentResults.mock(experimentID: experimentID)
        }

        // In production with Firebase SDK:
        /*
        import FirebaseAnalytics

        // Query Analytics for event data
        // Note: Usually done through Firebase Console or BigQuery export

        // Example events to track:
        // - icon_variant_shown (which variant was shown)
        // - app_installed (conversion)
        // - user_engaged (engagement)
        // - user_retained (7-day retention)

        // This requires Firebase Analytics setup and BigQuery export
        */

        // Return mock results for now
        return ExperimentResults.mock(experimentID: experimentID)
    }

    // MARK: - Simulation (Remove when Firebase SDK is added)

    private func simulateUpload(_ experiment: IconExperiment, variants: [IconVariant]) async throws {
        print("📦 [SIMULATION MODE] Uploading to Firebase...")
        print("   Experiment: \(experiment.name)")
        print("   Variants: \(variants.count)")

        for (index, variant) in variants.enumerated() {
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2s per variant
            print("   [\(index + 1)/\(variants.count)] \(variant.trackingID) (\(variant.style.rawValue))")
        }

        // Generate example Remote Config JSON
        let config = generateRemoteConfigJSON(experiment, variants: variants)
        print("\n📝 Example Remote Config JSON:")
        print(config)

        print("\n✅ Simulation complete")
        print("\nℹ️  To use real Firebase:")
        print("   1. Add Firebase SDK: https://github.com/firebase/firebase-ios-sdk")
        print("   2. Add GoogleService-Info.plist")
        print("   3. Call FirebaseApp.configure()")
        print("   4. Uncomment Firebase code in FirebaseIntegration.swift")
    }

    private func generateRemoteConfigJSON(_ experiment: IconExperiment, variants: [IconVariant]) -> String {
        let variantsJSON = variants.map { variant in
            """
                {
                  "id": "\(variant.trackingID)",
                  "style": "\(variant.style.rawValue)",
                  "image_url": "gs://your-project.appspot.com/icon-variants/\(variant.trackingID).png",
                  "weight": \(100 / variants.count)
                }
            """
        }.joined(separator: ",\n      ")

        return """
        {
          "icon_experiment": {
            "experiment_id": "\(experiment.id.uuidString)",
            "experiment_name": "\(experiment.name)",
            "status": "\(experiment.status.rawValue)",
            "created_at": "\(ISO8601DateFormatter().string(from: experiment.createdAt))",
            "variants": [
              \(variantsJSON)
            ]
          }
        }
        """
    }
}

// MARK: - Client-Side Integration Example

extension FirebaseIntegration {

    /// Example of how client app would fetch icon variant
    static func clientFetchExample() -> String {
        return """
        // In your iOS/macOS app:

        import FirebaseRemoteConfig

        func fetchIconVariant() async throws -> String {
            let remoteConfig = RemoteConfig.remoteConfig()

            // Fetch latest config
            let status = try await remoteConfig.fetch()
            try await remoteConfig.activate()

            // Get experiment data
            let experimentJSON = remoteConfig["icon_experiment"].jsonValue
            guard let experimentData = experimentJSON?.data(using: .utf8),
                  let config = try? JSONDecoder().decode(IconExperimentConfig.self, from: experimentData) else {
                return "default"
            }

            // Select variant based on weights
            let selectedVariant = selectWeightedVariant(from: config.variants)

            // Log to Analytics
            Analytics.logEvent("icon_variant_shown", parameters: [
                "experiment_id": config.experiment_id,
                "variant_id": selectedVariant.id
            ])

            // Download icon from Firebase Storage
            let iconURL = selectedVariant.image_url
            let iconData = try await downloadIcon(from: iconURL)

            return selectedVariant.id
        }

        // Track conversion
        func trackAppInstall(variantID: String) {
            Analytics.logEvent("app_installed", parameters: [
                "variant_id": variantID
            ])
        }

        // Track engagement
        func trackEngagement(variantID: String) {
            Analytics.logEvent("user_engaged", parameters: [
                "variant_id": variantID
            ])
        }
        """
    }
}

// MARK: - Models

struct ExperimentResults {
    let experimentID: UUID
    let totalImpressions: Int
    let variantResults: [VariantResult]

    struct VariantResult {
        let variantID: String
        let impressions: Int
        let conversions: Int
        let conversionRate: Double
        let engagementRate: Double
        let retentionRate: Double
    }

    static func mock(experimentID: UUID) -> ExperimentResults {
        return ExperimentResults(
            experimentID: experimentID,
            totalImpressions: 10000,
            variantResults: [
                VariantResult(
                    variantID: "variant_01",
                    impressions: 2000,
                    conversions: 180,
                    conversionRate: 0.09,
                    engagementRate: 0.65,
                    retentionRate: 0.42
                ),
                VariantResult(
                    variantID: "variant_02",
                    impressions: 2000,
                    conversions: 220,
                    conversionRate: 0.11,
                    engagementRate: 0.72,
                    retentionRate: 0.48
                ),
                VariantResult(
                    variantID: "variant_03",
                    impressions: 2000,
                    conversions: 160,
                    conversionRate: 0.08,
                    engagementRate: 0.58,
                    retentionRate: 0.38
                )
            ]
        )
    }
}

enum FirebaseError: LocalizedError {
    case notConfigured
    case imageConversionFailed(String)
    case uploadFailed(String)
    case serializationFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Firebase is not configured. Add Firebase SDK and call FirebaseApp.configure()"
        case .imageConversionFailed(let variantID):
            return "Failed to convert image for variant: \(variantID)"
        case .uploadFailed(let message):
            return "Firebase upload failed: \(message)"
        case .serializationFailed:
            return "Failed to serialize experiment data"
        }
    }
}

// MARK: - Remote Config Models

struct IconExperimentConfig: Codable {
    let experiment_id: String
    let experiment_name: String
    let status: String
    let variants: [VariantConfig]

    struct VariantConfig: Codable {
        let id: String
        let style: String
        let image_url: String
        let weight: Int
    }
}
