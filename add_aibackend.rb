#!/usr/bin/env ruby
require 'securerandom'

project_path = 'Icon Creator.xcodeproj/project.pbxproj'
content = File.read(project_path)

file_ref_id = SecureRandom.uuid.gsub('-', '')[0..23].upcase
build_file_id = SecureRandom.uuid.gsub('-', '')[0..23].upcase

# Add PBXFileReference
file_ref = "\t\t#{file_ref_id} /* AIBackendManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AIBackendManager.swift; sourceTree = \"<group>\"; };\n"
content.sub!(/\/\* End PBXFileReference section \*\//, file_ref + "\t\t/* End PBXFileReference section */")

# Add PBXBuildFile
build_file = "\t\t#{build_file_id} /* AIBackendManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = #{file_ref_id} /* AIBackendManager.swift */; };\n"
content.sub!(/\/\* End PBXBuildFile section \*\//, build_file + "\t\t/* End PBXBuildFile section */")

# Add to Sources phase
content.sub!(/(\/\* Sources \*\/ = \{[^}]*files = \([^)]*)/m) { $1 + "\n\t\t\t\t#{build_file_id} /* AIBackendManager.swift in Sources */," }

File.write(project_path, content)
puts "✓ Added AIBackendManager.swift to Icon Creator project"
