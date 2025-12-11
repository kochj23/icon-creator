# Icon Creator

A professional macOS application for generating app icons for all Apple platforms with automatic Xcode project integration. Includes comprehensive App Store Connect screenshot tools, icon validation, device frame mockups, and batch image conversion!

## Features

### 🆕 NEW in v2.4.0

#### Multi-Size Screenshot Resizer
- **All App Store Connect Sizes**: Supports all required screenshot sizes for iPhone, iPad, Mac, Apple TV, Apple Watch, and Apple Vision Pro
- **Batch Resize**: Convert one screenshot to all required sizes at once
- **Platform-Specific Sizes**:
  - **iPhone**: 6.9", 6.7", 6.5", 6.1", 5.8", 5.5", 4.7", 4.0" displays
  - **iPad**: 13", 12.9", 11", 10.5", 9.7" displays
  - **Mac**: 2880×1800, 2560×1600, 1440×900, 1280×800
  - **Apple TV**: 4K (3840×2160), 1080p (1920×1080)
  - **Apple Watch**: All sizes from 38mm to 49mm Ultra
  - **Apple Vision Pro**: 2712×1536
- **Aspect Ratio Preservation**: Maintains original aspect ratio with letterbox/pillarbox
- **Customizable Background**: Choose any color for letterbox/pillarbox bars
- **High Quality Scaling**: Uses advanced interpolation for crystal-clear results
- **All Formats Supported**: PNG, JPG, HEIC, TIFF, BMP, GIF, and more

#### Icon Validation (App Store Compliance)
- **Automated Quality Checks**:
  - ✅ Transparency detection (iOS icons must be opaque)
  - ✅ Alpha channel validation (prevents edge artifacts)
  - ✅ DPI/Resolution verification (minimum 72 PPI)
  - ✅ Color space validation (sRGB recommended)
  - ✅ File size limits (warns if > 2MB, errors if > 10MB)
  - ✅ Minimum size requirements (1024×1024 for App Store)
  - ✅ Aspect ratio checks (must be square)
  - ✅ Image quality assessment (compression artifacts)
  - ✅ Content validation (detects blank/placeholder icons)
  - ✅ Accessibility checks (contrast, readability)
- **Real-Time Validation**: Validates icons before export to prevent App Store rejections
- **Detailed Reports**: Shows all errors and warnings with actionable fixes
- **Platform-Specific Rules**: Applies correct validation rules per platform (iOS, macOS, etc.)

#### Device Frame Generator
- **Professional Mockups**: Add realistic device frames to screenshots
- **Supported Devices**:
  - iPhone 16 Pro Max, iPhone 15 Plus, iPhone 14 Pro Max, iPhone 13 Pro Max, iPhone 8 Plus
  - iPad Pro 13", iPad Pro 12.9", iPad Pro 11"
  - MacBook Pro 16", MacBook Pro 14"
  - Apple TV 4K
  - Apple Watch Ultra, Apple Watch 45mm
- **Frame Colors**: Black, White, Silver, Gold, Space Gray, Midnight Green, Pacific Blue, Graphite, Sierra Blue, Product Red
- **Background Styles**:
  - Solid color
  - Gradient (with angle control)
  - Transparent (for compositing)
- **Device Details**: Automatically renders notch, Dynamic Island, bezels, Digital Crown
- **Professional Shadows**: Optional drop shadow for depth
- **Batch Generation**: Generate multiple color variants at once

#### Batch Image Conversion
- **Format Conversion**: Convert between PNG, JPEG, TIFF, HEIC
- **Quality Control**: Adjustable compression quality for JPEG
- **Batch Processing**: Convert multiple images at once
- **Preserve Metadata**: Maintains EXIF data when possible

### Screenshot Resizer (v2.3.0+)
- **Drag & Drop Support**: Simple, intuitive interface
- **Instant Export**: Saves to Pictures folder and opens in Finder

### Icon Generation
- **Multi-Platform Support**: Generate icons for iOS, macOS, tvOS, watchOS, iMessage, and Mac Catalyst
- **Drag & Drop Interface**: Simply drag an image into the app
- **Automatic Square Cropping**: Non-square images are automatically cropped to square (center crop)
- **Live Preview**: See changes in real-time as you adjust settings
- **Customizable Output**:
  - Auto-crop toggle (on by default)
  - Scale adjustment (50% - 200%)
  - Padding control (0% - 30%)
  - Background color selection
  - High-quality image interpolation
- **Restore Original**: Undo auto-crop with one click

### Xcode Project Integration (Enhanced!)
- **Automatic Asset Catalog Creation**: Creates Assets.xcassets if missing - works with any project!
- **🆕 Configurable Project Locations** (v2.5.0):
  - **Custom Directories**: Add any folder where you keep Xcode projects
  - **Git Repository Cloning**: Clone directly from GitHub, GitLab, Bitbucket
  - **Cloud Storage**: Auto-detect iCloud Drive, Dropbox, Google Drive, OneDrive
  - **Spotlight Search**: System-wide .xcodeproj discovery
  - **Xcode Recents**: Import from Xcode's recent projects list
  - **Network Volumes**: Support for NFS, SMB, AFP mounted drives
  - **Recent Projects**: Track your 10 most recently used projects
  - **Import/Export**: Share configurations across machines or team members
  - **Enable/Disable**: Toggle locations on/off without removing them
- **Intelligent Multi-Location Scanning**: Scans all enabled locations
- **Platform Auto-Detection**: Automatically identifies iOS, macOS, tvOS, watchOS projects
- **One-Click Installation**: Install icons directly into your project's asset catalog
- **Smart Workflow**: Choose between auto-install or manual export
- **No File Management**: Icons are automatically placed in the correct location
- **Visual Feedback**: Shows which directories were scanned and how many projects found

### Icon Sizes Supported

#### iOS / Mac Catalyst
20×20, 29×29, 40×40, 58×58, 60×60, 76×76, 80×80, 87×87, 120×120, 152×152, 167×167, 180×180, 1024×1024

#### macOS
16×16, 32×32, 64×64, 128×128, 256×256, 512×512, 1024×1024

#### tvOS
400×400, 1280×1280

#### watchOS
24×24, 27×27, 29×29, 40×40, 44×44, 50×50, 51×51, 86×86, 98×98, 108×108, 117×117, 129×129, 1024×1024

#### iMessage
60×60, 67×67, 74×74, 81×81, 120×120, 134×134, 148×148, 180×180, 1024×1024

## Installation

### Requirements
- macOS 12.0 or later
- Xcode 14.0 or later (for building)
- File system access to Desktop folder (granted automatically on first run)

### Building from Source
1. Open `Icon Creator.xcodeproj` in Xcode
2. **Add XcodeProjectManager.swift to the project** (if not already added):
   - Right-click on the "Icon Creator" folder in Project Navigator
   - Select "Add Files to 'Icon Creator'..."
   - Choose `XcodeProjectManager.swift`
   - Ensure "Copy items if needed" is **UNCHECKED**
   - Click "Add"
3. Select the "Icon Creator" scheme
4. Build and run (⌘R)

## Usage

### Quick Start (New Streamlined Workflow!)
1. **Launch Icon Creator**
2. **Drag and drop** an image file (PNG, JPG, HEIC, etc.)
3. **Select which Xcode project** this icon is for from the dialog
   - The app automatically detects the project's platform (iOS, macOS, tvOS, etc.)
   - Platform is auto-selected based on detection
4. **Adjust settings** as needed (optional):
   - Scale: Resize the icon within its bounds
   - Padding: Add space around the icon
   - Background Color: Set the background color
5. **Click "Export Icons"**
   - Icons are automatically generated at optimal sizes for the platform
   - Icons are automatically installed into the project's Assets.xcassets
   - Done! Open your project to see the new icons

### Manual Export (Traditional Method)
1. Disable "Automatically install icons into selected project"
2. Click "Export Icons"
3. Icons are saved to `~/Pictures/IconCreator-[timestamp]/`
4. Each platform gets its own folder with `AppIcon.appiconset`
5. Manually drag the appiconset into your Xcode project

### Auto-Install to Xcode Project (New Method)
1. Enable "Automatically install icons into selected project"
2. Select your target project from the dropdown
3. Click "Export Icons"
4. Icons are automatically installed into your project's `Assets.xcassets`
5. Open your project in Xcode to see the new icons

## Project Structure

```
Icon Creator/
├── IconCreatorApp.swift              # App entry point
├── ContentView.swift                  # Main UI with project integration
├── IconGenerator.swift                # Icon generation and export engine
├── XcodeProjectManager.swift         # Xcode project discovery and installation
├── Icon_Creator.entitlements         # App entitlements
├── Info.plist                         # App configuration
├── Assets.xcassets/                   # App resources
├── XCODE_PROJECT_INTEGRATION.md      # Detailed integration documentation
└── README.md                          # This file
```

## Technical Details

### Architecture
- **SwiftUI**: Modern declarative UI framework
- **MVVM Pattern**: Separation of concerns with ObservableObject
- **Async/Await**: Modern concurrency for export operations
- **File Management**: Secure file access with sandboxing support

### Key Components

#### IconGenerator
- Validates source images (size, aspect ratio)
- Generates icons at multiple sizes with proper scaling
- Exports Xcode-compatible `AppIcon.appiconset` folders
- Creates proper `Contents.json` files for asset catalogs

#### XcodeProjectManager
- Discovers Xcode projects in the workspace
- Locates asset catalogs within projects
- Installs icons directly into projects
- Handles errors gracefully with user-friendly messages

#### ContentView
- Drag & drop interface for image selection
- Live preview with adjustable settings
- Platform selection with visual cards
- Export progress tracking
- Xcode project integration UI

### File Formats
- **Input**: PNG, JPG, JPEG, HEIC, TIFF, BMP, GIF
- **Output**: PNG (required by Xcode for app icons)

### Image Quality
- Uses high-quality interpolation for resizing
- Maintains aspect ratio
- Supports transparency
- Optimized for retina displays (@2x, @3x)

## Development

### Adding New Features
1. Update the appropriate Swift file
2. Add unit tests if applicable
3. Update this README
4. Create or update feature-specific documentation

### Building for Distribution
1. Set scheme to Release
2. Archive the application (Product > Archive)
3. Export as macOS app
4. Notarize with Apple (recommended)

### Code Style
- Swift style guide compliance
- Comprehensive inline documentation
- MARK comments for organization
- Descriptive variable and function names

## Known Issues & Limitations

1. **Single Platform Auto-Install**: Currently only installs first selected platform
2. **Asset Catalog Required**: Xcode projects must have `Assets.xcassets`
3. **No Icon Backup**: Overwrites existing icons without backup
4. **Fixed Project Directory**: Only scans `/Users/kochj/Desktop/xcode/`

## Roadmap

### Planned Features
- [ ] Multiple platform installation in single operation
- [ ] Configurable project directory
- [ ] Icon backup before overwriting
- [ ] Batch processing of multiple images
- [ ] Custom icon size support
- [ ] Template management
- [ ] Recently used projects
- [ ] Git integration to track changes

### Under Consideration
- [ ] Command-line interface
- [ ] Watch folder for automatic processing
- [ ] Icon compression options
- [ ] Preview in different contexts (home screen, App Store, etc.)
- [ ] Export presets

## Troubleshooting

### Image Quality Issues
- **Problem**: Generated icons look blurry
- **Solution**: Use a source image of at least 1024×1024 pixels

### Auto-Install Not Working (FIXED in v1.1.3!)
- **Problem**: "Could not find Assets.xcassets" error - NO LONGER OCCURS!
- **Solution**: The app now automatically creates Assets.xcassets if missing
- **What happens**: Console shows "📁 Creating new asset catalog..." and icons install successfully
- **Optional**: Add the created Assets.xcassets to Xcode's Project Navigator manually

### Projects Not Appearing
- **Problem**: "No Xcode projects found" message
- **Solution**:
  - **First Time Users**: macOS may be blocking file access due to sandboxing
  - **Fix**: Run the app from Xcode (⌘R) to properly sign with entitlements
  - Verify projects are in `/Users/kochj/Desktop/xcode/`
  - Click "Refresh Projects" button
  - Check Console.app for permission errors
  - If still failing, check System Settings → Privacy & Security → Files and Folders

### Export Fails
- **Problem**: Export button does nothing or shows error
- **Solution**:
  - Verify source image is valid
  - Check file permissions
  - Ensure sufficient disk space

## Support

For issues, questions, or feature requests:
1. Check the [XCODE_PROJECT_INTEGRATION.md](XCODE_PROJECT_INTEGRATION.md) for detailed integration docs
2. Review the troubleshooting section above
3. Check Console.app for detailed error messages

## License

[Add your license information here]

## Version History

### v1.1 (2025-10-28)
- Added Xcode project integration
- Automatic project discovery
- One-click icon installation
- Smart export workflow

### v1.0 (Initial Release)
- Multi-platform icon generation
- Drag & drop interface
- Live preview
- Customizable scale, padding, and background color
- Export to Pictures folder

## Credits

Built with Swift and SwiftUI for macOS.

---

**Icon Creator** - Generate beautiful app icons for all Apple platforms with zero hassle.
