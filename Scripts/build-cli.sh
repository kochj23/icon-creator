#!/bin/bash
#
# build-cli.sh
# Automatically build Icon Creator CLI during Xcode build
# Author: Jordan Koch
# Date: 2026-01-21
#

set -e

echo "🔨 Building Icon Creator CLI..."

# Get paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CLI_DIR="$PROJECT_DIR/CLI"
BUILD_DIR="$CLI_DIR/.build"

# Navigate to CLI directory
cd "$CLI_DIR"

# Build CLI in release mode
echo "📦 Running swift build..."
swift build -c release

# Check if build succeeded
if [ ! -f "$BUILD_DIR/release/icon-creator" ]; then
    echo "❌ CLI build failed"
    exit 1
fi

echo "✅ CLI built successfully: $BUILD_DIR/release/icon-creator"

# Copy to app bundle Resources
RESOURCES_DIR="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

if [ -n "$RESOURCES_DIR" ]; then
    mkdir -p "$RESOURCES_DIR/CLI"
    cp "$BUILD_DIR/release/icon-creator" "$RESOURCES_DIR/CLI/"
    chmod +x "$RESOURCES_DIR/CLI/icon-creator"
    echo "✅ CLI copied to app bundle"
else
    echo "ℹ️  Not building within Xcode, CLI bundle copy skipped"
fi

# Create symlink-ready version
INSTALLER_DIR="$PROJECT_DIR/Installer/Components"
mkdir -p "$INSTALLER_DIR"
cp "$BUILD_DIR/release/icon-creator" "$INSTALLER_DIR/icon-creator-cli"
chmod +x "$INSTALLER_DIR/icon-creator-cli"

echo "✅ CLI build complete!"
