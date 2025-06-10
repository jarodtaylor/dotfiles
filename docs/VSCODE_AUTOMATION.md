# VSCode Backup Automation

This repository includes a sophisticated three-layer automation system for backing up VSCode settings to your dotfiles repository.

## 🎯 Philosophy

The VSCode automation follows the "state keeper" philosophy:

- **VSCode manages day-to-day settings** - Live configuration that changes as you work
- **Dotfiles provide disaster recovery** - Foundational settings restored after system wipes
- **Smart automation bridges the gap** - Periodic backups of important changes

## 📋 Three-Layer Automation

### 1. ⏰ Weekly Automated Backup (LaunchAgent)

**File**: `home/Library/LaunchAgents/com.user.vscode-backup.plist`
**Schedule**: Every Sunday at 6:00 PM
**Purpose**: Automatic weekly backup without user intervention

```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Weekday</key>
    <integer>0</integer> <!-- Sunday -->
    <key>Hour</key>
    <integer>18</integer> <!-- 6 PM -->
</dict>
```

**What it backs up**:

- Settings (`settings.json`)
- Keybindings (`keybindings.json`)
- Code snippets (`snippets/`)
- Extension list (`extensions-list.txt`)

### 2. 🔔 Smart Terminal Reminders

**File**: `home/dot_config/zsh/functions/system/vscode-backup-reminder.zsh`
**Trigger**: Runs automatically when starting new terminal sessions
**Intelligence**: Shows reminders based on multiple conditions

**Reminder Logic**:

```bash
# Show reminder if:
# 1. Settings changed + 3+ days since backup, OR
# 2. 14+ days since any backup, OR
# 3. Settings changed + 1+ day since backup

# Throttling:
# - Max once per day per reminder type
# - Only 1 in 5 terminal sessions (to avoid spam)
```

**User Control**:

- `vscode-backup-auto off` - Disable reminders
- `vscode-backup-auto on` - Re-enable reminders
- Reminders respect user preferences and don't spam

### 3. 🪝 Git Hook Integration

**File**: `.chezmoiscripts/run_once_install-vscode-backup-hooks.sh`
**Purpose**: Auto-trigger backups after commits in development repositories
**Scope**: Scans common dev directories (`~/Code`, `~/Projects`, etc.)

**Hook Behavior**:

- Runs after **any** commit in development repos
- Throttled to maximum once per hour
- Creates VSCode backup and commits to dotfiles repo
- Only activates if zsh functions are available

## 🛠 Manual Commands

All manual backup/restore commands are available via zsh functions:

```bash
# Manual backup
vscode-backup                    # Backup all VSCode settings

# Status checking
vscode-backup-status            # Check if settings have changed
vscode-backup-status --detailed # Show file-by-file comparison

# Restore from backup
vscode-restore                  # Restore settings from dotfiles
vscode-restore-extensions       # Reinstall extensions from list

# Automation control
vscode-backup-auto off          # Disable reminder system
vscode-backup-auto on           # Enable reminder system
vscode-automation-status        # Check automation health
```

## 📁 Backed Up Files

The system backs up these VSCode configuration files:

```
~/.config/Code/User/
├── settings.json          → home/dot_config/Code/User/settings.json
├── keybindings.json       → home/dot_config/Code/User/keybindings.json
├── extensions-list.txt    → home/dot_config/Code/User/extensions-list.txt
└── snippets/              → home/dot_config/Code/User/snippets/
    └── *.code-snippets
```

**Not Backed Up** (intentionally in `.chezmoiignore`):

- Live workspace state
- Recently opened files
- Temporary preferences
- Cache and session data

## 🔧 Setup Process

### Automatic Setup (via chezmoi)

When applying dotfiles, the system automatically:

1. **Creates LaunchAgent** (`run_once_setup-vscode-automation.sh`)

   - Copies plist file to `~/Library/LaunchAgents/`
   - Loads the agent for immediate activation
   - Verifies VSCode installation

2. **Installs Git Hooks** (`run_once_install-vscode-backup-hooks.sh`)

   - Scans development directories
   - Installs post-commit hooks in git repositories
   - Preserves existing hooks

3. **Activates Reminders**
   - Smart reminder system activates automatically
   - Respects user preferences and throttling

### Manual Setup

If you need to set up manually:

```bash
# Load LaunchAgent
launchctl load ~/Library/LaunchAgents/com.user.vscode-backup.plist

# Install git hooks (run from dotfiles directory)
./.chezmoiscripts/run_once_install-vscode-backup-hooks.sh

# Create initial backup
source ~/.zshrc
vscode-backup
```

## 🎛 Configuration

### LaunchAgent Customization

Edit `home/Library/LaunchAgents/com.user.vscode-backup.plist`:

```xml
<!-- Change schedule (example: daily at 9 PM) -->
<key>StartCalendarInterval</key>
<dict>
    <key>Hour</key>
    <integer>21</integer>
    <key>Minute</key>
    <integer>0</integer>
</dict>
```

### Reminder Frequency

Edit reminder logic in `vscode-backup-reminder.zsh`:

```bash
# Change reminder frequency (currently 1 in 5 sessions)
if (( RANDOM % 5 == 0 )); then

# Change reminder thresholds
MAJOR_THRESHOLD_DAYS=14        # Force reminder after 14 days
CHANGE_THRESHOLD_DAYS=3        # Remind after 3 days if changed
```

### Git Hook Throttling

Modify throttle period in hook installation script:

```bash
THROTTLE_PERIOD=3600  # 1 hour (3600 seconds)
```

## 🔍 Troubleshooting

### LaunchAgent Not Running

```bash
# Check if loaded
launchctl list | grep vscode-backup

# Reload if necessary
launchctl unload ~/Library/LaunchAgents/com.user.vscode-backup.plist
launchctl load ~/Library/LaunchAgents/com.user.vscode-backup.plist

# Check logs
cat /tmp/vscode-backup.log
cat /tmp/vscode-backup-error.log
```

### Reminders Not Showing

```bash
# Check if disabled
vscode-backup-auto status

# Re-enable if needed
vscode-backup-auto on

# Check throttle files
ls -la ~/.cache/vscode-backup-*
```

### Git Hooks Not Working

```bash
# Check if hooks are installed
find ~/Code -name "post-commit" -exec grep -l "VSCode backup hook" {} \;

# Reinstall hooks
./.chezmoiscripts/run_once_install-vscode-backup-hooks.sh

# Check throttle status
cat ~/.cache/vscode-backup-git-throttle
```

### Functions Not Available

```bash
# Source zsh configuration
source ~/.zshrc

# Check if functions are loaded
which vscode-backup

# Manually source if needed
source ~/.config/zsh/functions/system/vscode-backup.zsh
```

## 🎨 Customization

### Different Backup Schedule

Modify the LaunchAgent plist file to change when automatic backups occur:

- **Daily**: Remove `<key>Weekday</key>` section
- **Workdays only**: Set `<key>Weekday</key>` to 1-5
- **Multiple times**: Create multiple `StartCalendarInterval` dicts

### Additional Files

To backup additional VSCode files, modify the backup function:

```bash
# In vscode-backup.zsh, add to the backup list:
cp "$VSCODE_USER_DIR/additional-file.json" "$BACKUP_DIR/"
```

### Different VSCode Variants

For Cursor, VSCode Insiders, or other variants:

```bash
# Update paths in backup functions
VSCODE_USER_DIR="$HOME/.config/Cursor/User"  # For Cursor
VSCODE_USER_DIR="$HOME/.config/Code - Insiders/User"  # For Insiders
```

## 🔄 Integration with Chezmoi

The automation integrates seamlessly with chezmoi's workflow:

1. **Changes tracked automatically** - Modified settings are detected and backed up
2. **Version controlled** - All backups are committed to the dotfiles repository
3. **Disaster recovery** - Full restoration possible from fresh dotfiles application
4. **Cross-machine sync** - Settings propagate across all machines using the dotfiles

This creates a robust system where your VSCode configuration is always protected and synchronized, while still allowing for natural evolution of your development environment.

---

The VSCode automation system balances convenience with control, ensuring your settings are always backed up without getting in the way of your workflow.
