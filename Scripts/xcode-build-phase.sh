#!/bin/bash
#
# xcode-build-phase.sh
# Xcode Build Phase Script - Automatically builds CLI during app build
# Add this script to Xcode: Target → Build Phases → New Run Script Phase
# Author: Jordan Koch
# Date: 2026-01-21
#

# Only build CLI in Release configuration
if [ "$CONFIGURATION" != "Release" ]; then
    echo "ℹ️  Skipping CLI build (Debug configuration)"
    exit 0
fi

echo "🔨 Building Icon Creator CLI (Xcode Build Phase)"

# Set paths
PROJECT_DIR="${PROJECT_DIR:-${SRCROOT}}"
CLI_DIR="$PROJECT_DIR/CLI"

if [ ! -d "$CLI_DIR" ]; then
    echo "⚠️  CLI directory not found: $CLI_DIR"
    exit 0
fi

cd "$CLI_DIR"

# Check for Package.swift
if [ ! -f "Package.swift" ]; then
    echo "⚠️  No Package.swift found, skipping CLI build"
    exit 0
fi

# Build CLI
echo "📦 swift build -c release"
swift build -c release 2>&1 | grep -E "Compiling|Linking|error:" || true

# Check if build succeeded
CLI_BINARY="$CLI_DIR/.build/release/icon-creator"

if [ ! -f "$CLI_BINARY" ]; then
    echo "❌ CLI build failed"
    # Don't fail the main build
    exit 0
fi

echo "✅ CLI built successfully"

# Copy to app bundle Resources
RESOURCES_DIR="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

if [ -n "$RESOURCES_DIR" ]; then
    mkdir -p "$RESOURCES_DIR/CLI"
    cp "$CLI_BINARY" "$RESOURCES_DIR/CLI/icon-creator"
    chmod +x "$RESOURCES_DIR/CLI/icon-creator"

    # Verify it copied
    if [ -f "$RESOURCES_DIR/CLI/icon-creator" ]; then
        echo "✅ CLI embedded in app bundle: $RESOURCES_DIR/CLI/icon-creator"
    fi
fi

# Copy automation templates to Resources
mkdir -p "$RESOURCES_DIR/Automation/GitHub"
mkdir -p "$RESOURCES_DIR/Automation/Fastlane"

cp "$PROJECT_DIR/Automation/GitHub"/*.yml "$RESOURCES_DIR/Automation/GitHub/" 2>/dev/null || true
cp "$PROJECT_DIR/Automation/Fastlane"/*.rb "$RESOURCES_DIR/Automation/Fastlane/" 2>/dev/null || true
cp "$PROJECT_DIR/Automation/Fastlane/Fastfile.example" "$RESOURCES_DIR/Automation/Fastlane/" 2>/dev/null || true

echo "✅ Automation templates embedded"

# Copy documentation
mkdir -p "$RESOURCES_DIR/Documentation"

cp "$PROJECT_DIR/ADVANCED_FEATURES_DOCUMENTATION.md" "$RESOURCES_DIR/Documentation/" 2>/dev/null || true
cp "$PROJECT_DIR/NEW_FEATURES_SUMMARY.md" "$RESOURCES_DIR/Documentation/" 2>/dev/null || true
cp "$PROJECT_DIR/IMPLEMENTATION_COMPLETE.md" "$RESOURCES_DIR/Documentation/" 2>/dev/null || true

echo "✅ Documentation embedded"

echo "🎉 Build phase complete!"
