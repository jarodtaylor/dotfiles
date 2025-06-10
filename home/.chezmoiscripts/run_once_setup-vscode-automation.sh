#!/bin/bash

# Setup VSCode backup automation - runs once when applying chezmoi
# This is a self-contained script that doesn't depend on zsh functions

echo "🚀 Setting up VSCode backup automation (chezmoi one-time setup)..."

# Load LaunchAgent for weekly backups
echo "⏰ Setting up weekly automated backups..."

if launchctl list | grep -q "com.user.vscode-backup"; then
  echo "✅ Weekly backup job already running"
else
  echo "🔄 Loading weekly backup LaunchAgent..."
  if launchctl load ~/Library/LaunchAgents/com.user.vscode-backup.plist 2>/dev/null; then
    echo "✅ Weekly backup job loaded successfully"
    echo "📅 Automated backup schedule: Sundays at 6:00 PM"
  else
    echo "⚠️  Could not load LaunchAgent automatically"
    echo "💡 Manual fix: launchctl load ~/Library/LaunchAgents/com.user.vscode-backup.plist"
  fi
fi

# Check if we can create an initial backup
echo ""
echo "🧩 Checking VSCode installation..."

if [[ -d "$HOME/.config/Code/User" ]]; then
  echo "✅ VSCode User directory found"

  # Create backup directory if it doesn't exist
  mkdir -p "$HOME/.local/share/chezmoi/home/dot_config/Code/User"

  if command -v code >/dev/null 2>&1; then
    echo "✅ VSCode CLI available"
  else
    echo "⚠️  VSCode CLI 'code' not found - extension backup may not work"
  fi
else
  echo "ℹ️  VSCode User directory not found yet - no problem, it will be created when you first use VSCode"
fi

echo ""
echo "✅ VSCode automation setup complete!"
echo ""
echo "🎯 What's been set up:"
echo "  📅 Weekly automated backup: Sundays at 6:00 PM"
echo "  🪝 Git hooks: Will be installed when you commit in dev repos"
echo "  🔔 Smart reminders: Will show when you start terminal sessions"
echo ""
echo "💡 Next steps:"
echo "  • Run 'vscode-backup' to create your first manual backup"
echo "  • Run 'vscode-automation-status' to check everything is working"
echo "  • The system will automatically backup VSCode settings weekly"
