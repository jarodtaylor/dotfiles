# Personal Dotfiles

This repository contains my personal dotfiles, managed with [Chezmoi](https://www.chezmoi.io/). It's designed to streamline the setup of new macOS development machines, whether for personal or professional use.

## Pre-Testing TODOs

### 1. Configuration Management
- [ ] SSH and Git configuration for multiple GitHub identities
- [ ] Verify all template variables are consistent

### 2. 1Password Integration
- [ ] Ensure vault names are consistent across scripts
- [ ] Standardize SSH key naming convention
- [ ] Verify signing key paths in Git config

## Quick Start
1. Install 1Password and sign in
2. Enable SSH agent in 1Password (Settings → Developer)
3. Run:
   ```bash
   curl -sfL https://raw.githubusercontent.com/jarodtaylor/dotfiles/main/.startup.sh | bash
   ```

## Project Organization

The repository follows XDG Base Directory specification:
```
need to update and add a directory structure tree
```

## Implemented Features

### Package Management
- Declarative package management using Homebrew
- Packages defined in `packages.yaml`
- Automatic installation/updates via `run_onchange` scripts

### Development Environment
- mise for version management (Node.js, Elixir, Python, Ruby, etc.)
- Modular zsh configuration with separate files for:
  - Aliases
  - Options
  - Utility functions

### Git Profile Management
We've implemented a flexible Git profile system that:
- Uses a single source of truth (`config.yaml`)
- Supports multiple GitHub identities
- Automatically creates development directories
- Integrates with 1Password for key management

Example profile configuration:
```toml
[[profiles]]
name = "Jarod Taylor"
email = "jartaylo@estee.com"
github_user = "jartaylo"
directory = "~/src/elc"
signingkey = "..." # Managed by 1Password
```

### 1Password Strategy
Goal: Maximize 1Password usage for all authentication
- SSH key management
- Two-factor authentication
- Secure password generation
- Git commit signing
- CLI integration

## TODO List

### 1. SSH & Authentication
- [x] Create SSH keys in 1Password
- [ ] Configure SSH agent for both profiles
- [ ] Test GitHub authentication
- [ ] Document key management process

### 2. Git Configuration
- [ ] Create global .gitignore file
- [ ] Set up commit signing with 1Password
- [ ] Configure Git LFS if needed
- [ ] Add useful Git aliases

### 3. Development Environment
- [ ] Configure VS Code/Cursor settings
  - [ ] Extensions
  - [ ] User settings
  - [ ] Keybindings
- [ ] Set up language-specific tools via mise
  - [ ] Node.js/TypeScript
  - [ ] Python
  - [ ] Ruby
  - [ ] Go
- [ ] Configure terminal preferences
  - [ ] Warp settings
  - [ ] Shell aliases
  - [ ] Custom functions

### 4. Documentation
- [ ] Document .zshrc vs .zprofile usage
- [ ] Add installation instructions
- [ ] Document common workflows
- [ ] Add troubleshooting guide

## Frontend Development Setup

Primary tools and frameworks:
- TypeScript
- React
- Next.js
- Remix

(To be expanded with specific configurations and tools)

## Setup Process

1. Initial Bootstrap (`.startup.sh`)
   - Install XCode Command Line Tools
   - Install Homebrew
   - Install chezmoi
   - Clone dotfiles repository

2. Prerequisites (`run_once_before_`)
   - Install required packages (Homebrew)
   - Configure 1Password CLI
   
3. Core Configuration (dotfiles)
   - Git profiles
   - SSH configuration
   - Development tools configuration

4. Final Setup (`run_once_after_`)
   - Git configuration
   - SSH key generation
   - GitHub authentication
   - Development environment setup
