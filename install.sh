#!/usr/bin/env bash
# -*-mode:sh-*- vim:ft=sh

set -eo pipefail

# Install Xcode Command Line Tools first (required for git)
echo "🛠️  Checking for Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
  echo "📥 Installing Xcode Command Line Tools..."
  echo "   This is required for git and other developer tools"

  # Install command line tools
  xcode-select --install

  echo "⏳ Waiting for Xcode Command Line Tools installation to complete..."
  echo "   You may see a system dialog - please click 'Install' if it appears"

  # Wait for installation to complete
  while ! xcode-select -p &>/dev/null; do
    echo "   Still installing... (this can take 5-10 minutes)"
    sleep 30
  done

  echo "✅ Xcode Command Line Tools installed successfully"
else
  echo "✅ Xcode Command Line Tools already installed"
fi

echo ""
echo "🚀 Installing chezmoi and applying dotfiles..."

# Now install and run chezmoi with correct branch syntax
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --verbose --apply --branch refactor-simplify jarodtaylor

