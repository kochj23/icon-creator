import SwiftUI

/// A saved configuration of icon settings that can be reused
struct IconPreset: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var settings: IconSettings
    var thumbnail: Data? // PNG data for preview
    var isBuiltIn: Bool = false
    var createdDate: Date = Date()

    init(id: UUID = UUID(), name: String, settings: IconSettings, thumbnail: Data? = nil, isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.settings = settings
        self.thumbnail = thumbnail
        self.isBuiltIn = isBuiltIn
        self.createdDate = Date()
    }

    // MARK: - Built-in Presets

    static var minimalist: IconPreset {
        var settings = IconSettings()
        settings.scale = 0.7
        settings.padding = 15
        settings.backgroundColor = ColorComponents(.white)
        return IconPreset(name: "Minimalist", settings: settings, isBuiltIn: true)
    }

    static var padded: IconPreset {
        var settings = IconSettings()
        settings.scale = 0.8
        settings.padding = 20
        settings.backgroundColor = ColorComponents(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        return IconPreset(name: "Padded", settings: settings, isBuiltIn: true)
    }

    static var fullBleed: IconPreset {
        var settings = IconSettings()
        settings.scale = 1.2
        settings.padding = 0
        settings.backgroundColor = ColorComponents(.white)
        return IconPreset(name: "Full Bleed", settings: settings, isBuiltIn: true)
    }

    static var rounded: IconPreset {
        var settings = IconSettings()
        settings.scale = 0.9
        settings.padding = 10
        settings.backgroundColor = ColorComponents(.white)
        settings.effects.cornerRadiusEnabled = true
        settings.effects.cornerRadius = 20
        return IconPreset(name: "Rounded", settings: settings, isBuiltIn: true)
    }

    static var shadowed: IconPreset {
        var settings = IconSettings()
        settings.scale = 0.85
        settings.padding = 12
        settings.backgroundColor = ColorComponents(.white)
        settings.effects.shadowEnabled = true
        settings.effects.shadowBlur = 15
        settings.effects.shadowOffsetY = 8
        return IconPreset(name: "Shadowed", settings: settings, isBuiltIn: true)
    }

    static var gradient: IconPreset {
        var settings = IconSettings()
        settings.scale = 0.9
        settings.padding = 10
        settings.effects.backgroundType = .gradient(.sunset, .diagonal)
        return IconPreset(name: "Gradient", settings: settings, isBuiltIn: true)
    }

    static var bordered: IconPreset {
        var settings = IconSettings()
        settings.scale = 0.85
        settings.padding = 12
        settings.backgroundColor = ColorComponents(.white)
        settings.effects.borderEnabled = true
        settings.effects.borderWidth = 3
        settings.effects.borderColor = ColorComponents(.black)
        return IconPreset(name: "Bordered", settings: settings, isBuiltIn: true)
    }

    static var allBuiltIn: [IconPreset] {
        [minimalist, padded, fullBleed, rounded, shadowed, gradient, bordered]
    }
}
