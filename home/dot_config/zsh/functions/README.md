# ZSH Functions Organization

This directory contains shell functions organized by purpose for better maintainability.

## 📁 Directory Structure

### `cli/` - Interactive CLI Tools

Daily-use commands for development workflow. These are loaded as zsh functions for fast access.

- `ffe.zsh` - **F**ast **F**ile **E**dit: Interactive file finder with preview
- `fgc.zsh` - **F**ind **G**it **C**ommit: Interactive git commit browser
- `fif.zsh` - **F**ind **I**n **F**iles: Search text in files with preview
- `fkp.zsh` - **F**ind **K**ill **P**ort: Interactive port/process management
- `glg.zsh` - **G**it **L**og **G**rep: Search git history interactively
- `yazi.zsh.tmpl` - Yazi file manager wrapper

### `config/` - Shell Configuration

Core shell setup and theming. Loaded first during zsh initialization.

- `fzf-opts.zsh` - FZF theme and default options
- `starship.zsh.tmpl` - Starship prompt initialization
- `prompt-newline.zsh.tmpl` - Prompt formatting helpers

### `system/` - System Integration

Functions that integrate with system features but are used regularly.

- `vscode-backup.zsh` - Manual VSCode backup/restore commands
- `vscode-backup-reminder.zsh` - Smart backup reminders (auto-runs on shell startup)

## 🔄 Loading Order

Functions are loaded in this order in `.zshrc`:

1. **config/** - Shell configuration first
2. **cli/** - Interactive tools second
3. **system/** - System utilities last

## 🧹 Design Principles

- **CLI tools** = Fast, interactive, used daily → zsh functions
- **Configuration** = Shell setup, theming → zsh functions
- **System setup** = One-time automation → Consider chezmoi scripts
- **Utilities** = Maintenance tasks → Could be standalone scripts

## 🔧 Moved to Better Locations

System administration functions have been moved to more appropriate locations:

### Chezmoi Scripts (`.chezmoiscripts/`)

- `run_once_setup-vscode-automation.sh` - Sets up automation on new machines
- `run_once_install-vscode-backup-hooks.sh` - Installs git hooks in dev repos

### Standalone Scripts (`bin/`)

- `smoketest` - Terminal display testing utility (can be run from anywhere)

This keeps zsh functions focused on daily workflow tools while moving system administration to the appropriate lifecycle management.
