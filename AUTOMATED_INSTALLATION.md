# Icon Creator - Automated Installation Guide
**Version:** 3.0.0
**Author:** Jordan Koch
**Date:** January 21, 2026

---

## 🎯 Overview

Icon Creator v3.0 features **fully automated installation** with zero manual configuration required. Everything is set up automatically when you install the app.

---

## 📦 What Gets Installed Automatically

### 1. **Icon Creator Application**
- Main macOS app with full GUI
- All 14 advanced features included
- Embedded CLI tool
- Embedded documentation
- Embedded automation templates

### 2. **Command-Line Interface (CLI)**
- Automatically installed to `/usr/local/bin/icon-creator`
- 6 commands: generate, watch, optimize, analyze, variants
- Works immediately after installation
- No manual build required

### 3. **GitHub Actions Workflows**
- Bundled in app Resources
- First-run wizard offers to deploy
- One-click deployment to your repository
- Automatic icon generation on push

### 4. **Automation Templates**
- Fastlane plugin templates
- Webhook server configuration
- CI/CD examples

### 5. **Complete Documentation**
- Comprehensive guides
- Code examples
- Troubleshooting tips

---

## 🚀 Installation Process (User Perspective)

### STEP 1: Mount DMG
```
Double-click: IconCreator-v3.0.0-buildXXXX.dmg
```

### STEP 2: Drag to Applications
```
Drag "Icon Creator.app" → Applications folder
```

### STEP 3: Run Post-Install Script
```
Double-click: "Install CLI & Setup.command"
```

**What Happens Automatically:**
- ✅ CLI installed to /usr/local/bin (requires admin password)
- ✅ Configuration directory created (~/.icon-creator)
- ✅ Default config written
- ✅ PATH updated (if needed)
- ✅ Installation verified

### STEP 4: Launch Icon Creator
```
Open: /Applications/Icon Creator.app
```

**What Happens Automatically:**
- ✅ First-run setup wizard appears
- ✅ Offers to deploy GitHub Actions (one click)
- ✅ Offers to configure Firebase (opens guide)
- ✅ Offers to enable iCloud (opens settings)
- ✅ Configuration saved

### STEP 5: Done!
```
Everything is ready to use. Zero manual configuration.
```

---

## 🔧 For Developers: Build Automation

### Xcode Build Phase Integration

Add this to your Xcode project to automatically build CLI during app build:

**Xcode → Target → Build Phases → + → New Run Script Phase**

```bash
# Name: Build Icon Creator CLI
# Shell: /bin/bash
# Script:

"${SRCROOT}/Scripts/xcode-build-phase.sh"
```

**What It Does:**
- Automatically builds CLI in Release mode
- Embeds CLI binary in app Resources
- Copies GitHub Actions workflows to app Resources
- Copies Fastlane templates to app Resources
- Embeds all documentation

### Automated Installer Creation

Run the complete installer build script:

```bash
cd "/Volumes/Data/xcode/Icon Creator"
./Scripts/create-installer.sh
```

**What It Does:**
1. ✅ Builds CLI with swift build
2. ✅ Builds Xcode project
3. ✅ Archives application
4. ✅ Exports to binaries directory
5. ✅ Bundles CLI into app Resources
6. ✅ Bundles automation templates
7. ✅ Bundles documentation
8. ✅ Creates DMG with post-install script
9. ✅ Copies to NAS backup
10. ✅ Installs to /Applications
11. ✅ Creates release notes

**Output:**
```
/Volumes/Data/xcode/binaries/YYYYMMDD-IconCreator-v3.0.0/
├── Icon Creator.app (with embedded CLI)
├── IconCreator-v3.0.0-buildXXXX.dmg
└── RELEASE_NOTES.md

DMG Contents:
├── Icon Creator.app
├── Applications (symlink)
├── Install CLI & Setup.command (auto-installer)
└── README.txt
```

---

## 🎯 User Experience Flow

### Traditional Approach (Manual - OLD WAY ❌)
```
1. Install app
2. Read documentation
3. cd CLI && swift build -c release
4. sudo cp .build/release/icon-creator /usr/local/bin/
5. Copy GitHub Actions manually
6. Edit workflow files
7. Configure Firebase manually
8. Enable iCloud manually
Total Time: 30-60 minutes
```

### Automated Approach (NEW WAY ✅)
```
1. Drag app to Applications
2. Run "Install CLI & Setup.command"
3. Click "Install" in first-run wizard
Total Time: 2 minutes
```

**Time Savings: 95%**

---

## 🔍 What Happens Behind the Scenes

### During DMG Creation
```bash
./Scripts/create-installer.sh
```

1. Builds CLI automatically
2. Builds app with embedded resources
3. Creates DMG with:
   - App bundle (with CLI inside)
   - Post-install script
   - README
   - Applications symlink

### When User Runs Post-Install Script
```bash
Install CLI & Setup.command
```

1. Verifies app is in /Applications
2. Extracts CLI from app bundle
3. Copies to /usr/local/bin (requests admin password)
4. Creates ~/.icon-creator/ config directory
5. Writes default configuration
6. Verifies installation
7. Shows next steps

### When User Launches App (First Time)
```swift
FirstRunSetupAssistant appears automatically
```

1. Checks what's already installed
2. Offers one-click installation for missing components:
   - CLI tool (if not installed)
   - GitHub Actions (finds git repo, deploys workflows)
   - Firebase (opens setup guide)
   - iCloud (opens System Settings)
3. Saves completion state
4. Never shows again (unless reset)

---

## 🎨 First-Run Wizard Features

### Intelligent Detection
- ✅ Detects if CLI is already installed
- ✅ Finds git repositories automatically
- ✅ Checks for existing GitHub workflows
- ✅ Detects Firebase configuration
- ✅ Checks iCloud availability

### One-Click Installation
- ✅ "Install Now" buttons for each feature
- ✅ Progress indicators during installation
- ✅ Success confirmation with checkmarks
- ✅ Error handling with helpful messages

### Skip or Complete
- ✅ "Skip Setup" for advanced users
- ✅ "Complete Setup" when all done
- ✅ Optional features clearly marked
- ✅ Can be run again later from menu

---

## 🔄 Integration Points

### 1. Xcode Build Phase
```
Add to Target → Build Phases:
Script: ${SRCROOT}/Scripts/xcode-build-phase.sh
Runs: Before "Copy Bundle Resources"
```

### 2. App Delegate / Main App
```swift
import SwiftUI

@main
struct IconCreatorApp: App {
    @StateObject private var setupCoordinator = SetupCoordinator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(isPresented: $setupCoordinator.shouldShowSetupWizard) {
                    FirstRunSetupAssistant(isPresented: $setupCoordinator.shouldShowSetupWizard)
                        .onDisappear {
                            setupCoordinator.markSetupComplete()
                        }
                }
        }
    }
}
```

### 3. Menu Item (For Re-Running Setup)
```swift
Menu("Setup") {
    Button("Run Setup Wizard...") {
        setupCoordinator.shouldShowSetupWizard = true
    }

    Button("Install CLI Tool...") {
        // Run CLI installation
    }

    Button("Deploy GitHub Workflows...") {
        // Run workflow deployment
    }
}
```

---

## 📋 Installation Checklist (Automated)

| Step | What Happens | User Action |
|------|--------------|-------------|
| 1️⃣ Mount DMG | DMG mounts | Double-click DMG |
| 2️⃣ Install App | App copied | Drag to Applications |
| 3️⃣ Install CLI | CLI installed to /usr/local/bin | Run post-install script |
| 4️⃣ Launch App | Setup wizard appears | Open app |
| 5️⃣ GitHub Actions | Workflows deployed to repo | Click "Install Now" |
| 6️⃣ Firebase | Setup guide opens | (Optional) |
| 7️⃣ iCloud | System Settings opens | (Optional) |
| 8️⃣ Complete | Config saved, wizard closes | Click "Done" |

**Total User Clicks: ~5**
**Total Time: ~2 minutes**

---

## 🛠️ Developer Workflow

### Build Complete Installer

**Single Command:**
```bash
cd "/Volumes/Data/xcode/Icon Creator"
./Scripts/create-installer.sh
```

**Output:**
```
📦 Complete installer package in:
   /Volumes/Data/xcode/binaries/YYYYMMDD-IconCreator-v3.0.0/

Contents:
✅ Icon Creator.app (with embedded CLI and resources)
✅ IconCreator-v3.0.0-buildXXXX.dmg (full installer)
✅ RELEASE_NOTES.md

DMG includes:
✅ Icon Creator.app
✅ Applications symlink
✅ Install CLI & Setup.command (auto-installer)
✅ README.txt

Automatically:
✅ Installed to /Applications
✅ Copied to NAS backup
✅ CLI embedded in app
✅ All resources bundled
```

### Quick Development Build

**For testing without full packaging:**
```bash
# Build app only
xcodebuild -project "Icon Creator.xcodeproj" \
    -scheme "Icon Creator" \
    -configuration Release \
    build

# CLI builds automatically via build phase
```

---

## 🎯 Benefits of Automated Installation

### For Users
- ✅ **Zero technical knowledge required**
- ✅ **No terminal commands needed**
- ✅ **No manual file copying**
- ✅ **No PATH configuration**
- ✅ **Everything just works**

### For Developers (You)
- ✅ **Single script to build everything**
- ✅ **Consistent installation process**
- ✅ **No support requests about installation**
- ✅ **Professional user experience**
- ✅ **Automated testing possible**

### For Distribution
- ✅ **Professional DMG installer**
- ✅ **Looks like commercial software**
- ✅ **Easy to share (just send DMG)**
- ✅ **No complex instructions needed**
- ✅ **App Store ready (if needed)**

---

## 🧪 Testing the Installer

### Test Complete Flow
```bash
# 1. Build installer
./Scripts/create-installer.sh

# 2. Test DMG mounting
open "/Volumes/Data/xcode/binaries/YYYYMMDD-IconCreator-v3.0.0/IconCreator-v3.0.0-buildXXXX.dmg"

# 3. Drag app to Applications

# 4. Run post-install script
# (Double-click "Install CLI & Setup.command" in DMG)

# 5. Verify CLI installed
icon-creator version

# 6. Launch app
open "/Applications/Icon Creator.app"

# 7. Verify setup wizard appears

# 8. Test GitHub Actions deployment
# (Click "Install Now" for GitHub Actions)

# 9. Verify workflows deployed
ls ~/.icon-creator/
cat ~/.icon-creator/config.json
```

---

## 🔐 Security Considerations

### Post-Install Script
- ✅ Requests admin password only once
- ✅ Only writes to safe locations (/usr/local/bin)
- ✅ Validates paths before writing
- ✅ Shows exactly what it's doing

### CLI Installation
- ✅ Extracted from signed app bundle
- ✅ Inherits code signature from parent app
- ✅ No network downloads required
- ✅ No suspicious activity

### Setup Wizard
- ✅ Runs in app sandbox
- ✅ Only deploys to user-owned git repos
- ✅ No credential storage
- ✅ Optional features clearly marked

---

## 📝 Troubleshooting

### "CLI not found after installation"
```bash
# Check if installed
ls -la /usr/local/bin/icon-creator

# Check PATH
echo $PATH | grep /usr/local/bin

# Add to PATH if missing
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### "Setup wizard doesn't appear"
```bash
# Delete config to reset
rm -rf ~/.icon-creator/

# Relaunch app
open "/Applications/Icon Creator.app"
```

### "GitHub Actions deployment failed"
```
Common causes:
- Not in a git repository
- No write permissions
- .github/workflows/ already exists

Solution:
- Initialize git: git init
- Or deploy manually from app Resources
```

---

## 🎉 Summary

Icon Creator v3.0 features **completely automated installation**:

1. **Build:** One script builds everything
2. **Package:** DMG includes all components
3. **Install:** Post-install script sets up CLI
4. **Setup:** First-run wizard configures features
5. **Done:** Everything works immediately

**No manual steps. No terminal commands. No configuration files.**

**Just drag, install, and use!** 🚀

---

## 📞 Support

If automated installation fails:
- Check TROUBLESHOOTING.md
- Open issue: https://github.com/kochj23/icon-creator/issues
- Run manual installation steps in ADVANCED_FEATURES_DOCUMENTATION.md

---

**Built for ease of use. Built for automation. Built for professionals.**
