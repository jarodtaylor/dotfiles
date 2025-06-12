#!/bin/bash

set -o pipefail

# Debug mode: Set CHEZMOI_DEBUG=1 for verbose chezmoi output
# Example: CHEZMOI_DEBUG=1 ./.startup.sh

# ##########################################
# INSTALL XCODE COMMAND LINE TOOLS FIRST   #
# ##########################################

echo "🛠️  Checking for Xcode Command Line Tools..."

# Check if command line tools are installed
if ! xcode-select -p &>/dev/null; then
  echo "📥 Installing Xcode Command Line Tools..."
  echo "   This is required for git, homebrew, and other developer tools"
  echo "   The installation may take several minutes..."
  echo ""

  # Install command line tools non-interactively
  # This prevents the popup dialog that can get hidden behind the terminal
  sudo xcode-select --install 2>/dev/null || true

  echo "⏳ Waiting for Xcode Command Line Tools installation to complete..."
  echo "   You may see a system dialog - please click 'Install' if it appears"
  echo "   This step is essential and cannot be skipped"
  echo ""

  # Wait for installation to complete
  while ! xcode-select -p &>/dev/null; do
    echo "   Still installing... (this can take 5-10 minutes)"
    sleep 30
  done

  echo "✅ Xcode Command Line Tools installed successfully"
else
  echo "✅ Xcode Command Line Tools already installed"
fi

# Accept Xcode license if needed
echo "📋 Checking Xcode license..."
if ! xcodebuild -license check &>/dev/null; then
  echo "📝 Accepting Xcode license agreement..."
  sudo xcodebuild -license accept
  echo "✅ Xcode license accepted"
else
  echo "✅ Xcode license already accepted"
fi

echo ""

# ##########################################
# PREREQUISITES & ASSUMPTIONS              #
# ##########################################
echo "🎯 Jarod's Magical Development Environment"
echo "========================================"
echo ""
echo "🪄 About to transform this Mac into a fully-configured development machine!"
echo ""
echo "⚠️  Quick setup (do these first):"
echo "   1. Have your 1Password account details ready."
echo "   2. This script will install 1Password and prompt for setup."
echo ""
echo "✨ Then this script magically installs:"
echo "   • All development tools (Git, Node, Python, etc.)"
echo "   • 90+ productivity applications"
echo "   • Custom shell with superpowers"
echo "   • Perfect configurations for everything"
echo "   • Automated backup systems"
echo ""
echo "🚀 Goal: Zero to coding in 60 minutes!"
echo ""

# Smart initial prompt with auto-continue
if [ -t 0 ] && [ -t 1 ]; then
  read -p "Ready to get your development superpowers? Press ENTER or Ctrl+C to abort..."
else
  echo "🪄 Auto-starting in non-interactive mode..."
  sleep 2
fi
echo ""

# Smart interactive mode detection with self-healing
if [ ! -t 0 ] && [ ! -t 1 ]; then
  echo "⚠️  Running in non-interactive mode - some prompts may not work perfectly."
  echo "💡 For best experience, download and run the script directly:"
  echo 'curl -sfL https://raw.githubusercontent.com/jarodtaylor/dotfiles/main/.startup.sh -o setup.sh && bash setup.sh'
  echo ""
  echo "🪄 Continuing with magic setup anyway..."
  sleep 3
fi

# Smart prompt function with auto-fallback
prompt_yn() {
  local prompt="$1"
  local default="$2"
  local response

  # Auto-default in non-interactive mode
  if [ ! -t 0 ] || [ ! -t 1 ]; then
    echo "$prompt (auto-defaulting to: $default)"
    case "$default" in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
    esac
  fi

  while true; do
    read -p "$prompt (y/n) [$default]: " response
    response=${response:-$default}
    case "$response" in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "Please answer yes or no.";;
    esac
  done
}

# ##########################################
# INSTALL CHEZMOI AND APPLY DOTFILES       #
# ##########################################

# Function to apply dotfiles configuration
apply_dotfiles_config() {
  echo "🎯 Applying Jarod's development environment..."

  # Try to apply configuration, with auto-recovery
  local max_attempts=3
  local attempt=1

  while [ $attempt -le $max_attempts ]; do
    echo "📦 Setting up development tools and configurations (attempt $attempt/$max_attempts)..."

    # Install chezmoi if not present
    if ! command -v chezmoi &>/dev/null; then
      echo "Installing chezmoi..."
      sh -c "$(curl -fsLS get.chezmoi.io)"
    fi

    # Clear any corrupted state and start fresh
    if [ $attempt -gt 1 ]; then
      echo "🔧 Clearing previous state and retrying..."
      rm -rf "$HOME/.cache/chezmoi" 2>/dev/null
    fi

    echo "🔍 Applying configuration with chezmoi..."
    # Apply the configuration with clean output for automation
    # Use CHEZMOI_DEBUG=1 environment variable for verbose output when needed
    if [[ ${CHEZMOI_DEBUG:-0} == 1 ]]; then
      echo "🔍 Debug mode enabled - showing verbose output..."
      "$HOME/bin/chezmoi" init --apply --verbose jarodtaylor
    else
      "$HOME/bin/chezmoi" init --apply jarodtaylor
    fi

    if [ $? -eq 0 ]; then
      echo "✅ Development environment configured successfully!"
      return 0
    else
      echo "❌ Configuration attempt $attempt failed with exit code $?"

      # Quick health check without overwhelming output
      if [ -d "$HOME/.local/share/chezmoi" ]; then
        echo "📁 Chezmoi source directory exists"

        # Check for key indicators of success/failure
        config_count=$(find "$HOME/.config" -maxdepth 1 -type d 2>/dev/null | wc -l)
        echo "📊 Found $config_count configuration directories"

        if [ ! -f "$HOME/.zshrc" ]; then
          echo "⚠️  Missing .zshrc (shell config may not be applied)"
        fi

        if [[ ${CHEZMOI_DEBUG:-0} == 1 ]]; then
          echo "📋 Chezmoi status (debug mode):"
          "$HOME/bin/chezmoi" status || echo "❌ Chezmoi status failed"
        fi
      else
        echo "❌ Chezmoi source directory missing - init failed"
      fi

      # Clear any corrupted template cache or state
      rm -rf "$HOME/.cache/chezmoi" 2>/dev/null
      ((attempt++))
      sleep 2
    fi
  done

  echo "❌ Configuration failed after $max_attempts attempts"
  echo "💡 This might be a network issue - try running the script again"
  return 1
}

# Apply dotfiles configuration
config_success=false
if [ -d "$HOME/.local/share/chezmoi" ] && command -v chezmoi &>/dev/null; then
  if prompt_yn "🔄 Development environment already configured. Refresh with latest updates?" "y"; then
    echo "🔄 Refreshing configuration..."
    cd "$HOME/.local/share/chezmoi" && git pull origin main
    echo "🔍 Applying updates..."
    if [[ ${CHEZMOI_DEBUG:-0} == 1 ]]; then
      "$HOME/bin/chezmoi" apply --verbose
    else
      "$HOME/bin/chezmoi" apply
    fi

    if [ $? -eq 0 ]; then
      config_success=true
    else
      echo "❌ Refresh apply failed, trying full reconfiguration..."
      if apply_dotfiles_config; then
        config_success=true
      fi
    fi
  else
    echo "⏭️  Skipping configuration refresh."
    config_success=true  # User chose to skip, so don't show failure
  fi
else
  if apply_dotfiles_config; then
    config_success=true
  fi
fi

# ##########################################
# MAGICAL SUCCESS CELEBRATION              #
# ##########################################

if [ "$config_success" = true ]; then
  echo ""
  echo "🎉✨ MAGIC COMPLETE! ✨🎉"
echo "========================"
echo ""
echo "🪄 Your Mac has been transformed into a development powerhouse!"
echo ""
echo "🌟 What you got:"
echo "   • Perfect shell with AI-powered tools"
echo "   • 90+ applications ready to use"
echo "   • All configurations tuned for maximum productivity"
echo "   • Automated backups and sync"
echo ""
echo "🚀 Next steps:"
echo "   1. Open a fresh terminal to experience the magic"
echo "   2. Some apps may ask for password on first launch"
echo "   3. Everything is configured and ready to go!"
echo ""
echo "💫 Welcome to your supercharged development environment!"
else
  echo ""
  echo "❌ Setup encountered issues but we got pretty far!"
  echo "=========================================="
  echo ""
  echo "🎯 What worked:"
  echo "   • Homebrew and all packages installed"
  echo "   • System tools configured"
  echo ""
  echo "⚠️  What needs attention:"
  echo "   • Some configurations failed to apply"
  echo "   • Try running the script again"
  echo "   • Check if 1Password is properly set up"
  echo ""
  echo "💡 Most things should still work - open a new terminal and explore!"
fi
