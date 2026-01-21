//
//  KeywordIconGenerator.swift
//  Icon Creator
//
//  AI-powered keyword-to-icon generation
//  Inspired by VibeScape by Jason Cox (https://github.com/jasonacox/VibeScape)
//
//  ATTRIBUTION:
//  - VibeScape concept by Jason Cox
//  - Keyword-based theme generation inspired by VibeScape's seasonal system
//  - Adapted for app icon creation with SwarmUI and OpenAI DALL-E support
//
//  Author: Jordan Koch
//  Date: 2026-01-20
//

import Foundation
import SwiftUI
import AppKit

/// Generates app icons from keywords using AI image generation
/// Inspired by VibeScape's keyword-based approach
@MainActor
class KeywordIconGenerator: ObservableObject {
    @Published var isGenerating = false
    @Published var generatedIcons: [GeneratedIcon] = []
    @Published var lastError: String?
    @Published var generationProgress: Double = 0

    // Image generation providers
    @Published var selectedProvider: ImageProvider = .comfyUI
    @Published var swarmUIURL: String = "http://localhost:7801"
    @Published var comfyUIURL: String = "http://localhost:8188"
    @Published var automatic1111URL: String = "http://localhost:7860"
    @Published var openAIKey: String = ""
    @Published var openAIModel: String = "dall-e-3"

    // Icon generation settings
    @Published var iconSize: String = "1024x1024"
    @Published var iconStyle: String = "modern app icon"
    @Published var numberOfVariants: Int = 3

    // Note: AI backend integration requires AIBackendManager in project
    // private let aiBackend = AIBackendManager.shared

    // MARK: - Keyword-to-Icon Generation (VibeScape-Inspired)

    /// Generate app icons from keywords
    /// Inspired by VibeScape's keyword-based generation system
    func generateIconsFromKeywords(_ keywords: [String], appName: String? = nil) async -> [GeneratedIcon] {
        isGenerating = true
        generationProgress = 0
        defer {
            isGenerating = false
            generationProgress = 0
        }

        print("🎨 KEYWORD ICON GENERATION (VibeScape-inspired)")
        print("Keywords: \(keywords.joined(separator: ", "))")

        var generated: [GeneratedIcon] = []

        // Generate variants based on keywords
        for (index, keyword) in keywords.prefix(numberOfVariants).enumerated() {
            generationProgress = Double(index) / Double(min(keywords.count, numberOfVariants))

            let prompt = buildIconPrompt(keyword: keyword, appName: appName)
            print("Generating icon \(index + 1)/\(numberOfVariants): \(keyword)")

            if let image = await generateSingleIcon(prompt: prompt, keyword: keyword) {
                let icon = GeneratedIcon(
                    keyword: keyword,
                    prompt: prompt,
                    image: image,
                    provider: selectedProvider,
                    timestamp: Date()
                )

                generated.append(icon)

                await MainActor.run {
                    self.generatedIcons.append(icon)
                }
            }

            generationProgress = Double(index + 1) / Double(min(keywords.count, numberOfVariants))
        }

        print("✓ Generated \(generated.count) icons from keywords")
        return generated
    }

    // MARK: - Prompt Building (VibeScape-Inspired)

    private func buildIconPrompt(keyword: String, appName: String?) -> String {
        // Build prompt similar to VibeScape's seasonal themes
        var prompt = "App icon design for"

        if let appName = appName {
            prompt += " '\(appName)'"
        }

        prompt += ", keyword: \(keyword), "
        prompt += iconStyle
        prompt += ", clean geometric shapes, "
        prompt += "solid background, "
        prompt += "professional iOS app icon style, "
        prompt += "centered composition, "
        prompt += "no text or words, "
        prompt += "\(iconSize) resolution, "
        prompt += "suitable for Apple App Store"

        return prompt
    }

    // MARK: - AI-Enhanced Keyword Expansion

    /// Use AI to expand user keywords into richer icon prompts
    /// Example: "music" → "musical notes, sound waves, headphones, vinyl record"
    func expandKeywords(_ keywords: [String]) async -> [String] {
        guard AIBackendManager.shared.activeBackend != nil else {
            lastError = "AI backend not configured. Click 'AI Config' button to set up Ollama or MLX."
            return keywords
        }

        let prompt = """
        Expand these keywords into detailed visual elements suitable for app icons.

        Keywords: \(keywords.joined(separator: ", "))

        For each keyword, provide 3-5 related concrete visual elements:
        - Use shapes, symbols, objects (not abstract concepts)
        - Think about iconic, recognizable imagery
        - Suitable for app icons

        Example:
        "music" → "musical note, headphones, sound waveform, microphone, vinyl record"
        "security" → "shield, lock, key, fingerprint, padlock, checkmark"

        Respond with comma-separated visual elements.
        """

        do {
            let response = try await AIBackendManager.shared.generate(
                prompt: prompt,
                systemPrompt: "You are an icon designer. Convert keywords into concrete visual elements suitable for app icons.",
                temperature: 0.7,
                maxTokens: 400
            )

            let expanded = response.components(separatedBy: "\n")
                .filter { !$0.isEmpty }
                .flatMap { $0.components(separatedBy: ",") }
                .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            if !expanded.isEmpty {
                lastError = nil // Clear any previous errors
                return expanded
            } else {
                return keywords
            }
        } catch {
            lastError = "AI expansion failed: \(error.localizedDescription). Click 'AI Config' to configure AI backend."
            return keywords
        }
    }

    // MARK: - Image Generation

    private func generateSingleIcon(prompt: String, keyword: String) async -> NSImage? {
        switch selectedProvider {
        case .swarmUI:
            return await generateWithSwarmUI(prompt: prompt)
        case .comfyUI:
            return await generateWithComfyUI(prompt: prompt)
        case .automatic1111:
            return await generateWithAutomatic1111(prompt: prompt)
        case .openAI:
            return await generateWithOpenAI(prompt: prompt)
        case .stablediffusion:
            return await generateWithStableDiffusion(prompt: prompt)
        }
    }

    // MARK: - SwarmUI Integration (VibeScape Default)

    /// Generate icon using SwarmUI (VibeScape's default provider)
    private func generateWithSwarmUI(prompt: String) async -> NSImage? {
        guard let url = URL(string: "\(swarmUIURL)/API/GenerateText2Image") else {
            lastError = "Invalid SwarmUI URL"
            return nil
        }

        let requestBody: [String: Any] = [
            "prompt": prompt,
            "model": "Flux/flux1-schnell-fp8", // VibeScape default
            "width": 1024,
            "height": 1024,
            "cfg_scale": 1.0,
            "steps": 6, // VibeScape default for fast generation
            "seed": -1 // Random
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                lastError = "SwarmUI returned error"
                return nil
            }

            // Parse SwarmUI response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let imagesArray = json["images"] as? [String],
               let base64String = imagesArray.first {
                return decodeBase64Image(base64String)
            }

            lastError = "Failed to parse SwarmUI response"
            return nil
        } catch {
            lastError = "SwarmUI error: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - OpenAI DALL-E Integration

    /// Generate icon using OpenAI DALL-E (VibeScape alternate)
    private func generateWithOpenAI(prompt: String) async -> NSImage? {
        guard !openAIKey.isEmpty else {
            lastError = "OpenAI API key not configured"
            return nil
        }

        guard let url = URL(string: "https://api.openai.com/v1/images/generations") else {
            return nil
        }

        let requestBody: [String: Any] = [
            "model": openAIModel,
            "prompt": prompt,
            "n": 1,
            "size": iconSize,
            "quality": "hd",
            "style": "vivid"
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                lastError = "OpenAI returned error"
                return nil
            }

            // Parse OpenAI response
            struct OpenAIImageResponse: Codable {
                struct ImageData: Codable {
                    let url: String?
                    let b64_json: String?
                }
                let data: [ImageData]
            }

            let decoder = JSONDecoder()
            let imageResponse = try decoder.decode(OpenAIImageResponse.self, from: data)

            if let imageData = imageResponse.data.first {
                // Try URL first
                if let urlString = imageData.url,
                   let imageURL = URL(string: urlString),
                   let downloadedData = try? Data(contentsOf: imageURL),
                   let image = NSImage(data: downloadedData) {
                    return image
                }

                // Try base64
                if let base64 = imageData.b64_json {
                    return decodeBase64Image(base64)
                }
            }

            lastError = "Failed to parse OpenAI response"
            return nil
        } catch {
            lastError = "OpenAI error: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - ComfyUI Integration

    /// Generate icon using ComfyUI (Local Stable Diffusion)
    /// ComfyUI: https://github.com/comfyanonymous/ComfyUI
    private func generateWithComfyUI(prompt: String) async -> NSImage? {
        // First check if ComfyUI is actually running
        guard let testURL = URL(string: "\(comfyUIURL)/system_stats") else {
            lastError = "Invalid ComfyUI URL: \(comfyUIURL)"
            return nil
        }

        do {
            let (_, testResponse) = try await URLSession.shared.data(from: testURL)
            guard (testResponse as? HTTPURLResponse)?.statusCode == 200 else {
                lastError = "ComfyUI not responding at \(comfyUIURL). Is it running? Start with: ~/AI/start-comfyui.sh"
                return nil
            }
        } catch {
            lastError = "Cannot connect to ComfyUI at \(comfyUIURL). Is it running? Start with: ~/AI/start-comfyui.sh"
            return nil
        }

        guard let url = URL(string: "\(comfyUIURL)/prompt") else {
            lastError = "Invalid ComfyUI URL"
            return nil
        }

        // Simplified ComfyUI workflow for SDXL
        let workflow: [String: Any] = [
            "prompt": [
                "3": [
                    "inputs": [
                        "seed": Int.random(in: 0...999999999),
                        "steps": 20,
                        "cfg": 7.0,
                        "sampler_name": "euler",
                        "scheduler": "normal",
                        "denoise": 1.0,
                        "model": ["4", 0],
                        "positive": ["6", 0],
                        "negative": ["7", 0],
                        "latent_image": ["5", 0]
                    ],
                    "class_type": "KSampler"
                ],
                "4": [
                    "inputs": [
                        "ckpt_name": "sd_xl_base_1.0.safetensors"
                    ],
                    "class_type": "CheckpointLoaderSimple"
                ],
                "5": [
                    "inputs": [
                        "width": 1024,
                        "height": 1024,
                        "batch_size": 1
                    ],
                    "class_type": "EmptyLatentImage"
                ],
                "6": [
                    "inputs": [
                        "text": prompt,
                        "clip": ["4", 1]
                    ],
                    "class_type": "CLIPTextEncode"
                ],
                "7": [
                    "inputs": [
                        "text": "text, watermark, signature, blurry, low quality",
                        "clip": ["4", 1]
                    ],
                    "class_type": "CLIPTextEncode"
                ],
                "8": [
                    "inputs": [
                        "samples": ["3", 0],
                        "vae": ["4", 2]
                    ],
                    "class_type": "VAEDecode"
                ],
                "9": [
                    "inputs": [
                        "filename_prefix": "icon",
                        "images": ["8", 0]
                    ],
                    "class_type": "SaveImage"
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: workflow)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                lastError = "ComfyUI connection error. Is ComfyUI running on \(comfyUIURL)?"
                return nil
            }

            // Parse response for prompt_id
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let promptId = json["prompt_id"] as? String {

                print("ComfyUI prompt submitted: \(promptId)")

                // Wait for image generation with polling
                var attempts = 0
                let maxAttempts = 60 // 60 seconds max

                while attempts < maxAttempts {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second
                    attempts += 1

                    // Check if generation is complete
                    guard let historyURL = URL(string: "\(comfyUIURL)/history/\(promptId)") else { continue }

                    do {
                        let (historyData, _) = try await URLSession.shared.data(from: historyURL)

                        if let historyJson = try? JSONSerialization.jsonObject(with: historyData) as? [String: Any],
                           let promptData = historyJson[promptId] as? [String: Any],
                           let outputs = promptData["outputs"] as? [String: Any] {

                            print("ComfyUI outputs found")

                            // Extract image filename from outputs
                            for (nodeId, output) in outputs {
                                if let outputDict = output as? [String: Any],
                                   let images = outputDict["images"] as? [[String: Any]] {

                                    for imageInfo in images {
                                        if let filename = imageInfo["filename"] as? String,
                                           let subfolder = imageInfo["subfolder"] as? String {

                                            // Download image
                                            let imageURL = URL(string: "\(comfyUIURL)/view?filename=\(filename)&subfolder=\(subfolder)&type=output")!
                                            print("ComfyUI downloading: \(imageURL)")

                                            if let imageData = try? Data(contentsOf: imageURL),
                                               let image = NSImage(data: imageData) {
                                                print("✓ ComfyUI image retrieved successfully")
                                                return image
                                            }
                                        } else if let filename = imageInfo["filename"] as? String {
                                            // Try without subfolder
                                            let imageURL = URL(string: "\(comfyUIURL)/view?filename=\(filename)&type=output")!
                                            print("ComfyUI downloading: \(imageURL)")

                                            if let imageData = try? Data(contentsOf: imageURL),
                                               let image = NSImage(data: imageData) {
                                                print("✓ ComfyUI image retrieved successfully")
                                                return image
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } catch {
                        // Keep waiting
                        continue
                    }
                }

                lastError = "ComfyUI generation timeout after \(attempts) seconds. Check ComfyUI logs."
                return nil
            }

            lastError = "Failed to submit prompt to ComfyUI. Check ComfyUI is running and model is loaded."
            return nil
        } catch {
            lastError = "ComfyUI error: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Automatic1111 Integration

    /// Generate icon using Automatic1111 (Stable Diffusion WebUI)
    /// AUTOMATIC1111: https://github.com/AUTOMATIC1111/stable-diffusion-webui
    private func generateWithAutomatic1111(prompt: String) async -> NSImage? {
        guard let url = URL(string: "\(automatic1111URL)/sdapi/v1/txt2img") else {
            lastError = "Invalid Automatic1111 URL"
            return nil
        }

        let requestBody: [String: Any] = [
            "prompt": prompt,
            "negative_prompt": "text, watermark, signature, blurry, low quality, distorted",
            "steps": 20,
            "cfg_scale": 7.0,
            "width": 1024,
            "height": 1024,
            "sampler_name": "Euler",
            "seed": -1,
            "n_iter": 1,
            "batch_size": 1
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120 // Image generation takes time

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = "Automatic1111 connection error"
                return nil
            }

            if httpResponse.statusCode != 200 {
                lastError = "Automatic1111 error (HTTP \(httpResponse.statusCode)). Is Automatic1111 running on \(automatic1111URL)?"
                return nil
            }

            // Parse Automatic1111 response
            struct Auto1111Response: Codable {
                let images: [String]
            }

            let decoder = JSONDecoder()
            let imageResponse = try decoder.decode(Auto1111Response.self, from: data)

            if let base64String = imageResponse.images.first {
                return decodeBase64Image(base64String)
            }

            lastError = "Failed to parse Automatic1111 response"
            return nil
        } catch {
            lastError = "Automatic1111 error: \(error.localizedDescription). Is Automatic1111 running?"
            return nil
        }
    }

    // MARK: - Stable Diffusion Integration (Deprecated)

    /// Generate icon using local Stable Diffusion
    private func generateWithStableDiffusion(prompt: String) async -> NSImage? {
        // Deprecated - use ComfyUI or Automatic1111 instead
        lastError = "Stable Diffusion deprecated. Use ComfyUI or Automatic1111 instead."
        return nil
    }

    // MARK: - Preset Keyword Themes (VibeScape-Inspired)

    /// Get preset keywords for common app categories
    /// Inspired by VibeScape's seasonal themes
    func getPresetKeywords(category: IconCategory) -> [String] {
        switch category {
        case .productivity:
            return ["checklist", "calendar", "document", "clipboard", "tasks", "notes", "pencil"]

        case .social:
            return ["people", "chat bubble", "heart", "comments", "network", "community", "sharing"]

        case .entertainment:
            return ["play button", "music note", "film reel", "game controller", "popcorn", "ticket"]

        case .finance:
            return ["dollar sign", "coin", "chart", "wallet", "credit card", "bank", "piggy bank"]

        case .health:
            return ["heart", "plus sign", "pulse", "apple", "dumbbell", "medical cross", "stethoscope"]

        case .travel:
            return ["airplane", "globe", "map pin", "compass", "suitcase", "camera", "passport"]

        case .food:
            return ["fork and knife", "chef hat", "apple", "coffee cup", "pizza slice", "shopping cart"]

        case .education:
            return ["book", "graduation cap", "pencil", "lightbulb", "microscope", "calculator", "backpack"]

        case .utilities:
            return ["gear", "wrench", "settings", "tools", "calculator", "lock", "shield"]

        case .weather:
            return ["sun", "cloud", "rain", "snow", "lightning", "temperature", "wind"]
        }
    }

    // MARK: - Helper Functions

    private func decodeBase64Image(_ base64String: String) -> NSImage? {
        // Remove data URI prefix if present
        var cleanedBase64 = base64String
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")

        // Remove whitespace and newlines
        cleanedBase64 = cleanedBase64.components(separatedBy: CharacterSet.whitespacesAndNewlines).joined()

        guard let imageData = Data(base64Encoded: cleanedBase64) else {
            return nil
        }

        return NSImage(data: imageData)
    }

    private func parseIconConcepts(_ response: String) -> [IconConcept]? {
        // Extract JSON from response
        guard let jsonString = extractJSON(from: response),
              let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let conceptsArray = json["concepts"] as? [[String: Any]] else {
            return nil
        }

        return conceptsArray.compactMap { dict -> IconConcept? in
            guard let name = dict["name"] as? String,
                  let description = dict["description"] as? String,
                  let elements = dict["elements"] as? [String],
                  let colors = dict["colors"] as? [String],
                  let layout = dict["layout"] as? String,
                  let rationale = dict["rationale"] as? String else {
                return nil
            }

            return IconConcept(
                name: name,
                description: description,
                elements: elements,
                colors: colors,
                layout: layout,
                rationale: rationale
            )
        }
    }

    private func extractJSON(from text: String) -> String? {
        if let range = text.range(of: "\\{[\\s\\S]*\\}", options: .regularExpression) {
            return String(text[range])
        }
        return text.hasPrefix("{") ? text : nil
    }

    // MARK: - Export

    /// Save generated icon to file
    func saveIcon(_ icon: GeneratedIcon, to url: URL) throws {
        guard let tiffData = icon.image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            throw KeywordIconGeneratorError.exportFailed
        }

        try pngData.write(to: url)
    }

    /// Export all generated icons to folder
    func exportAllIcons(to folder: URL) async throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        for (index, icon) in generatedIcons.enumerated() {
            let filename = "icon_\(icon.keyword)_\(index + 1).png"
            let fileURL = folder.appendingPathComponent(filename)
            try saveIcon(icon, to: fileURL)
        }

        print("✓ Exported \(generatedIcons.count) icons to \(folder.path)")
    }
}

// MARK: - Data Models

struct GeneratedIcon: Identifiable {
    let id = UUID()
    let keyword: String
    let prompt: String
    let image: NSImage
    let provider: ImageProvider
    let timestamp: Date

    var filename: String {
        "icon_\(keyword.replacingOccurrences(of: " ", with: "_"))_\(timestamp.timeIntervalSince1970).png"
    }
}

enum ImageProvider: String, CaseIterable {
    case comfyUI = "ComfyUI (Local)"
    case automatic1111 = "Automatic1111 (Local)"
    case swarmUI = "SwarmUI (Local)"
    case openAI = "OpenAI DALL-E"
    case stablediffusion = "Stable Diffusion (Deprecated)"

    var requiresKey: Bool {
        self == .openAI
    }

    var icon: String {
        switch self {
        case .comfyUI: return "network"
        case .automatic1111: return "cpu.fill"
        case .swarmUI: return "server.rack"
        case .openAI: return "cloud.fill"
        case .stablediffusion: return "xmark.circle"
        }
    }

    var attribution: String? {
        switch self {
        case .comfyUI:
            return "ComfyUI (https://github.com/comfyanonymous/ComfyUI)"
        case .automatic1111:
            return "AUTOMATIC1111 (https://github.com/AUTOMATIC1111/stable-diffusion-webui)"
        case .swarmUI:
            return "SwarmUI - Local image generation"
        default:
            return nil
        }
    }

    var defaultURL: String {
        switch self {
        case .comfyUI: return "http://localhost:8188"
        case .automatic1111: return "http://localhost:7860"
        case .swarmUI: return "http://localhost:7801"
        default: return ""
        }
    }
}

enum IconCategory: String, CaseIterable {
    case productivity = "Productivity"
    case social = "Social"
    case entertainment = "Entertainment"
    case finance = "Finance"
    case health = "Health & Fitness"
    case travel = "Travel"
    case food = "Food & Drink"
    case education = "Education"
    case utilities = "Utilities"
    case weather = "Weather"

    var icon: String {
        switch self {
        case .productivity: return "checkmark.circle.fill"
        case .social: return "person.3.fill"
        case .entertainment: return "play.circle.fill"
        case .finance: return "dollarsign.circle.fill"
        case .health: return "heart.fill"
        case .travel: return "airplane"
        case .food: return "fork.knife"
        case .education: return "book.fill"
        case .utilities: return "gearshape.fill"
        case .weather: return "cloud.sun.fill"
        }
    }
}

struct IconConcept: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let elements: [String]
    let colors: [String]
    let layout: String
    let rationale: String
}

enum KeywordIconGeneratorError: LocalizedError {
    case exportFailed
    case generationFailed
    case invalidProvider

    var errorDescription: String? {
        switch self {
        case .exportFailed:
            return "Failed to export icon"
        case .generationFailed:
            return "Failed to generate icon"
        case .invalidProvider:
            return "Invalid image generation provider"
        }
    }
}
