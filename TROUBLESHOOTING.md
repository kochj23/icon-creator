# Troubleshooting Guide - Icon Creator

## Common Issues and Solutions

### Issue: "No Xcode projects found in /Users/kochj/Desktop/xcode"

This is the most common issue and is caused by macOS sandboxing preventing the app from accessing your Desktop folder.

#### Symptoms
- Project selector shows "No Xcode projects found"
- Project dropdown is empty
- "0 Xcode projects available" message

#### Root Cause
The app is sandboxed for security, and macOS restricts access to certain folders (Desktop, Documents, etc.) unless explicitly granted.

#### Solution Steps

**Option 1: Run from Xcode (Recommended)**
1. Open `Icon Creator.xcodeproj` in Xcode
2. Select the "Icon Creator" scheme
3. Click Run (⌘R)
4. The app will launch with proper entitlements and file access

**Option 2: Check Entitlements (If built from terminal)**
1. Verify `Icon_Creator.entitlements` contains:
   ```xml
   <key>com.apple.security.temporary-exception.files.absolute-path.read-write</key>
   <array>
       <string>/Users/kochj/Desktop/</string>
       <string>/Users/kochj/Desktop/xcode/</string>
   </array>
   ```
2. Rebuild the app: `xcodebuild -project "Icon Creator.xcodeproj" clean build`

**Option 3: Grant Manual Permissions**
1. Open **System Settings** → **Privacy & Security**
2. Scroll to **Files and Folders**
3. Find "Icon Creator" in the list
4. Enable access to Desktop folder
5. Restart the app

**Option 4: Disable Sandboxing (Development Only)**
1. Open `Icon_Creator.entitlements`
2. Change `<key>com.apple.security.app-sandbox</key>` to `<false/>`
3. Rebuild the app
4. ⚠️ **Warning**: Only for development! Don't distribute unsigned apps

#### Verification
After applying a solution:
1. Restart the app
2. Check the console for: "✅ Discovered X Xcode projects"
3. The project selector should show all your projects

---

## Other Common Issues

### Issue: Build Failed - "Cannot find 'XcodeProjectManager' in scope"

#### Symptoms
- Build error when compiling
- `ContentView.swift` shows error about missing type

#### Root Cause
`XcodeProjectManager.swift` was not added to the Xcode project build targets.

#### Solution
1. In Xcode Project Navigator, right-click "Icon Creator" folder
2. Select "Add Files to 'Icon Creator'..."
3. Choose `XcodeProjectManager.swift`
4. **Uncheck** "Copy items if needed"
5. Click "Add"
6. Build again (⌘B)

---

### Issue: "Could not find Assets.xcassets in project"

#### Symptoms
- Error when trying to install icons
- Message: "Could not find Assets.xcassets in project 'ProjectName'"

#### Root Cause
The target Xcode project doesn't have an asset catalog.

#### Solution
1. Open the target project in Xcode
2. File → New → File
3. Search for "Asset Catalog"
4. Name it "Assets" and click Create
5. Try icon installation again

---

### Issue: Image Won't Load / Drop Zone Not Working

#### Symptoms
- Dragging image does nothing
- File picker doesn't accept images
- "Failed to load image" error

#### Root Cause
- Image format not supported
- File permissions issue
- Image file corrupted

#### Solution
1. **Check image format**: Use PNG, JPG, or HEIC
2. **Check image size**: Minimum 64×64, recommended 1024×1024
3. **Try different image**: Verify the file isn't corrupted
4. **Check file location**: Ensure image is in accessible location (not in restricted folder)

---

### Issue: Icons Look Blurry or Low Quality

#### Symptoms
- Generated icons appear pixelated
- Icons look worse than source image

#### Root Cause
Source image resolution is too low.

#### Solution
1. Use source image of at least **1024×1024 pixels**
2. For best results, use 2048×2048 or higher
3. Ensure source image is square (1:1 aspect ratio)
4. Use PNG format for best quality

---

### Issue: Platform Not Auto-Detected Correctly

#### Symptoms
- Wrong platform selected (e.g., iOS project detected as macOS)
- "Unknown platform" shown for project

#### Root Cause
- Project's `project.pbxproj` doesn't contain standard SDK settings
- Multi-platform project with unusual configuration

#### Solution
1. **Manual Override**: Disable auto-install and manually select platform
2. **Update Project**: Ensure project has proper SDKROOT setting
3. **Check Project File**: Open `project.pbxproj` and verify SDKROOT value

---

### Issue: Export Fails with Permission Error

#### Symptoms
- "Export failed" error
- Permission denied error in console
- Can't write to Pictures folder

#### Root Cause
App doesn't have permission to write to Pictures folder.

#### Solution
1. Check entitlements include:
   ```xml
   <key>com.apple.security.assets.pictures.read-write</key>
   <true/>
   ```
2. Grant permission in System Settings → Privacy & Security → Files and Folders
3. Try exporting to different location

---

### Issue: App Crashes on Launch

#### Symptoms
- App quits immediately after launch
- Crash report generated

#### Solution
1. **Check macOS version**: Requires macOS 12.0+
2. **Rebuild from scratch**:
   ```bash
   cd "/Users/kochj/Desktop/xcode/Icon Creator"
   xcodebuild clean
   xcodebuild build
   ```
3. **Check Console.app** for crash logs
4. **Verify entitlements** are properly formatted

---

### Issue: Multiple Platforms Detected, Wrong One Selected

#### Symptoms
- iOS + Mac Catalyst project selects iOS instead of Catalyst
- Multi-platform project doesn't select preferred platform

#### Root Cause
Platform priority ordering: iOS > macOS > tvOS > watchOS > iMessage > Mac Catalyst

#### Solution
1. **Manual Selection**: Disable auto-install, manually choose platform
2. **Modify Priority**: Edit `XcodeProjectManager.swift` `primaryPlatform` computed property
3. **Future Enhancement**: Will add platform selection in dialog

---

## Debugging Tips

### Enable Verbose Logging
The app prints helpful debug information to the console:
- "✅ Discovered X Xcode projects"
- "✅ Detected platforms for [project]: iOS, macOS"
- "✅ Found Assets.xcassets at: [path]"
- "⚠️" warnings for issues

**To view logs:**
1. Run app from Xcode to see Xcode console
2. Or open Console.app and filter by "Icon Creator"

### Check File Permissions
```bash
# Verify Desktop folder exists and is readable
ls -la /Users/kochj/Desktop/xcode/

# Check for .xcodeproj bundles
find /Users/kochj/Desktop/xcode -name "*.xcodeproj" -type d

# Verify app has correct entitlements
codesign -d --entitlements :- "/path/to/Icon Creator.app"
```

### Test Project Detection Manually
```bash
# See what the app should detect
find /Users/kochj/Desktop/xcode -name "*.xcodeproj" -maxdepth 2

# Check a specific project's platform
grep SDKROOT "/Users/kochj/Desktop/xcode/HomeKitTV/HomeKitTV.xcodeproj/project.pbxproj"
```

---

## Getting Help

### Before Reporting Issues
1. ✅ Run from Xcode (not double-clicking app bundle)
2. ✅ Check Console.app for error messages
3. ✅ Verify projects exist in `/Users/kochj/Desktop/xcode/`
4. ✅ Try the "Refresh Projects" button
5. ✅ Restart the app

### Information to Include
When reporting issues, include:
- macOS version
- Xcode version
- Error messages from Console.app
- Screenshot of the issue
- Steps to reproduce

### Known Limitations
- Only scans `/Users/kochj/Desktop/xcode/` (not configurable yet)
- Single platform installation when auto-install enabled
- No backup of existing icons before overwrite
- Requires asset catalog in target project

---

## Performance Issues

### Issue: Slow Project Discovery

#### Symptoms
- App takes long time to launch
- "Discovering projects..." hangs

#### Solution
- **Normal**: 11 projects should take <1 second
- **Slow network drives**: Move projects to local drive
- **Too many files**: Clean up build folders, DerivedData

### Issue: High Memory Usage

#### Symptoms
- App uses lots of RAM
- System slows down during icon generation

#### Solution
- **Expected**: Each icon generation uses temporary memory
- **Large images**: Use smaller source images (1024×1024 sufficient)
- **Multiple exports**: Close and reopen app between large batches

---

## Advanced Troubleshooting

### Reset App Completely
```bash
# Remove app from Applications
rm -rf "/Applications/Icon Creator.app"

# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/Icon_Creator-*

# Rebuild from scratch
cd "/Users/kochj/Desktop/xcode/Icon Creator"
xcodebuild clean build
```

### Manually Add File Access
If entitlements aren't working, use `tccutil` (risky, not recommended):
```bash
# Reset privacy settings (requires SIP disabled)
tccutil reset SystemPolicyDesktopFolder com.yourcompany.IconCreator
```

### Inspect Entitlements
```bash
# Check what entitlements are actually applied
codesign -d --entitlements - "/path/to/Icon Creator.app/Contents/MacOS/Icon Creator"
```

---

## FAQ

**Q: Why does the app need Desktop access?**
A: To automatically discover your Xcode projects in `/Users/kochj/Desktop/xcode/`.

**Q: Is my data safe?**
A: Yes. The app only reads project files and writes to asset catalogs. It's sandboxed and can't access files outside permitted locations.

**Q: Can I change the project directory?**
A: Not yet. Currently hardcoded to `/Users/kochj/Desktop/xcode/`. Configurable paths are planned for v1.2.

**Q: Why do I need to run from Xcode?**
A: Running from Xcode properly signs the app with entitlements. Double-clicking the .app bundle may not apply entitlements correctly.

**Q: Will this work after I archive/export the app?**
A: Yes, if properly signed with entitlements during export. For distribution, you may need to notarize with Apple.

---

## Still Having Issues?

If none of these solutions work:
1. Check the [README.md](README.md) for general usage
2. Review [XCODE_PROJECT_INTEGRATION.md](XCODE_PROJECT_INTEGRATION.md) for technical details
3. Look at Console.app for detailed error messages
4. Try running with sandboxing disabled (development only)
