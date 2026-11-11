//
//  KeywordExpansion.swift
//  Icon Creator
//
//  "Expand Keywords": turns a few keywords into concrete visual elements for icon prompts. AI when available
//  (NovaAIKit), otherwise a built-in icon vocabulary. Every AI reply is validated before it reaches the UI.
//
//  Author: Jordan Koch
//

import Foundation
import NovaAIKit

enum KeywordExpansion {
    /// Most elements kept from one reply.
    static let maxElements = 30
    /// Longest element accepted (characters).
    static let maxElementLength = 60

    static let systemPrompt =
        "You are an icon designer. Convert keywords into concrete visual elements suitable for app icons."

    static func prompt(for keywords: [String]) -> String {
        """
        Expand these keywords into detailed visual elements suitable for app icons.

        Keywords: \(keywords.joined(separator: ", "))

        For each keyword, provide 3-5 related concrete visual elements:
        - Use shapes, symbols, objects (not abstract concepts)
        - Think about iconic, recognizable imagery
        - Suitable for app icons

        Example:
        "music" → "musical note, headphones, sound waveform, microphone, vinyl record"
        "security" → "shield, lock, key, fingerprint, padlock, checkmark"

        Respond with comma-separated visual elements only.
        """
    }

    static func request(for keywords: [String]) -> NovaAIRequest {
        NovaAIRequest(prompt: prompt(for: keywords), system: systemPrompt, temperature: 0.7, maxTokens: 400)
    }

    /// Validator: comma/line separated elements → trimmed, de-duplicated, length- and count-clamped list.
    /// Throws when nothing usable is left.
    @Sendable static func parse(_ reply: String) throws -> [String] {
        var seen = Set<String>()
        let items = reply
            .components(separatedBy: CharacterSet(charactersIn: ",\n;"))
            .map { $0.components(separatedBy: ":").last ?? $0 }
            .map { $0.replacingOccurrences(of: #"^\s*\d+[.)]\s+"#, with: "", options: .regularExpression) }
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines
                .union(CharacterSet(charactersIn: "-*•\"'`."))) }
            .map { $0.replacingOccurrences(of: "→", with: " ") }
            .filter { !$0.isEmpty && $0.count <= maxElementLength }
            .filter { seen.insert($0.lowercased()).inserted }
        guard !items.isEmpty else { throw NovaAIValidationError("no visual elements in the reply") }
        return Array(items.prefix(maxElements))
    }

    /// Built-in vocabulary used when AI is off, unreachable or its reply is rejected.
    static let vocabulary: [String: [String]] = [
        "music": ["musical note", "headphones", "sound waveform", "microphone", "vinyl record"],
        "security": ["shield", "padlock", "key", "fingerprint", "checkmark"],
        "chat": ["speech bubble", "two speech bubbles", "ellipsis", "envelope"],
        "message": ["speech bubble", "envelope", "paper plane"],
        "weather": ["sun", "cloud", "raindrop", "lightning bolt", "snowflake"],
        "photo": ["camera", "lens aperture", "picture frame", "mountain and sun"],
        "camera": ["camera body", "lens aperture", "shutter", "flash"],
        "finance": ["coin", "bar chart", "wallet", "dollar sign", "upward arrow"],
        "money": ["coin", "banknote", "wallet", "piggy bank"],
        "health": ["heart", "pulse line", "medical cross", "leaf"],
        "fitness": ["dumbbell", "running shoe", "stopwatch", "heart"],
        "travel": ["airplane", "globe", "suitcase", "map pin", "compass"],
        "map": ["map pin", "folded map", "compass", "route line"],
        "food": ["fork and knife", "plate", "chef hat", "apple"],
        "game": ["game controller", "joystick", "dice", "star"],
        "code": ["curly braces", "terminal prompt", "angle brackets", "gear"],
        "developer": ["curly braces", "terminal prompt", "hammer", "gear"],
        "network": ["connected nodes", "globe", "signal waves", "router"],
        "cloud": ["cloud", "upload arrow", "server", "sync arrows"],
        "sync": ["circular arrows", "cloud", "two devices", "checkmark"],
        "file": ["document", "folder", "paper clip", "stack of pages"],
        "calendar": ["calendar page", "clock", "checkmark", "bell"],
        "time": ["clock face", "hourglass", "stopwatch", "calendar"],
        "news": ["newspaper", "megaphone", "globe", "headline bars"],
        "book": ["open book", "bookmark", "pen", "stack of books"],
        "education": ["graduation cap", "book", "pencil", "light bulb"],
        "shopping": ["shopping bag", "cart", "price tag", "gift box"],
        "social": ["people silhouettes", "heart", "speech bubble", "share arrow"],
        "video": ["play button", "film strip", "clapperboard", "screen"],
        "ai": ["neural network nodes", "sparkles", "chip", "brain outline"],
        "home": ["house", "key", "light bulb", "thermostat"],
        "car": ["car silhouette", "steering wheel", "road", "fuel gauge"],
        "art": ["paint brush", "palette", "pencil", "canvas"],
        "design": ["pen tool", "palette", "ruler", "grid"],
        "mail": ["envelope", "paper plane", "inbox tray", "at sign"],
        "notes": ["notepad", "pencil", "checklist", "sticky note"],
        "search": ["magnifying glass", "spotlight", "binoculars"],
        "settings": ["gear", "sliders", "wrench", "toggle switch"],
        "tools": ["wrench", "hammer", "screwdriver", "toolbox"],
        "space": ["rocket", "planet with ring", "star", "crescent moon"],
        "nature": ["leaf", "tree", "mountain", "sun"],
        "data": ["bar chart", "database cylinder", "pie chart", "table grid"],
    ]

    /// Built-in expansion: known keywords → vocabulary, unknown keywords → "<keyword> symbol"/"<keyword> silhouette".
    /// Never empty for non-empty input; keeps the user's keywords first.
    @Sendable static func builtIn(_ keywords: [String]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        func add(_ s: String) { if seen.insert(s.lowercased()).inserted { out.append(s) } }
        for raw in keywords {
            let k = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !k.isEmpty else { continue }
            add(k)
            let key = k.lowercased()
            let words = key.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
            let match = vocabulary[key] ?? words.lazy.compactMap { vocabulary[$0] }.first
            if let match {
                match.forEach(add)
            } else {
                add("\(k) symbol")
                add("\(k) silhouette")
            }
        }
        return Array(out.prefix(maxElements))
    }
}
