#!/bin/bash

# Install VSCode backup hooks in development repositories
# This runs once when setting up a new machine with chezmoi

echo "🪝 Installing VSCode backup git hooks in development directories..."

# Define common development directories
DEV_DIRS=(
  "$HOME/Code"
  "$HOME/Projects"
  "$HOME/Development"
  "$HOME/dev"
  "$HOME/src"
  "$HOME/workspace"
)

# Function to install hook in a single repo
install_hook_in_repo() {
  local repo_path="$1"
  local hooks_dir="$repo_path/.git/hooks"
  local post_commit_hook="$hooks_dir/post-commit"

  # Create hooks directory if it doesn't exist
  mkdir -p "$hooks_dir"

  # Check if our hook is already installed
  if [[ -f "$post_commit_hook" ]] && grep -q "VSCode backup hook" "$post_commit_hook"; then
    return 0  # Already installed
  fi

  # Create or append to post-commit hook
  if [[ -f "$post_commit_hook" ]]; then
    echo "" >> "$post_commit_hook"
  else
    echo "#!/bin/bash" > "$post_commit_hook"
    echo "" >> "$post_commit_hook"
  fi

  # Add our hook code
  cat >> "$post_commit_hook" << 'HOOK_EOF'
# VSCode backup hook - Auto-backup settings after commits
# Added by chezmoi setup

# Only run if we have zsh and the backup function
if command -v zsh >/dev/null 2>&1 && [[ -f "$HOME/.config/zsh/functions/system/vscode-backup.zsh" ]]; then
  # Throttle: only backup once per hour max
  BACKUP_THROTTLE_FILE="$HOME/.cache/vscode-backup-git-throttle"
  CURRENT_TIME=$(date +%s)
  THROTTLE_PERIOD=3600  # 1 hour

  SHOULD_BACKUP=true
  if [[ -f "$BACKUP_THROTTLE_FILE" ]]; then
    LAST_BACKUP=$(cat "$BACKUP_THROTTLE_FILE" 2>/dev/null || echo "0")
    if (( CURRENT_TIME - LAST_BACKUP < THROTTLE_PERIOD )); then
      SHOULD_BACKUP=false
    fi
  fi

  if [[ "$SHOULD_BACKUP" == "true" ]]; then
    echo "🔄 Auto-backing up VSCode settings..."
    zsh -c "source ~/.zshrc && vscode-backup && cd ~/.local/share/chezmoi && git add . && git commit -m 'Auto-backup VSCode settings after commit in $(basename $(pwd))' >/dev/null 2>&1"

    # Update throttle file
    mkdir -p "$(dirname "$BACKUP_THROTTLE_FILE")"
    echo "$CURRENT_TIME" > "$BACKUP_THROTTLE_FILE"

    echo "✅ VSCode settings backed up automatically"
  fi
fi
HOOK_EOF

  # Make executable
  chmod +x "$post_commit_hook"

  return 1  # Newly installed
}

# Install hooks in development directories
INSTALLED_COUNT=0

for dev_dir in "${DEV_DIRS[@]}"; do
  if [[ -d "$dev_dir" ]]; then
    echo "📁 Scanning: $dev_dir"

    # Find git repos in this directory (max depth 2)
    while IFS= read -r -d '' repo; do
      repo_dir="$(dirname "$repo")"
      repo_name="$(basename "$repo_dir")"

      if install_hook_in_repo "$repo_dir"; then
        echo "  ✅ $repo_name (already had hook)"
      else
        echo "  🆕 $repo_name (hook installed)"
        ((INSTALLED_COUNT++))
      fi
    done < <(find "$dev_dir" -maxdepth 2 -name ".git" -type d -print0 2>/dev/null)
  fi
done

if (( INSTALLED_COUNT > 0 )); then
  echo ""
  echo "✅ Installed VSCode backup hooks in $INSTALLED_COUNT new repositories"
  echo "💡 Hooks will auto-backup VSCode settings after commits (max once/hour)"
else
  echo ""
  echo "ℹ️  No new repositories found or all already have hooks installed"
fi

echo "🎉 VSCode backup hooks setup complete!"
