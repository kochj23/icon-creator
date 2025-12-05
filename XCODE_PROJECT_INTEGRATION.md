# Xcode Project Integration Feature

## Overview

The Icon Creator app now includes automatic Xcode project integration, allowing you to drag an image into the app and have icons automatically installed into your selected Xcode project without any manual file management.

## Features

### Automatic Project Discovery
- Scans `/Users/kochj/Desktop/xcode/` for all Xcode projects
- Automatically detects platform type for each project (iOS, macOS, tvOS, watchOS)
- Displays projects in an easy-to-use dropdown menu and modal selector
- Refresh button to re-scan for new projects

### Intelligent Platform Detection (NEW in v1.1!)
- **Automatic SDKROOT Detection**: Reads project.pbxproj to identify target platforms
- **Multi-Platform Support**: Detects iOS, macOS, tvOS, watchOS, Mac Catalyst, iMessage
- **Smart Fallback**: Infers platform from project name if SDK not found
- **Priority Ordering**: Selects most appropriate platform when multiple are detected

### Project Selection on Image Drop (NEW in v1.1!)
- **Modal Dialog**: Beautiful project selector appears when you drag an image in
- **Visual Platform Indicators**: Shows SF Symbol icons for each platform (iPhone, Mac, TV, Watch)
- **Auto-Detection Display**: Shows which platforms were detected for each project
- **One-Click Selection**: Simply click a project and hit Continue

### Auto-Optimized Icon Sizes (NEW in v1.1!)
- **Platform-Specific Optimization**: Automatically selects correct platform based on project type
- **Optimal Size Generation**: Generates all required sizes for the detected platform
- **No Manual Configuration**: Platform selection happens automatically

### One-Click Icon Installation
- Select your target Xcode project from the dialog
- Generate and install icons directly into the project's `Assets.xcassets` folder
- No manual copying or file management required

### Smart Export Workflow
- **Auto-Install Mode**: When enabled with a project selected, icons are installed directly into the project
- **Manual Export Mode**: When disabled, icons export to Pictures folder as before
- **Project-First Workflow**: Select project first, then everything is configured automatically
- Temporary files are automatically cleaned up after installation

## Usage

### New Streamlined Workflow (v1.1+)

1. **Launch Icon Creator**
2. **Drag & drop an image** into the app (recommended 1024×1024 or larger)
3. **Select project from dialog** - A modal appears asking which Xcode project this icon is for
   - Shows all discovered projects with their detected platforms
   - Displays platform icons (iPhone, Mac, Apple TV, Watch, etc.)
   - Shows auto-detected platform information
4. **Click "Continue"** - The app automatically:
   - Loads the image
   - Selects the optimal platform based on project type
   - Enables auto-install mode
   - Pre-selects the target project
5. **Adjust settings** (optional) - Scale, padding, background color
6. **Click "Export Icons"** - Done! Icons are automatically generated and installed

### Legacy Workflow (Manual Mode)

1. **Launch Icon Creator**
2. **Drag & drop an image** into the app (recommended 1024×1024 or larger)
3. **Adjust settings** (scale, padding, background color) as needed
4. **Select target platform** (iOS, macOS, tvOS, watchOS, iMessage, or Mac Catalyst)
5. **Enable "Automatically install icons into selected project"** toggle
6. **Select your Xcode project** from the dropdown menu
7. **Click "Export Icons"** - Done! Icons are automatically installed

### Discovered Projects

The app currently discovers these projects:
- RTSP Rotator
- DisneyGPT
- MboxChatCLI
- Icon Creator
- Site Rotator 2.0
- SiteRotator
- HomeKitAssistant
- DisneyGPT Monitor
- AppDelegate
- Site ScreenSaver 2.0
- HomeKitTV

## Architecture

### Components

#### XcodeProjectManager.swift
Main class responsible for:
- **Project Discovery**: Recursively searches for `.xcodeproj` bundles
- **Project Management**: Maintains list of available projects and selection state
- **Icon Installation**: Copies generated `AppIcon.appiconset` into project's asset catalog
- **Asset Catalog Detection**: Automatically finds `Assets.xcassets` folder in projects
- **Error Handling**: Graceful handling of missing asset catalogs or permission issues

#### XcodeProjectSelectionView
SwiftUI view component providing:
- Toggle for enabling/disabling auto-install
- Dropdown picker for project selection
- Refresh button for re-scanning projects
- Quick link to open selected project in Xcode
- Status messages and helpful hints

#### Updated Export Workflow (ContentView.swift)
- Detects if auto-install is enabled and project is selected
- Routes export to temporary directory for installation or Pictures folder for manual export
- Automatically installs icons and cleans up temporary files
- Provides clear success/error messages

### File Structure

```
Icon Creator/
├── IconCreatorApp.swift          # App entry point
├── ContentView.swift              # Main UI (updated with project integration)
├── IconGenerator.swift            # Icon generation engine
├── XcodeProjectManager.swift     # NEW: Project discovery and installation
└── Assets.xcassets/              # App resources
```

## Technical Details

### Project Discovery Algorithm
1. Enumerates all directories in `/Users/kochj/Desktop/xcode/`
2. Identifies directories with `.xcodeproj` extension
3. Creates `XcodeProject` model with name and path
4. Sorts alphabetically by display name
5. Publishes to UI via `@Published` property

### Asset Catalog Detection
1. Searches project directory for `Assets.xcassets` folder
2. Skips build directories, DerivedData, and `.xcodeproj` bundles
3. Returns first matching asset catalog found
4. Throws error if no asset catalog exists

### Installation Process
1. Validates source `AppIcon.appiconset` folder exists
2. Locates target project's `Assets.xcassets` folder
3. Removes existing `AppIcon.appiconset` if present
4. Copies new `AppIcon.appiconset` folder with all icons and `Contents.json`
5. Returns success or throws descriptive error

### Error Handling

#### XcodeProjectError Enum
- `assetsNotFound(project:)`: Asset catalog doesn't exist in project
- `installationFailed(reason:)`: General installation failure with details

#### User-Facing Messages
- "✓ Success! Icons installed to '[Project]' project" - Installation succeeded
- "✗ Installation Error: [details]" - Installation failed with reason
- "⚠️ No Xcode projects found..." - No projects in base directory

## Requirements

- macOS 12.0 or later
- SwiftUI
- File system access to `/Users/kochj/Desktop/xcode/`
- Xcode projects must contain an `Assets.xcassets` folder

## Known Limitations

1. **Single Platform Installation**: Currently only installs the first selected platform when auto-install is enabled
2. **Asset Catalog Required**: Projects must have an existing `Assets.xcassets` folder
3. **Fixed Base Directory**: Scans only `/Users/kochj/Desktop/xcode/` (could be made configurable)
4. **No Undo**: Overwrites existing `AppIcon.appiconset` without backup

## Future Enhancements

Possible improvements:
- [ ] Support for multiple platforms in single installation
- [ ] Configurable base directory for project discovery
- [ ] Backup existing icons before overwriting
- [ ] Open project in Xcode automatically after installation
- [ ] Support for multiple asset catalogs per project
- [ ] Integration with git to show what changed
- [ ] Drag & drop for project selection
- [ ] Recently used projects list

## Troubleshooting

### "No Xcode projects found"
- Verify projects exist in `/Users/kochj/Desktop/xcode/`
- Click "Refresh Projects" button
- Check that directories have `.xcodeproj` extension

### "Could not find Assets.xcassets"
- Open the project in Xcode
- Add an Asset Catalog: File > New > File > Asset Catalog
- Rebuild Icon Creator and try again

### Installation fails silently
- Check Console.app for error messages
- Verify file permissions on target project
- Ensure project isn't open in Xcode during installation

## API Reference

### XcodeProjectManager

```swift
class XcodeProjectManager: ObservableObject {
    @Published var projects: [XcodeProject]
    @Published var selectedProject: XcodeProject?

    func discoverProjects()
    func installIcons(from sourceURL: URL, to project: XcodeProject, platform: Platform) throws
    func openInXcode(_ project: XcodeProject)
}
```

### XcodeProject

```swift
struct XcodeProject: Identifiable, Hashable {
    let id: UUID
    let name: String
    let path: URL

    var displayName: String
    var pathString: String
}
```

### XcodeProjectError

```swift
enum XcodeProjectError: LocalizedError {
    case assetsNotFound(project: String)
    case installationFailed(reason: String)
}
```

## Version History

### v1.0 (2025-10-28)
- Initial implementation of Xcode project integration
- Automatic project discovery
- One-click icon installation
- Toggle for enabling/disabling auto-install
- Smart export workflow with temporary file cleanup
