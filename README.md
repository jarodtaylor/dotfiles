# 🏠 Personal Dotfiles

> **Fair Warning**: These dotfiles are highly opinionated and tailored for my specific macOS development workflow. They showcase patterns and automation that might be useful, but you'll likely want to fork and heavily customize rather than use directly.

A clean, simple dotfiles management system built on [Chezmoi](https://www.chezmoi.io/) following Tom Payne's philosophy of declarative configuration and natural tool idempotency.

## 🎯 Philosophy

This repository follows Tom Payne's **"simple and declarative"** approach:

- **Leverage each tool's natural idempotency** instead of fighting it with custom logic
- **Use direct `onepasswordRead` calls** in templates for secrets
- **Simple brew bundle** for package installation (naturally idempotent)
- **Minimal scripts** focused only on macOS defaults configuration
- **No complex detection logic** or backup mechanisms

The goal is a clean, maintainable setup that gets you from zero to productive development environment in minutes.

## ✨ Key Features

### 🔐 Security-First Design

- **1Password integration** with direct `onepasswordRead` template calls
- **SSH keys managed by 1Password** with automatic agent configuration
- **Git signing** through 1Password SSH keys
- **Dynamic SSH config** stored in 1Password notes for ultimate flexibility

### 🛠 Developer Workflow Optimization

- **90+ applications** installed via brew bundle
- **Development tools** managed by mise (Node.js, Python, Ruby, etc.)
- **Comprehensive shell setup** with Zsh, Starship, and productivity tools
- **macOS system configuration** via simple defaults commands

### 📁 Clean Organization

- **Before scripts**: Package installation (brew bundle, mise)
- **Templates**: Declarative config using direct `onepasswordRead`
- **After scripts**: Minimal macOS defaults configuration
- **Dynamic configs**: Stored in 1Password for flexibility without code changes

## 🚀 Quick Setup

### One-Line Install (Zero to Coding in 60 Minutes!)

```bash
curl -sfL https://raw.githubusercontent.com/jarodtaylor/dotfiles/refactor-simplify/install.sh | bash
```

This will:

1. Install Xcode Command Line Tools (with GUI prompts)
2. Install and run chezmoi with my dotfiles
3. Install 90+ applications via Homebrew
4. Configure development tools with mise
5. Apply all configurations and settings

### What You'll Get

- **Perfect shell** with AI-powered tools and productivity enhancements
- **90+ applications** ready to use (VS Code, Docker, browsers, etc.)
- **Development environment** with Node.js, Python, Ruby, Go, etc.
- **All configurations** tuned for maximum productivity
- **1Password integration** for secure SSH and Git operations

## 🔧 Manual Setup (Recommended for Others)

### 1. Prerequisites

The install script handles these, but for manual setup:

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install 1Password app and CLI (optional but recommended)
# Download from App Store or:
brew install --cask 1password 1password-cli
```

### 2. Fork and Customize

```bash
# Fork this repository on GitHub, then:
git clone https://github.com/YOURUSERNAME/dotfiles.git
cd dotfiles

# Customize the package lists:
# - home/.chezmoiscripts/run_onchange_before_10-install-packages.sh.tmpl
# Remove 1Password references if not using:
# - home/.chezmoi.toml.tmpl
# - home/private_dot_ssh/config.tmpl
# - home/dot_gitconfig.tmpl
```

### 3. Initialize Your Version

```bash
# Initialize chezmoi with your repository
chezmoi init https://github.com/YOURUSERNAME/dotfiles.git

# Review what will be applied
chezmoi diff

# Apply (start with --dry-run to be safe)
chezmoi apply --dry-run
chezmoi apply
```

## 📚 What's Included

### Core Applications (90+)

**Development Tools:**

- VS Code, Cursor, Neovim
- Docker, Postman, GitHub Desktop
- Terminal apps (Ghostty, Wezterm)

**Productivity:**

- 1Password, Raycast, CleanShot
- Notion, Obsidian, Todoist
- Slack, Discord, Zoom

**System Tools:**

- Aerospace (window management)
- Karabiner Elements (keyboard customization)
- Various fonts and utilities

### Development Environment

- **mise** for runtime management (Node.js, Python, Ruby, Go, etc.)
- **Comprehensive CLI tools** (bat, eza, fzf, ripgrep, lazygit, etc.)
- **Database tools** (PostgreSQL, Redis, pgcli)
- **Modern shell** with Zsh, Starship prompt, and abbreviations

### Configuration Files

- **Git** with Delta diff viewer and 1Password SSH signing
- **SSH** with 1Password agent integration
- **Zsh** with organized functions and productivity aliases
- **Neovim** with modern configuration
- **macOS** system preferences and defaults

## 🗂 Repository Structure

```
├── home/                                    # Files applied to ~
│   ├── .chezmoiscripts/                    # Setup scripts
│   │   ├── run_onchange_before_10-install-packages.sh.tmpl  # Brew + mise
│   │   └── run_onchange_after_10-configure-macos.sh        # System defaults
│   ├── .chezmoitemplates/                  # Reusable snippets
│   ├── .config/                            # App configurations
│   │   ├── zsh/                           # Shell setup
│   │   ├── git/                           # Git configuration
│   │   ├── nvim/                          # Neovim config
│   │   └── [other apps]/                 # Tool configs
│   ├── private_dot_ssh/                    # SSH configuration
│   └── dot_gitconfig.tmpl                  # Git global config
├── install.sh                              # One-line installer
└── README.md                               # This file
```

## 🎨 Customization Guide

### Package Management

Edit `home/.chezmoiscripts/run_onchange_before_10-install-packages.sh.tmpl`:

```bash
{{ $brews := list
  "your-brew-packages"
  "here" -}}

{{ $casks := list
  "your-cask-apps"
  "here" -}}
```

### 1Password Integration

If not using 1Password, remove references in:

- `home/.chezmoi.toml.tmpl`
- `home/private_dot_ssh/config.tmpl`
- `home/dot_gitconfig.tmpl`

### macOS Defaults

Customize system settings in:

- `home/.chezmoiscripts/run_onchange_after_10-configure-macos.sh`

## 🔄 Key Differences from Complex Approach

### Before (Complex)

- Hundreds of lines of detection logic
- Multiple backup and restore mechanisms
- Complex 1Password setup scripts
- Conditional environment variables
- Timeout-based package installation

### After (Simple)

- Direct `onepasswordRead` calls in templates
- Single brew bundle for packages
- Minimal scripts for macOS defaults only
- Leverages natural tool idempotency
- Clean, declarative configuration

## 🤝 Contributing

While this repository is highly personal, I'm happy to:

- Answer questions about the simplified patterns used
- Review suggestions for better organization
- Help troubleshoot issues when adapting the setup

## ⚠️ Disclaimers

- **macOS-focused**: Assumes macOS with Homebrew
- **1Password optimized**: Many features work best with 1Password
- **Opinionated choices**: Specific tools and configurations for my workflow

## 🙏 Inspiration

This simplified approach is heavily inspired by:

- **[Tom Payne's dotfiles](https://github.com/twpayne/dotfiles)** - The creator of chezmoi's own clean approach
- **[Chezmoi documentation](https://www.chezmoi.io/)** - Best practices and patterns
- **[MasahiroSakoda's dotfiles](https://github.com/MasahiroSakoda/dotfiles/)** - Multi-platform simplicity

---

**Remember**: The best dotfiles are simple, maintainable, and match _your_ workflow. This repository shows how to achieve a lot with very little complexity!
