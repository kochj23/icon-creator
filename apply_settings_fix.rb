#!/usr/bin/env ruby

# Read ContentView
content = File.read('ContentView.swift')

# Add showingAISettings state if not present
unless content.include?('showingAISettings')
  content.sub!(/(@State private var resizedScreenshotImage.*?\n)/, '\1    @State private var showingAISettings = false
')
end

# Add AI Config button if not present
unless content.include?('AI Config')
  content.sub!(/(if !screenshotResizerMode \{.*?Button\(action:.*?showingPresetLibrary.*?\n)/m) do
    "#{$1}
                        Button(action: { showingAISettings = true }) {
                            Label(\"AI Config\", systemImage: \"cpu\")
                        }
"
  end
end

# Add sheet for AI settings if not present
unless content.include?('showingAISettings')
  content.sub!(/(.sheet\(isPresented: \$showingPresetLibrary.*?\}\n)/, '\1        .sheet(isPresented: $showingAISettings) {
            AIBackendSettingsView()
        }
')
end

# Add onAppear initialization if not present
unless content.include?('AIBackendManager.shared.checkBackendAvailability')
  content.sub!(/(\.onChange\(of: iconGenerator.sourceImage.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\}\n)/, '\1        .onAppear {
            Task {
                await AIBackendManager.shared.checkBackendAvailability()
            }
        }
')
end

File.write('ContentView.swift', content)
puts "✓ Applied settings fixes to ContentView"
