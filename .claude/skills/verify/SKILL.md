---
name: verify
description: Verify the chezmoi environment is healthy and check what changes would be applied. Run after making changes to dotfiles.
---

Run the following verification steps in order. Stop and report if any step fails.

## Step 1: Environment Health

```bash
chezmoi doctor
```

Report any warnings or errors. Common issues: missing age key, 1Password not authenticated, stale config.

## Step 2: Template Validation

For any `.tmpl` files that were recently modified, verify they render correctly:

```bash
chezmoi execute-template < <file>
```

If template rendering fails, show the error and the relevant template line.

## Step 3: Diff Check

```bash
chezmoi diff
```

Show a summary of what would change if `chezmoi apply` were run. Flag anything unexpected — especially changes to:
- SSH configs or keys
- Git signing configuration
- PAM/sudo configuration
- Encrypted files

## Step 4: Summary

Report:
- Environment health status
- Number of files that would change
- Any files with unexpected diffs
- Recommendation: safe to apply, or needs review
