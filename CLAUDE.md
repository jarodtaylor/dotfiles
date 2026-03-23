# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Chezmoi-managed dotfiles for macOS. The source directory is `home/` (set via `.chezmoiroot`). All target paths are relative to `~/`.

## Key Architecture

- **`.chezmoiroot`** points to `home/` — all managed dotfiles live under `home/`, not the repo root
- **Templates** (`.tmpl` files) use Go text/template syntax with chezmoi extensions
- **Encrypted files** use age encryption (key path in `.chezmoi.toml.tmpl`)
- **1Password integration** provides SSH keys and secrets via `onepasswordRead` — never hardcode secrets
- **Multi-profile**: personal and work git configs, with work config encrypted via age

## Chezmoi Conventions

- **File prefixes**: `dot_` → `.`, `private_` → 0600 perms, `executable_` → 0755 perms, `encrypted_` → decrypted on apply
- **Script naming**: `run_onchange_before_*` runs before apply when content changes, `run_onchange_after_*` runs after, `run_once_*` runs once ever
- **Script ordering**: Lexicographic within category — numeric prefixes control order (00, 10, 20...)
- **Template variables**: `.chezmoi.os`, `.chezmoi.arch`, `.brew_prefix`, `.ageKeyFile`, `.ssh_key`, `.work_ssh_key`
- **Template helpers**: `home/.chezmoitemplates/scripts/` contains reusable script functions (logging, sudo, brew eval)
- **External dependencies**: `.chezmoiexternal.toml` pulls repos (e.g., catppuccin zsh-syntax-highlighting)

## Scripts (actual files in `home/.chezmoiscripts/`)

- `run_onchange_before_10-install-packages.sh.tmpl` — Homebrew formulae + casks
- `run_onchange_before_20-create-age-key.sh.tmpl` — Age encryption key
- `run_onchange_after_00-pam-config.sh.tmpl` — Touch ID/Apple Watch sudo via pam-reattach

> **Note**: `docs/CHEZMOI_SCRIPTS.md` is outdated — script names and numbering differ from actual files. Trust the filesystem over the docs.

## Languages & Formatting

- **Shell/Zsh**: Primary scripting language. Zsh config uses zimfw plugin manager and zsh-abbr (not aliases).
- **Lua**: Neovim config in `home/dot_config/nvim/lua/`. Formatter: stylua (2-space indent, spaces, 120 col width — see `home/dot_config/nvim/stylua.toml`)
- **TOML**: starship, aerospace, mise, yazi configs
- **Go templates**: All `.tmpl` files use chezmoi's Go template engine

## Working with This Repo

- Always test changes with `chezmoi diff` before `chezmoi apply`
- Use `chezmoi execute-template < file.tmpl` to debug template rendering
- Use `chezmoi doctor` to verify the chezmoi environment is healthy
- Homebrew prefix varies by arch: `/opt/homebrew` (arm64) vs `/usr/local` (amd64) — always use `.brew_prefix` in templates
- `.chezmoiignore` excludes repo-only files (README, LICENSE, install.sh) from being applied

## Subdirectory Notes

For module-specific instructions, subdirectory `CLAUDE.md` files can be added (e.g., `home/dot_config/nvim/CLAUDE.md` for Neovim-specific guidance). They load automatically when Claude works in those directories.
