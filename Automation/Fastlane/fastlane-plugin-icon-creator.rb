# Fastlane Plugin for Icon Creator
# Automates icon generation in iOS/macOS build pipelines
# Author: Jordan Koch
# Date: 2026-01-21

require 'fastlane/plugin/icon_creator/version'

module Fastlane
  module IconCreator
    # Return all .rb files inside the "actions" and "helper" directory
    def self.all_classes
      Dir[File.expand_path('**/{actions,helper}/*.rb', File.dirname(__FILE__))]
    end
  end
end

# By default we want to import all available actions and helpers
# A plugin can contain any number of actions and plugins
Fastlane::IconCreator.all_classes.each do |current|
  require current
end

module Fastlane
  module Actions
    class GenerateAppIconsAction < Action
      def self.run(params)
        require 'fileutils'
        require 'json'

        source_path = params[:source]
        output_path = params[:output]
        platforms = params[:platforms]
        preset = params[:preset]
        optimize = params[:optimize]

        UI.message("🎨 Generating app icons...")
        UI.message("Source: #{source_path}")
        UI.message("Output: #{output_path}")
        UI.message("Platforms: #{platforms.join(', ')}")

        # Build CLI command
        cmd = "icon-creator generate"
        cmd += " --input '#{source_path}'"
        cmd += " --output '#{output_path}'"
        cmd += " --platforms #{platforms.join(',')}" if platforms.any?
        cmd += " --preset '#{preset}'" if preset
        cmd += " --verbose"

        # Execute icon generation
        result = Actions.sh(cmd, log: true)

        # Optimize if requested
        if optimize
          UI.message("⚡ Optimizing icons...")
          optimize_cmd = "icon-creator optimize --input '#{output_path}' --aggressive"
          Actions.sh(optimize_cmd, log: true)
        end

        # Analyze results
        analyze_cmd = "icon-creator analyze --input '#{output_path}' --format json"
        analysis_json = Actions.sh(analyze_cmd, log: false)

        begin
          analysis = JSON.parse(analysis_json)

          UI.success("✅ Icon generation complete!")
          UI.message("📊 Statistics:")
          UI.message("  • Files: #{analysis['totalFiles']}")
          UI.message("  • Total Size: #{human_filesize(analysis['totalSize'])}")
          UI.message("  • Average Size: #{human_filesize(analysis['averageSize'])}")

          if analysis['issues'].any?
            UI.important("⚠️  Issues found:")
            analysis['issues'].each { |issue| UI.message("  • #{issue}") }
          end

          return analysis
        rescue JSON::ParserError => e
          UI.error("Could not parse analysis results: #{e.message}")
          return { success: true }
        end
      end

      def self.human_filesize(size)
        units = ['B', 'KB', 'MB', 'GB']
        unit_index = 0

        while size >= 1024.0 && unit_index < units.length - 1
          size /= 1024.0
          unit_index += 1
        end

        "#{size.round(2)} #{units[unit_index]}"
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Generate app icons for iOS, macOS, watchOS, and tvOS using Icon Creator"
      end

      def self.details
        "Automates the generation of app icons across multiple Apple platforms. " \
        "Supports custom presets, optimization, and performance analysis."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :source,
            env_name: "ICON_CREATOR_SOURCE",
            description: "Source image path (PNG or JPG)",
            verify_block: proc do |value|
              UI.user_error!("Source image not found: #{value}") unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :output,
            env_name: "ICON_CREATOR_OUTPUT",
            description: "Output directory for generated icons",
            default_value: "./generated-icons"
          ),
          FastlaneCore::ConfigItem.new(
            key: :platforms,
            description: "Platforms to generate icons for",
            type: Array,
            default_value: ["iOS", "macOS"],
            verify_block: proc do |value|
              valid = ["iOS", "macOS", "watchOS", "tvOS"]
              invalid = value - valid
              UI.user_error!("Invalid platforms: #{invalid.join(', ')}") if invalid.any?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :preset,
            env_name: "ICON_CREATOR_PRESET",
            description: "Preset name to apply",
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :optimize,
            description: "Optimize generated icons for file size",
            type: Boolean,
            default_value: true
          )
        ]
      end

      def self.return_value
        "Hash containing icon generation statistics and analysis"
      end

      def self.authors
        ["Jordan Koch"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end

      def self.example_code
        [
          'generate_app_icons(
            source: "./assets/icon.png",
            platforms: ["iOS", "macOS"],
            optimize: true
          )',
          'generate_app_icons(
            source: ENV["ICON_SOURCE"],
            output: "./Assets.xcassets",
            platforms: ["iOS"],
            preset: "rounded"
          )'
        ]
      end

      def self.category
        :project
      end
    end

    class GenerateIconVariantsAction < Action
      def self.run(params)
        source = params[:source]
        output = params[:output]
        count = params[:count]
        styles = params[:styles]

        UI.message("🎨 Generating #{count} icon variants...")

        cmd = "icon-creator variants"
        cmd += " --input '#{source}'"
        cmd += " --output '#{output}'"
        cmd += " --count #{count}"
        cmd += " --styles #{styles.join(',')}" if styles.any?
        cmd += " --verbose"

        Actions.sh(cmd, log: true)

        # Read variant catalog
        catalog_path = File.join(output, "variant-catalog.json")
        if File.exist?(catalog_path)
          catalog = JSON.parse(File.read(catalog_path))

          UI.success("✅ Generated #{catalog['total_variants']} variants")
          catalog['variants'].each_with_index do |variant, index|
            UI.message("  #{index + 1}. #{variant['style']} (#{variant['id']})")
          end

          return catalog
        else
          UI.success("✅ Variants generated")
          return { success: true }
        end
      end

      def self.description
        "Generate multiple icon variants for A/B testing"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :source,
            description: "Source image path",
            verify_block: proc do |value|
              UI.user_error!("Source not found: #{value}") unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :output,
            description: "Output directory for variants",
            default_value: "./icon-variants"
          ),
          FastlaneCore::ConfigItem.new(
            key: :count,
            description: "Number of variants to generate",
            type: Integer,
            default_value: 5
          ),
          FastlaneCore::ConfigItem.new(
            key: :styles,
            description: "Styles to apply to variants",
            type: Array,
            default_value: ["original", "gradient", "shadow", "rounded", "vibrant"]
          )
        ]
      end

      def self.authors
        ["Jordan Koch"]
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          'generate_icon_variants(
            source: "./icon.png",
            count: 5,
            styles: ["original", "gradient", "shadow"]
          )'
        ]
      end
    end
  end
end
