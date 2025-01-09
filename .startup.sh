#!/bin/bash

set -eo pipefail

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

# Install 1Password CLI using Homebrew
if ! command -v op &>/dev/null; then
  echo "Installing 1Password CLI..."
  brew install --cask 1password/tap/1password-cli
fi

# Run Chezmoi to apply dotfiles
if command -v chezmoi &>/dev/null; then
  echo "Reapplying chezmoi configuration..."
  chezmoi state delete && chezmoi init && chezmoi apply
else
  echo "Chezmoi is not installed. Installing Chezmoi and applying dotfiles..."
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --verbose --apply jarodtaylor
fi


