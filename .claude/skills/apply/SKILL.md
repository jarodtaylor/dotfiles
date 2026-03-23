---
name: apply
description: Apply chezmoi changes to the home directory. Shows a diff preview first and asks for confirmation before applying. User-only — Claude should not invoke this automatically.
disable-model-invocation: true
---

## Step 1: Preview Changes

Run `chezmoi diff` and display a summary of all files that will be changed, created, or deleted.

Group changes by category:
- **Shell config** (zsh, zshrc, zshenv, abbreviations)
- **Editor config** (neovim, vscode, cursor)
- **Git config** (gitconfig, signing, delta)
- **System config** (pam, aerospace, karabiner)
- **Other**

## Step 2: Confirm

Use AskUserQuestion to ask: "Apply these changes?" with options:
- "Apply all" — proceed with full apply
- "Apply specific files" — ask which files to apply with `chezmoi apply <target>`
- "Cancel" — abort

## Step 3: Apply

Run the chosen apply command:

```bash
# Full apply
chezmoi apply

# Or targeted apply
chezmoi apply <target-path>
```

## Step 4: Verify

Run `chezmoi diff` again to confirm no remaining differences for the applied files. Report success or any issues.
