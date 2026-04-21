# Testing & Validation

Layered, fast-feedback-first. Don't boot a VM for every change.

## 1. Template render check (seconds)

When editing a `.tmpl`:

```bash
chezmoi execute-template < home/path/to/file.tmpl
```

Output should be fully rendered — no stray `{{ }}` and no template
delimiters surviving. If the `.tmpl` is a shell script, pipe the output
through `shellcheck`:

```bash
chezmoi execute-template < home/.chezmoiscripts/foo.sh.tmpl | shellcheck -s bash -
```

## 2. Shellcheck (seconds)

```bash
shellcheck home/bin/executable_dot bootstrap.sh
```

For templates, use the render-then-pipe approach above.

## 3. Dry-run apply (~10s, read-only)

```bash
chezmoi apply --dry-run -v
```

Tells you what apply would do without doing it. Great for catching
regressions before committing.

## 4. `dot doctor` (seconds, read-only)

```bash
dot doctor
```

Multi-layer health check (chezmoi doctor + brew drift + launchd agent
state + op session). Keep it green.

## 5. Parallels VM integration (30–60 min)

Used for milestone validation, not every change.

### Baseline snapshot

`clean-macos-with-1password` — saved state after:

- Fresh macOS install
- Xcode Command Line Tools installed
- 1Password app installed, signed in, CLI integration enabled
- 1Password CLI installed; `op signin` complete

Keep this snapshot sacred. Never overwrite it.

### Test procedure

1. In Parallels: **Actions → Manage Snapshots → Go To** `clean-macos-with-1password`.
2. Open Terminal in the VM.
3. **Verify 1Password CLI session is live** before running bootstrap.
   `op` sessions expire (default 30 days, shorter if the app locked or
   the VM was stopped), and the baseline snapshot's cached session may
   be stale even if it was active at snapshot time:

   ```bash
   op whoami || op signin
   ```

4. Run the one-liner (override the branch as needed):

   ```bash
   CHEZMOI_BRANCH=design/chezmoi-ironclad bash <(curl -fsSL \
     https://raw.githubusercontent.com/jarodtaylor/dotfiles/design/chezmoi-ironclad/bootstrap.sh)
   ```

5. Walk away ~30–60 minutes. Return for the password-prompt burst at
   the end (interactive installers: docker-desktop, karabiner, ms-*, etc.).
6. Close the terminal. Open a new one so the new PATH + zsh config load.
7. Verify:

   ```bash
   dot doctor
   dot status
   brew bundle check --file="$(chezmoi source-path)/Brewfile"
   launchctl print "gui/$(id -u)/com.jarodtaylor.dots-sync" | head -5
   ```

8. Induce drift, confirm capture works:

   ```bash
   brew install cowsay
   dot sync --dry-run   # expect to see +cowsay in preview
   dot sync             # commits
   brew uninstall cowsay
   dot sync             # commits removal
   ```

9. If everything passes, take a new checkpoint snapshot (e.g.
   `post-cp3-bootstrap`) and revert to baseline to keep the baseline
   pristine for the next pass.

### When to run VM integration

- End of every phase (CP-1 / CP-2 / CP-3 / CP-4)
- Before any merge to `main`
- After any change to `bootstrap.sh`, `.chezmoiscripts/`, the `dot` CLI,
  or 1Password integration
- After dependency bumps (chezmoi version, brew migrations)

### When to skip VM integration

- Small Brewfile additions (single `brew` lines)
- Doc-only changes
- New skill files under `dot_claude/skills/`
- Neovim config tweaks

## 6. Optional: GitHub Actions CI

Not implemented. Would be valuable as a future addition:

- `shellcheck` all shell files
- `chezmoi execute-template` every `.tmpl` and fail on error
- `plutil -lint` every plist under `home/Library/LaunchAgents/`
- Trigger on PRs targeting `main`

Not required for local confidence — the steps above cover 99% of
regressions before they hit a VM.
