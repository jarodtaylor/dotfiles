# Chezmoi Scripts & Automation

This document explains the automation scripts and their execution order in this dotfiles repository.

## 📋 Script Execution Order

Chezmoi executes scripts in lexicographical order within each category:

### 1. `run_onchange_before_*` - Prerequisites

These run **before** applying dotfiles when their dependencies change:

```bash
run_onchange_before_00-brew-packages.sh.tmpl    # Install packages
run_onchange_before_10-create-age-key.sh.tmpl   # Generate encryption key
run_onchange_before_20-1password-setup.sh.tmpl  # Verify 1Password access
```

### 2. File Application

Chezmoi applies all configuration files to the home directory.

### 3. `run_onchange_after_*` - Configuration

These run **after** applying dotfiles when their dependencies change:

```bash
run_onchange_after_10-pam-config.sh.tmpl        # Touch ID/Apple Watch auth
run_onchange_after_40-mise.sh.tmpl              # Programming language runtimes
```

### 4. `run_once_*` - One-Time Setup

These run exactly once per machine:

```bash
run_once_setup-vscode-automation.sh             # VSCode backup automation
run_once_install-vscode-backup-hooks.sh         # Git hooks for dev repos
```

## 🔧 Script Details

### Package Management (`run_onchange_before_00-brew-packages.sh.tmpl`)

**Purpose**: Install and maintain system packages via Homebrew
**Triggers**: When the package list in the script changes
**Key Features**:

- Installs Homebrew if missing
- Handles both formulae and casks
- Special handling for `zsh-abbr@6` (specific version requirement)
- Maintains system packages like development tools, terminal apps, productivity software

**Customization**: Modify the `$brews` and `$casks` arrays to match your preferred tools.

### Encryption Setup (`run_onchange_before_10-create-age-key.sh.tmpl`)

**Purpose**: Generate age encryption key for sensitive dotfiles
**Triggers**: When chezmoi config changes or key is missing
**Security Note**: The generated key is used to decrypt sensitive configurations like work git settings.

### 1Password Integration (`run_onchange_before_20-1password-setup.sh.tmpl`)

**Purpose**: Verify 1Password CLI access and SSH key availability
**Triggers**: When 1Password configuration changes
**Dependencies**: 1Password app and CLI must be installed and authenticated
**Security Model**: SSH keys and sensitive data are stored in 1Password, not in the dotfiles repo

### System Authentication (`run_onchange_after_10-pam-config.sh.tmpl`)

**Purpose**: Configure Touch ID and Apple Watch for sudo authentication
**Triggers**: When PAM configuration changes
**macOS Specific**: Creates `/etc/pam.d/sudo_local` for persistent auth configuration
**Dependencies**: `pam-reattach` for tmux compatibility

### Development Runtimes (`run_onchange_after_40-mise.sh.tmpl`)

**Purpose**: Install and maintain programming language runtimes
**Triggers**: When mise configuration files change
**Key Features**:

- Updates mise itself
- Prunes removed runtime versions
- Installs new runtimes based on config

### VSCode Automation (`run_once_setup-vscode-automation.sh`)

**Purpose**: Set up automated VSCode settings backup
**Run Frequency**: Once per machine
**Components**:

- Loads the weekly backup LaunchAgent
- Verifies VSCode installation
- Creates backup directories
- Provides status and troubleshooting info

**Self-Contained**: This script doesn't depend on zsh functions to avoid chicken-and-egg problems during chezmoi initialization.

### Git Hook Installation (`run_once_install-vscode-backup-hooks.sh`)

**Purpose**: Install git post-commit hooks in development repositories
**Run Frequency**: Once per machine
**Key Features**:

- Scans common development directories
- Installs throttled backup hooks (max once per hour)
- Preserves existing hooks by appending
- Searches multiple directory patterns: `~/Code`, `~/Projects`, `~/Development`, etc.

**Hook Behavior**: After commits in development repos, automatically triggers VSCode backup and commits changes to dotfiles repo.

## 🎯 Design Principles

### State Management

- **Idempotent**: Scripts can be run multiple times safely
- **Conditional**: Only execute when dependencies change (via chezmoi's `run_onchange_`)
- **Self-Healing**: Missing configurations are automatically restored

### Error Handling

- **Graceful Degradation**: Scripts continue even if optional components fail
- **Clear Feedback**: Descriptive success/failure messages
- **Dependency Checking**: Verify prerequisites before proceeding

### Security

- **Minimal Secrets**: Sensitive data stored in 1Password, not dotfiles
- **Encrypted Storage**: Age encryption for any sensitive configurations that must be stored
- **Permission Management**: Careful handling of sudo requirements

## 🔀 Template System

Scripts ending in `.tmpl` use chezmoi's template system:

```bash
{{ .brew_prefix }}              # Homebrew path (Intel vs Apple Silicon)
{{ .ageKeyFile }}              # Age encryption key path
{{- if eq .chezmoi.os "darwin" -}}  # macOS-specific logic
```

**Available Variables**:

- `.chezmoi.os` - Operating system
- `.chezmoi.arch` - Architecture (arm64, amd64)
- `.brew_prefix` - Homebrew installation path
- `.ageKeyFile` - Age encryption key file path

## 🛠 Troubleshooting

### Script Won't Run

1. Check file permissions: `ls -la ~/.local/share/chezmoi/.chezmoiscripts/`
2. Verify template syntax: `chezmoi execute-template < script.tmpl`
3. Run with debug: `chezmoi apply --debug`

### LaunchAgent Issues

```bash
# Check status
launchctl list | grep vscode-backup

# Reload agent
launchctl unload ~/Library/LaunchAgents/com.user.vscode-backup.plist
launchctl load ~/Library/LaunchAgents/com.user.vscode-backup.plist

# Check logs
cat /tmp/vscode-backup.log
cat /tmp/vscode-backup-error.log
```

### 1Password Authentication

```bash
# Sign in to 1Password
op signin

# Test key access
op read "op://Personal/4ytcjbe2ui6iz5sjfe7fn54jea/public_key"
```

## 🔄 Customization for Other Setups

### Removing macOS Dependencies

1. Delete `run_onchange_after_10-pam-config.sh.tmpl`
2. Modify package script to use Linux package manager
3. Remove LaunchAgent references
4. Update template conditions to check for your OS

### Alternative Package Managers

Replace Homebrew sections with:

```bash
# apt-get (Debian/Ubuntu)
sudo apt-get update && sudo apt-get install -y package1 package2

# pacman (Arch)
sudo pacman -S package1 package2

# dnf (Fedora)
sudo dnf install package1 package2
```

### Different Secrets Management

1. Remove 1Password script
2. Update `.chezmoi.toml.tmpl` to remove 1Password references
3. Replace with your preferred secrets management (SOPS, etc.)

---

The automation system is designed to be robust and self-documenting. Each script includes extensive comments explaining its purpose and behavior.
