#!/bin/bash

# Setup VSCode backup automation - runs once when applying chezmoi
# This is better as a chezmoi script since it's a one-time system setup

echo "🚀 Setting up VSCode backup automation (chezmoi one-time setup)..."

# Source the zsh functions we need
if [[ -f "$HOME/.config/zsh/functions/system/setup-vscode-automation.zsh" ]]; then
  source "$HOME/.config/zsh/functions/system/setup-vscode-automation.zsh"

  # Run the setup non-interactively
  echo "📋 Running automated setup..."

  # Load LaunchAgent
  if ! launchctl list | grep -q "com.user.vscode-backup"; then
    echo "🔄 Loading weekly backup LaunchAgent..."
    launchctl load ~/Library/LaunchAgents/com.user.vscode-backup.plist 2>/dev/null || {
      echo "⚠️  Could not load LaunchAgent automatically"
      echo "💡 Run 'launchctl load ~/Library/LaunchAgents/com.user.vscode-backup.plist' manually"
    }
  fi

  echo "✅ VSCode automation setup complete!"
  echo "💡 Use 'vscode-automation-status' to check status"
  echo "💡 Use 'setup-vscode-automation' for interactive setup"
else
  echo "❌ VSCode automation functions not found"
  echo "💡 Run 'chezmoi apply' to ensure all files are in place"
fi
