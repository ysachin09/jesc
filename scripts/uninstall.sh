#!/bin/bash

# Jira Escalation Analyzer - Complete Uninstall Script
# This script removes all traces of the Jira Escalation Analyzer

set -e

TOOL_NAME="jira-escalation-analyzer"
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/$TOOL_NAME"
TOOL_EXECUTABLE="$INSTALL_DIR/jesc"

echo "🗑️  Uninstalling Jira Escalation Analyzer"
echo "📱 Removing: jesc command"
echo "=========================================="

# Function to ask for confirmation
confirm_action() {
    echo -n "$1 (y/N): "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Check if tool is installed
if [[ ! -f "$TOOL_EXECUTABLE" ]]; then
    echo "❌ jesc command not found. Already uninstalled?"
    exit 0
fi

echo "Found installation at: $TOOL_EXECUTABLE"
echo ""

# 1. Remove main executable
echo "🔧 Step 1: Remove main executable"
if confirm_action "Remove $TOOL_EXECUTABLE?"; then
    rm -f "$TOOL_EXECUTABLE"
    echo "✅ Removed main executable"
else
    echo "⏭️  Skipped executable removal"
fi
echo ""

# 2. Remove configuration directory
echo "📁 Step 2: Remove configuration directory"
if [[ -d "$CONFIG_DIR" ]]; then
    echo "Configuration directory contains:"
    ls -la "$CONFIG_DIR" 2>/dev/null || echo "  (empty or inaccessible)"
    echo ""
    
    if confirm_action "Remove entire config directory $CONFIG_DIR?"; then
        rm -rf "$CONFIG_DIR"
        echo "✅ Removed configuration directory"
    else
        echo "⏭️  Skipped config directory removal"
        echo "ℹ️  You may want to manually backup your config first:"
        echo "   cp -r $CONFIG_DIR ~/jira-analyzer-backup"
    fi
else
    echo "ℹ️  No configuration directory found"
fi
echo ""

# 3. Remove PATH modification
echo "🛤️  Step 3: Remove PATH modification"

# Determine shell config file
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
else
    echo "⚠️  Unknown shell: $SHELL"
    echo "You may need to manually remove PATH entry from your shell config"
    SHELL_CONFIG=""
fi

if [[ -n "$SHELL_CONFIG" && -f "$SHELL_CONFIG" ]]; then
    # Check if PATH modification exists
    if grep -q "HOME/.local/bin" "$SHELL_CONFIG"; then
        echo "Found PATH modification in: $SHELL_CONFIG"
        
        if confirm_action "Remove PATH modification from $SHELL_CONFIG?"; then
            # Create backup
            cp "$SHELL_CONFIG" "$SHELL_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
            echo "📦 Created backup: $SHELL_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
            
            # Remove the line
            sed -i.tmp '/export PATH.*HOME\/.local\/bin/d' "$SHELL_CONFIG"
            rm -f "$SHELL_CONFIG.tmp"
            
            echo "✅ Removed PATH modification"
            echo "🔄 Restart your terminal or run: source $SHELL_CONFIG"
        else
            echo "⏭️  Skipped PATH modification removal"
            echo "ℹ️  You can manually remove this line from $SHELL_CONFIG:"
            echo '   export PATH="$HOME/.local/bin:$PATH"'
        fi
    else
        echo "ℹ️  No PATH modification found in $SHELL_CONFIG"
    fi
else
    echo "ℹ️  Shell config file not found or not supported"
fi
echo ""

# 4. Find and offer to remove analysis directories
echo "🔍 Step 4: Find analysis directories"
ANALYSIS_DIRS=$(find "$HOME/.config" -name "analysis_*" -type d 2>/dev/null | grep -E "analysis_[0-9]{8}_[0-9]{6}_[A-Z]+-[0-9]+" || true)

if [[ -n "$ANALYSIS_DIRS" ]]; then
    echo "Found analysis directories:"
    echo "$ANALYSIS_DIRS" | while read -r dir; do
        echo "  $dir"
    done
    echo ""
    
    if confirm_action "Remove all analysis directories? (Contains historical analysis data)"; then
        echo "$ANALYSIS_DIRS" | while read -r dir; do
            rm -rf "$dir"
            echo "🗑️  Removed: $dir"
        done
        echo "✅ Removed all analysis directories"
    else
        echo "⏭️  Skipped analysis directories removal"
        echo "ℹ️  You can manually remove them later if needed"
    fi
else
    echo "ℹ️  No analysis directories found"
fi
echo ""

# 5. Check for any remaining traces
echo "🔍 Step 5: Check for remaining traces"
REMAINING_FILES=()

# Check for any remaining files
if [[ -f "$TOOL_EXECUTABLE" ]]; then
    REMAINING_FILES+=("$TOOL_EXECUTABLE")
fi

if [[ -d "$CONFIG_DIR" ]]; then
    REMAINING_FILES+=("$CONFIG_DIR")
fi

if [[ ${#REMAINING_FILES[@]} -gt 0 ]]; then
    echo "⚠️  Some files were not removed:"
    for file in "${REMAINING_FILES[@]}"; do
        echo "  $file"
    done
    echo ""
    echo "You can manually remove these if needed."
else
    echo "✅ No remaining files found"
fi

# 6. Final status
echo ""
echo "🎉 Uninstall Summary"
echo "==================="

if [[ ! -f "$TOOL_EXECUTABLE" ]]; then
    echo "✅ Main executable: REMOVED"
else
    echo "⚠️  Main executable: STILL EXISTS"
fi

if [[ ! -d "$CONFIG_DIR" ]]; then
    echo "✅ Configuration directory: REMOVED"
else
    echo "⚠️  Configuration directory: STILL EXISTS"
fi

if [[ -n "$SHELL_CONFIG" && -f "$SHELL_CONFIG" ]]; then
    if ! grep -q "HOME/.local/bin" "$SHELL_CONFIG"; then
        echo "✅ PATH modification: REMOVED"
    else
        echo "⚠️  PATH modification: STILL EXISTS"
    fi
fi

echo ""
echo "🔄 Next Steps:"

if [[ ! -f "$TOOL_EXECUTABLE" ]]; then
    echo "✅ Jira Escalation Analyzer has been successfully uninstalled!"
    echo ""
    echo "Optional:"
    echo "• Restart your terminal to apply PATH changes"
    echo "• Remove jq if it was installed only for this tool: brew uninstall jq"
else
    echo "⚠️  Uninstall incomplete. You may need to manually remove remaining files."
fi

echo ""
echo "Thanks for using Jira Escalation Analyzer! 👋" 