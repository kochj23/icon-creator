//
//  AIIconAssistant.swift
//  Icon Creator
//
//  AI-powered icon design assistance
//  Supports Ollama, MLX Toolkit, and TinyLLM by Jason Cox
//  Author: Jordan Koch
//  Date: 2025-01-17
//
//  THIRD-PARTY ATTRIBUTION:
//  - TinyLLM by Jason Cox (https://github.com/jasonacox/TinyLLM)
//

import Foundation
import SwiftUI
import AppKit

/// AI-powered icon design assistant
@MainActor
class AIIconAssistant: ObservableObject {
    @Published var isAnalyzing = false
    @Published var iconConcepts: [IconConcept] = []
    @Published var colorPalettes: [ColorPalette] = []
    @Published var designFeedback: DesignFeedback?
    @Published var complianceFeedback: ComplianceFeedback?
    @Published var lastError: String?

    private let aiBackend = AIBackendManager.shared

    // MARK: - Feature 1: AI Icon Concept Generation

    /// Generate icon design concepts from text description
    func generateIconConcepts(from description: String, platform: String, style: String? = nil) async -> [IconConcept] {
        guard aiBackend.activeBackend != nil else {
            return generateBasicConcepts(description: description)
        }

        isAnalyzing = true
        defer { isAnalyzing = false }

        let stylePrompt = style.map { "Style: \($0)" } ?? "Style: Modern, clean"

        let prompt = """
        Generate 3 app icon design concepts based on this description.

        Description: \(description)
        Platform: \(platform)
        \(stylePrompt)

        For each concept, provide:
        1. Main visual elements (shapes, symbols)
        2. Color scheme (2-3 colors with hex codes)
        3. Layout/composition
        4. Rationale for the design

        Respond in JSON format:
        {
            "concepts": [
                {
                    "name": "Concept name",
                    "description": "Visual description",
                    "elements": ["element1", "element2"],
                    "colors": ["#hex1", "#hex2", "#hex3"],
                    "layout": "Layout description",
                    "rationale": "Why this works"
                }
            ]
        }
        """

        do {
            let response = try await aiBackend.generate(
                prompt: prompt,
                systemPrompt: "You are an expert icon designer for Apple platforms. Generate creative, professional icon concepts.",
                temperature: 0.8,
                maxTokens: 800
            )

            if let concepts = parseIconConcepts(response) {
                await MainActor.run {
                    self.iconConcepts = concepts
                }
                return concepts
            }
        } catch {
            lastError = error.localizedDescription
            print("AI Icon Concepts error: \(error)")
        }

        return generateBasicConcepts(description: description)
    }

    private func generateBasicConcepts(description: String) -> [IconConcept] {
        return [
            IconConcept(
                name: "Simple & Clean",
                description: "Minimalist design with single symbol on solid background",
                elements: ["Main symbol", "Solid background", "Optional accent"],
                colors: ["#007AFF", "#FFFFFF", "#000000"],
                layout: "Centered symbol with padding",
                rationale: "Simple designs are most recognizable at small sizes"
            ),
            IconConcept(
                name: "Gradient Modern",
                description: "Contemporary gradient background with bold symbol",
                elements: ["Bold symbol", "Gradient background", "Subtle shadow"],
                colors: ["#FF6B6B", "#4ECDC4", "#45B7D1"],
                layout: "Symbol in upper third, gradient fills background",
                rationale: "Gradients create depth and visual interest"
            ),
            IconConcept(
                name: "Flat Material",
                description: "Flat design with layered elements",
                elements: ["Layered shapes", "Flat colors", "Clean edges"],
                colors: ["#2ECC71", "#3498DB", "#E74C3C"],
                layout: "Layered composition with geometric shapes",
                rationale: "Material design is clean and professional"
            )
        ]
    }

    // MARK: - Feature 2: AI Color Palette Suggestions

    /// Generate color palette recommendations
    func suggestColorPalettes(for concept: String, mood: String? = nil) async -> [ColorPalette] {
        guard aiBackend.activeBackend != nil else {
            return generateBasicPalettes()
        }

        isAnalyzing = true
        defer { isAnalyzing = false }

        let moodText = mood.map { "Mood: \($0)" } ?? "Mood: Professional"

        let prompt = """
        Suggest 4 color palettes for an app icon.

        Concept: \(concept)
        \(moodText)

        For each palette, provide:
        - Name (descriptive)
        - Colors (3-5 hex codes)
        - Description (when to use it)
        - Psychology (emotional impact)

        Respond in JSON:
        {
            "palettes": [
                {
                    "name": "Palette name",
                    "colors": ["#hex1", "#hex2", "#hex3"],
                    "description": "Description",
                    "psychology": "Emotional impact"
                }
            ]
        }
        """

        do {
            let response = try await aiBackend.generate(
                prompt: prompt,
                systemPrompt: "You are a color theory expert for app icon design. Suggest harmonious, professional palettes.",
                temperature: 0.7,
                maxTokens: 600
            )

            if let palettes = parseColorPalettes(response) {
                await MainActor.run {
                    self.colorPalettes = palettes
                }
                return palettes
            }
        } catch {
            lastError = error.localizedDescription
            print("AI Color Palettes error: \(error)")
        }

        return generateBasicPalettes()
    }

    private func generateBasicPalettes() -> [ColorPalette] {
        return [
            ColorPalette(
                name: "Tech Blue",
                colors: ["#007AFF", "#5AC8FA", "#FFFFFF"],
                description: "Professional, trustworthy, tech-focused",
                psychology: "Blue conveys trust, stability, and professionalism"
            ),
            ColorPalette(
                name: "Warm Energy",
                colors: ["#FF6B6B", "#FF9F1C", "#FFCF00"],
                description: "Energetic, friendly, approachable",
                psychology: "Warm colors create excitement and friendliness"
            ),
            ColorPalette(
                name: "Nature Fresh",
                colors: ["#2ECC71", "#27AE60", "#F1C40F"],
                description: "Natural, fresh, eco-friendly",
                psychology: "Green represents growth, health, and nature"
            ),
            ColorPalette(
                name: "Premium Dark",
                colors: ["#1A1A1A", "#FFD700", "#FFFFFF"],
                description: "Luxurious, premium, sophisticated",
                psychology: "Dark with gold accent conveys luxury and quality"
            )
        ]
    }

    // MARK: - Feature 3: AI Design Feedback

    /// Analyze icon design and provide feedback
    func analyzeIconDesign(image: NSImage, description: String, platform: String) async -> DesignFeedback {
        guard aiBackend.activeBackend != nil else {
            return generateBasicFeedback(image: image)
        }

        isAnalyzing = true
        defer { isAnalyzing = false }

        // Extract image properties
        let imageAnalysis = analyzeImageProperties(image)

        let prompt = """
        Provide expert design feedback for this app icon.

        Icon Description: \(description)
        Platform: \(platform)

        Image Properties:
        - Size: \(Int(image.size.width))×\(Int(image.size.height))
        - Has Transparency: \(imageAnalysis.hasTransparency ? "Yes" : "No")
        - Dominant Colors: \(imageAnalysis.dominantColors.joined(separator: ", "))
        - Complexity: \(imageAnalysis.complexity)

        Evaluate:
        1. Visual clarity at small sizes (64x64, 32x32)
        2. Color harmony and contrast
        3. Uniqueness and memorability
        4. Platform appropriateness
        5. Potential issues

        Respond in JSON:
        {
            "overallScore": 0-100,
            "strengths": ["strength1", "strength2"],
            "weaknesses": ["issue1", "issue2"],
            "recommendations": ["fix1", "fix2"],
            "appStoreReadiness": "ready|needs-work|not-ready"
        }
        """

        do {
            let response = try await aiBackend.generate(
                prompt: prompt,
                systemPrompt: "You are an Apple platform icon design expert. Provide constructive, specific feedback.",
                temperature: 0.5,
                maxTokens: 500
            )

            if let feedback = parseDesignFeedback(response) {
                await MainActor.run {
                    self.designFeedback = feedback
                }
                return feedback
            }
        } catch {
            lastError = error.localizedDescription
        }

        return generateBasicFeedback(image: image)
    }

    private func generateBasicFeedback(image: NSImage) -> DesignFeedback {
        let analysis = analyzeImageProperties(image)

        var strengths: [String] = []
        var weaknesses: [String] = []
        var recommendations: [String] = []

        // Basic checks
        if !analysis.hasTransparency {
            strengths.append("No transparency (iOS compliant)")
        } else {
            weaknesses.append("Has transparency (iOS icons must be opaque)")
            recommendations.append("Remove alpha channel for iOS compatibility")
        }

        if image.size.width >= 1024 {
            strengths.append("High resolution (1024×1024+)")
        } else {
            weaknesses.append("Low resolution (less than 1024×1024)")
            recommendations.append("Use at least 1024×1024 source image")
        }

        let score = strengths.count * 20 - weaknesses.count * 10
        let clampedScore = max(0, min(100, score + 50))

        return DesignFeedback(
            overallScore: clampedScore,
            strengths: strengths,
            weaknesses: weaknesses,
            recommendations: recommendations,
            appStoreReadiness: clampedScore >= 70 ? .ready : clampedScore >= 50 ? .needsWork : .notReady
        )
    }

    // MARK: - Feature 4: AI App Store Compliance Check

    /// Check icon against App Store guidelines
    func checkAppStoreCompliance(image: NSImage, platform: String, iconPurpose: String) async -> ComplianceFeedback {
        guard aiBackend.activeBackend != nil else {
            return performBasicComplianceCheck(image: image, platform: platform)
        }

        isAnalyzing = true
        defer { isAnalyzing = false }

        let imageAnalysis = analyzeImageProperties(image)

        let prompt = """
        Review this app icon for App Store compliance.

        Platform: \(platform)
        Purpose: \(iconPurpose)

        Technical Details:
        - Size: \(Int(image.size.width))×\(Int(image.size.height))
        - Transparency: \(imageAnalysis.hasTransparency ? "Yes" : "No")
        - Complexity: \(imageAnalysis.complexity)

        Check against Apple guidelines:
        1. iOS icons must NOT have transparency
        2. Icons must be square (1:1 aspect ratio)
        3. Minimum 1024×1024 for App Store
        4. No rounded corners (system applies them)
        5. Must be recognizable at small sizes
        6. Should not replicate Apple UI elements
        7. Must not use Apple product images
        8. Should be unique and not generic

        Respond in JSON:
        {
            "compliant": true|false,
            "issues": ["issue1", "issue2"],
            "warnings": ["warning1", "warning2"],
            "recommendations": ["fix1", "fix2"],
            "severity": "pass|minor|major|critical"
        }
        """

        do {
            let response = try await aiBackend.generate(
                prompt: prompt,
                systemPrompt: "You are an Apple App Store review expert. Check icon compliance with strict Apple guidelines.",
                temperature: 0.3,
                maxTokens: 400
            )

            if let compliance = parseComplianceFeedback(response) {
                await MainActor.run {
                    self.complianceFeedback = compliance
                }
                return compliance
            }
        } catch {
            lastError = error.localizedDescription
        }

        return performBasicComplianceCheck(image: image, platform: platform)
    }

    private func performBasicComplianceCheck(image: NSImage, platform: String) -> ComplianceFeedback {
        var issues: [String] = []
        var warnings: [String] = []
        var recommendations: [String] = []

        let analysis = analyzeImageProperties(image)

        // iOS transparency check
        if platform.lowercased().contains("ios") && analysis.hasTransparency {
            issues.append("iOS icons must not have transparency")
            recommendations.append("Remove alpha channel or fill with solid background")
        }

        // Size check
        if image.size.width < 1024 || image.size.height < 1024 {
            issues.append("Icon must be at least 1024×1024 for App Store")
            recommendations.append("Use higher resolution source image")
        }

        // Aspect ratio check
        if abs(image.size.width - image.size.height) > 1 {
            issues.append("Icon must be square (1:1 aspect ratio)")
            recommendations.append("Crop or resize to square dimensions")
        }

        let severity: ComplianceSeverity = issues.isEmpty ? .pass : issues.count > 2 ? .critical : .major

        return ComplianceFeedback(
            compliant: issues.isEmpty,
            issues: issues,
            warnings: warnings,
            recommendations: recommendations,
            severity: severity
        )
    }

    // MARK: - Image Analysis Helpers

    private func analyzeImageProperties(_ image: NSImage) -> ImageAnalysis {
        // Check for transparency
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return ImageAnalysis(hasTransparency: false, dominantColors: [], complexity: "unknown")
        }

        let hasAlpha = bitmap.hasAlpha
        let hasTransparency = hasAlpha && containsTransparentPixels(bitmap)

        // Sample dominant colors
        let dominantColors = extractDominantColors(from: bitmap)

        // Estimate complexity
        let complexity = estimateComplexity(bitmap)

        return ImageAnalysis(
            hasTransparency: hasTransparency,
            dominantColors: dominantColors,
            complexity: complexity
        )
    }

    private func containsTransparentPixels(_ bitmap: NSBitmapImageRep) -> Bool {
        guard bitmap.hasAlpha else { return false }

        let width = bitmap.pixelsWide
        let height = bitmap.pixelsHigh
        let bytesPerPixel = bitmap.bitsPerPixel / 8

        guard let data = bitmap.bitmapData else { return false }

        // Sample pixels to check for transparency
        for y in stride(from: 0, to: height, by: 10) {
            for x in stride(from: 0, to: width, by: 10) {
                let offset = (y * width + x) * bytesPerPixel
                if offset + bytesPerPixel <= bitmap.bytesPerRow * height {
                    let alpha = data[offset + 3]
                    if alpha < 255 {
                        return true
                    }
                }
            }
        }

        return false
    }

    private func extractDominantColors(from bitmap: NSBitmapImageRep) -> [String] {
        // Sample center pixels for dominant color
        let centerX = bitmap.pixelsWide / 2
        let centerY = bitmap.pixelsHigh / 2
        let bytesPerPixel = bitmap.bitsPerPixel / 8

        guard let data = bitmap.bitmapData else { return [] }

        var sampledColors: [String] = []

        for dy in [-10, 0, 10] {
            for dx in [-10, 0, 10] {
                let x = centerX + dx
                let y = centerY + dy

                if x >= 0 && x < bitmap.pixelsWide && y >= 0 && y < bitmap.pixelsHigh {
                    let offset = (y * bitmap.pixelsWide + x) * bytesPerPixel
                    if offset + bytesPerPixel <= bitmap.bytesPerRow * bitmap.pixelsHigh {
                        let r = data[offset]
                        let g = data[offset + 1]
                        let b = data[offset + 2]

                        let hex = String(format: "#%02X%02X%02X", r, g, b)
                        sampledColors.append(hex)
                    }
                }
            }
        }

        return Array(Set(sampledColors)).prefix(3).map { $0 }
    }

    private func estimateComplexity(_ bitmap: NSBitmapImageRep) -> String {
        // Simple complexity estimation based on unique colors
        let uniqueColors = Set(extractDominantColors(from: bitmap)).count

        if uniqueColors <= 3 {
            return "Simple (1-3 colors)"
        } else if uniqueColors <= 6 {
            return "Moderate (4-6 colors)"
        } else {
            return "Complex (7+ colors)"
        }
    }

    // MARK: - JSON Parsing

    private func parseIconConcepts(_ response: String) -> [IconConcept]? {
        guard let jsonData = extractJSON(from: response)?.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let conceptsArray = json["concepts"] as? [[String: Any]] else {
            return nil
        }

        return conceptsArray.compactMap { dict in
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

    private func parseColorPalettes(_ response: String) -> [ColorPalette]? {
        guard let jsonData = extractJSON(from: response)?.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let palettesArray = json["palettes"] as? [[String: Any]] else {
            return nil
        }

        return palettesArray.compactMap { dict in
            guard let name = dict["name"] as? String,
                  let colors = dict["colors"] as? [String],
                  let description = dict["description"] as? String,
                  let psychology = dict["psychology"] as? String else {
                return nil
            }

            return ColorPalette(
                name: name,
                colors: colors,
                description: description,
                psychology: psychology
            )
        }
    }

    private func parseDesignFeedback(_ response: String) -> DesignFeedback? {
        guard let jsonData = extractJSON(from: response)?.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }

        let score = json["overallScore"] as? Int ?? 50
        let strengths = json["strengths"] as? [String] ?? []
        let weaknesses = json["weaknesses"] as? [String] ?? []
        let recommendations = json["recommendations"] as? [String] ?? []
        let readinessStr = json["appStoreReadiness"] as? String ?? "needs-work"

        let readiness: AppStoreReadiness = readinessStr == "ready" ? .ready :
                                          readinessStr == "not-ready" ? .notReady : .needsWork

        return DesignFeedback(
            overallScore: score,
            strengths: strengths,
            weaknesses: weaknesses,
            recommendations: recommendations,
            appStoreReadiness: readiness
        )
    }

    private func parseComplianceFeedback(_ response: String) -> ComplianceFeedback? {
        guard let jsonData = extractJSON(from: response)?.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }

        let compliant = json["compliant"] as? Bool ?? false
        let issues = json["issues"] as? [String] ?? []
        let warnings = json["warnings"] as? [String] ?? []
        let recommendations = json["recommendations"] as? [String] ?? []
        let severityStr = json["severity"] as? String ?? "major"

        let severity: ComplianceSeverity = severityStr == "pass" ? .pass :
                                          severityStr == "minor" ? .minor :
                                          severityStr == "major" ? .major : .critical

        return ComplianceFeedback(
            compliant: compliant,
            issues: issues,
            warnings: warnings,
            recommendations: recommendations,
            severity: severity
        )
    }

    private func extractJSON(from text: String) -> String? {
        // Try to find JSON in response (sometimes LLMs wrap it in markdown)
        if let range = text.range(of: "\\{[\\s\\S]*\\}", options: .regularExpression) {
            return String(text[range])
        }
        return text.hasPrefix("{") ? text : nil
    }
}

// MARK: - Data Models

struct IconConcept: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let elements: [String]
    let colors: [String]
    let layout: String
    let rationale: String
}

struct ColorPalette: Identifiable {
    let id = UUID()
    let name: String
    let colors: [String]
    let description: String
    let psychology: String

    var swiftUIColors: [Color] {
        colors.compactMap { Color(hex: $0) }
    }
}

struct DesignFeedback {
    let overallScore: Int // 0-100
    let strengths: [String]
    let weaknesses: [String]
    let recommendations: [String]
    let appStoreReadiness: AppStoreReadiness

    enum AppStoreReadiness: String {
        case ready = "Ready for App Store"
        case needsWork = "Needs Improvement"
        case notReady = "Not Ready"

        var color: Color {
            switch self {
            case .ready: return .green
            case .needsWork: return .orange
            case .notReady: return .red
            }
        }
    }
}

struct ComplianceFeedback {
    let compliant: Bool
    let issues: [String]
    let warnings: [String]
    let recommendations: [String]
    let severity: ComplianceSeverity

    enum ComplianceSeverity: String {
        case pass = "Pass"
        case minor = "Minor Issues"
        case major = "Major Issues"
        case critical = "Critical Issues"

        var color: Color {
            switch self {
            case .pass: return .green
            case .minor: return .blue
            case .major: return .orange
            case .critical: return .red
            }
        }
    }
}

struct ImageAnalysis {
    let hasTransparency: Bool
    let dominantColors: [String]
    let complexity: String
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0

        guard Scanner(string: hex).scanHexInt64(&int) else { return nil }

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
