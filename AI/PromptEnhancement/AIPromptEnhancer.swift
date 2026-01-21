import Foundation

//
//  AIPromptEnhancer.swift
//  Icon Creator - AI Prompt Enhancement
//
//  Enhance simple keywords into detailed AI prompts
//  Author: Jordan Koch
//  Date: 2026-01-21
//

/// AI-powered prompt enhancement for better icon generation
/// Takes simple keywords and expands them into detailed, optimized prompts
class AIPromptEnhancer: ObservableObject {

    // MARK: - Published Properties

    @Published var isEnhancing = false

    // MARK: - Properties

    private let aiBackend: AIBackendType
    private let promptTemplates: [String: String]

    enum AIBackendType {
        case ollama
        case mlx
        case openai
    }

    // MARK: - Initialization

    init(backend: AIBackendType = .ollama) {
        self.aiBackend = backend

        // Pre-defined prompt templates for common icon types
        self.promptTemplates = [
            "app": "A modern, minimalist app icon featuring {concept}, vibrant colors, clean design, professional App Store quality, trending on Dribbble, centered composition",
            "logo": "A sleek logo design for {concept}, memorable brand identity, scalable vector style, modern aesthetic, suitable for app icon",
            "tool": "A {concept} tool icon in flat design style, clear symbolism, productivity focused, intuitive visual metaphor",
            "game": "A vibrant game icon for {concept}, eye-catching colors, playful design, engaging visual style, mobile game aesthetic",
            "social": "A modern social app icon representing {concept}, connected community feel, contemporary design trends, human-centric",
            "business": "A professional {concept} icon, corporate aesthetic, trustworthy design, business-appropriate color palette",
            "creative": "An artistic {concept} icon, creative and expressive, unique visual style, inspiring design"
        ]
    }

    // MARK: - Enhancement

    /// Enhance a simple prompt into a detailed, optimized prompt
    func enhance(_ simplePrompt: String, style: PromptStyle = .balanced) async throws -> EnhancedPrompt {
        await MainActor.run {
            isEnhancing = true
        }

        defer {
            Task { @MainActor in
                isEnhancing = false
            }
        }

        // Detect intent and category
        let intent = detectIntent(simplePrompt)

        // Generate enhanced prompt
        let enhanced = try await generateEnhancedPrompt(
            original: simplePrompt,
            intent: intent,
            style: style
        )

        return EnhancedPrompt(
            original: simplePrompt,
            enhanced: enhanced,
            intent: intent,
            style: style,
            suggestions: generateSuggestions(for: simplePrompt, intent: intent)
        )
    }

    // MARK: - Intent Detection

    private func detectIntent(_ prompt: String) -> PromptIntent {
        let lowercased = prompt.lowercased()

        // Check for specific keywords
        if lowercased.contains("app") || lowercased.contains("application") {
            return .app
        } else if lowercased.contains("logo") || lowercased.contains("brand") {
            return .logo
        } else if lowercased.contains("game") || lowercased.contains("gaming") {
            return .game
        } else if lowercased.contains("social") || lowercased.contains("community") {
            return .social
        } else if lowercased.contains("tool") || lowercased.contains("utility") {
            return .tool
        } else if lowercased.contains("business") || lowercased.contains("corporate") {
            return .business
        } else {
            return .creative
        }
    }

    // MARK: - Prompt Generation

    private func generateEnhancedPrompt(
        original: String,
        intent: PromptIntent,
        style: PromptStyle
    ) async throws -> String {

        // Try AI-powered enhancement first
        if let aiEnhanced = try? await enhanceWithAI(original, intent: intent, style: style) {
            return aiEnhanced
        }

        // Fallback to template-based enhancement
        return enhanceWithTemplate(original, intent: intent, style: style)
    }

    private func enhanceWithAI(
        _ prompt: String,
        intent: PromptIntent,
        style: PromptStyle
    ) async throws -> String {
        // In production: Call Ollama/MLX API

        /*
        Example Ollama integration:

        let systemPrompt = """
        You are an expert at writing prompts for AI image generation of app icons.
        Enhance the user's simple keyword into a detailed, optimized prompt.
        Focus on: visual style, color palette, composition, quality descriptors.
        Keep it under 100 words.
        """

        let userPrompt = """
        Enhance this app icon keyword into a detailed prompt: "\(prompt)"
        Style preference: \(style.rawValue)
        Purpose: \(intent.rawValue)
        """

        let response = try await callOllama(
            model: "mistral:latest",
            system: systemPrompt,
            prompt: userPrompt
        )

        return response
        */

        // Simulation for now
        throw EnhancementError.aiNotConfigured
    }

    private func enhanceWithTemplate(
        _ prompt: String,
        intent: PromptIntent,
        style: PromptStyle
    ) -> String {

        // Get base template
        var enhanced = promptTemplates[intent.rawValue] ?? promptTemplates["app"]!

        // Replace {concept} with actual prompt
        enhanced = enhanced.replacingOccurrences(of: "{concept}", with: prompt)

        // Add style-specific modifiers
        switch style {
        case .minimalist:
            enhanced += ", minimal details, clean and simple, flat design aesthetic, geometric shapes"
        case .detailed:
            enhanced += ", highly detailed, intricate design elements, rich textures, depth and dimension"
        case .vibrant:
            enhanced += ", bold vibrant colors, high contrast, eye-catching palette, energetic feel"
        case .professional:
            enhanced += ", polished and refined, professional quality, sophisticated design, premium feel"
        case .playful:
            enhanced += ", playful and fun, friendly design, approachable aesthetic, joyful colors"
        case .balanced:
            enhanced += ", balanced design, harmonious colors, versatile style, wide appeal"
        }

        // Add quality descriptors
        enhanced += ", 4K quality, sharp and crisp, optimized for small sizes, iconic and memorable"

        return enhanced
    }

    // MARK: - Suggestions

    private func generateSuggestions(for prompt: String, intent: PromptIntent) -> [String] {
        var suggestions: [String] = []

        // Suggest variations
        suggestions.append(contentsOf: [
            "Try adding: 'gradient background'",
            "Try adding: 'neon glow effect'",
            "Try adding: 'minimalist style'",
            "Try adding: 'rounded corners'",
            "Try adding: 'glossy finish'"
        ])

        // Intent-specific suggestions
        switch intent {
        case .app:
            suggestions.append("Consider: iOS Human Interface Guidelines style")
        case .game:
            suggestions.append("Consider: 3D rendered style with depth")
        case .business:
            suggestions.append("Consider: corporate blue color palette")
        case .creative:
            suggestions.append("Consider: artistic and unique composition")
        default:
            break
        }

        return suggestions.prefix(5).map { $0 }
    }

    // MARK: - Batch Enhancement

    /// Enhance multiple prompts at once
    func batchEnhance(_ prompts: [String], style: PromptStyle = .balanced) async throws -> [EnhancedPrompt] {
        var results: [EnhancedPrompt] = []

        for prompt in prompts {
            let enhanced = try await enhance(prompt, style: style)
            results.append(enhanced)
        }

        return results
    }

    // MARK: - Prompt Analysis

    /// Analyze a prompt and provide quality score
    func analyzePrompt(_ prompt: String) -> PromptAnalysis {
        var score = 0.0
        var feedback: [String] = []

        // Length check
        let wordCount = prompt.split(separator: " ").count
        if wordCount < 5 {
            feedback.append("Prompt is too short. Add more descriptive details.")
            score += 0.2
        } else if wordCount < 15 {
            feedback.append("Good length. Could add more specific details.")
            score += 0.6
        } else if wordCount < 30 {
            feedback.append("Excellent detail level.")
            score += 1.0
        } else {
            feedback.append("Prompt might be too long. Consider simplifying.")
            score += 0.7
        }

        // Style descriptors
        let styleKeywords = ["minimalist", "modern", "clean", "professional", "vibrant", "detailed"]
        let hasStyle = styleKeywords.contains { prompt.lowercased().contains($0) }

        if hasStyle {
            score += 0.5
            feedback.append("Good: Contains style descriptors.")
        } else {
            feedback.append("Consider adding style descriptors (minimalist, modern, etc.).")
        }

        // Quality descriptors
        let qualityKeywords = ["4K", "quality", "professional", "polished", "crisp", "sharp"]
        let hasQuality = qualityKeywords.contains { prompt.lowercased().contains($0) }

        if hasQuality {
            score += 0.3
            feedback.append("Good: Contains quality descriptors.")
        } else {
            feedback.append("Consider adding quality descriptors (4K, professional, etc.).")
        }

        // Composition
        let compositionKeywords = ["centered", "composition", "balanced", "symmetrical"]
        let hasComposition = compositionKeywords.contains { prompt.lowercased().contains($0) }

        if hasComposition {
            score += 0.2
            feedback.append("Good: Specifies composition.")
        }

        // Normalize score
        score = min(1.0, score / 2.0)

        return PromptAnalysis(
            prompt: prompt,
            qualityScore: score,
            wordCount: wordCount,
            feedback: feedback
        )
    }
}

// MARK: - Models

struct EnhancedPrompt {
    let original: String
    let enhanced: String
    let intent: PromptIntent
    let style: PromptStyle
    let suggestions: [String]
}

enum PromptIntent: String {
    case app
    case logo
    case game
    case social
    case tool
    case business
    case creative
}

enum PromptStyle: String, CaseIterable {
    case minimalist = "Minimalist"
    case detailed = "Detailed"
    case vibrant = "Vibrant"
    case professional = "Professional"
    case playful = "Playful"
    case balanced = "Balanced"
}

struct PromptAnalysis {
    let prompt: String
    let qualityScore: Double // 0-1
    let wordCount: Int
    let feedback: [String]
}

enum EnhancementError: LocalizedError {
    case aiNotConfigured
    case enhancementFailed

    var errorDescription: String? {
        switch self {
        case .aiNotConfigured:
            return "AI backend not configured. Using template-based enhancement."
        case .enhancementFailed:
            return "Failed to enhance prompt"
        }
    }
}

// MARK: - Example Usage

extension AIPromptEnhancer {
    static func exampleUsage() -> String {
        return """
        // Basic enhancement
        let enhancer = AIPromptEnhancer()
        let enhanced = try await enhancer.enhance("music app")

        print("Original: \\(enhanced.original)")
        print("Enhanced: \\(enhanced.enhanced)")
        print("Suggestions:")
        enhanced.suggestions.forEach { print("  - \\($0)") }

        // Batch enhancement with different styles
        let prompts = ["fitness app", "food delivery", "meditation"]
        let results = try await enhancer.batchEnhance(prompts, style: .minimalist)

        // Analyze prompt quality
        let analysis = enhancer.analyzePrompt("create a modern app icon")
        print("Quality Score: \\(analysis.qualityScore)")
        analysis.feedback.forEach { print("  - \\($0)") }
        """
    }
}
