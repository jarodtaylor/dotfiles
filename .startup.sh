#!/bin/bash

set -o pipefail

# ##########################################
# PREREQUISITES & ASSUMPTIONS              #
# ##########################################
echo "🏠 Jarod's Dotfiles Setup"
echo "========================="
echo ""
echo "⚠️  PREREQUISITES:"
echo "   • 1Password app installed and authenticated"
echo "   • Internet connection"
echo "   • Admin privileges (sudo access)"
echo ""
echo "🎯 This script will install:"
echo "   • Xcode Command Line Tools"
echo "   • Homebrew"
echo "   • 1Password CLI"
echo "   • Chezmoi + full dotfiles configuration"
echo ""
read -p "Press ENTER to continue or Ctrl+C to abort..."
echo ""

# Check if running in interactive mode
if [ ! -t 0 ]; then
  echo "Error: This script is being run in non-interactive mode."
  echo "This can happen when piping the script directly to bash."
  echo ""
  echo "Please run the script using this command instead:"
  echo 'bash -c "$(curl -sfL https://raw.githubusercontent.com/jarodtaylor/dotfiles/main/.startup.sh)"'
  echo ""
  echo "This will ensure proper TTY handling for sudo prompts and interactive elements."
  exit 1
fi

# Function to prompt for yes/no
prompt_yn() {
  local prompt="$1"
  local default="$2"
  local response

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
# INSTALL PREREQUISITES                    #
# ##########################################

echo "Installing required dependencies for dotfiles..."

# Install 1Password CLI (hard dependency)
if ! command -v op &>/dev/null; then
  echo "Installing 1Password CLI..."
  brew install --cask 1password-cli
else
  echo "1Password CLI already installed"
fi

# ##########################################
# INSTALL CHEZMOI AND APPLY DOTFILES       #
# ##########################################

# Function to install and apply Chezmoi
install_and_apply_chezmoi() {
  echo "Installing Chezmoi and applying dotfiles..."
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply jarodtaylor
}

# Run Chezmoi to apply dotfiles
if command -v chezmoi &>/dev/null && [ -d "$HOME/.local/share/chezmoi" ] && chezmoi status &>/dev/null; then
  if prompt_yn "Chezmoi is already installed and initialized. Reapply configuration?" "y"; then
    echo "Reapplying chezmoi configuration..."
    chezmoi apply
  else
    echo "Skipping Chezmoi configuration."
  fi
else
  if command -v chezmoi &>/dev/null; then
    echo "Chezmoi command exists but repository not properly initialized. Reinitializing..."
  else
    echo "Chezmoi is not installed. Installing and applying configuration..."
  fi
  install_and_apply_chezmoi
fi
