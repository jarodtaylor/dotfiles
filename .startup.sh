#!/bin/bash

set -eo pipefail

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

# Check if Homebrew is installed
is_brew_installed() {
  [ -d "/opt/homebrew" ] || [ -d "/usr/local/Homebrew" ]
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

# Install Homebrew if it is not installed or not in the PATH
if is_brew_installed && is_brew_path_set; then
  echo "Homebrew is installed and in the PATH."
elif is_brew_installed && ! is_brew_path_set; then
  echo "Homebrew is installed but not in the PATH."
  set_brew_path
else
  echo "Homebrew is not installed. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  set_brew_path
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
if command -v chezmoi &>/dev/null && [ -d "$HOME/.local/share/chezmoi" ]; then
  if prompt_yn "Chezmoi is already installed. Reapply configuration?" "y"; then
    echo "Reapplying chezmoi configuration..."
    chezmoi apply
  else
    echo "Skipping Chezmoi configuration."
  fi
else
  echo "Chezmoi is not fully set up. Installing and applying configuration..."
  install_and_apply_chezmoi
fi
