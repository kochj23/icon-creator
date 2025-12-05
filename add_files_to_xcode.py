#!/usr/bin/env python3
"""
Script to add new Swift files to Xcode project.pbxproj
Programmatically modifies the project file to include all Phase 1 files.
"""

import uuid
import re

# Files to add
NEW_FILES = [
    "Models/Batch/BatchItem.swift",
    "Models/Core/IconPreset.swift",
    "Models/Core/IconSettings.swift",
    "Services/ImageProcessing/ImageProcessor.swift",
    "ViewModels/BatchProcessingManager.swift",
    "ViewModels/PresetManager.swift",
    "Views/Batch/BatchQueueView.swift",
    "Views/Effects/ImageEffectsPanel.swift",
    "Views/Presets/PresetLibraryView.swift",
    "Views/Preview/ContextPreviewView.swift",
]

def generate_id():
    """Generate a 24-character hex ID for Xcode"""
    return ''.join([format(x, '02X') for x in uuid.uuid4().bytes[:12]])

def add_files_to_project(project_path):
    """Add new files to the Xcode project"""

    # Read project file
    with open(project_path, 'r') as f:
        content = f.read()

    # Generate IDs for each file
    file_refs = {}
    build_files = {}

    for filepath in NEW_FILES:
        filename = filepath.split('/')[-1]
        file_refs[filepath] = generate_id()
        build_files[filepath] = generate_id()

    # Add to PBXBuildFile section
    build_file_entries = []
    for filepath, build_id in build_files.items():
        filename = filepath.split('/')[-1]
        file_ref_id = file_refs[filepath]
        entry = f"\t\t{build_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {filename} */; }};"
        build_file_entries.append(entry)

    # Insert into PBXBuildFile section
    build_section_pattern = r'(/\* End PBXBuildFile section \*/)'
    build_section_insert = '\n'.join(build_file_entries) + '\n'
    content = re.sub(build_section_pattern, build_section_insert + r'\1', content)

    # Add to PBXFileReference section
    file_ref_entries = []
    for filepath, file_ref_id in file_refs.items():
        filename = filepath.split('/')[-1]
        entry = f"\t\t{file_ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{filepath}\"; sourceTree = \"<group>\"; }};"
        file_ref_entries.append(entry)

    # Insert into PBXFileReference section
    file_ref_pattern = r'(/\* End PBXFileReference section \*/)'
    file_ref_insert = '\n'.join(file_ref_entries) + '\n'
    content = re.sub(file_ref_pattern, file_ref_insert + r'\1', content)

    # Add to main group children
    main_group_pattern = r'(IC0000150000000000000001 = \{[\s\S]*?children = \()'
    group_entries = [f"\n\t\t\t\t{file_refs[filepath]} /* {filepath.split('/')[-1]} */," for filepath in NEW_FILES]
    content = re.sub(main_group_pattern, r'\1' + ''.join(group_entries), content)

    # Add to Sources build phase
    sources_pattern = r'(IC0000190000000000000001 /\* Sources \*/ = \{[\s\S]*?files = \()'
    source_entries = [f"\n\t\t\t\t{build_files[filepath]} /* {filepath.split('/')[-1]} in Sources */," for filepath in NEW_FILES]
    content = re.sub(sources_pattern, r'\1' + ''.join(source_entries), content)

    # Write back
    with open(project_path, 'w') as f:
        f.write(content)

    print(f"✅ Added {len(NEW_FILES)} files to Xcode project")
    for filepath in NEW_FILES:
        print(f"   - {filepath}")

if __name__ == '__main__':
    project_path = 'Icon Creator.xcodeproj/project.pbxproj'
    add_files_to_project(project_path)
