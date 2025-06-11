#!/bin/bash
# test-local-simulation.sh - Simulate fresh install testing locally

set -eo pipefail

BACKUP_DIR="$HOME/.dotfiles-test-backup-$(date +%Y%m%d-%H%M%S)"
TEST_HOME="$HOME/dotfiles-test-env"

echo "🧪 Local Dotfiles Testing Simulation"
echo "This will create a test environment and backup existing configs"

# Create test environment
mkdir -p "$TEST_HOME"
mkdir -p "$BACKUP_DIR"

echo "📦 Backing up existing configs to: $BACKUP_DIR"

# Backup existing dotfiles
[[ -d "$HOME/.local/share/chezmoi" ]] && cp -r "$HOME/.local/share/chezmoi" "$BACKUP_DIR/"
[[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$BACKUP_DIR/"
[[ -d "$HOME/.config" ]] && cp -r "$HOME/.config" "$BACKUP_DIR/"

echo "🎭 Creating simulated fresh environment..."

# Set environment variables to simulate fresh system
export DOTFILES_TESTING=true
export HOME="$TEST_HOME"
export XDG_CONFIG_HOME="$TEST_HOME/.config"
export XDG_DATA_HOME="$TEST_HOME/.local/share"

# Create basic directory structure
mkdir -p "$TEST_HOME"/{.config,.local/share}

echo "🚀 Testing startup script in simulated environment..."
echo "HOME is now: $HOME"

# Test the startup script
cd "$TEST_HOME"
curl -sfL https://raw.githubusercontent.com/jarodtaylor/dotfiles/main/.startup.sh -o test-startup.sh

# Show what would be different
echo "📋 Testing startup script (dry run mode)..."
TESTING_MODE=true bash test-startup.sh

echo "✅ Test complete!"
echo "🔄 Restoring original environment..."

# Restore original HOME
unset DOTFILES_TESTING
export HOME="$(echo ~)"

echo "💾 Backup saved to: $BACKUP_DIR"
echo "🗑️  Clean up test environment with: rm -rf $TEST_HOME"
