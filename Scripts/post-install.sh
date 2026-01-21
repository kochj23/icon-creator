#!/bin/bash
#
# post-install.sh
# Post-installation script for Icon Creator DMG
# Automatically installs CLI tool and sets up environment
# Author: Jordan Koch
# Date: 2026-01-21
#

set -e

echo "🎉 Icon Creator Post-Installation Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Detect if running from DMG or after installation
APP_PATH="/Applications/Icon Creator.app"

if [ ! -d "$APP_PATH" ]; then
    echo "⚠️  Icon Creator.app not found in /Applications"
    echo "Please drag Icon Creator.app to Applications first"
    exit 1
fi

echo "✅ Found Icon Creator.app"

# Check for CLI tool in app bundle
CLI_IN_BUNDLE="$APP_PATH/Contents/Resources/CLI/icon-creator"

if [ -f "$CLI_IN_BUNDLE" ]; then
    echo "📦 Installing CLI tool to /usr/local/bin..."

    # Create /usr/local/bin if it doesn't exist
    sudo mkdir -p /usr/local/bin

    # Copy CLI tool
    sudo cp "$CLI_IN_BUNDLE" /usr/local/bin/icon-creator
    sudo chmod +x /usr/local/bin/icon-creator

    # Verify installation
    if command -v icon-creator &> /dev/null; then
        VERSION=$(icon-creator version 2>/dev/null || echo "unknown")
        echo "✅ CLI installed: $VERSION"
    else
        echo "⚠️  CLI installed but not in PATH"
        echo "   Add /usr/local/bin to your PATH in ~/.zshrc or ~/.bash_profile"
    fi
else
    echo "⚠️  CLI tool not found in app bundle"
    echo "   Build the CLI separately: cd CLI && swift build -c release"
fi

# Create configuration directory
CONFIG_DIR="$HOME/.icon-creator"
mkdir -p "$CONFIG_DIR"
echo "✅ Created config directory: $CONFIG_DIR"

# Create default configuration
cat > "$CONFIG_DIR/config.json" << 'EOF'
{
  "version": "3.0.0",
  "cli_installed": true,
  "first_run": true,
  "github_workflows_deployed": false,
  "firebase_configured": false,
  "icloud_enabled": false
}
EOF

echo "✅ Created default configuration"

# Offer to add shell completion
echo ""
echo "🔧 Optional: Add CLI to your shell PATH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SHELL_RC="$HOME/.zshrc"
if [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bash_profile"
fi

if ! grep -q "icon-creator" "$SHELL_RC" 2>/dev/null; then
    echo ""
    echo "Add the following to $SHELL_RC:"
    echo ""
    echo "  # Icon Creator CLI"
    echo "  export PATH=\"/usr/local/bin:\$PATH\""
    echo ""
    echo "Then run: source $SHELL_RC"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Installation Complete!"
echo ""
echo "Next Steps:"
echo "  1. Launch Icon Creator.app"
echo "  2. Run the first-time setup wizard"
echo "  3. (Optional) Enable GitHub Actions automation"
echo "  4. (Optional) Enable Firebase for A/B testing"
echo "  5. (Optional) Enable iCloud sync"
echo ""
echo "Quick Test:"
echo "  icon-creator version"
echo ""
echo "Documentation:"
echo "  open '$APP_PATH/Contents/Resources/Documentation'"
echo ""
echo "🎉 Enjoy Icon Creator v3.0!"
