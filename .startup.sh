#!/bin/bash

set -o pipefail

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

# Debug function for troubleshooting chezmoi issues
debug_chezmoi() {
  echo "🔍 CHEZMOI DEBUG INFORMATION"
  echo "============================="
  echo ""

  echo "📍 Environment:"
  echo "  PWD: $(pwd)"
  echo "  USER: $USER"
  echo "  HOME: $HOME"
  echo "  ONEPASSWORD_AVAILABLE: ${ONEPASSWORD_AVAILABLE:-not set}"
  echo ""

  echo "🛠️  Tool availability:"
  echo "  chezmoi: $(command -v chezmoi || echo 'NOT FOUND')"
  echo "  op: $(command -v op || echo 'NOT FOUND')"
  echo "  git: $(command -v git || echo 'NOT FOUND')"
  echo ""

  if command -v chezmoi &>/dev/null; then
    echo "📋 Chezmoi configuration:"
    echo "  Source dir: $("$HOME/bin/chezmoi" source-path 2>/dev/null || echo 'ERROR')"
    echo "  Config file: $("$HOME/bin/chezmoi" config-file 2>/dev/null || echo 'ERROR')"
    echo ""

    echo "📊 Chezmoi status:"
    ONEPASSWORD_AVAILABLE="${ONEPASSWORD_AVAILABLE:-false}" "$HOME/bin/chezmoi" status 2>&1 || echo "❌ Status command failed"
    echo ""

    echo "🗂️  Source directory contents:"
    if [ -d "$HOME/.local/share/chezmoi" ]; then
      find "$HOME/.local/share/chezmoi/home" -type f | head -20
    else
      echo "❌ Source directory doesn't exist"
    fi
  fi

  echo ""
  echo "📁 Current ~/.config contents:"
  find "$HOME/.config" -maxdepth 1 -type d 2>/dev/null | sort || echo "❌ Can't read ~/.config"

  echo ""
  echo "🔑 Key files status:"
  for file in .zshrc .zshenv .ssh/config; do
    if [ -f "$HOME/$file" ]; then
      echo "  ✅ ~/$file exists"
    else
      echo "  ❌ ~/$file missing"
    fi
  done
}

# Uncomment the line below and run this script to get debug info:
# debug_chezmoi && exit 0

# ##########################################
# PREREQUISITES & ASSUMPTIONS              #
# ##########################################
echo "🎯 Jarod's Magical Development Environment"
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
  echo ""
  echo "🔐 1Password Setup"
  echo "=================="
  echo "1Password CLI can be used to securely manage SSH keys and other secrets."
  echo "This is optional but recommended for the full experience."
  echo ""
  read -p "Would you like to install and use 1Password CLI? (y/n) [y]: " use_1password
  use_1password=${use_1password:-y}

  if [[ $use_1password =~ ^[Yy]$ ]]; then
    echo "Installing 1Password CLI..."
    brew install --cask 1password-cli
    echo "✅ 1Password CLI installed"

    echo ""
    echo "Please sign in to 1Password CLI to continue..."
    echo "This will enable automatic SSH key management and git signing."
    echo ""

    # Attempt to sign in
    if ! op account list &>/dev/null; then
      echo "Opening 1Password sign-in..."
      op signin || echo "⚠️  1Password sign-in skipped - you can sign in later with 'op signin'"
    fi

    # Verify it's working
    if op account list &>/dev/null; then
      echo "✅ 1Password CLI ready"
      export ONEPASSWORD_AVAILABLE=true
    else
      echo "⚠️  1Password CLI installed but not signed in"
      echo "   You can sign in later with: op signin"
      export ONEPASSWORD_AVAILABLE=false
    fi
  else
    echo "⏭️  Skipping 1Password CLI installation"
    export ONEPASSWORD_AVAILABLE=false
  fi
else
  echo "✅ 1Password CLI already installed"
  # Check if signed in
  if op account list &>/dev/null; then
    echo "✅ 1Password CLI ready"
    export ONEPASSWORD_AVAILABLE=true
  else
    echo "⚠️  1Password CLI not signed in"
    read -p "Would you like to sign in now? (y/n) [y]: " signin_now
    signin_now=${signin_now:-y}

    if [[ $signin_now =~ ^[Yy]$ ]]; then
      op signin || echo "⚠️  1Password sign-in skipped"

      if op account list &>/dev/null; then
        echo "✅ 1Password CLI ready"
        export ONEPASSWORD_AVAILABLE=true
      else
        export ONEPASSWORD_AVAILABLE=false
      fi
    else
      export ONEPASSWORD_AVAILABLE=false
    fi
  fi
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
      echo "Installing chezmoi..."
      sh -c "$(curl -fsLS get.chezmoi.io)"
    fi

    # Clear any corrupted state and start fresh
    if [ $attempt -gt 1 ]; then
      echo "🔧 Clearing previous state and retrying..."
      rm -rf "$HOME/.cache/chezmoi" 2>/dev/null
    fi

    echo "🔍 Running chezmoi with verbose output to debug any issues..."
    # Apply the configuration with verbose output and proper error reporting
    if ONEPASSWORD_AVAILABLE="$ONEPASSWORD_AVAILABLE" "$HOME/bin/chezmoi" init --apply --verbose jarodtaylor; then
      echo "✅ Development environment configured successfully!"
      return 0
    else
      echo "❌ Configuration attempt $attempt failed with exit code $?"
      echo "🔍 Checking what files were actually applied..."

      # Show what was applied so far
      if [ -d "$HOME/.local/share/chezmoi" ]; then
        echo "📁 Chezmoi source directory exists"
        echo "📊 Applied configurations:"
        find "$HOME/.config" -maxdepth 1 -type d | sort

        echo "🔍 Checking for common failure points..."

        # Check if zsh config exists
        if [ ! -f "$HOME/.zshrc" ]; then
          echo "❌ Missing .zshrc - this is a key indicator"
        fi

        # Check chezmoi status for more details
        echo "📋 Chezmoi status:"
        ONEPASSWORD_AVAILABLE="$ONEPASSWORD_AVAILABLE" "$HOME/bin/chezmoi" status || echo "❌ Chezmoi status failed"
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
    echo "🔍 Applying updates with verbose output..."
    if ONEPASSWORD_AVAILABLE="$ONEPASSWORD_AVAILABLE" "$HOME/bin/chezmoi" apply --verbose; then
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
