//
//  AISettingsSheet.swift
//  Icon Creator
//
//  AI settings (NovaAIKit): on/off, backend + model pickers, editable URLs, Keychain-stored keys, connection test.
//  Shown from the toolbar's "AI Config" button and in Settings (⌘,).
//
//  Author: Jordan Koch
//

import SwiftUI
import NovaAIKit

struct AISettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            NovaAISettingsView(ai: AppAI.shared, footer: AppAI.fallbackDescription)
            Divider()
            HStack {
                NovaAIStatusIndicator(ai: AppAI.shared)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(minWidth: 560, minHeight: 560)
    }
}

/// Settings window content (⌘,).
struct IconCreatorSettingsView: View {
    var body: some View {
        TabView {
            NovaAISettingsView(ai: AppAI.shared, footer: AppAI.fallbackDescription)
                .tabItem { Label("AI", systemImage: "cpu") }
        }
        .frame(width: 600, height: 600)
    }
}
