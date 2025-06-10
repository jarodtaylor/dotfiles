# vscode-backup-reminder - Smart reminder for VSCode/Cursor backup
#
# Tags: vscode, cursor, backup, reminder, automation
#
# Purpose: Check if VSCode settings have changed and remind user to backup
# Usage: Called automatically in zsh startup or manually
#
# Shows reminders based on:
# - Time since last backup
# - Whether settings have changed since last backup
# - Configurable reminder intervals

vscode-backup-reminder() {
  local chezmoi_source="$HOME/.local/share/chezmoi"
  local vscode_user="$HOME/.config/Code/User"
  local chezmoi_vscode="$chezmoi_source/home/dot_config/Code/User"
  local reminder_file="$HOME/.cache/vscode-backup-reminder"

  # Don't show reminder more than once per day
  if [[ -f "$reminder_file" ]]; then
    local last_reminder=$(cat "$reminder_file" 2>/dev/null || echo "0")
    local now=$(date +%s)
    local one_day=86400

    if (( now - last_reminder < one_day )); then
      return 0
    fi
  fi

  # Check if VSCode directory exists
  [[ ! -d "$vscode_user" ]] && return 0

  # Check when last backup was made
  local last_backup=0
  if [[ -f "$chezmoi_vscode/settings.json" ]]; then
    last_backup=$(stat -f %m "$chezmoi_vscode/settings.json" 2>/dev/null || echo "0")
  fi

  local now=$(date +%s)
  local days_since_backup=$(( (now - last_backup) / 86400 ))

  # Check if current settings are different from backup
  local settings_changed=false
  if [[ -f "$vscode_user/settings.json" && -f "$chezmoi_vscode/settings.json" ]]; then
    if ! diff -q "$vscode_user/settings.json" "$chezmoi_vscode/settings.json" >/dev/null 2>&1; then
      settings_changed=true
    fi
  elif [[ -f "$vscode_user/settings.json" && ! -f "$chezmoi_vscode/settings.json" ]]; then
    settings_changed=true
  fi

  # Show reminder based on conditions
  local should_remind=false
  local reminder_message=""

  if [[ "$settings_changed" == "true" ]] && (( days_since_backup > 3 )); then
    should_remind=true
    reminder_message="⚠️  VSCode settings have changed and haven't been backed up in $days_since_backup days"
  elif (( days_since_backup > 14 )); then
    should_remind=true
    reminder_message="🕰️  It's been $days_since_backup days since your last VSCode backup"
  elif [[ "$settings_changed" == "true" ]] && (( days_since_backup > 1 )); then
    should_remind=true
    reminder_message="💡 VSCode settings have changed since your last backup ($days_since_backup days ago)"
  fi

  if [[ "$should_remind" == "true" ]]; then
    echo ""
    echo "┌─ VSCode Backup Reminder ─────────────────────────────────────────────┐"
    echo "│ $reminder_message"
    echo "│"
    echo "│ Commands:"
    echo "│   vscode-backup           # Backup current settings"
    echo "│   vscode-backup-status    # Check backup status"
    echo "│   vscode-backup-auto off  # Disable reminders"
    echo "└───────────────────────────────────────────────────────────────────────┘"
    echo ""

    # Record that we showed a reminder
    mkdir -p "$(dirname "$reminder_file")"
    echo "$now" > "$reminder_file"
  fi
}

# vscode-backup-status - Show backup status information
vscode-backup-status() {
  local chezmoi_source="$HOME/.local/share/chezmoi"
  local vscode_user="$HOME/.config/Code/User"
  local chezmoi_vscode="$chezmoi_source/home/dot_config/Code/User"

  echo "📊 VSCode Backup Status"
  echo "========================"

  if [[ ! -d "$vscode_user" ]]; then
    echo "❌ VSCode User directory not found"
    return 1
  fi

  if [[ ! -d "$chezmoi_vscode" ]]; then
    echo "❌ No backup found - run 'vscode-backup' to create initial backup"
    return 1
  fi

  # Check last backup date
  if [[ -f "$chezmoi_vscode/settings.json" ]]; then
    local last_backup_date=$(stat -f %Sm -t "%Y-%m-%d %H:%M" "$chezmoi_vscode/settings.json" 2>/dev/null)
    echo "📅 Last backup: $last_backup_date"
  else
    echo "❌ No settings.json backup found"
  fi

  # Check if files have changed
  echo ""
  echo "📋 File Status:"

  for file in settings.json keybindings.json; do
    if [[ -f "$vscode_user/$file" && -f "$chezmoi_vscode/$file" ]]; then
      if diff -q "$vscode_user/$file" "$chezmoi_vscode/$file" >/dev/null 2>&1; then
        echo "  ✅ $file: up to date"
      else
        echo "  ⚠️  $file: CHANGED since backup"
      fi
    elif [[ -f "$vscode_user/$file" ]]; then
      echo "  🆕 $file: exists but not backed up"
    elif [[ -f "$chezmoi_vscode/$file" ]]; then
      echo "  🗑️  $file: backed up but deleted locally"
    fi
  done

  # Extensions comparison
  if command -v code >/dev/null 2>&1; then
    local current_extensions=$(mktemp)
    local backed_extensions="$chezmoi_vscode/extensions-list.txt"

    code --list-extensions > "$current_extensions"

    if [[ -f "$backed_extensions" ]]; then
      local current_count=$(wc -l < "$current_extensions")
      local backed_count=$(wc -l < "$backed_extensions")

      if diff -q "$current_extensions" "$backed_extensions" >/dev/null 2>&1; then
        echo "  ✅ extensions: up to date ($current_count extensions)"
      else
        echo "  ⚠️  extensions: CHANGED since backup (current: $current_count, backed up: $backed_count)"
      fi
    else
      echo "  🆕 extensions: not backed up yet"
    fi

    rm "$current_extensions"
  fi
}

# vscode-backup-auto - Control automatic reminders
vscode-backup-auto() {
  local config_file="$HOME/.config/vscode-backup-config"

  case "$1" in
    "off"|"disable")
      echo "REMINDERS_DISABLED=true" > "$config_file"
      echo "🔕 VSCode backup reminders disabled"
      echo "💡 Run 'vscode-backup-auto on' to re-enable"
      ;;
    "on"|"enable")
      echo "REMINDERS_DISABLED=false" > "$config_file"
      echo "🔔 VSCode backup reminders enabled"
      ;;
    "status")
      if [[ -f "$config_file" ]] && grep -q "REMINDERS_DISABLED=true" "$config_file"; then
        echo "🔕 Reminders are currently DISABLED"
      else
        echo "🔔 Reminders are currently ENABLED"
      fi
      ;;
    *)
      echo "Usage: vscode-backup-auto [on|off|status]"
      echo ""
      echo "Commands:"
      echo "  on      Enable automatic reminders"
      echo "  off     Disable automatic reminders"
      echo "  status  Show current reminder status"
      ;;
  esac
}

# Check if reminders are disabled
_vscode_backup_reminders_enabled() {
  local config_file="$HOME/.config/vscode-backup-config"

  if [[ -f "$config_file" ]] && grep -q "REMINDERS_DISABLED=true" "$config_file"; then
    return 1
  fi

  return 0
}

# Auto-run reminder on shell startup (with throttling)
if _vscode_backup_reminders_enabled; then
  # Only run reminder 1 in 5 times to avoid being annoying
  if (( RANDOM % 5 == 0 )); then
    vscode-backup-reminder
  fi
fi
