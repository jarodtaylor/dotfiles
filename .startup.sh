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
# 1PASSWORD SETUP & AUTHENTICATION        #
# ##########################################

echo ""
echo "🔐 1Password Integration Setup"
echo "=============================="
echo "1Password CLI can securely manage your SSH keys and other secrets."
echo "This is completely optional but provides the best security experience."
echo ""

read -p "Will you be using 1Password for SSH key management? (y/n) [y]: " use_1password
use_1password=${use_1password:-y}

if [[ $use_1password =~ ^[Yy]$ ]]; then
  echo ""
  echo "🔧 Setting up 1Password integration..."

  # Install 1Password CLI if needed
  if ! command -v op &>/dev/null; then
    echo "📥 Installing 1Password CLI..."
    brew install --cask 1password-cli
    echo "✅ 1Password CLI installed"
  else
    echo "✅ 1Password CLI already installed"
  fi

  # Check if already signed in
  if op account list &>/dev/null; then
    echo "✅ Already signed in to 1Password CLI"
  else
    echo ""
    echo "🔑 1Password Authentication Required"
    echo "==================================="
    echo "You need to sign in to 1Password CLI to continue."
    echo "This will enable automatic SSH key management."
    echo ""
    echo "Choose your authentication method:"
    echo "1. Use 1Password app integration (recommended)"
    echo "2. Add account manually"
    echo ""

    read -p "Enter choice (1/2) [1]: " auth_choice
    auth_choice=${auth_choice:-1}

    if [[ $auth_choice == "1" ]]; then
      echo ""
      echo "Please enable 1Password CLI integration in your 1Password app:"
      echo "• Open 1Password app"
      echo "• Go to Settings > Developer"
      echo "• Enable 'Integrate with 1Password CLI'"
      echo ""
      read -p "Press Enter when you've enabled CLI integration..."

      # Test if integration works
      if op account list &>/dev/null; then
        echo "✅ 1Password CLI integration working"
      else
        echo "❌ CLI integration not working, trying manual signin..."
        op signin || {
          echo "⚠️  1Password setup failed"
          echo "   Continuing without 1Password integration..."
          export ONEPASSWORD_AVAILABLE=false
          echo ""
          read -p "Press Enter to continue..."
        }
      fi
    else
      echo "Adding 1Password account manually..."
      op account add || {
        echo "⚠️  Failed to add 1Password account"
        echo "   Continuing without 1Password integration..."
        export ONEPASSWORD_AVAILABLE=false
        echo ""
        read -p "Press Enter to continue..."
      }
    fi
  fi

  # Verify 1Password is working and test SSH key access
  if op account list &>/dev/null; then
    echo ""
    echo "🧪 Testing 1Password SSH key access..."

    # Test if we can read the SSH keys
    if op read "op://Personal/4ytcjbe2ui6iz5sjfe7fn54jea/public_key" &>/dev/null; then
      echo "✅ Personal SSH key accessible"
      personal_key_ok=true
    else
      echo "⚠️  Personal SSH key not found in 1Password"
      personal_key_ok=false
    fi

    if op read "op://Personal/orsplwhcmkbfmxdwbf6udvpjvu/public_key" &>/dev/null; then
      echo "✅ Work SSH key accessible"
      work_key_ok=true
    else
      echo "⚠️  Work SSH key not found in 1Password"
      work_key_ok=false
    fi

    if [[ $personal_key_ok == true && $work_key_ok == true ]]; then
      echo "🎉 1Password SSH integration fully configured!"
      export ONEPASSWORD_AVAILABLE=true
    else
      echo ""
      echo "⚠️  Some SSH keys missing from 1Password"
      echo "   You can add them later or continue with manual SSH key generation"
      read -p "Continue with 1Password anyway? (y/n) [n]: " continue_anyway
      continue_anyway=${continue_anyway:-n}

      if [[ $continue_anyway =~ ^[Yy]$ ]]; then
        export ONEPASSWORD_AVAILABLE=true
      else
        export ONEPASSWORD_AVAILABLE=false
      fi
    fi
  else
    echo "❌ 1Password authentication failed"
    export ONEPASSWORD_AVAILABLE=false
  fi
else
  echo "⏭️  Skipping 1Password setup"
  export ONEPASSWORD_AVAILABLE=false
fi

echo ""
if [[ $ONEPASSWORD_AVAILABLE == true ]]; then
  echo "✅ 1Password integration: ENABLED"
  echo "   SSH keys will be managed automatically"
else
  echo "⚠️  1Password integration: DISABLED"
  echo "   SSH keys will be generated manually during setup"
fi
echo ""

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
