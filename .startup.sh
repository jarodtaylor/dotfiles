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

  # Install 1Password CLI first - needed for all subsequent checks
  onepassword_cli_installed=false
  if ! command -v op &>/dev/null; then
    echo "📥 Installing 1Password CLI..."
    brew install --cask 1password-cli
    onepassword_cli_installed=true
    echo "✅ 1Password CLI installed"
  else
    echo "✅ 1Password CLI already installed"
  fi

  # Check if 1Password app is installed
  onepassword_app_installed=false
  if ! ls /Applications/1Password\ *.app &>/dev/null; then
    echo "📥 Installing 1Password app..."
    brew install --cask 1password
    onepassword_app_installed=true
    echo "✅ 1Password app installed"
    echo "   Please set up 1Password app and add your account before continuing"
  else
    echo "✅ 1Password app already installed"
  fi

  # Function to check if 1Password is properly authenticated
  check_1password_auth() {
    local accounts
    accounts=$(op account list 2>/dev/null)
    if [[ -n "$accounts" && "$accounts" != *"No accounts configured"* ]]; then
      return 0
    else
      return 1
    fi
  }

  # If we just installed the app, user needs to set it up first
  if [[ $onepassword_app_installed == true ]]; then
    echo ""
    echo "🎯 1Password App Setup Required"
    echo "==============================="
    echo "Since we just installed 1Password app, you need to set it up first:"
    echo "1. Open 1Password app (it should launch automatically)"
    echo "2. Sign in to your 1Password account"
    echo "3. Complete the setup process"
    echo ""
    echo "Once you've signed in to the 1Password app, we can enable CLI integration."
    echo ""
    read -p "Press Enter when you've set up the 1Password app..."

    # Open 1Password app
    open -a "1Password 7 - Password Manager" 2>/dev/null || open -a "1Password" 2>/dev/null || true
  fi

  # If we just installed CLI or app, it definitely won't be authenticated yet
  if [[ $onepassword_cli_installed == true || $onepassword_app_installed == true ]]; then
    echo "🔑 New 1Password installation detected - authentication required"
    auth_needed=true
  elif check_1password_auth; then
    echo "✅ Already signed in to 1Password CLI"
    auth_needed=false
  else
    auth_needed=true
  fi

  if [[ $auth_needed == true ]]; then
    echo ""
    echo "🔑 1Password Authentication Required"
    echo "==================================="
    echo "You need to sign in to 1Password CLI to continue."
    echo "This will enable automatic SSH key management."
    echo ""

    # Re-check if app is available (may have been installed/launched since initial check)
    if ls /Applications/1Password\ *.app &>/dev/null; then
      echo "Choose your authentication method:"
      echo "1. Use 1Password app integration (recommended)"
      echo "2. Add account manually"
      echo ""

      read -p "Enter choice (1/2) [1]: " auth_choice
      auth_choice=${auth_choice:-1}

      if [[ $auth_choice == "1" ]]; then
        echo ""
        echo "🔗 Setting up 1Password app integration..."
        echo ""
        echo "📋 Steps to enable CLI integration:"
        echo "   1. Open 1Password app (if not already open)"
        echo "   2. Go to Settings → Developer"
        echo "   3. Turn on 'Integrate with 1Password CLI'"
        echo "   4. Optional: Turn on Touch ID for easy authentication"
        echo ""
        echo "💡 This allows the CLI to authenticate through the app instead of passwords"
        echo ""
        read -p "Press Enter when you've enabled CLI integration..."

        # Give a moment for the integration to activate
        echo "🔄 Testing CLI integration..."
        sleep 2

        # Test if integration works
        if check_1password_auth; then
          echo "✅ 1Password CLI integration working!"
        else
          echo "⚠️  CLI integration not detected. Let's try a different approach."
          echo ""
          echo "Choose how to proceed:"
          echo "1. Try again (maybe integration needs a moment to activate)"
          echo "2. Add account manually"
          echo "3. Skip 1Password integration"

          read -p "Enter choice (1/2/3) [1]: " retry_choice
          retry_choice=${retry_choice:-1}

          if [[ $retry_choice == "1" ]]; then
            echo "🔄 Retesting integration..."
            sleep 3
            if check_1password_auth; then
              echo "✅ 1Password CLI integration working!"
            else
              echo "❌ Still not working, falling back to manual setup..."
              op signin || {
                echo "⚠️  1Password setup failed"
                echo "   Continuing without 1Password integration..."
                export ONEPASSWORD_AVAILABLE=false
                echo ""
                read -p "Press Enter to continue..."
                return
              }
            fi
          elif [[ $retry_choice == "2" ]]; then
            echo "Adding 1Password account manually..."
            op account add && op signin || {
              echo "⚠️  Failed to add 1Password account"
              echo "   Continuing without 1Password integration..."
              export ONEPASSWORD_AVAILABLE=false
              echo ""
              read -p "Press Enter to continue..."
              return
            }
          else
            echo "⏭️  Skipping 1Password integration"
            export ONEPASSWORD_AVAILABLE=false
            return
          fi
        fi
      else
        echo "Adding 1Password account manually..."
        op account add && op signin || {
          echo "⚠️  Failed to add 1Password account"
          echo "   Continuing without 1Password integration..."
          export ONEPASSWORD_AVAILABLE=false
          echo ""
          read -p "Press Enter to continue..."
          return
        }
      fi
    else
      echo "❌ 1Password app not found"
      echo ""
      echo "The app may still be launching or wasn't installed properly."
      echo "Choose how to proceed:"
      echo "1. Wait and check again (app might still be starting)"
      echo "2. Add account manually"
      echo "3. Skip 1Password integration"

      read -p "Enter choice (1/2/3) [1]: " fallback_choice
      fallback_choice=${fallback_choice:-1}

             if [[ $fallback_choice == "1" ]]; then
         echo "⏳ Waiting 10 seconds for 1Password app to launch..."
         sleep 10
         if ls /Applications/1Password\ *.app &>/dev/null; then
           echo "✅ 1Password app found! Proceeding with app integration..."
           echo ""
           echo "📋 Steps to enable CLI integration:"
           echo "   1. Open 1Password app (if not already open)"
           echo "   2. Go to Settings → Developer"
           echo "   3. Turn on 'Integrate with 1Password CLI'"
           echo "   4. Optional: Turn on Touch ID for easy authentication"
           echo ""
           read -p "Press Enter when you've enabled CLI integration..."

           if check_1password_auth; then
             echo "✅ 1Password CLI integration working!"
           else
             echo "❌ Integration still not working, falling back to manual setup"
             op account add && op signin || {
               echo "⚠️  Failed to add 1Password account"
               export ONEPASSWORD_AVAILABLE=false
               echo ""
               read -p "Press Enter to continue..."
               return
             }
           fi
         else
           echo "❌ App still not found, falling back to manual setup"
           op account add && op signin || {
             echo "⚠️  Failed to add 1Password account"
             export ONEPASSWORD_AVAILABLE=false
             echo ""
             read -p "Press Enter to continue..."
             return
           }
         fi
      elif [[ $fallback_choice == "2" ]]; then
        echo "Adding 1Password account manually..."
        op account add && op signin || {
          echo "⚠️  Failed to add 1Password account"
          echo "   Continuing without 1Password integration..."
          export ONEPASSWORD_AVAILABLE=false
          echo ""
          read -p "Press Enter to continue..."
          return
        }
      else
        echo "⏭️  Skipping 1Password integration"
        export ONEPASSWORD_AVAILABLE=false
        return
      fi
    fi
  fi

  # Verify 1Password is working and test SSH key access
  if check_1password_auth; then
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

    echo "🔍 Applying configuration with chezmoi..."
    # Apply the configuration with clean output for automation
    # Use CHEZMOI_DEBUG=1 environment variable for verbose output when needed
    if [[ ${CHEZMOI_DEBUG:-0} == 1 ]]; then
      echo "🔍 Debug mode enabled - showing verbose output..."
      ONEPASSWORD_AVAILABLE="$ONEPASSWORD_AVAILABLE" "$HOME/bin/chezmoi" init --apply --verbose jarodtaylor
    else
      ONEPASSWORD_AVAILABLE="$ONEPASSWORD_AVAILABLE" "$HOME/bin/chezmoi" init --apply jarodtaylor
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
          ONEPASSWORD_AVAILABLE="$ONEPASSWORD_AVAILABLE" "$HOME/bin/chezmoi" status || echo "❌ Chezmoi status failed"
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
      ONEPASSWORD_AVAILABLE="$ONEPASSWORD_AVAILABLE" "$HOME/bin/chezmoi" apply --verbose
    else
      ONEPASSWORD_AVAILABLE="$ONEPASSWORD_AVAILABLE" "$HOME/bin/chezmoi" apply
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
