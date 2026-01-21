#!/usr/bin/env ruby
require 'securerandom'

project_path = Dir.glob('*.xcodeproj/project.pbxproj')[0]
content = File.read(project_path)

files = [
  { name: 'KeywordIconGenerator.swift', path: 'KeywordIconGenerator.swift' },
  { name: 'KeywordIconGeneratorView.swift', path: 'KeywordIconGeneratorView.swift' }
]

files.each do |file|
  file_ref_id = SecureRandom.uuid.gsub('-', '')[0..23].upcase
  build_file_id = SecureRandom.uuid.gsub('-', '')[0..23].upcase
  
  # Add PBXFileReference
  file_ref = "\t\t#{file_ref_id} /* #{file[:name]} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = #{file[:path]}; sourceTree = \"<group>\"; };\n"
  content.sub!(/\/\* End PBXFileReference section \*\//, file_ref + "\t\t/* End PBXFileReference section */")
  
  # Add PBXBuildFile
  build_file = "\t\t#{build_file_id} /* #{file[:name]} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_ref_id} /* #{file[:name]} */; };\n"
  content.sub!(/\/\* End PBXBuildFile section \*\//, build_file + "\t\t/* End PBXBuildFile section */")
  
  # Add to Sources phase
  content.sub!(/(\/\* Sources \*\/ = \{[^}]*files = \([^)]*)/m) { $1 + "\n\t\t\t\t#{build_file_id} /* #{file[:name]} in Sources */," }
  
  puts "✓ #{file[:name]}"
end

File.write(project_path, content)
puts "\n✅ Files added to Icon Creator project!"
