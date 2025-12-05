# Automatic Project Discovery Feature

## Overview

Icon Creator now automatically discovers Xcode projects across multiple common locations on your system. You no longer need to keep all your projects in a single directory - the app will find them wherever they are!

## How It Works

### Intelligent Multi-Location Scanning

When Icon Creator launches, it automatically scans these common locations where developers typically store Xcode projects:

#### Primary Locations
1. **Desktop**
   - `~/Desktop/xcode` - Dedicated Xcode projects folder
   - `~/Desktop` - Root Desktop folder

2. **Documents**
   - `~/Documents/Xcode` - Organized Xcode folder
   - `~/Documents/Projects` - General projects folder
   - `~/Documents` - Root Documents folder

3. **Developer Folders**
   - `~/Developer` - Apple's recommended location
   - `~/Developer/Projects` - Projects subfolder

4. **Common Project Directories**
   - `~/Projects` - Standard projects folder
   - `~/Code` - Popular for code repositories
   - `~/Development` - Common development folder
   - `~/workspace` - Lowercase workspace
   - `~/Workspace` - Capitalized workspace

5. **iCloud Drive** (if available)
   - `~/Library/Mobile Documents/com~apple~CloudDocs/Projects`
   - `~/Library/Mobile Documents/com~apple~CloudDocs/Xcode`

### Smart Discovery Algorithm

1. **Existence Check**: Only scans directories that actually exist
2. **Recursive Search**: Searches subdirectories for `.xcodeproj` bundles
3. **Duplicate Prevention**: Skips projects already found in other locations
4. **Platform Detection**: Automatically identifies the platform for each project
5. **Alphabetical Sorting**: Presents projects in a clean, sorted list

## Benefits

### Find Projects Anywhere
- No need to consolidate all projects in one location
- Works with your existing folder structure
- Supports multiple project organization styles

### Zero Configuration
- No settings to configure
- No paths to specify
- Just works automatically

### Visual Feedback
- See how many locations were scanned
- Expandable list shows exact paths scanned
- Clear indication of how many projects were found

### Performance Optimized
- Skips hidden files and system directories
- Efficient directory enumeration
- Duplicate detection prevents redundant processing

## UI Features

### Main Project Selection View
Shows a collapsible disclosure group with:
- Total number of projects found
- Number of locations scanned
- Expandable list of scanned directory paths

### Project Selector Dialog
Displays:
- "X found in Y location(s)" at the top
- Empty state with helpful message if no projects found
- List of scanned locations for troubleshooting

## Technical Details

### Discovery Process

```swift
// Automatic location detection
let locations = getCommonProjectLocations()

// Scans each location
for directory in locations {
    // Find .xcodeproj bundles
    // Detect platform from project.pbxproj
    // Add to discovered projects list
}

// Sort and present to user
projects.sort(by: displayName)
```

### Platform Detection

For each discovered project, the app:
1. Reads `project.pbxproj` file
2. Searches for SDKROOT values
3. Identifies target platforms
4. Stores platform information with project

### Duplicate Handling

If the same project appears in multiple scanned locations (e.g., symlinks or aliases), only the first occurrence is included.

## Permissions

### Required Entitlements

The app requires read access to:
- Desktop folder
- Documents folder
- Developer folder
- Common project directories

These permissions are included in the app's entitlements and granted automatically when running from Xcode.

### First Run

On first launch, macOS may prompt you to grant file access. This is normal and required for the app to discover projects.

## Troubleshooting

### No Projects Found

If no projects are discovered:

1. **Check Console Output**: Look for these messages:
   ```
   📁 Found X potential project directories:
      - /Users/you/Desktop
      - /Users/you/Documents
      ...
   🔍 Scanning for Xcode projects in X locations...
   ✅ Discovered Y Xcode projects across X directories
   ```

2. **Verify Project Locations**: Ensure your `.xcodeproj` bundles are in one of the scanned locations

3. **Check Permissions**:
   - Run from Xcode (⌘R) to ensure proper entitlements
   - Check System Settings → Privacy & Security → Files and Folders

4. **Refresh Projects**: Click the "Refresh Projects" button to re-scan

### Projects in Unexpected Locations

If your projects are in a custom location not listed above:

**Current Workaround:**
- Move projects to a scanned location, or
- Create a symlink in a scanned location:
  ```bash
  ln -s /path/to/your/projects ~/Desktop/xcode
  ```

**Future Enhancement:**
Configurable custom directories are planned for v1.2.

### Performance with Many Projects

The discovery process is optimized for typical project counts (10-100 projects):

- **10-50 projects**: Instant (<1 second)
- **50-200 projects**: Very fast (1-2 seconds)
- **200+ projects**: May take a few seconds

If discovery is slow:
- Check for network drives (slower than local storage)
- Clean up old/archived projects
- Consider organizing into fewer top-level directories

## Console Logging

The app provides detailed console output for debugging:

```
📁 Found 5 potential project directories:
   - /Users/kochj/Desktop
   - /Users/kochj/Desktop/xcode
   - /Users/kochj/Documents
   - /Users/kochj/Developer
   - /Users/kochj/Projects

🔍 Scanning for Xcode projects in 5 locations...

✅ Detected platforms for HomeKitTV.xcodeproj: tvOS
✅ Detected platforms for Site Rotator 2.0.xcodeproj: macOS
✅ Detected platforms for DisneyGPT.xcodeproj: iOS

✅ Discovered 11 Xcode projects across 5 directories
```

If no projects found:
```
⚠️ No projects found. Scanned locations:
   - /Users/kochj/Desktop
   - /Users/kochj/Documents
   ...
```

## API Reference

### XcodeProjectManager

#### Properties
```swift
@Published var projects: [XcodeProject]       // Discovered projects
@Published var scannedDirectories: [String]   // Paths that were scanned
```

#### Methods
```swift
func discoverProjects()                       // Re-scans all locations
static func getCommonProjectLocations() -> [URL]  // Returns scan locations
```

## Comparison: v1.0 vs v1.1+

### v1.0 (Single Location)
- Hardcoded to `/Users/kochj/Desktop/xcode/`
- Required all projects in one location
- No flexibility

### v1.1+ (Multi-Location)
- Scans 13+ common locations
- Finds projects anywhere
- Automatic discovery
- Visual feedback
- Better for real-world workflows

## Future Enhancements

### Planned for v1.2
- [ ] Configurable custom directories
- [ ] Remember recently used project locations
- [ ] Exclude specific directories from scanning
- [ ] Search depth limit configuration

### Planned for v1.3
- [ ] Watch folders for new projects
- [ ] Cache results for faster startup
- [ ] Network drive support with timeout
- [ ] Project favorites/pinning

### Under Consideration
- [ ] Scan git repositories for Xcode projects
- [ ] Integration with Xcode's recent projects list
- [ ] Export discovered projects list
- [ ] Project organization suggestions

## Version History

### v1.1.0 (2025-10-28)
**Added:** Automatic multi-location project discovery
- Scans 13+ common project locations
- Duplicate prevention
- Visual feedback in UI
- Enhanced console logging

### v1.0.0 (2025-10-28)
Single location scanning (`/Users/kochj/Desktop/xcode/`)

## Tips & Best Practices

### Organization Strategies

**Strategy 1: Centralized**
Keep all projects in `~/Developer/`:
```
~/Developer/
  ├── iOS/
  ├── macOS/
  └── tvOS/
```

**Strategy 2: By Client/Company**
```
~/Projects/
  ├── PersonalProjects/
  ├── ClientA/
  └── ClientB/
```

**Strategy 3: Mixed**
```
~/Desktop/current-work/
~/Documents/archived-projects/
~/Developer/open-source/
```

**All strategies work!** Icon Creator finds projects in all locations.

### Performance Tips

1. **Use Local Storage**: Projects on network drives are slower to scan
2. **Regular Cleanup**: Archive old projects to reduce scan time
3. **Shallow Hierarchies**: Fewer nested directories scan faster

### Permission Management

Grant access once, works forever:
1. Run app from Xcode first time
2. macOS grants necessary permissions
3. Future launches work automatically

## FAQ

**Q: Can I add custom locations?**
A: Not yet, but it's planned for v1.2. For now, use symlinks.

**Q: Does it scan my entire hard drive?**
A: No, only specific common locations are scanned.

**Q: What about symbolic links?**
A: Symlinks are followed, but duplicates are filtered out.

**Q: Does it support network drives?**
A: Yes, but they're slower. Use local storage when possible.

**Q: How often does it scan?**
A: On app launch and when you click "Refresh Projects".

**Q: Can I see which directories were scanned?**
A: Yes! Expand the disclosure group in the project selection view.

**Q: Does it work with iCloud Drive?**
A: Yes, if your projects are in iCloud's Projects or Xcode folders.

**Q: What if my projects are in ~/Code/GitHub/iOS/?**
A: The app scans ~/Code/, so projects in ~/Code/GitHub/iOS/ will be found.

**Q: Does it cache results?**
A: Not yet. Every launch does a fresh scan (typically <1 second).

## Support

If you have projects in a location that's not being scanned:
1. Check the console output to see which locations are scanned
2. Consider moving projects to a scanned location
3. Create a symlink as a temporary workaround
4. Wait for v1.2 which will support custom directories

---

**Icon Creator** - Now finds your projects wherever they are!
