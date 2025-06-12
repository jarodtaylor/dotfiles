# 🏠 Personal Dotfiles

> **Fair Warning**: These dotfiles are highly opinionated and tailored for my specific macOS development workflow. They showcase patterns and automation that might be useful, but you'll likely want to fork and heavily customize rather than use directly.

A sophisticated dotfiles management system built on [Chezmoi](https://www.chezmoi.io/) with extensive automation, multi-identity support, and macOS-specific optimizations.

## 🎯 Philosophy

This repository follows a "**state keeper**" approach where:

- **Chezmoi manages the foundational configuration** - the stuff you need after a disaster
- **Applications handle day-to-day settings** - live configurations that change frequently
- **Automation bridges the gap** - smart backups and sync when it makes sense

The goal isn't to manage every single setting, but to have a solid foundation that gets you 90% of the way back to productivity after setting up a new machine.

## ✨ Key Features

### 🔐 Security-First Design

- **1Password integration** for secrets management
- **Age encryption** for sensitive configurations
- **Multi-identity Git setup** (personal/work with separate SSH keys)
- **SSH agent through 1Password** for seamless key management

### 🤖 Smart Automation

- **Weekly VSCode backup** via LaunchAgent
- **Git hook integration** for automatic backups after commits
- **Smart reminder system** that knows when to nudge you about backups
- **One-time setup scripts** that run during chezmoi initialization

### 🛠 Developer Workflow Optimization

- **Organized shell functions** categorized by purpose (CLI tools, config, system)
- **Comprehensive tool configuration** (Git, Neovim, VS Code, Terminal apps)
- **macOS-specific optimizations** (window management, system integration)
- **Unified package management** with Homebrew and mise

### 📁 Clean Organization

- **Structured function loading** (config → CLI → system)
- **Template-driven configuration** with environment-specific values
- **Modular chezmoi scripts** for different setup phases
- **Comprehensive `.chezmoiignore`** to avoid over-management

## 🚀 Quick Setup (YOLO!)

If you want to try my exact setup (not recommended unless you're me):

```bash
bash -c "$(curl -sfL https://raw.githubusercontent.com/jarodtaylor/dotfiles/refactor-simplify/install.sh)"
```

This installs Xcode Command Line Tools, Homebrew, and applies the full configuration.

## 🔧 Manual Setup (Recommended for Others)

### 1. Prerequisites

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install chezmoi
brew install chezmoi

# Install 1Password CLI (optional, for secrets)
brew install 1password-cli
```

### 2. Fork and Customize

```bash
# Fork this repository on GitHub, then:
git clone https://github.com/YOURUSERNAME/dotfiles.git
cd dotfiles

# Review and customize:
# - home/.chezmoi.toml.tmpl (remove 1Password references if not using)
# - home/.chezmoiignore (adjust for your preferences)
# - home/.chezmoiscripts/ (remove macOS-specific stuff if needed)
# - Package lists in run_onchange_before_00-brew-packages.sh.tmpl
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

### Core Tools & Configuration

- **Zsh** with Starship prompt, organized functions, and smart abbreviations
- **Git** with Delta diff viewer, multiple identity support, and workflow aliases
- **Neovim** with LazyVim configuration
- **VS Code/Cursor** with settings, keybindings, and automated backup
- **Terminal apps** (Ghostty, Kitty) with matching themes

### macOS Integration

- **Aerospace** tiling window manager configuration
- **Karabiner Elements** keyboard customization
- **LaunchAgents** for background automation
- **System preferences** automation (Touch ID, PAM configuration)

### Development Environment

- **mise** for runtime version management (Node.js, Python, Ruby, etc.)
- **Comprehensive package management** with Homebrew
- **Database tools** (PostgreSQL, Redis)
- **CLI productivity tools** (bat, eza, fzf, ripgrep, etc.)

## 🗂 Repository Structure

```
├── home/                           # Files that get applied to ~
│   ├── .chezmoiscripts/           # One-time and conditional setup scripts
│   ├── .chezmoitemplates/         # Reusable template snippets
│   ├── .config/                   # Application configurations
│   │   ├── zsh/functions/         # Organized shell functions
│   │   │   ├── cli/              # Daily workflow tools
│   │   │   ├── config/           # Shell configuration
│   │   │   └── system/           # System integration
│   │   ├── Code/User/            # VS Code configuration
│   │   └── [other apps]/         # Tool-specific configs
│   ├── bin/                       # Executable scripts
│   └── Library/LaunchAgents/      # macOS background automation
├── .startup.sh                    # Automated installation script
└── README.md                      # This file
```

## 🎨 Customization Guide

### For Different Operating Systems

- Remove macOS-specific files in `home/.chezmoiscripts/`
- Update package manager in brew packages script
- Adjust paths in configuration files
- Remove `home/Library/` LaunchAgent files

### For Different Workflows

- Modify the functions in `home/.config/zsh/functions/`
- Update application configurations in `home/.config/`
- Adjust the package lists in the scripts
- Customize the `.chezmoiignore` patterns

### For Different Security Models

- Remove 1Password references in `home/.chezmoi.toml.tmpl`
- Replace age encryption with your preferred method
- Update SSH key management approach
- Modify git identity configuration

## 📖 Additional Documentation

- **[ZSH Functions Guide](home/dot_config/zsh/functions/README.md)** - Detailed breakdown of shell function organization
- **[Chezmoi Scripts & Automation](docs/CHEZMOI_SCRIPTS.md)** - Deep dive into setup automation and script execution
- **[VSCode Backup Automation](docs/VSCODE_AUTOMATION.md)** - Complete guide to the three-layer backup system

## 🤝 Contributing

While this repository is highly personal, I'm happy to:

- Answer questions about the patterns and approaches used
- Review suggestions for better organization or automation
- Help troubleshoot issues you encounter when adapting the setup

## ⚠️ Disclaimers

- **macOS-focused**: Most automation assumes macOS (Homebrew, LaunchAgents, etc.)
- **Opinionated tool choices**: Heavy use of specific tools (Starship, Neovim, etc.)
- **1Password dependent**: Many security features assume 1Password CLI
- **Personal workflow**: Optimized for my specific development patterns

## 🙏 Inspiration

This repository builds on ideas from the dotfiles community, particularly:

- [Chezmoi documentation](https://www.chezmoi.io/) for configuration management patterns
- [ThePrimeagen](https://github.com/ThePrimeagen/.dotfiles) for Neovim configuration inspiration
- [Catppuccin](https://github.com/catppuccin) for consistent theming across tools

---

**Remember**: The best dotfiles are the ones that match _your_ workflow. Use this as inspiration, but don't be afraid to rip out everything that doesn't fit your needs!
