# How to Add Custom Xcode Project Locations

**Status**: Feature implemented in v2.5.0, requires manual Xcode project integration (5 minutes)

---

## 🎯 Quick Answer

**Currently in v2.4.0**: Icon Creator scans these hardcoded locations automatically:
- `/Volumes/Data/xcode/`
- `~/Desktop/xcode/`
- `~/Desktop/`
- `~/Documents/Xcode/`
- `~/Documents/Projects/`
- `~/Documents/`
- `~/Developer/`
- `~/Developer/Projects/`
- `~/Projects/`
- `~/Code/`
- `~/Development/`
- `~/workspace/`
- `~/Workspace/`
- `~/Library/Mobile Documents/com~apple~CloudDocs/Projects/` (iCloud)
- `~/Library/Mobile Documents/com~apple~CloudDocs/Xcode/` (iCloud)

**Workaround**: Put your Xcode projects in any of these directories.

---

## 🆕 Configurable Locations (v2.5.0 - In Progress)

The new feature supports:
- ✅ Custom directories anywhere on your Mac
- ✅ Git repository cloning (GitHub/GitLab/Bitbucket)
- ✅ Cloud storage (iCloud, Dropbox, Google Drive, OneDrive)
- ✅ Network volumes
- ✅ Spotlight system-wide search
- ✅ Xcode recent projects
- ✅ Recent projects tracking
- ✅ Import/export configurations

**Status**: Code complete, needs 5-minute manual Xcode setup

---

## 📋 Manual Setup Steps (Complete v2.5.0)

### Step 1: Open Xcode Project

```bash
open "/Volumes/Data/xcode/Icon Creator/Icon Creator.xcodeproj"
```

### Step 2: Add New Files to Project

**In Xcode Project Navigator:**

1. **Add ProjectLocation.swift**
   - Right-click on `Models/Core` folder
   - Select "Add Files to 'Icon Creator'..."
   - Navigate to: `Models/Core/ProjectLocation.swift`
   - **Important**: UNCHECK "Copy items if needed"
   - Click "Add"

2. **Add ProjectLocationManager.swift**
   - Right-click on `Services/Project` folder
   - Select "Add Files to 'Icon Creator'..."
   - Navigate to: `Services/Project/ProjectLocationManager.swift`
   - **Important**: UNCHECK "Copy items if needed"
   - Click "Add"

3. **Add ProjectLocationsView.swift**
   - Right-click on `Views/Settings` folder
   - Select "Add Files to 'Icon Creator'..."
   - Navigate to: `Views/Settings/ProjectLocationsView.swift`
   - **Important**: UNCHECK "Copy items if needed"
   - Click "Add"

### Step 3: Uncomment Integration Code

**In XcodeProjectManager.swift:**

Find line ~64:
```swift
// TODO v2.5.0: Uncomment after adding ProjectLocationManager.swift to Xcode project
// private let locationManager = ProjectLocationManager()
```

Change to:
```swift
private let locationManager = ProjectLocationManager()
```

Find lines ~73-80:
```swift
// TODO v2.5.0: Uncomment after adding ProjectLocationManager.swift to Xcode project
/*
init(locationManager: ProjectLocationManager) {
    ...
}
*/
```

Remove the `/*` and `*/` to uncomment the init method.

Find lines ~192-227:
```swift
// TODO v2.5.0: Uncomment after adding all location manager files to Xcode project
/*
func discoverProjectsFromConfiguredLocations() {
    ...
}
*/
```

Remove the `/*` and `*/` to uncomment the method.

**In ContentView.swift:**

Find lines ~1045-1052 (Configure Locations button):
```swift
// TODO v2.5.0: Uncomment after adding ProjectLocationsView.swift to Xcode project
/*
Button(action: { showingLocationSettings = true }) {
    Label("Configure Locations", systemImage: "gearshape")
}
...
*/
```

Remove the `/*` and `*/`.

Find lines ~1059-1064 (Sheet presentation):
```swift
// TODO v2.5.0: Uncomment after adding ProjectLocationsView.swift to Xcode project
/*
.sheet(isPresented: $showingLocationSettings) {
    ProjectLocationsView()
}
*/
```

Remove the `/*` and `*/`.

### Step 4: Build and Run

```bash
cd "/Volumes/Data/xcode/Icon Creator"
xcodebuild -project "Icon Creator.xcodeproj" -scheme "Icon Creator" -configuration Release build
```

Or in Xcode:
- Press ⌘B to build
- Press ⌘R to run

### Step 5: Use the Feature!

After launching, you'll see a new **"Configure Locations"** button (gear icon) in the Xcode Project Integration section.

Click it to:
- Add custom directories
- Clone Git repositories
- Enable cloud storage
- Enable Spotlight search
- View recent projects
- Import/export configurations

---

## 🎬 Quick Demo After Setup

### Adding a Custom Directory

1. Click **"Configure Locations"** button (gear icon)
2. Click **"Add Directory"**
3. Enter name: "My Projects"
4. Click **"Browse..."** and select your directory
5. Click **"Add"**
6. Click **"Done"**
7. Click **"Refresh Projects"** in main window
8. Your projects from that directory now appear!

### Cloning a GitHub Repository

1. Click **"Configure Locations"** button
2. Click **"Clone from Git"**
3. Enter URL: `https://github.com/username/my-ios-app.git`
4. Click **"Clone"** (wait for progress)
5. Click **"Done"**
6. Click **"Refresh Projects"**
7. Cloned project now appears in the list!

---

## 🔧 Why Manual Steps Are Needed

Xcode's `project.pbxproj` file has a complex structure that requires:
- File reference UUIDs
- Group hierarchy
- Build phase associations
- Target membership

The Python and Ruby scripts aren't reliably adding the new files to the correct groups. The safest method is using Xcode's GUI, which takes ~2 minutes.

---

## 📞 Need Help?

If you encounter issues:

1. **Check File Paths**: Verify files exist at:
   - `Models/Core/ProjectLocation.swift`
   - `Services/Project/ProjectLocationManager.swift`
   - `Views/Settings/ProjectLocationsView.swift`

2. **Check Build Errors**: Look for missing types:
   - `ProjectLocationManager`
   - `ProjectLocationsView`
   - `ProjectLocation`

3. **Verify Uncommenting**: Make sure all `/*` and `*/` are removed

4. **Clean Build**: Product → Clean Build Folder (⌘⇧K) in Xcode

---

## ⏱️ Time Estimate

- **Step 1**: Open Xcode → 10 seconds
- **Step 2**: Add 3 files → 2 minutes
- **Step 3**: Uncomment code → 1 minute
- **Step 4**: Build → 1 minute
- **Step 5**: Test feature → 1 minute

**Total**: ~5 minutes

---

## 🎉 After Completion

You'll have access to:
- **9 location types** (local, Git, cloud, Spotlight, etc.)
- **Unlimited custom directories**
- **Git repository cloning**
- **Import/export team configurations**
- **Recent projects tracking**
- **Per-location statistics**

See `PROJECT_LOCATIONS_FEATURE.md` for complete documentation.

---

**Feature Status**: ✅ Implemented, ⏳ Awaiting Xcode GUI integration
