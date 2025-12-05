# Changelog

All notable changes to the Icon Creator project are documented in this file.

## [1.1.3] - 2025-10-28

### Added - Automatic Asset Catalog Creation

#### Major Feature
- **Automatic Assets.xcassets Creation**
  - No more "Could not find Assets.xcassets" errors
  - Automatically creates asset catalog if missing
  - Works with brand new projects
  - Zero configuration required

#### Smart Asset Management
- **Auto-Detection**
  - Searches for existing Assets.xcassets first
  - Only creates if genuinely missing
  - Never overwrites existing catalogs

- **Standard Structure**
  - Creates Xcode-compatible folder structure
  - Initializes with proper Contents.json
  - Standard location (next to .xcodeproj)
  - Correct permissions and format

- **Seamless Installation**
  - Creation happens automatically during icon installation
  - User sees console message about creation
  - Icons installed immediately after creation
  - No manual steps required

#### User Experience
- **Console Feedback**
  - "📁 No Assets.xcassets found. Creating new asset catalog..."
  - "✅ Created Assets.xcassets at: [path]"
  - "ℹ️ Note: You may need to add this to your Xcode project manually"

#### Documentation
- New ASSET_CATALOG_AUTO_CREATION.md with complete documentation
- Updated troubleshooting guides
- Enhanced error messages

### Changed
- `findAssetsFolder` now `findOrCreateAssetsFolder`
- Error handling updated (removed `assetsNotFound` error)
- Installation workflow now never fails due to missing catalog

### Benefits
- Works with brand new projects immediately
- No manual Xcode file creation needed
- Eliminates common error scenario
- Backward compatible with existing projects

## [1.1.2] - 2025-10-28

### Added - Automatic Image Cropping

#### Major Feature
- **Automatic Square Cropping**
  - Non-square images automatically cropped to square
  - Center crop algorithm preserves important central content
  - Eliminates "Image should be square" errors
  - Works with any aspect ratio

#### Smart Cropping
- **Center Crop Method**
  - Crops to smallest dimension (width or height)
  - Preserves center of image
  - Landscape: trims left/right edges
  - Portrait: trims top/bottom edges

- **Visual Feedback**
  - Blue scissors icon when image is cropped
  - Shows original and new dimensions
  - Example: "✂️ Image auto-cropped to square (1080×1080)"

- **Restore Original**
  - "Restore Original" button appears after auto-crop
  - One-click undo of automatic cropping
  - Original image preserved in memory during session

#### User Controls
- **Auto-Crop Toggle**
  - Located in "Adjust Icon" settings section
  - Enabled by default
  - Can be disabled for manual control
  - Description: "Automatically trim non-square images to square"

#### Technical Improvements
- Lossless cropping (no quality degradation)
- High-quality CGImage-based implementation
- Aspect ratio tolerance: 0.95-1.05 considered "square enough"
- Minimum size validation after crop

#### Documentation
- New AUTO_CROP.md with complete feature documentation
- Updated README.md with auto-crop feature
- Enhanced troubleshooting guide

### Changed
- Image validation now auto-crops instead of rejecting non-square images
- Error workflow replaced with automatic correction
- Default behavior: accept any image, auto-crop if needed

### Benefits
- Works with screenshots, photos, social media images
- No external editor needed for cropping
- Faster workflow - drop any image and go
- 95% of images work perfectly with center crop

## [1.1.1] - 2025-10-28

### Added - Automatic Multi-Location Project Discovery

#### Major Feature
- **Intelligent Multi-Location Scanning**
  - Automatically scans 13+ common project locations
  - Finds projects in Desktop, Documents, Developer, Projects, Code, Development, workspace folders
  - Supports iCloud Drive project folders
  - No configuration required - just works!

#### Enhanced Discovery
- **Smart Location Detection**
  - Only scans directories that exist
  - Skips hidden files and system directories
  - Prevents duplicate project entries
  - Efficient recursive search

- **Visual Feedback**
  - Shows number of locations scanned
  - Expandable list of scanned directory paths
  - "X found in Y location(s)" in project selector
  - Empty state with helpful message when no projects found

#### Updated Entitlements
- Added read access to common project directories
- Desktop, Documents, Developer, Projects, Code, Development, workspace
- Maintains security through sandboxing

#### Documentation
- New AUTO_DISCOVERY.md with complete feature documentation
- Updated README.md with multi-location scanning details
- Enhanced troubleshooting guide

### Changed
- `XcodeProjectManager` now scans multiple locations instead of single directory
- Removed hardcoded `/Users/kochj/Desktop/xcode/` requirement
- Projects can now be anywhere in common locations

### Performance
- Optimized directory enumeration
- Duplicate detection prevents redundant processing
- Typically <1 second for 10-50 projects

## [1.1.0] - 2025-10-28

### Added - Intelligent Project Selection & Platform Detection

#### Major Features
- **Project Selection Dialog on Image Drop**
  - Modal dialog appears when dragging an image into the app
  - Shows all discovered Xcode projects with visual indicators
  - Displays detected platform information for each project
  - Beautiful UI with SF Symbol icons (iPhone, Mac, TV, Watch, etc.)

- **Automatic Platform Detection**
  - Reads `project.pbxproj` files to detect target platforms
  - Identifies iOS, macOS, tvOS, watchOS, Mac Catalyst, and iMessage projects
  - Smart fallback: infers platform from project name if SDK detection fails
  - Priority ordering: iOS > macOS > tvOS > watchOS > iMessage > Mac Catalyst

- **Auto-Optimized Icon Generation**
  - Automatically selects optimal platform based on detected project type
  - Generates icons at correct sizes for the target platform
  - No manual platform selection required
  - Streamlined workflow: drag image → select project → done!

#### New Components
- `ProjectSelectorSheet` - Modal sheet for project selection
- `ProjectSelectionRow` - Individual project row with platform indicators
- Enhanced `XcodeProject` model with:
  - `detectedPlatforms` - Set of all detected platforms
  - `primaryPlatform` - Most appropriate platform
  - `platformDescription` - Human-readable platform list

#### Enhanced XcodeProjectManager
- `detectPlatforms(in:)` - Parses project.pbxproj for platform detection
- Platform detection based on:
  - SDKROOT settings (iphoneos, macosx, appletvos, watchos)
  - TARGETED_DEVICE_FAMILY
  - SUPPORTS_MACCATALYST flag
  - MessagesExtension detection
  - Project name inference

#### UI/UX Improvements
- Streamlined workflow: 5 steps reduced to 3 steps
- Visual platform indicators throughout the UI
- Auto-configuration based on project type
- Clear feedback on detected platforms
- Professional modal design with image preview

#### Documentation
- Updated README.md with new streamlined workflow
- Enhanced XCODE_PROJECT_INTEGRATION.md with v1.1 features
- New CHANGELOG.md to track version history
- Comprehensive API documentation for new components

### Changed
- Image drop workflow now triggers project selector first
- Platform selection now automatic based on project type
- Auto-install mode enabled by default when project is selected via dialog
- Export workflow optimized for project-first approach

### Technical Details
- Platform detection via `project.pbxproj` parsing
- Support for multi-platform projects
- Improved state management for pending images
- Enhanced project discovery with platform metadata

## [1.0.0] - 2025-10-28

### Initial Features
- Multi-platform icon generation (iOS, macOS, tvOS, watchOS, iMessage, Mac Catalyst)
- Drag & drop interface for image selection
- Live preview with adjustable settings:
  - Scale adjustment (50% - 200%)
  - Padding control (0% - 30%)
  - Background color selection
- Platform selection with visual cards
- Export progress tracking
- Xcode project integration:
  - Automatic project discovery
  - Icon installation into Assets.xcassets
  - Smart export workflow (auto-install vs manual export)
- High-quality icon generation:
  - Support for PNG, JPG, HEIC, TIFF, BMP, GIF
  - High-quality interpolation
  - Retina display support (@2x, @3x)
  - Xcode-compatible AppIcon.appiconset generation

## Future Enhancements

### Planned for v1.2
- [ ] Multiple platform installation in single operation
- [ ] Configurable project directory
- [ ] Icon backup before overwriting
- [ ] Recently used projects list
- [ ] Keyboard shortcuts for common actions

### Under Consideration
- [ ] Command-line interface
- [ ] Watch folder for automatic processing
- [ ] Icon compression options
- [ ] Preview in different contexts (home screen, App Store)
- [ ] Export presets
- [ ] Batch processing of multiple images
- [ ] Template management
- [ ] Git integration to track changes

## Version History

### v1.1.0 (2025-10-28)
**Project-First Workflow with Intelligent Platform Detection**
- Project selection dialog on image drop
- Automatic platform detection from project files
- Auto-optimized icon sizes
- Enhanced UI with platform indicators
- Streamlined 3-step workflow

### v1.0.0 (2025-10-28)
**Initial Release with Xcode Integration**
- Multi-platform icon generation
- Automatic Xcode project discovery
- One-click icon installation
- Drag & drop interface
- Live preview and customization
