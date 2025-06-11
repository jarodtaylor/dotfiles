#!/bin/bash

set -o pipefail

# ##########################################
# PREREQUISITES & ASSUMPTIONS              #
# ##########################################
echo "🎯 Jarod's Magic Development Environment"
echo "========================================"
echo ""
echo "🪄 About to transform this Mac into a fully-configured development machine!"
echo ""
echo "⚠️  Quick setup (do these first):"
echo "   1. Install 1Password app from App Store"
echo "   2. Sign in to 1Password"
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

# ########################################
# INSTALL XCODE COMMAND LINE TOOLS       #
# ########################################

# Check for Xcode Command Line Tools and install them if not present
xcode-select -p &>/dev/null
if [ $? -ne 0 ]; then
  echo "Installing Xcode Command Line Tools ..."
  xcode-select --install
else
  echo "XCode Command Line Tools already installed"
fi

# Accept Xcode license
echo "before accepting license"
xcode_version=$(xcodebuild -version | grep '^Xcode\s' | sed -E 's/^Xcode[[:space:]]+([0-9\.]+)/\1/')
accepted_license_version=$(defaults read /Library/Preferences/com.apple.dt.Xcode 2>/dev/null | grep IDEXcodeVersionForAgreedToGMLicense | cut -d '"' -f 2)
if [ "$xcode_version" != "$accepted_license_version" ]; then
  sudo xcodebuild -license accept
fi

# ########################################
# INSTALL HOMEBREW                       #
# ########################################

# Check if Homebrew is installed and functional
is_brew_installed() {
  [ -d "/opt/homebrew" ] || [ -d "/usr/local/Homebrew" ]
}

# Check if Homebrew installation is complete and functional
is_brew_functional() {
  command -v brew &>/dev/null && brew --version &>/dev/null
}

# Check if Homebrew is in the PATH
is_brew_path_set() {
  command -v brew &>/dev/null
}

# Set Homebrew in the PATH
set_brew_path() {
  if [ -d "/opt/homebrew/bin" ]; then
    # For Apple Silicon Mac
    echo "Apple Silicon Mac detected. Setting Homebrew path..."
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -d "/usr/local/bin" ]; then
    # For Intel Mac
    echo "Intel Mac detected. Setting Homebrew path..."
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

# Install Homebrew if it is not installed or not functional
if is_brew_functional; then
  echo "Homebrew is installed and functional."
elif is_brew_installed; then
  echo "Homebrew directory exists but not functional. Setting PATH and checking..."
  set_brew_path
  if ! is_brew_functional; then
    echo "Homebrew installation appears incomplete. Reinstalling..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    set_brew_path
  fi
else
  echo "Homebrew is not installed. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  set_brew_path
fi

# ##########################################
# INSTALL ESSENTIAL CLI TOOLS              #
# ##########################################

echo "Installing essential CLI tools for dotfiles..."

# Install 1Password CLI (required for secrets in chezmoi templates)
if ! command -v op &>/dev/null; then
  echo "Installing 1Password CLI..."
  brew install --cask 1password-cli
  echo "✅ 1Password CLI installed"
else
  echo "✅ 1Password CLI already installed"
fi

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
      sh -c "$(curl -fsLS get.chezmoi.io)"
    fi

    # Clear any corrupted state and start fresh
    if [ $attempt -gt 1 ]; then
      echo "🔧 Clearing previous state and retrying..."
      rm -rf "$HOME/.local/share/chezmoi" "$HOME/.config/chezmoi" 2>/dev/null
    fi

    # Apply the configuration
    if chezmoi init --apply jarodtaylor 2>/dev/null; then
      echo "✅ Development environment configured successfully!"
      return 0
    else
      echo "⚠️  Configuration attempt $attempt failed, auto-recovering..."
      ((attempt++))
      sleep 2
    fi
  done

  echo "❌ Configuration failed after $max_attempts attempts"
  echo "💡 This might be a network issue - try running the script again"
  return 1
}

# Apply dotfiles configuration
if [ -d "$HOME/.local/share/chezmoi" ] && command -v chezmoi &>/dev/null; then
  if prompt_yn "🔄 Development environment already configured. Refresh with latest updates?" "y"; then
    echo "🔄 Refreshing configuration..."
    cd "$HOME/.local/share/chezmoi" && git pull origin main &>/dev/null
    chezmoi apply || apply_dotfiles_config
  else
    echo "⏭️  Skipping configuration refresh."
  fi
else
  apply_dotfiles_config
fi

# ##########################################
# MAGICAL SUCCESS CELEBRATION              #
# ##########################################

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
