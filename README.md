> ⚠️ **WIP ENTER AT YOUR OWN RISK**

# Personal Dotfiles

This repository contains my personal dotfiles, managed with [Chezmoi](https://www.chezmoi.io/).

## Quick Start

1. Install 1Password and sign in
2. Enable SSH agent in 1Password (Settings → Developer)
3. Run:

   ```bash
   bash -c "$(curl -sfL https://raw.githubusercontent.com/jarodtaylor/dotfiles/main/.startup.sh)"
   ```

   > **Note**: This command preserves the TTY connection, which is required for proper sudo prompts and interactive elements during the installation process.
