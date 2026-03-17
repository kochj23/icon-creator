import Foundation
import WidgetKit
import AppIntents

// MARK: - Timeline Entry

struct IconCreatorEntry: TimelineEntry {
    let date: Date
    let data: IconCreatorWidgetData
    let configuration: ConfigurationAppIntent?

    init(date: Date = Date(),
         data: IconCreatorWidgetData = IconCreatorWidgetData(),
         configuration: ConfigurationAppIntent? = nil) {
        self.date = date
        self.data = data
        self.configuration = configuration
    }

    static var placeholder: IconCreatorEntry {
        IconCreatorEntry(data: .placeholder)
    }
}

// MARK: - Widget Intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Icon Creator Widget"
    static var description = IntentDescription("Shows recent projects and quick actions")

    @Parameter(title: "Show Presets")
    var showPresets: Bool

    @Parameter(title: "Show Generation Status")
    var showGenerationStatus: Bool

    init() {
        self.showPresets = true
        self.showGenerationStatus = true
    }

    init(showPresets: Bool, showGenerationStatus: Bool) {
        self.showPresets = showPresets
        self.showGenerationStatus = showGenerationStatus
    }
}
