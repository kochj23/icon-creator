#!/usr/bin/env ruby

project_path = 'Icon Creator.xcodeproj/project.pbxproj'
content = File.read(project_path)

# Files to remove
files_to_remove = ['AIIconAssistant.swift', 'AIAssistantView.swift']

files_to_remove.each do |file|
  # Find and comment out references
  content.gsub!(/.*#{Regexp.escape(file)}.*\n/, '')
  puts "✓ Removed references to #{file}"
end

File.write(project_path, content)
