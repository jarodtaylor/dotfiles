# vscode-backup - Backup current VSCode/Cursor settings to chezmoi
#
# Tags: vscode, cursor, backup, chezmoi, settings, sync
#
# Purpose: Manually backup current VSCode/Cursor settings to chezmoi repository
# Usage: vscode-backup
#
# What it does:
# 1. Copies current VSCode/Cursor settings from ~/.config/Code/User/ to chezmoi
# 2. Updates the chezmoi repository with current state
# 3. Allows you to restore settings later if needed
#
# Examples:
#   vscode-backup          # Backup current settings
#   vscode-restore         # Restore settings from chezmoi (companion function)

vscode-backup() {
  local chezmoi_source="$HOME/.local/share/chezmoi"
  local vscode_user="$HOME/.config/Code/User"
  local chezmoi_vscode="$chezmoi_source/home/dot_config/Code/User"

  echo "🔄 Backing up VSCode/Cursor settings to chezmoi..."

  # Check if VSCode User directory exists
  if [[ ! -d "$vscode_user" ]]; then
    echo "❌ VSCode User directory not found: $vscode_user"
    return 1
  fi

  # Create chezmoi directory if it doesn't exist
  mkdir -p "$chezmoi_vscode"

  # Copy current settings
  echo "📋 Copying settings.json..."
  cp "$vscode_user/settings.json" "$chezmoi_vscode/settings.json" 2>/dev/null || echo "⚠️  settings.json not found"

  echo "⌨️  Copying keybindings.json..."
  cp "$vscode_user/keybindings.json" "$chezmoi_vscode/keybindings.json" 2>/dev/null || echo "⚠️  keybindings.json not found"

  echo "🧩 Copying extensions list..."
  if command -v code >/dev/null 2>&1; then
    code --list-extensions >! "$chezmoi_vscode/extensions-list.txt"
    echo "✅ Extensions list updated"
  else
    echo "⚠️  'code' command not found, skipping extensions list"
  fi

  echo "📝 Copying snippets..."
  if [[ -d "$vscode_user/snippets" ]]; then
    cp -r "$vscode_user/snippets" "$chezmoi_vscode/" 2>/dev/null
    echo "✅ Snippets copied"
  else
    echo "⚠️  No snippets directory found"
  fi

  echo ""
  echo "✅ Backup complete! Files saved to:"
  echo "   $chezmoi_vscode"
  echo ""
  echo "💡 Tip: Now commit your changes with:"
  echo "   cd $chezmoi_source && git add . && git commit -m 'Update VSCode settings'"
}

# vscode-restore - Restore VSCode/Cursor settings from chezmoi
vscode-restore() {
  local chezmoi_source="$HOME/.local/share/chezmoi"
  local vscode_user="$HOME/.config/Code/User"
  local chezmoi_vscode="$chezmoi_source/home/dot_config/Code/User"

  echo "🔄 Restoring VSCode/Cursor settings from chezmoi..."

  # Check if chezmoi backup exists
  if [[ ! -d "$chezmoi_vscode" ]]; then
    echo "❌ No VSCode backup found in chezmoi: $chezmoi_vscode"
    echo "💡 Run 'vscode-backup' first to create a backup"
    return 1
  fi

  # Create VSCode User directory if it doesn't exist
  mkdir -p "$vscode_user"

  # Restore settings
  echo "📋 Restoring settings.json..."
  cp "$chezmoi_vscode/settings.json" "$vscode_user/settings.json" 2>/dev/null && echo "✅ settings.json restored" || echo "⚠️  settings.json not found in backup"

  echo "⌨️  Restoring keybindings.json..."
  cp "$chezmoi_vscode/keybindings.json" "$vscode_user/keybindings.json" 2>/dev/null && echo "✅ keybindings.json restored" || echo "⚠️  keybindings.json not found in backup"

  echo "🧩 Installing extensions..."
  if [[ -f "$chezmoi_vscode/extensions-list.txt" ]] && command -v code >/dev/null 2>&1; then
    while read -r extension; do
      [[ -n "$extension" ]] && code --install-extension "$extension" --force
    done < "$chezmoi_vscode/extensions-list.txt"
    echo "✅ Extensions installed"
  else
    echo "⚠️  Extensions list not found or 'code' command not available"
  fi

  echo "📝 Restoring snippets..."
  if [[ -d "$chezmoi_vscode/snippets" ]]; then
    cp -r "$chezmoi_vscode/snippets" "$vscode_user/" 2>/dev/null
    echo "✅ Snippets restored"
  else
    echo "⚠️  No snippets found in backup"
  fi

  echo ""
  echo "✅ Restore complete!"
  echo "💡 Restart VSCode/Cursor to see all changes"
}
