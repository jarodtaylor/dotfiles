# Chezmoi Ironclad Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the existing chezmoi dotfiles repo into an "ironclad" setup: daily workflow is friction-free (`brew install`, drop-in AI tool customizations work with zero chezmoi ceremony), state is captured automatically via a `dots sync` tool + nightly launchd agent, and a fresh machine bootstraps end-to-end in ~30–60 minutes of walkaway time from a one-liner.

**Architecture:** Hybrid source-of-truth. Machine is source of truth for mutable inventory (installed Homebrew packages, AI tool skills/agents/plugins); repo is source of truth for hand-edited configs (nvim, ghostty, zsh, git, etc.). `dots sync` captures machine state into the repo and commits; `chezmoi apply` pushes repo configs to machine. Runtime state (logs, caches, sessions, sqlite DBs) is filtered via `.chezmoiignore`. Secrets resolved via 1Password templates at apply time.

**Tech Stack:** Bash, chezmoi, Homebrew (Brewfile), 1Password CLI, launchd, age encryption, mise (already in place), macOS.

**Spec reference:** `docs/superpowers/specs/2026-04-16-chezmoi-ironclad-design.md`

**Branch:** `design/chezmoi-ironclad` (already checked out, spec already committed)

---

## Phased rollout & VM checkpoints

The user will validate in a Parallels macOS VM between phases before committing 100%. Phase-end VM checkpoints are explicit tasks; do not skip them.

| Phase | Focus | Approx. time | VM checkpoint |
|---|---|---|---|
| **0** | Branch + VM baseline | 30 min | Snapshot saved |
| **1** | Audit & cleanup (drift reconciliation) | ½ day | CP-1: clean-state bootstrap works |
| **2** | Sync infrastructure (`dots` CLI, AI tool capture, 1Password expansion) | 1 day | CP-2: `dots sync` round-trip in VM |
| **3** | Automation & bootstrap (launchd, `bootstrap.sh`, docs) | ½ day | CP-3: one-liner bootstrap in fresh VM |
| **4** | Full validation & merge | ½ day | CP-4 final: time-to-productive < 60 min in VM |

Commits happen continuously within each phase; the checkpoint is a hold point, not a commit gate.

---

## File structure

### New files
| Path | Purpose |
|---|---|
| `bootstrap.sh` (repo root) | One-liner entry: install Xcode CLT, brew, chezmoi, then `chezmoi init --apply`. Replaces `install.sh`. |
| `home/Brewfile` | Declarative Homebrew manifest (taps, brews, casks). Replaces hardcoded list in script. |
| `home/bin/executable_dots` | Main CLI — subcommands `sync`, `apply`, `doctor`, `status`, `new-machine`, `edit`, `help`. |
| `home/Library/LaunchAgents/com.jarodtaylor.dots-sync.plist` | launchd plist for daily auto-sync. |
| `home/.chezmoiscripts/run_onchange_after_20-launchd-reload.sh.tmpl` | Loads/reloads the launchd agent on `chezmoi apply`. |
| `home/dot_claude/` (tree) | Captured `~/.claude` config: `CLAUDE.md`, `settings.json`, `statusline.sh`, `skills/`, `agents/`, `commands/`, `hooks/`, `plugins/installed_plugins.json`, `plugins/known_marketplaces.json`, `consensus.json`, `dot_env.tmpl`. |
| `home/dot_codex/` (tree) | Captured `~/.codex` config: `config.toml`, `agents/`, `skills/`, `memories/`, `plugins/`, `version.json`, `auth.json.tmpl`. |
| `home/dot_gemini/` (tree) | Captured `~/.gemini` — config, skills, extensions configs. |
| `home/dot_cursor/` (tree) | Captured `~/.cursor` — settings.json, keybindings.json, snippets, extensions list. |
| `home/dot_claude.json.tmpl` | Templated `~/.claude.json` — machine-specific fields substituted. |
| `SETUP.md` (repo root) | Detailed new-machine walkthrough (human steps before running bootstrap). |
| `docs/AUDITING.md` | How to decide sync vs. ignore when a new AI tool shows up. |
| `docs/TESTING.md` | Parallels snapshot procedure, dry-run recipes, shellcheck usage. |
| `docs/KNOWN_ISSUES.md` | Generated Phase 4 — captures any rough edges from final validation. |

### Modified files
| Path | Change |
|---|---|
| `home/.chezmoi.toml.tmpl` | Add `age.identityCommand` (1Password-backed age key); keep current 1Password SSH integration. |
| `home/.chezmoiignore` | Aggressive runtime-state patterns for AI tool directories. |
| `home/.chezmoiscripts/run_onchange_before_10-install-packages.sh.tmpl` | Shrink to `brew bundle --file=Brewfile --cleanup` + mise logic; remove hardcoded package lists. |
| `README.md` | Refreshed: current architecture, adoption instructions, one-liner. |
| `CLAUDE.md` (repo root) | Refresh to reflect new architecture (`dots` CLI, sync model, 1Password-backed age). |

### Removed files
| Path | Reason |
|---|---|
| `home/.chezmoiscripts/run_onchange_before_20-create-age-key.sh.tmpl` | Age key moves to 1Password; no on-disk plaintext key. |
| `home/dot_config/nvim_old/` | Dead code. |
| `docs/CHEZMOI_SCRIPTS.md` | Outdated; replaced by refreshed README + CLAUDE.md. |
| `install.sh` | Replaced by `bootstrap.sh` with fixed branch reference (`main` not `refactor-simplify`). |
| `package.json`, `package-lock.json` (repo root) | 4-byte stubs, pointless. |
| `home/dot_config/kitty/`, `home/dot_config/wezterm/` if present | Terminal emulator pruning (keep ghostty only; decided Task 1.2). |
| `test-local-simulation.sh`, `test-vm-setup.sh`, `VM-TESTING-GUIDE.md` | Audited Task 1.10 — remove if outdated, otherwise modernize into `docs/TESTING.md`. |

---

# Phase 0: Foundation

## Task 0.1: Confirm branch state

**Files:** none (verification only)

- [ ] **Step 1: Confirm we're on the right branch**

```bash
cd /Users/jarodtaylor/.local/share/chezmoi
git status
git branch --show-current
```

Expected: `On branch design/chezmoi-ironclad`, `working tree clean`.

- [ ] **Step 2: Confirm spec is present**

```bash
ls docs/superpowers/specs/2026-04-16-chezmoi-ironclad-design.md
```

Expected: file exists.

- [ ] **Step 3: Confirm repo remote is correct**

```bash
git remote -v
```

Expected: `origin` points to `github.com/jarodtaylor/dotfiles` (or user fork). No action if correct.

## Task 0.2: Parallels VM baseline snapshot

**Files:** none (VM config)

- [ ] **Step 1: Prepare a clean macOS VM**

In Parallels: create or select a clean macOS install. The version should match the host (macOS Sequoia / 14+). Finish initial setup (user account, skip iCloud/Find My optional prompts). Do **not** install Homebrew yet.

- [ ] **Step 2: Install Xcode Command Line Tools in VM**

Inside the VM:

```bash
xcode-select --install
```

Click "Install" in the GUI prompt. Wait for completion.

- [ ] **Step 3: Install 1Password app in VM**

Inside the VM: download 1Password app from https://1password.com/downloads/mac/, sign in to your account. Enable SSH agent and CLI integration in 1Password Developer settings.

- [ ] **Step 4: Install 1Password CLI in VM**

```bash
curl -fsSL https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor -o /usr/share/keyrings/1password-archive-keyring.gpg || true
# On macOS the simpler path:
brew install --cask 1password-cli 2>/dev/null || curl -fsSL https://app-updates.agilebits.com/product_history/CLI2 | head -20
# Prefer: download and install via dmg from https://app-updates.agilebits.com/product_history/CLI2
op --version
```

Expected: `op` version string.

(If brew isn't yet installed in VM, install op CLI manually from the 1Password downloads page. Brew will be installed later by `bootstrap.sh`.)

- [ ] **Step 5: Authenticate 1Password CLI**

```bash
op account add
op signin
```

Expected: `Account added`, then successful signin.

- [ ] **Step 6: Create Parallels snapshot named "clean-macos-with-1password"**

In Parallels menu: Actions → Take Snapshot → Name: `clean-macos-with-1password`. Description: "Fresh macOS + Xcode CLT + 1Password app+CLI signed in. Use as baseline for bootstrap testing."

- [ ] **Step 7: Verify snapshot**

In Parallels menu: Actions → Manage Snapshots. Confirm snapshot exists.

- [ ] **Step 8: Commit a note of the VM baseline**

No code commit. Note the VM snapshot name in your own records or in a file under `docs/` for reference. (We'll formalize the procedure in `docs/TESTING.md` during Phase 3.)

---

# Phase 1: Audit & Cleanup

Goal of this phase: reconcile drift, prune cruft, migrate secrets off disk. Exit with a repo and machine in lockstep.

## Task 1.1: Snapshot current machine state

**Files:**
- Create: `/tmp/chezmoi-audit/brew-leaves.txt`
- Create: `/tmp/chezmoi-audit/brew-casks.txt`
- Create: `/tmp/chezmoi-audit/brew-taps.txt`
- Create: `/tmp/chezmoi-audit/home-dirs.txt`

- [ ] **Step 1: Capture current installed inventories**

```bash
mkdir -p /tmp/chezmoi-audit
brew leaves > /tmp/chezmoi-audit/brew-leaves.txt
brew list --cask > /tmp/chezmoi-audit/brew-casks.txt
brew tap > /tmp/chezmoi-audit/brew-taps.txt
ls -d ~/.??*/ | sort > /tmp/chezmoi-audit/home-dirs.txt
```

- [ ] **Step 2: Compare against declared list**

```bash
cd ~/.local/share/chezmoi
grep -oE '"[^"]+"' home/.chezmoiscripts/run_onchange_before_10-install-packages.sh.tmpl \
  | sed 's/"//g' | sort -u > /tmp/chezmoi-audit/declared.txt

diff /tmp/chezmoi-audit/brew-leaves.txt /tmp/chezmoi-audit/declared.txt || true
```

Expected: diff lists both drifted-in items and declared-but-absent items. Save output.

- [ ] **Step 3: Review `/tmp/chezmoi-audit/` contents**

Manually open each file. Produce a mental map (or notes) of what's there vs. what's expected.

## Task 1.2: Drift decisions (interactive)

**Files:** none (decision-capturing)

Work through each drift item and decide KEEP, REMOVE, or OPEN-QUESTION. Record decisions in `/tmp/chezmoi-audit/decisions.md` for reference during Brewfile creation (Task 1.3).

- [ ] **Step 1: Create decisions file**

```bash
cat > /tmp/chezmoi-audit/decisions.md <<'EOF'
# Drift Decisions — 2026-04-16

## Brews (installed but undeclared)
- aubio: KEEP/REMOVE/?
- cmake: KEEP/REMOVE/?
- curl: KEEP/REMOVE/?
- git-lfs: KEEP/REMOVE/?
- libsamplerate: KEEP/REMOVE/?
- pinentry-mac: KEEP/REMOVE/?
- pipx: KEEP/REMOVE/?
- python@3.9: KEEP/REMOVE/?
- python@3.11: KEEP/REMOVE/?
- python@3.12: KEEP/REMOVE/?
- rust: KEEP/REMOVE/?   # note: conflicts conceptually with declared `rustup`
- silicon: KEEP/REMOVE/?
- vhs: KEEP/REMOVE/?
- virtualenv: KEEP/REMOVE/?
- yt-dlp: KEEP/REMOVE/?
- zimfw: KEEP/REMOVE/?  # note: may be auto-installed by zsh setup
- elco (via elc-online/tap): KEEP/REMOVE/?
- encore (via encoredev/tap): KEEP/REMOVE/?
- shopify-cli (via shopify/shopify): KEEP/REMOVE/?

## Casks (installed but undeclared)
- arc: KEEP/REMOVE/?
- beekeeper-studio: KEEP/REMOVE/?
- betterdisplay: KEEP/REMOVE/?
- blackhole-2ch: KEEP/REMOVE/?
- chromedriver: KEEP/REMOVE/?
- docker-desktop: KEEP/REMOVE/?  # note: overlaps with `docker` formula
- microsoft-auto-update: KEEP/REMOVE/?  # likely auto-installed
- todoist-app: KEEP/REMOVE/?  # overlaps with `todoist` cask
- warp: KEEP/REMOVE/?
- wezterm: KEEP/REMOVE/?
- factoryfloor: KEEP/REMOVE/?  # declared, verify
- zoom: KEEP/REMOVE/?

## Declared but not top-level leaves (dependency promotion?)
- ffmpeg: PROMOTE-TO-LEAF/REMOVE-FROM-DECLARATION/?
- libpq: PROMOTE-TO-LEAF/REMOVE-FROM-DECLARATION/?

## Terminal emulators (multiple installed — pick one)
- ghostty: KEEP (primary, config under dot_config/ghostty)
- kitty: KEEP/REMOVE? (config still in dot_config/kitty)
- wezterm: KEEP/REMOVE? (no config in dot_config)
- warp: KEEP/REMOVE? (no config in dot_config)

## Undeclared taps (currently in use)
- alltuner/tap: KEEP (feeds factoryfloor cask)
- elc-online/tap: depends on elco decision
- encoredev/tap: depends on encore decision
- shopify/shopify: depends on shopify-cli decision
EOF
$EDITOR /tmp/chezmoi-audit/decisions.md
```

- [ ] **Step 2: Fill in each decision**

Open in editor. For each item, replace the `KEEP/REMOVE/?` placeholder with one concrete choice. No `?` should remain when you save. Note any rationale inline for nontrivial calls (e.g., `yt-dlp: KEEP — use monthly for personal video archiving`).

- [ ] **Step 3: Sanity-check decisions list**

```bash
grep -E 'KEEP/REMOVE|\?$' /tmp/chezmoi-audit/decisions.md || echo "All decisions resolved."
```

Expected: `All decisions resolved.` If anything comes back, revisit step 2.

## Task 1.3: Generate curated Brewfile

**Files:**
- Create: `home/Brewfile`

- [ ] **Step 1: Create the Brewfile scaffold**

```bash
cat > ~/.local/share/chezmoi/home/Brewfile <<'EOF'
# =============================================================================
# Brewfile — Jarod Taylor's macOS dotfiles
# =============================================================================
# Managed by chezmoi + `dots sync`.
# To apply: `brew bundle --file=$(chezmoi source-path)/home/Brewfile --cleanup`
# To capture installed state: `dots sync` (runs `brew bundle dump --force --describe`)
#
# Groups are cosmetic; bundle dump flattens them on overwrite. Keep comments
# that explain WHY a package is here (non-obvious items) so future audits are easy.

# -----------------------------------------------------------------------------
# Taps
# -----------------------------------------------------------------------------
tap "felixkratz/formulae"           # sketchybar + borders
tap "olets/tap"                     # zsh-abbr
tap "nikitabobko/tap"               # aerospace window manager
tap "alltuner/tap"                  # factoryfloor
# TAPS-FROM-DECISIONS: append elc-online, encoredev, shopify/shopify if kept

# -----------------------------------------------------------------------------
# Core CLI
# -----------------------------------------------------------------------------
brew "age"                          # file encryption (chezmoi secrets)
brew "bat"
brew "chezmoi"
brew "direnv"
brew "eza"
brew "fd"
brew "fzf"
brew "gh"
brew "git"
brew "git-delta"
brew "jq"
brew "mise"
brew "ripgrep"
brew "starship"
brew "tlrc"
brew "tree"
brew "wget"
brew "yazi"
brew "zoxide"
brew "zsh"

# (continue with remaining KEEP decisions from Task 1.2)
# -----------------------------------------------------------------------------
# Casks
# -----------------------------------------------------------------------------
cask "1password"
cask "1password-cli"
cask "ghostty"
# (continue with remaining KEEP decisions from Task 1.2)
EOF
```

- [ ] **Step 2: Fill in the rest from decisions**

Manually complete the Brewfile using `/tmp/chezmoi-audit/decisions.md`. For every `KEEP`, add a `brew "X"` or `cask "X"` line. For every `REMOVE`, do nothing. For terminal emulators, only include the ones you chose to keep.

- [ ] **Step 3: Validate Brewfile parses**

```bash
brew bundle check --file=~/.local/share/chezmoi/home/Brewfile --verbose
```

Expected: either "The Brewfile's dependencies are satisfied." or a list of missing items. The list tells you what you'll need to install (for REMOVE items that are still installed) or what's missing (typos).

- [ ] **Step 4: Commit the Brewfile**

```bash
cd ~/.local/share/chezmoi
git add home/Brewfile
git commit -m "feat: add curated Brewfile replacing hardcoded list"
```

## Task 1.4: Switch install-packages script to Brewfile

**Files:**
- Modify: `home/.chezmoiscripts/run_onchange_before_10-install-packages.sh.tmpl`

- [ ] **Step 1: Rewrite the script**

Replace the contents of `home/.chezmoiscripts/run_onchange_before_10-install-packages.sh.tmpl` with:

```bash
#!/bin/bash

set -eufo pipefail

{{ template "scripts/script_eval_brew" . }}
{{ template "scripts/script_sudo" . }}
{{ template "scripts/script_helper" . }}

# Brewfile hash so chezmoi re-runs this script when the Brewfile changes.
# Brewfile hash: {{ include "../Brewfile" | sha256sum }}
# Mise config hash: {{ includeTemplate "dot_config/mise/config.toml.tmpl" | sha256sum }}
# Default npm packages hash: {{ includeTemplate "dot_config/mise/dot_default-npm-packages.tmpl" | sha256sum }}
# Default gems hash: {{ includeTemplate "dot_config/mise/dot_default-gems.tmpl" | sha256sum }}

BREWFILE="{{ .chezmoi.sourceDir }}/Brewfile"

# Install Homebrew if not present
if ! command -v brew &>/dev/null; then
  log_info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$({{ .brew_prefix }}/bin/brew shellenv)"
fi

# Handle zsh-abbr version-pinned install (requires specific version)
if brew list zsh-abbr &>/dev/null; then
  brew unlink zsh-abbr
  brew uninstall --force zsh-abbr
fi
brew install olets/tap/zsh-abbr@6
brew link --overwrite zsh-abbr@6

brew install olets/tap/zsh-autosuggestions-abbreviations-strategy

# Apply Brewfile (installs missing, prunes extras)
log_info "Applying Brewfile..."
brew bundle --file="$BREWFILE" --cleanup --no-lock

# Configure mise
if command -v mise &>/dev/null; then
    log_info "Upgrading mise and managing development tools..."
    mise upgrade

    prunable_output=$(mise ls --prunable 2>/dev/null || true)
    if [ -n "$prunable_output" ]; then
        echo "$prunable_output" | while IFS= read -r item; do
            if [ -n "$item" ]; then
                log_debug "Pruning removed tool: $item"
                mise prune "$item"
            fi
        done
    fi
else
    log_warning "Warning: mise not found. Package installation may have failed."
fi
```

- [ ] **Step 2: Validate template renders**

```bash
cd ~/.local/share/chezmoi
chezmoi execute-template < home/.chezmoiscripts/run_onchange_before_10-install-packages.sh.tmpl | head -40
```

Expected: rendered shell script with actual paths (no unrendered `{{ }}`), `BREWFILE=...` pointing to actual source dir.

- [ ] **Step 3: shellcheck the rendered script**

```bash
chezmoi execute-template < home/.chezmoiscripts/run_onchange_before_10-install-packages.sh.tmpl | shellcheck -s bash -
```

Expected: no errors (warnings about template-rendered values are acceptable; fix any real issues).

- [ ] **Step 4: Commit**

```bash
cd ~/.local/share/chezmoi
git add home/.chezmoiscripts/run_onchange_before_10-install-packages.sh.tmpl
git commit -m "refactor: delegate package installation to Brewfile"
```

## Task 1.5: Apply and reconcile

**Files:** none (runtime action)

- [ ] **Step 1: Preview what apply will do**

```bash
cd ~/.local/share/chezmoi
chezmoi apply --dry-run -v
```

Expected: shows the install-packages script will re-run (because its hash comment changed).

- [ ] **Step 2: Apply**

```bash
chezmoi apply -v
```

Expected: script runs `brew bundle --cleanup` which installs/uninstalls packages to match Brewfile. Watch for unexpected removals. Time: 1–10 minutes depending on drift size.

- [ ] **Step 3: Verify reconciliation**

```bash
brew bundle check --file=$(chezmoi source-path)/home/Brewfile
brew leaves | sort > /tmp/chezmoi-audit/brew-leaves-after.txt
diff /tmp/chezmoi-audit/brew-leaves.txt /tmp/chezmoi-audit/brew-leaves-after.txt
```

Expected: `check` reports "dependencies are satisfied"; diff shows only intended removals.

- [ ] **Step 4: If any surprise removals, restore**

If `--cleanup` removed something you meant to keep, add it to the Brewfile, re-run `chezmoi apply`. Iterate until state matches intent.

## Task 1.6: Remove nvim_old

**Files:**
- Remove: `home/dot_config/nvim_old/`

- [ ] **Step 1: Remove from source**

```bash
cd ~/.local/share/chezmoi
git rm -rf home/dot_config/nvim_old
```

- [ ] **Step 2: Confirm target no longer referenced**

```bash
grep -r nvim_old home/ || echo "No references."
```

Expected: `No references.`

- [ ] **Step 3: Apply and clean target**

```bash
chezmoi apply -v
rm -rf ~/.config/nvim_old
```

- [ ] **Step 4: Commit**

```bash
git commit -m "chore: remove dead nvim_old config"
```

## Task 1.7: Remove unused terminal emulator configs

**Files:**
- Remove (conditional, per Task 1.2 decisions): `home/dot_config/kitty/`, `home/dot_config/wezterm/` (if exist)

- [ ] **Step 1: Check what exists**

```bash
ls -d ~/.local/share/chezmoi/home/dot_config/{kitty,wezterm,warp} 2>/dev/null
```

- [ ] **Step 2: For each terminal config you decided to drop in Task 1.2, remove**

```bash
cd ~/.local/share/chezmoi
# Example — adjust to your decisions:
git rm -rf home/dot_config/kitty
# git rm -rf home/dot_config/wezterm   # only if present and decided DROP
```

- [ ] **Step 3: Apply and clean target**

```bash
chezmoi apply -v
# Manually clean target if chezmoi doesn't remove (it should for git-rm'd files):
rm -rf ~/.config/kitty    # or other dirs that you removed
```

- [ ] **Step 4: Commit**

```bash
git commit -m "chore: prune unused terminal emulator configs"
```

## Task 1.8: Migrate age key to 1Password

**Files:**
- Modify: `home/.chezmoi.toml.tmpl`
- Remove: `home/.chezmoiscripts/run_onchange_before_20-create-age-key.sh.tmpl`

- [ ] **Step 1: Verify current age key**

```bash
ls -la ~/key.txt
age-keygen -y ~/key.txt
```

Expected: public key string like `age1...`.

- [ ] **Step 2: Create 1Password entry for age key**

In 1Password app: create a new item of type **Secure Note** in the `Personal` vault named `Dotfiles Age Key`. Paste the **entire contents** of `~/key.txt` (it's typically two lines: a comment line + the secret key line `AGE-SECRET-KEY-...`) into the Note field. Add a tag `dotfiles` for findability.

Verify via CLI:

```bash
op item get "Dotfiles Age Key" --vault Personal --fields label=notesPlain --reveal
```

Expected: the full age key contents printed back.

- [ ] **Step 3: Update chezmoi config template**

Modify `home/.chezmoi.toml.tmpl`:

Replace lines 10–29 (the age-key detection block and the `encryption = "age"` block) with:

```go-template
{{ $ageIdentityCmd := list "op" "read" "op://Personal/Dotfiles Age Key/notesPlain" }}
{{- $agePublicKey := output "sh" "-c" "op read 'op://Personal/Dotfiles Age Key/notesPlain' 2>/dev/null | age-keygen -y 2>/dev/null || true" | trim -}}

{{- if $agePublicKey }}
encryption = "age"

[age]
identityCommand = [{{ range $i, $v := $ageIdentityCmd }}{{ if $i }}, {{ end }}{{ $v | quote }}{{ end }}]
recipient = {{ $agePublicKey | quote }}
{{- end }}
```

Also remove the now-unused `$ageKeyFile`, `$ageKeyExists`, `$ageRecipient` block (original lines ~10-21) and the `ageKeyFile`, `ageKeyExists` entries in `[data]`.

- [ ] **Step 4: Render and verify**

```bash
cd ~/.local/share/chezmoi
chezmoi execute-template < home/.chezmoi.toml.tmpl
```

Expected: rendered config shows `[age]` section with `identityCommand = ["op", "read", "op://Personal/Dotfiles Age Key/notesPlain"]` and `recipient = "age1..."` matching your public key.

- [ ] **Step 5: Run chezmoi init with new config**

```bash
chezmoi init
```

Expected: no prompts, no errors. It re-reads the toml template.

- [ ] **Step 6: Sanity-check encrypted file decryption still works**

If you have any `encrypted_*` files in source:

```bash
ls home/**/encrypted_* 2>/dev/null
chezmoi verify
```

Expected: `chezmoi verify` returns silently (or reports non-encryption-related diffs).

- [ ] **Step 7: Remove the create-age-key script**

```bash
git rm home/.chezmoiscripts/run_onchange_before_20-create-age-key.sh.tmpl
```

- [ ] **Step 8: (Don't delete ~/key.txt yet!) — defer deletion until VM checkpoint passes**

For now, leave `~/key.txt` on disk. Only once the VM test (CP-1) confirms the 1Password-backed flow works end-to-end will we remove it. Belt-and-suspenders.

- [ ] **Step 9: Commit**

```bash
git add home/.chezmoi.toml.tmpl
git commit -m "feat: migrate age decryption key to 1Password

No more plaintext age key on disk. chezmoi resolves the key at
apply time via the 1Password CLI. Falls back gracefully if op is
unavailable (encryption block omitted, same as before)."
```

## Task 1.9: Remove stale docs and test scripts

**Files:**
- Remove: `docs/CHEZMOI_SCRIPTS.md`, `test-local-simulation.sh`, `test-vm-setup.sh`, `VM-TESTING-GUIDE.md`, `package.json`, `package-lock.json`, `install.sh` (replaced later in Phase 3)

- [ ] **Step 1: Review what's there**

```bash
cd ~/.local/share/chezmoi
head -20 docs/CHEZMOI_SCRIPTS.md docs/VSCODE_AUTOMATION.md
head -20 test-local-simulation.sh test-vm-setup.sh
head -20 VM-TESTING-GUIDE.md
```

Decide for each: DROP or MIGRATE (migration target is `docs/TESTING.md` in Phase 3).

- [ ] **Step 2: Capture anything worth keeping**

If any file contains procedural content worth keeping (e.g., the VM testing guide has concrete steps you want to keep), copy the relevant sections to a scratchpad like `/tmp/chezmoi-audit/migrate-to-testing-md.md` for Task 3.8.

- [ ] **Step 3: Remove stale files**

```bash
git rm -f docs/CHEZMOI_SCRIPTS.md \
         test-local-simulation.sh \
         test-vm-setup.sh \
         VM-TESTING-GUIDE.md \
         package.json \
         package-lock.json
```

(Keep `install.sh` for now — Task 3.3 replaces it with `bootstrap.sh`.)

- [ ] **Step 4: Commit**

```bash
git commit -m "chore: remove stale docs and test scripts

- docs/CHEZMOI_SCRIPTS.md: outdated, covered by refreshed README.
- test-local-simulation.sh, test-vm-setup.sh, VM-TESTING-GUIDE.md:
  to be replaced by docs/TESTING.md in Phase 3.
- package.json, package-lock.json: 4-byte stubs with no purpose."
```

## Task 1.10: VM Checkpoint 1 — clean-state bootstrap

**Goal:** Confirm that after the Phase 1 changes, a fresh VM can bootstrap using the (still current) `install.sh` and reach a reconciled state with the new Brewfile and 1Password age key.

**Files:** none (VM integration test)

- [ ] **Step 1: Push the design branch to origin**

```bash
cd ~/.local/share/chezmoi
git push -u origin design/chezmoi-ironclad
```

- [ ] **Step 2: Restore VM to `clean-macos-with-1password` snapshot**

In Parallels: Actions → Manage Snapshots → select `clean-macos-with-1password` → Go To.

- [ ] **Step 3: Run the current `install.sh` from the design branch in VM**

Inside the VM:

```bash
# Clone the branch
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --verbose --apply --branch design/chezmoi-ironclad jarodtaylor
```

Expected: clone succeeds, chezmoi applies, brew bundle installs curated package set, 1Password CLI prompts for auth if needed, age key resolves via op.

- [ ] **Step 4: Verify in VM**

```bash
brew bundle check --file=$(chezmoi source-path)/home/Brewfile
ls ~/key.txt                           # Expected: No such file or directory
chezmoi verify                         # Expected: clean
```

- [ ] **Step 5: Record any failures**

If anything fails: note the error, revert the VM to snapshot, fix on host, push, repeat step 3. Do **not** proceed to Phase 2 until CP-1 passes.

- [ ] **Step 6: On success, delete `~/key.txt` on host**

```bash
# Only run this after CP-1 passes:
rm ~/key.txt
```

(VM already won't have this file; this is host cleanup only.)

- [ ] **Step 7: Commit a checkpoint marker (optional)**

```bash
cd ~/.local/share/chezmoi
git commit --allow-empty -m "checkpoint: CP-1 VM bootstrap validated on clean-macos-with-1password"
git push
```

---

# Phase 2: Sync Infrastructure

Goal: `dots` CLI, AI tool capture, secrets migration. Exit with `dots sync` working end-to-end on the host.

## Task 2.1: Scaffold `dots` CLI

**Files:**
- Create: `home/bin/executable_dots`

- [ ] **Step 1: Create the file with dispatcher skeleton**

```bash
cat > ~/.local/share/chezmoi/home/bin/executable_dots <<'EOF'
#!/usr/bin/env bash
# dots — personal dotfiles management CLI
#
# Subcommands:
#   sync         Capture drift into repo, optionally commit/push
#   apply        chezmoi apply + brew bundle (cleanup)
#   doctor       Multi-layer health check
#   status       One-line drift summary
#   new-machine  Interactive bootstrap helper
#   edit         Open the repo in $EDITOR
#   help         Show this help

set -euo pipefail

DOTS_SOURCE_DIR="$(chezmoi source-path 2>/dev/null || echo "$HOME/.local/share/chezmoi")"
DOTS_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dots-sync"
mkdir -p "$DOTS_STATE_DIR"

# --- Logging ---
if [ -t 1 ]; then
  readonly C_RESET=$'\033[0m' C_BLUE=$'\033[34m' C_GREEN=$'\033[32m' C_YELLOW=$'\033[33m' C_RED=$'\033[31m' C_DIM=$'\033[2m'
else
  readonly C_RESET='' C_BLUE='' C_GREEN='' C_YELLOW='' C_RED='' C_DIM=''
fi

log_info()  { printf "%s➜%s %s\n" "$C_BLUE"   "$C_RESET" "$*"; }
log_ok()    { printf "%s✓%s %s\n" "$C_GREEN"  "$C_RESET" "$*"; }
log_warn()  { printf "%s⚠%s %s\n" "$C_YELLOW" "$C_RESET" "$*"; }
log_err()   { printf "%s✗%s %s\n" "$C_RED"    "$C_RESET" "$*" >&2; }
log_debug() { [ "${DOTS_VERBOSE:-0}" = "1" ] && printf "%s  %s%s\n" "$C_DIM" "$*" "$C_RESET" || true; }

# --- Usage ---
usage() {
  cat <<'USAGE'
dots — personal dotfiles management CLI

Usage:
  dots <command> [flags]

Commands:
  sync          Capture drift into repo, optionally commit/push
  apply         chezmoi apply + brew bundle --cleanup
  doctor        Multi-layer health check
  status        One-line drift summary
  new-machine   Interactive bootstrap helper
  edit          Open the repo in $EDITOR
  help          Show this help

Common flags:
  --dry-run     Preview without writing
  --no-commit   Capture but don't auto-commit
  --push        Push to origin after commit
  -v,--verbose  Show underlying commands

Examples:
  dots sync --dry-run       # Preview what would be captured
  dots sync --push          # Capture + commit + push
  dots doctor               # Show system health
  dots apply                # Reconcile machine with repo
USAGE
}

# --- Subcommand: help ---
cmd_help() {
  usage
}

# --- Subcommand stubs (implemented in later tasks) ---
cmd_sync()        { log_err "sync: not yet implemented (Task 2.14)"; exit 2; }
cmd_apply()       { log_err "apply: not yet implemented (Task 2.2)"; exit 2; }
cmd_doctor()      { log_err "doctor: not yet implemented (Task 2.3)"; exit 2; }
cmd_status()      { log_err "status: not yet implemented (Task 2.4)"; exit 2; }
cmd_new_machine() { log_err "new-machine: not yet implemented (Task 3.4)"; exit 2; }
cmd_edit()        { ${EDITOR:-vi} "$DOTS_SOURCE_DIR"; }

# --- Main dispatch ---
main() {
  local cmd="${1:-help}"
  shift || true

  case "$cmd" in
    sync)        cmd_sync "$@" ;;
    apply)       cmd_apply "$@" ;;
    doctor)      cmd_doctor "$@" ;;
    status)      cmd_status "$@" ;;
    new-machine) cmd_new_machine "$@" ;;
    edit)        cmd_edit "$@" ;;
    help|-h|--help) cmd_help ;;
    *)
      log_err "Unknown command: $cmd"
      echo
      usage
      exit 64
      ;;
  esac
}

main "$@"
EOF
```

- [ ] **Step 2: Verify it runs via chezmoi-rendered path**

```bash
cd ~/.local/share/chezmoi
chezmoi apply -v
~/bin/dots help
```

Expected: help text printed. Exit 0.

- [ ] **Step 3: Verify unknown commands exit non-zero**

```bash
~/bin/dots frobnicate; echo "exit=$?"
```

Expected: error message, `exit=64`.

- [ ] **Step 4: shellcheck**

```bash
shellcheck ~/.local/share/chezmoi/home/bin/executable_dots
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
cd ~/.local/share/chezmoi
git add home/bin/executable_dots
git commit -m "feat(dots): scaffold CLI with help and command dispatcher"
```

## Task 2.2: `dots apply`

**Files:**
- Modify: `home/bin/executable_dots`

- [ ] **Step 1: Replace `cmd_apply` stub with real implementation**

Find `cmd_apply() { ... }` in `home/bin/executable_dots` and replace with:

```bash
cmd_apply() {
  local dry_run=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run) dry_run=1 ;;
      -v|--verbose) export DOTS_VERBOSE=1 ;;
      *) log_warn "unknown flag: $1" ;;
    esac
    shift
  done

  local chezmoi_flags=(-v)
  if [ "$dry_run" = "1" ]; then
    chezmoi_flags+=(--dry-run)
    # brew bundle has no --dry-run; we skip the step in dry-run mode
  fi

  log_info "chezmoi apply..."
  chezmoi apply "${chezmoi_flags[@]}"

  if [ "$dry_run" = "0" ]; then
    log_info "brew bundle --cleanup..."
    brew bundle --file="$DOTS_SOURCE_DIR/home/Brewfile" --cleanup --no-lock
  else
    log_info "(dry-run) would run: brew bundle --cleanup"
  fi

  log_ok "apply complete"
}
```

- [ ] **Step 2: Test `dots apply --dry-run`**

```bash
chezmoi apply -v   # make the change live first
~/bin/dots apply --dry-run
```

Expected: chezmoi shows planned changes; brew bundle skipped with "(dry-run)" note.

- [ ] **Step 3: Test `dots apply` (real)**

```bash
~/bin/dots apply
```

Expected: chezmoi applies, brew bundle reports "dependencies are satisfied", exit 0.

- [ ] **Step 4: shellcheck**

```bash
shellcheck ~/.local/share/chezmoi/home/bin/executable_dots
```

- [ ] **Step 5: Commit**

```bash
cd ~/.local/share/chezmoi
git add home/bin/executable_dots
git commit -m "feat(dots): implement apply subcommand"
```

## Task 2.3: `dots doctor`

**Files:**
- Modify: `home/bin/executable_dots`

- [ ] **Step 1: Replace `cmd_doctor` stub with real implementation**

```bash
cmd_doctor() {
  local fail=0

  echo
  log_info "== chezmoi =="
  if chezmoi doctor; then
    log_ok "chezmoi doctor passed"
  else
    log_err "chezmoi doctor reported issues"
    fail=1
  fi

  echo
  log_info "== Homebrew =="
  if brew bundle check --file="$DOTS_SOURCE_DIR/home/Brewfile" --verbose; then
    log_ok "Brewfile in sync with installed state"
  else
    log_warn "Brewfile drift detected (run 'dots sync' to capture or 'dots apply' to reconcile)"
    fail=1
  fi

  echo
  log_info "== Source repo =="
  local repo_status
  repo_status="$(git -C "$DOTS_SOURCE_DIR" status --porcelain)"
  if [ -z "$repo_status" ]; then
    log_ok "repo clean, nothing uncommitted"
  else
    log_warn "uncommitted changes in repo:"
    echo "$repo_status"
    fail=1
  fi

  echo
  log_info "== 1Password =="
  if op whoami >/dev/null 2>&1; then
    log_ok "1Password CLI signed in ($(op whoami | head -1))"
  else
    log_warn "1Password CLI not signed in (run 'op signin')"
    fail=1
  fi

  echo
  log_info "== dots-sync launchd agent =="
  if launchctl print "gui/$(id -u)/com.jarodtaylor.dots-sync" >/dev/null 2>&1; then
    local last_run
    last_run="$(stat -f '%Sm' "$DOTS_STATE_DIR/stdout.log" 2>/dev/null || echo 'never')"
    log_ok "launchd agent loaded (last log write: $last_run)"
  else
    log_warn "launchd agent not loaded — will be set up in Phase 3 (ok for now)"
  fi

  echo
  log_info "== AI tool directories =="
  local tool_dir
  for tool_dir in ~/.claude ~/.codex ~/.gemini ~/.cursor; do
    if [ -d "$tool_dir" ]; then
      log_ok "$(basename "$tool_dir") exists"
    else
      log_warn "$(basename "$tool_dir") missing"
    fi
  done

  echo
  if [ "$fail" = "0" ]; then
    log_ok "All checks passed."
  else
    log_warn "Some checks flagged attention (see above)."
  fi
  return "$fail"
}
```

- [ ] **Step 2: Apply and run**

```bash
chezmoi apply -v
~/bin/dots doctor
```

Expected: color-coded multi-section report. Probably 1–2 warnings (launchd not set up yet, etc.) — that's fine. Exit may be 1 if warnings; that's expected for now.

- [ ] **Step 3: shellcheck**

```bash
shellcheck ~/.local/share/chezmoi/home/bin/executable_dots
```

- [ ] **Step 4: Commit**

```bash
cd ~/.local/share/chezmoi
git add home/bin/executable_dots
git commit -m "feat(dots): implement doctor with multi-layer health check"
```

## Task 2.4: `dots status`

**Files:**
- Modify: `home/bin/executable_dots`

- [ ] **Step 1: Replace `cmd_status` stub**

```bash
cmd_status() {
  local dirty=0 brew_drift=0

  if ! git -C "$DOTS_SOURCE_DIR" diff-index --quiet HEAD -- 2>/dev/null; then
    dirty=1
  fi
  if ! brew bundle check --file="$DOTS_SOURCE_DIR/home/Brewfile" >/dev/null 2>&1; then
    brew_drift=1
  fi

  if [ "$dirty" = "0" ] && [ "$brew_drift" = "0" ]; then
    echo "clean"
    return 0
  fi

  local parts=()
  [ "$dirty" = "1" ]      && parts+=("repo-dirty")
  [ "$brew_drift" = "1" ] && parts+=("brew-drift")

  ( IFS=,; echo "${parts[*]}" )
  return 1
}
```

- [ ] **Step 2: Test**

```bash
chezmoi apply -v
~/bin/dots status
```

Expected: `clean` if nothing has changed, or a comma-separated list like `repo-dirty,brew-drift`.

- [ ] **Step 3: shellcheck**

```bash
shellcheck ~/.local/share/chezmoi/home/bin/executable_dots
```

- [ ] **Step 4: Commit**

```bash
cd ~/.local/share/chezmoi
git add home/bin/executable_dots
git commit -m "feat(dots): implement status subcommand"
```

## Task 2.5: Expand `.chezmoiignore`

**Files:**
- Modify: `home/.chezmoiignore`

- [ ] **Step 1: Add AI-tool runtime-state patterns**

Append to `home/.chezmoiignore`:

```text
# =============================================================================
# AI tool runtime state — captured by `dots sync` but filtered here so chezmoi
# does not track caches, logs, session databases, telemetry, or ephemeral state.
# Keep this list aggressive; when in doubt, ignore it.
# =============================================================================

# --- ~/.claude ---
.claude/cache/**
.claude/history.jsonl
.claude/projects/**
.claude/sessions/**
.claude/statsig/**
.claude/todos/**
.claude/ide/**
.claude/file-history/**
.claude/session-env/**
.claude/shell-snapshots/**
.claude/telemetry/**
.claude/backups/**
.claude/paste-cache/**
.claude/security_warnings_state_*.json
.claude/mcp-needs-auth-cache.json
.claude/stats-cache.json
.claude/plugins/marketplaces/**
.claude/plugins/cache/**
.claude/plugins/data/**
.claude/plugins/install-counts-cache.json
.claude/plugins/blocklist.json
.claude/cchubber-*
.claude/cchubber-report.html
.claude/debug/**
.claude/chrome/**
.claude/get-shit-done/**
.claude/gsd-file-manifest.json
.claude/downloads/**
.claude/tasks/**
.claude/teams/**
.claude/package.json

# --- ~/.codex ---
.codex/.tmp/**
.codex/cache/**
.codex/log/**
.codex/logs_*.sqlite
.codex/models_cache.json
.codex/session_index.jsonl
.codex/sessions/**
.codex/shell_snapshots/**
.codex/state_*.sqlite*
.codex/tmp/**
.codex/.personality_migration
.codex/gsd-file-manifest.json
.codex/get-shit-done/**

# --- ~/.gemini ---
.gemini/cache/**
.gemini/logs/**
.gemini/sessions/**
.gemini/tmp/**

# --- ~/.cursor ---
.cursor/workspaceStorage/**
.cursor/logs/**
.cursor/CachedData/**
.cursor/extensions/**
.cursor/User/globalStorage/**
.cursor/User/workspaceStorage/**

# Misc noise across all tools
.claude/.DS_Store
.codex/.DS_Store
.gemini/.DS_Store
.cursor/.DS_Store
```

- [ ] **Step 2: Render-check the ignore file**

```bash
cd ~/.local/share/chezmoi
chezmoi managed | grep -E '^\.claude/(cache|sessions|history)' && echo "LEAK — these should be ignored" || echo "OK"
```

Expected: `OK` (patterns not yet matched because nothing under those dirs is in source yet; that's fine — ignores are pre-configured before capture).

- [ ] **Step 3: Commit**

```bash
git add home/.chezmoiignore
git commit -m "feat: expand .chezmoiignore for AI tool runtime state"
```

## Task 2.6: Capture `~/.claude` into source

**Files:**
- Create: `home/dot_claude/` (tree of captured files)

- [ ] **Step 1: Add the whole directory (chezmoi respects .chezmoiignore)**

```bash
cd ~/.local/share/chezmoi
chezmoi add --recursive ~/.claude
```

Expected: takes a few seconds; many files added under `home/dot_claude/`.

- [ ] **Step 2: Verify runtime dirs were filtered**

```bash
ls home/dot_claude/ | head -30
ls home/dot_claude/cache/ 2>/dev/null && echo "LEAK" || echo "OK (cache filtered)"
ls home/dot_claude/sessions/ 2>/dev/null && echo "LEAK" || echo "OK (sessions filtered)"
ls home/dot_claude/projects/ 2>/dev/null && echo "LEAK" || echo "OK (projects filtered)"
```

Expected: three `OK` messages. If any `LEAK`, add the pattern to `.chezmoiignore` and re-add.

- [ ] **Step 3: Check for sensitive content**

```bash
grep -rE 'sk-|api[_-]?key|password|secret|token' home/dot_claude/ --include='*.json' --include='*.md' --include='*.sh' | grep -vE '(example|placeholder|"key":\s*"Some)' | head -30
```

Expected: nothing sensitive leaking. Anything that looks real → move to 1Password (next tasks).

- [ ] **Step 4: Confirm `.env` was captured (we'll template it next)**

```bash
ls home/dot_claude/dot_env 2>/dev/null
cat home/dot_claude/dot_env 2>/dev/null | head -5
```

Expected: file present. If it contains real secrets, they are **in git staging** but not committed yet — do not commit until Task 2.10 templates it.

- [ ] **Step 5: Stage but do not commit yet**

```bash
git add home/dot_claude/
```

Leave staged. Commit happens at end of Task 2.10 after secrets are templated.

## Task 2.7: Capture `~/.codex` into source

**Files:**
- Create: `home/dot_codex/` (tree)

- [ ] **Step 1: Add**

```bash
cd ~/.local/share/chezmoi
chezmoi add --recursive ~/.codex
```

- [ ] **Step 2: Verify filters**

```bash
ls home/dot_codex/cache/ 2>/dev/null && echo "LEAK" || echo "OK"
ls home/dot_codex/sessions/ 2>/dev/null && echo "LEAK" || echo "OK"
find home/dot_codex -name 'state_*.sqlite*' -o -name 'logs_*.sqlite' | head -5
```

Expected: `OK OK` and empty find output.

- [ ] **Step 3: Verify auth.json is captured (will be templated in Task 2.11)**

```bash
ls home/dot_codex/auth.json 2>/dev/null
```

Expected: file present. **Don't commit yet.**

- [ ] **Step 4: Stage**

```bash
git add home/dot_codex/
```

## Task 2.8: Capture `~/.gemini`

**Files:**
- Create: `home/dot_gemini/`

- [ ] **Step 1: Check if dir has meaningful content**

```bash
ls -la ~/.gemini/
du -sh ~/.gemini/
```

- [ ] **Step 2: Add**

```bash
chezmoi add --recursive ~/.gemini
```

- [ ] **Step 3: Verify no surprises**

```bash
ls ~/.local/share/chezmoi/home/dot_gemini/
```

Expected: config files, possibly skills. Caches/logs already filtered by Task 2.5 patterns.

- [ ] **Step 4: Stage**

```bash
git add home/dot_gemini/
```

## Task 2.9: Capture `~/.cursor`

**Files:**
- Create: `home/dot_cursor/`

- [ ] **Step 1: Capture config (not extension binaries)**

```bash
chezmoi add ~/.cursor/User/settings.json 2>/dev/null || true
chezmoi add ~/.cursor/User/keybindings.json 2>/dev/null || true
chezmoi add --recursive ~/.cursor/User/snippets 2>/dev/null || true
```

- [ ] **Step 2: Capture extensions list**

```bash
cursor --list-extensions > ~/.local/share/chezmoi/home/dot_cursor/extensions.txt
```

(If the `cursor` CLI isn't in PATH, install via Cursor app: Cmd-Shift-P → "Install 'cursor' command in PATH".)

- [ ] **Step 3: Verify**

```bash
cd ~/.local/share/chezmoi
ls home/dot_cursor/
```

Expected: `extensions.txt` + possibly `User/` subtree if present.

- [ ] **Step 4: Stage**

```bash
git add home/dot_cursor/
```

## Task 2.10: Template `~/.claude/.env` via 1Password

**Files:**
- Modify: `home/dot_claude/dot_env` → `home/dot_claude/dot_env.tmpl`

- [ ] **Step 1: Create 1Password entry for Claude env**

Inspect current `~/.claude/.env`:

```bash
cat ~/.claude/.env
```

For each `KEY=VALUE` line, decide which are secrets (API tokens) vs which are plain config (e.g., feature flags). Typically the whole file is secrets.

In 1Password: create a Secure Note named `Claude Code env` in `Personal` vault. Paste the full contents into the Note field. Tag `dotfiles`.

- [ ] **Step 2: Create the template**

```bash
cd ~/.local/share/chezmoi
cat > home/dot_claude/dot_env.tmpl <<'EOF'
{{/* Claude Code env vars — resolved from 1Password at apply time. */}}
{{ onepasswordRead "op://Personal/Claude Code env/notesPlain" }}
EOF
```

- [ ] **Step 3: Remove the non-template file (it has secrets in git staging)**

```bash
git reset HEAD home/dot_claude/dot_env 2>/dev/null || true
rm -f home/dot_claude/dot_env
# Also scrub from any prior accidental commit if one exists:
git log --all --oneline -- home/dot_claude/dot_env | head -5 \
  && log_warn "If any commits reference this file, consider git-filter-repo" || true
```

- [ ] **Step 4: Render-check**

```bash
chezmoi execute-template < home/dot_claude/dot_env.tmpl
```

Expected: the decrypted env contents printed to stdout (matches original `~/.claude/.env`).

- [ ] **Step 5: Apply and verify**

```bash
chezmoi apply -v
cat ~/.claude/.env
```

Expected: file contents unchanged from original. Claude Code still works.

- [ ] **Step 6: Stage the template**

```bash
git add home/dot_claude/dot_env.tmpl
```

## Task 2.11: Template `~/.codex/auth.json` via 1Password

**Files:**
- Modify: `home/dot_codex/auth.json` → `home/dot_codex/auth.json.tmpl`

- [ ] **Step 1: Create 1Password entry**

Inspect:

```bash
jq . ~/.codex/auth.json
```

Create Secure Note `Codex auth` in Personal vault. Paste full JSON contents into the Note field.

- [ ] **Step 2: Create template**

```bash
cd ~/.local/share/chezmoi
cat > home/dot_codex/auth.json.tmpl <<'EOF'
{{ onepasswordRead "op://Personal/Codex auth/notesPlain" }}
EOF
```

- [ ] **Step 3: Remove the non-template file**

```bash
git reset HEAD home/dot_codex/auth.json 2>/dev/null || true
rm -f home/dot_codex/auth.json
```

- [ ] **Step 4: Verify rendered output matches original**

```bash
chezmoi execute-template < home/dot_codex/auth.json.tmpl | jq . > /tmp/codex-auth-rendered.json
jq . ~/.codex/auth.json > /tmp/codex-auth-original.json
diff /tmp/codex-auth-rendered.json /tmp/codex-auth-original.json && echo "MATCH" || echo "DIFF — fix 1Password entry"
```

Expected: `MATCH`.

- [ ] **Step 5: Apply and verify Codex still works**

```bash
chezmoi apply -v
# Run any codex command that requires auth (adjust to your normal usage):
codex --version
# If your workflow has a no-op auth check, use it here.
```

Expected: codex authenticates normally.

- [ ] **Step 6: Stage**

```bash
git add home/dot_codex/auth.json.tmpl
```

## Task 2.12: Template `~/.claude.json`

**Files:**
- Create: `home/dot_claude.json.tmpl`

- [ ] **Step 1: Inspect the file**

```bash
du -h ~/.claude.json
jq 'keys' ~/.claude.json | head -40
```

- [ ] **Step 2: Identify machine-specific and sensitive fields**

Look for:
- Absolute paths (e.g., `/Users/jarodtaylor/...`) → replace with `{{ .chezmoi.homeDir }}` equivalent.
- Project lists keyed by absolute path → these should probably move to `.chezmoiignore` or be wiped on apply (Claude will rebuild on first invocation).
- Any OAuth tokens / auth blobs → template with `onepasswordRead`.

Create a notes scratch file:

```bash
jq 'paths(scalars) as $p | {path: $p, value: getpath($p)}' ~/.claude.json \
  | grep -iE 'token|secret|auth|key|password' > /tmp/claude-json-sensitive.txt
head -40 /tmp/claude-json-sensitive.txt
```

- [ ] **Step 3: Decide strategy**

Two options, pick one:

**Option A (simpler): Don't track `.claude.json` at all.** Add `.claude.json` to `.chezmoiignore`. Claude Code rebuilds it on first launch after a fresh apply. Trade-off: you lose project-history state on new machine (probably fine).

**Option B (full template):** Create `home/dot_claude.json.tmpl` that renders the non-sensitive skeleton, with `{{ onepasswordRead }}` for any auth fields and `{{ .chezmoi.homeDir }}` for paths.

**Recommendation:** Start with Option A. Promote to Option B only if you discover something important is being lost.

- [ ] **Step 4a: If Option A, add to ignore**

Append to `home/.chezmoiignore`:

```text
# ~/.claude.json: rebuilt by Claude Code on first launch; no need to track.
.claude.json
.claude.json.backup
```

Remove the file from source if previously added:

```bash
chezmoi forget ~/.claude.json 2>/dev/null || true
```

- [ ] **Step 4b: If Option B, create the template**

Build `home/dot_claude.json.tmpl` by hand, pasting the non-sensitive bulk and inserting `{{ onepasswordRead ... }}` for sensitive fields identified in Step 2. Render-check:

```bash
chezmoi execute-template < home/dot_claude.json.tmpl | jq . > /tmp/cj-rendered.json
diff <(jq . ~/.claude.json) /tmp/cj-rendered.json
```

Expected: diff shows only the intentional substitutions.

- [ ] **Step 5: Stage**

```bash
cd ~/.local/share/chezmoi
git add home/.chezmoiignore home/dot_claude.json.tmpl 2>/dev/null || git add home/.chezmoiignore
```

## Task 2.13: Commit all Phase 2 captures as one coherent commit

Now that secrets are templated, commit the captured AI tool dirs together.

- [ ] **Step 1: Final sensitive-content sweep**

```bash
cd ~/.local/share/chezmoi
grep -rE 'sk-[A-Za-z0-9]{20,}|ey[A-Za-z0-9-_]{30,}|ghp_[A-Za-z0-9]{30,}|AKIA[0-9A-Z]{16}' home/dot_claude home/dot_codex home/dot_gemini home/dot_cursor 2>/dev/null \
  | head -10
```

Expected: no output. Any hit = leaked secret → abort, template it.

- [ ] **Step 2: Diff the staging area**

```bash
git diff --cached --stat | head -30
```

Verify the scope looks right: hundreds of skills/agents files, no secrets.

- [ ] **Step 3: Commit the captures**

```bash
git commit -m "feat: capture AI tool configs into source tree

Captures ~/.claude, ~/.codex, ~/.gemini, ~/.cursor (configs only).
Runtime state (caches, sessions, sqlite DBs, logs, telemetry,
shell snapshots, backups) filtered via .chezmoiignore.

Secrets templated via 1Password:
- ~/.claude/.env → Personal/Claude Code env
- ~/.codex/auth.json → Personal/Codex auth

~/.claude.json excluded (rebuilt by Claude Code on first launch)."
```

## Task 2.14: Implement `dots sync`

**Files:**
- Modify: `home/bin/executable_dots`

- [ ] **Step 1: Replace `cmd_sync` stub with real implementation**

```bash
cmd_sync() {
  local dry_run=0 no_commit=0 do_push=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run)   dry_run=1 ;;
      --no-commit) no_commit=1 ;;
      --push)      do_push=1 ;;
      -v|--verbose) export DOTS_VERBOSE=1 ;;
      *) log_warn "unknown flag: $1" ;;
    esac
    shift
  done

  local brewfile="$DOTS_SOURCE_DIR/home/Brewfile"

  # --- 1. Dump Homebrew state to Brewfile ---
  log_info "capturing Homebrew state..."
  if [ "$dry_run" = "1" ]; then
    local tmpdump
    tmpdump="$(mktemp)"
    brew bundle dump --force --describe --file="$tmpdump" >/dev/null
    if ! diff -u "$brewfile" "$tmpdump" >/dev/null 2>&1; then
      log_warn "Brewfile would change; diff:"
      diff -u "$brewfile" "$tmpdump" | head -40
    else
      log_ok "Brewfile is in sync"
    fi
    rm -f "$tmpdump"
  else
    brew bundle dump --force --describe --file="$brewfile"
  fi

  # --- 2. Re-capture AI tool dirs ---
  log_info "capturing AI tool dirs..."
  local tool_dir
  for tool_dir in ~/.claude ~/.codex ~/.gemini ~/.cursor; do
    if [ -d "$tool_dir" ]; then
      if [ "$dry_run" = "1" ]; then
        log_debug "(dry-run) would: chezmoi add --recursive $tool_dir"
      else
        chezmoi add --recursive "$tool_dir" 2>&1 | grep -vE '^$' || true
      fi
    fi
  done

  # --- 3. Show diff ---
  cd "$DOTS_SOURCE_DIR" || exit 1
  if git diff --quiet && git diff --cached --quiet; then
    log_ok "no drift — repo is in sync"
    return 0
  fi

  log_info "drift detected:"
  git --no-pager diff --stat HEAD | sed 's/^/  /'

  if [ "$dry_run" = "1" ]; then
    log_info "dry-run: stopping here"
    return 0
  fi

  if [ "$no_commit" = "1" ]; then
    log_info "--no-commit: leaving changes unstaged"
    return 0
  fi

  # --- 4. Commit ---
  local summary
  summary="$(git diff --stat HEAD | tail -1)"
  git add -A
  git commit -m "state sync $(date +%Y-%m-%d): $summary"

  # --- 5. Optional push ---
  if [ "$do_push" = "1" ]; then
    log_info "pushing to origin..."
    git push
    log_ok "pushed"
  fi

  log_ok "sync complete"
}
```

- [ ] **Step 2: Apply and dry-run**

```bash
cd ~/.local/share/chezmoi
chezmoi apply -v
~/bin/dots sync --dry-run
```

Expected: prints brewfile diff (if any), "no drift" or diff stat, then "dry-run: stopping here".

- [ ] **Step 3: Real sync**

```bash
~/bin/dots sync
```

Expected: commits any drift with a message like `state sync 2026-04-16: 3 files changed, 12 insertions(+), 2 deletions(-)`.

- [ ] **Step 4: Run sync again — should be clean**

```bash
~/bin/dots sync
```

Expected: `no drift — repo is in sync`, exit 0.

- [ ] **Step 5: shellcheck**

```bash
shellcheck ~/.local/share/chezmoi/home/bin/executable_dots
```

- [ ] **Step 6: Commit**

```bash
cd ~/.local/share/chezmoi
git add home/bin/executable_dots
git commit -m "feat(dots): implement sync subcommand

Captures brew bundle dump, chezmoi adds AI tool dirs, shows
diff, auto-commits with descriptive message, optional push."
```

## Task 2.15: VM Checkpoint 2 — `dots sync` end-to-end in VM

- [ ] **Step 1: Push branch**

```bash
cd ~/.local/share/chezmoi
git push
```

- [ ] **Step 2: Restore VM to `clean-macos-with-1password`**

In Parallels: snapshot → Go To.

- [ ] **Step 3: In VM, run bootstrap on the design branch**

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --verbose --apply --branch design/chezmoi-ironclad jarodtaylor
```

- [ ] **Step 4: Verify `dots` is installed in VM**

```bash
which dots
dots help
dots doctor
```

Expected: all exit 0. `doctor` may warn about launchd (that's next phase).

- [ ] **Step 5: Make a deliberate drift and verify capture**

```bash
brew install cowsay
dots sync --dry-run
```

Expected: Brewfile diff shows `+brew "cowsay"`.

```bash
dots sync
```

Expected: commits the change.

- [ ] **Step 6: Remove, re-sync**

```bash
brew uninstall cowsay
dots sync
```

Expected: commits the removal.

- [ ] **Step 7: If all green, proceed to Phase 3**

If any failure: record, fix on host, push, restore VM, repeat.

---

# Phase 3: Automation & Bootstrap

Goal: launchd auto-sync, `bootstrap.sh`, human-facing documentation. Exit with one-liner bootstrap working in a fresh VM.

## Task 3.1: launchd plist

**Files:**
- Create: `home/Library/LaunchAgents/com.jarodtaylor.dots-sync.plist`

- [ ] **Step 1: Create the plist**

```bash
mkdir -p ~/.local/share/chezmoi/home/Library/LaunchAgents
cat > ~/.local/share/chezmoi/home/Library/LaunchAgents/com.jarodtaylor.dots-sync.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.jarodtaylor.dots-sync</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/zsh</string>
    <string>-lc</string>
    <string>/Users/jarodtaylor/bin/dots sync --push &gt;&gt; /Users/jarodtaylor/.local/state/dots-sync/stdout.log 2&gt;&gt; /Users/jarodtaylor/.local/state/dots-sync/stderr.log</string>
  </array>

  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>3</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>

  <key>RunAtLoad</key>
  <false/>

  <key>KeepAlive</key>
  <false/>

  <key>LowPriorityIO</key>
  <true/>

  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/bin:/bin</string>
    <key>HOME</key>
    <string>/Users/jarodtaylor</string>
  </dict>

  <key>WorkingDirectory</key>
  <string>/Users/jarodtaylor</string>
</dict>
</plist>
EOF
```

- [ ] **Step 2: Validate plist**

```bash
plutil -lint ~/.local/share/chezmoi/home/Library/LaunchAgents/com.jarodtaylor.dots-sync.plist
```

Expected: `OK`.

- [ ] **Step 3: Commit**

```bash
cd ~/.local/share/chezmoi
git add home/Library/LaunchAgents/com.jarodtaylor.dots-sync.plist
git commit -m "feat: add launchd plist for daily dots-sync at 03:00"
```

## Task 3.2: After-apply script to load launchd agent

**Files:**
- Create: `home/.chezmoiscripts/run_onchange_after_20-launchd-reload.sh.tmpl`

- [ ] **Step 1: Create the script**

```bash
cat > ~/.local/share/chezmoi/home/.chezmoiscripts/run_onchange_after_20-launchd-reload.sh.tmpl <<'EOF'
#!/bin/bash

set -eufo pipefail

{{ template "scripts/script_helper" . }}

# Hash of the plist so this script re-runs when the plist changes.
# Plist hash: {{ include "Library/LaunchAgents/com.jarodtaylor.dots-sync.plist" | sha256sum }}

PLIST_SRC="$HOME/Library/LaunchAgents/com.jarodtaylor.dots-sync.plist"
LABEL="com.jarodtaylor.dots-sync"

if [ ! -f "$PLIST_SRC" ]; then
  log_warning "dots-sync plist not found at $PLIST_SRC; skipping."
  exit 0
fi

UID_NUM="$(id -u)"
DOMAIN="gui/$UID_NUM"

# Bootout if loaded (idempotent reload).
if launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; then
  log_info "dots-sync agent already loaded; rebooting..."
  launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
fi

log_info "loading dots-sync launchd agent..."
launchctl bootstrap "$DOMAIN" "$PLIST_SRC"
launchctl enable "$DOMAIN/$LABEL"

log_debug "dots-sync agent loaded"
EOF
```

- [ ] **Step 2: Render-check**

```bash
cd ~/.local/share/chezmoi
chezmoi execute-template < home/.chezmoiscripts/run_onchange_after_20-launchd-reload.sh.tmpl
```

Expected: fully rendered shell script with embedded hash line.

- [ ] **Step 3: shellcheck**

```bash
chezmoi execute-template < home/.chezmoiscripts/run_onchange_after_20-launchd-reload.sh.tmpl | shellcheck -s bash -
```

- [ ] **Step 4: Apply**

```bash
chezmoi apply -v
```

Expected: agent loads. Confirm:

```bash
launchctl print "gui/$(id -u)/com.jarodtaylor.dots-sync" | head -10
```

Expected: plist info printed, state = waiting.

- [ ] **Step 5: Dry-run the agent manually**

```bash
launchctl kickstart -p "gui/$(id -u)/com.jarodtaylor.dots-sync"
sleep 3
tail -20 ~/.local/state/dots-sync/stdout.log
tail -5 ~/.local/state/dots-sync/stderr.log 2>/dev/null || true
```

Expected: log shows sync ran, either "no drift" or a committed sync.

- [ ] **Step 6: Commit**

```bash
cd ~/.local/share/chezmoi
git add home/.chezmoiscripts/run_onchange_after_20-launchd-reload.sh.tmpl
git commit -m "feat: auto-load dots-sync launchd agent on chezmoi apply"
```

## Task 3.3: Write `bootstrap.sh`

**Files:**
- Create: `bootstrap.sh` (repo root)
- Remove: `install.sh`

- [ ] **Step 1: Write the new bootstrap**

```bash
cat > ~/.local/share/chezmoi/bootstrap.sh <<'EOF'
#!/usr/bin/env bash
# bootstrap.sh — zero-to-productive macOS setup for this dotfiles repo
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/jarodtaylor/dotfiles/main/bootstrap.sh | bash
#
# Prereqs (not handled here — see SETUP.md):
#   1. macOS with user account created
#   2. Xcode Command Line Tools installed (xcode-select --install)
#   3. 1Password app installed, signed in, SSH agent + CLI enabled
#   4. 1Password CLI (`op`) installed and authenticated (`op signin`)
#
# This script does:
#   1. Install Homebrew (if missing)
#   2. Install chezmoi
#   3. chezmoi init --apply from this repo
#   (chezmoi apply then runs Brewfile, resolves 1Password templates,
#    loads the dots-sync launchd agent.)

set -euo pipefail

REPO_USER="jarodtaylor"
REPO_NAME="dotfiles"
BRANCH="${CHEZMOI_BRANCH:-main}"

log()  { printf "\033[34m➜\033[0m %s\n" "$*"; }
ok()   { printf "\033[32m✓\033[0m %s\n" "$*"; }
warn() { printf "\033[33m⚠\033[0m %s\n" "$*"; }
die()  { printf "\033[31m✗\033[0m %s\n" "$*" >&2; exit 1; }

# --- Preflight ---
log "preflight: checking prerequisites"

if ! xcode-select -p >/dev/null 2>&1; then
  die "Xcode Command Line Tools not installed. Run: xcode-select --install"
fi
ok "Xcode CLT present"

if ! command -v op >/dev/null 2>&1; then
  warn "1Password CLI (op) not in PATH. Secrets will fail to resolve."
  warn "Install via https://app-updates.agilebits.com/product_history/CLI2 and re-run."
  die  "Aborting. See SETUP.md for 1Password prereqs."
fi
ok "1Password CLI present"

if ! op whoami >/dev/null 2>&1; then
  die "1Password CLI not signed in. Run: op signin"
fi
ok "1Password CLI authenticated"

# --- Homebrew ---
if ! command -v brew >/dev/null 2>&1; then
  log "installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  ok "Homebrew already installed"
fi

# shellenv
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# --- chezmoi ---
if ! command -v chezmoi >/dev/null 2>&1; then
  log "installing chezmoi..."
  brew install chezmoi
else
  ok "chezmoi already installed"
fi

# --- init + apply ---
log "running: chezmoi init --apply --branch $BRANCH $REPO_USER"
chezmoi init --apply --verbose --branch "$BRANCH" "$REPO_USER"

ok "bootstrap complete"
log "next: open a new shell; run 'dots doctor' to verify everything is green"
EOF
chmod +x ~/.local/share/chezmoi/bootstrap.sh
```

- [ ] **Step 2: shellcheck**

```bash
shellcheck ~/.local/share/chezmoi/bootstrap.sh
```

Expected: no errors.

- [ ] **Step 3: Remove old install.sh**

```bash
cd ~/.local/share/chezmoi
git rm install.sh
```

- [ ] **Step 4: Commit**

```bash
git add bootstrap.sh
git commit -m "feat: replace install.sh with bootstrap.sh

bootstrap.sh fixes the hardcoded branch ref (previously
pointed at 'refactor-simplify'), adds preflight checks for
Xcode CLT + 1Password CLI auth, and delegates all package
installation to the Brewfile via chezmoi apply."
```

## Task 3.4: Implement `dots new-machine`

**Files:**
- Modify: `home/bin/executable_dots`

- [ ] **Step 1: Replace `cmd_new_machine` stub**

```bash
cmd_new_machine() {
  cat <<'EOM'
This command helps you through the one-time machine setup.
Run this AFTER you've finished `bootstrap.sh`.

Steps:
  1) open a fresh shell so PATH is updated
  2) verify 1Password CLI session is active
  3) run `dots doctor` and fix any warnings
  4) restart once to ensure launchd agent picks up cleanly
  5) optionally: `dots sync --dry-run` to see if any drift remains

If something looks wrong, read SETUP.md and docs/TESTING.md in the repo.
EOM

  log_info "verifying prereqs..."
  local ok=1
  if op whoami >/dev/null 2>&1; then
    log_ok "1Password signed in"
  else
    log_warn "1Password not signed in — run 'op signin'"
    ok=0
  fi

  if command -v chezmoi >/dev/null 2>&1; then
    log_ok "chezmoi installed"
  else
    log_err "chezmoi not installed — did bootstrap.sh complete?"
    ok=0
  fi

  if command -v brew >/dev/null 2>&1; then
    log_ok "brew installed"
  else
    log_err "brew not installed — did bootstrap.sh complete?"
    ok=0
  fi

  if [ "$ok" = "1" ]; then
    log_info "looks good. Running 'dots doctor' now:"
    cmd_doctor
  else
    log_err "fix the above before continuing"
    return 1
  fi
}
```

- [ ] **Step 2: Apply and test**

```bash
cd ~/.local/share/chezmoi
chezmoi apply -v
~/bin/dots new-machine
```

Expected: walkthrough text + doctor output.

- [ ] **Step 3: Commit**

```bash
git add home/bin/executable_dots
git commit -m "feat(dots): implement new-machine helper"
```

## Task 3.5: Refresh README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace contents**

```bash
cat > ~/.local/share/chezmoi/README.md <<'EOF'
# Personal Dotfiles (Chezmoi)

Opinionated macOS dotfiles managed by [chezmoi](https://www.chezmoi.io/).
Hybrid source-of-truth model: machine is source of truth for installed
packages and AI tool state; repo is source of truth for hand-edited configs.

> **Fair Warning**: highly personal setup. Fork and adapt; don't expect
> a plug-and-play experience on a different person's workflow.

## Quick start (new machine)

Prereqs — see [`SETUP.md`](SETUP.md) for detail:

1. macOS installed; user account created
2. `xcode-select --install`
3. 1Password app installed + signed in (enable SSH agent + CLI integration)
4. 1Password CLI installed + authenticated (`op signin`)

Then:

```bash
curl -fsSL https://raw.githubusercontent.com/jarodtaylor/dotfiles/main/bootstrap.sh | bash
```

That:
- Installs Homebrew and chezmoi
- Clones this repo + `chezmoi apply`
- Brewfile installs ~60 packages (CLI + casks)
- Configs rendered with secrets pulled from 1Password
- `dots-sync` launchd agent loaded (daily at 03:00)

## Daily workflow

```bash
brew install <anything>        # just works — no chezmoi edit needed
# ... add a skill to ~/.claude/skills/ ...
# ... edit ~/.claude/CLAUDE.md ...

dots sync                      # capture changes into repo and commit
dots sync --push               # + push to origin
```

The launchd agent runs `dots sync --push` nightly. You rarely need to run
it manually unless you want an immediate save point.

## Key commands

| Command | Purpose |
|---|---|
| `dots sync` | Capture drift into repo; commit (and optionally push) |
| `dots apply` | Reconcile machine with repo (`chezmoi apply` + `brew bundle`) |
| `dots doctor` | Multi-layer health check |
| `dots status` | One-line drift summary |
| `dots new-machine` | First-run helper after `bootstrap.sh` |
| `dots edit` | Open the source repo in `$EDITOR` |

## Architecture

See [`docs/superpowers/specs/2026-04-16-chezmoi-ironclad-design.md`](docs/superpowers/specs/2026-04-16-chezmoi-ironclad-design.md) for the full design.

Short version:
- **Machine-of-truth for mutable state**: brew, AI tool skills/agents/plugins. Captured via `dots sync`.
- **Repo-of-truth for authored configs**: `nvim`, `ghostty`, `starship`, `zsh`, `git`, etc. Edit in repo, `chezmoi apply` to machine.
- **Runtime state never syncs**: logs, caches, session history, sqlite DBs — filtered in `.chezmoiignore`.
- **Secrets via 1Password**: SSH keys, work git email, age decryption key, Claude/Codex auth.

## Key layout

```
bootstrap.sh                                    one-liner entry
home/                                            chezmoi source root
├── Brewfile                                     package manifest (tap/brew/cask)
├── bin/executable_dots                          the `dots` CLI
├── Library/LaunchAgents/com.jarodtaylor.dots-sync.plist
├── dot_claude/, dot_codex/, dot_gemini/, dot_cursor/    captured AI tool state
├── dot_config/                                  authored configs (nvim, ghostty, etc.)
├── private_dot_ssh/                             SSH config (1Password-backed)
├── .chezmoiscripts/                             runtime scripts (packages, pam, launchd)
└── .chezmoi.toml.tmpl                           per-machine config, 1Password integration
```

## Related docs

- [`SETUP.md`](SETUP.md) — detailed new-machine walkthrough
- [`docs/AUDITING.md`](docs/AUDITING.md) — how to decide sync vs. ignore for a new AI tool
- [`docs/TESTING.md`](docs/TESTING.md) — Parallels VM workflow, dry-run recipes
- [`docs/KNOWN_ISSUES.md`](docs/KNOWN_ISSUES.md) — known rough edges

## Inspiration

- [Tom Payne's dotfiles](https://github.com/twpayne/dotfiles) (chezmoi creator)
- [Chezmoi documentation](https://www.chezmoi.io/)
EOF
```

- [ ] **Step 2: Commit**

```bash
cd ~/.local/share/chezmoi
git add README.md
git commit -m "docs: refresh README for ironclad architecture"
```

## Task 3.6: Write SETUP.md

**Files:**
- Create: `SETUP.md`

- [ ] **Step 1: Write the walkthrough**

```bash
cat > ~/.local/share/chezmoi/SETUP.md <<'EOF'
# New Machine Setup

The one-liner in the README does the heavy lifting. This doc covers the
pre-one-liner steps (things that can't be automated yet) plus post-bootstrap
verification.

Total time: ~5 minutes of active clicks + 30–60 minutes walkaway.

## 0. Physical setup

Fresh macOS install, user account created, connected to wifi. Sign in to your
Apple ID (or skip; not strictly required).

## 1. Xcode Command Line Tools

```bash
xcode-select --install
```

A dialog appears. Click **Install**. Accept the license. Takes 5–15 minutes.
Wait for completion before proceeding.

Verify:

```bash
xcode-select -p
# Expected: /Library/Developer/CommandLineTools
```

## 2. 1Password (app + CLI)

### 2a. Install the 1Password app

Download from [1password.com/downloads/mac](https://1password.com/downloads/mac/).
Sign in with your account.

In **1Password → Settings → Developer**:
- Enable **Use the SSH agent**
- Enable **Integrate with 1Password CLI**

### 2b. Install the 1Password CLI

From [1password.com/downloads/command-line](https://1password.com/downloads/command-line/),
download the `.pkg` installer for macOS (or install via Homebrew *after*
bootstrap if you prefer — but `op` must exist before `bootstrap.sh` runs).

Verify:

```bash
op --version
```

Expected: version string, e.g. `2.30.x`.

### 2c. Authenticate

```bash
op account add   # paste sign-in URL, email, secret key
op signin        # unlocks session
op whoami        # verify
```

## 3. Verify required 1Password entries exist

The templates expect these entries in your `Personal` vault:

| Entry name | Type | Field read |
|---|---|---|
| `Dotfiles Age Key` | Secure Note | `notesPlain` |
| `Claude Code env` | Secure Note | `notesPlain` |
| `Codex auth` | Secure Note | `notesPlain` |
| (existing) Personal SSH key | SSH key | `public key` |
| (existing) Work SSH key | SSH key | `public key` |

Spot-check each:

```bash
op item list --vault Personal | grep -E 'Age Key|Claude Code env|Codex auth'
```

If any is missing, create it (see the main spec §8 for contents) before running bootstrap.

## 4. Run the one-liner

```bash
curl -fsSL https://raw.githubusercontent.com/jarodtaylor/dotfiles/main/bootstrap.sh | bash
```

This takes 30–60 minutes walkaway. Go make coffee.

When it finishes, close the terminal and open a new one (so the new PATH and
zsh config load).

## 5. Verify

```bash
dots doctor
```

Everything green. If anything warns or errors, see `docs/KNOWN_ISSUES.md` or
follow the hint in the warning.

```bash
dots new-machine
```

Walks you through any remaining first-run steps.

## 6. Optional: restart

Once to ensure all launchd agents and login items take effect cleanly.

---

## Troubleshooting

**`op whoami` fails after restart.** Your 1Password session expired. Run
`op signin` again. Chezmoi templates that read from op will fail until
you do.

**`chezmoi apply` says "recipient mismatch" for age.** The public key
stored in `.chezmoi.toml.tmpl` doesn't match the private key in 1Password.
Verify the `Dotfiles Age Key` entry contains the full keyfile (two lines:
comment + `AGE-SECRET-KEY-...`).

**Something broke after a sync.** Roll back: `cd $(chezmoi source-path) && git log --oneline | head`, then `git revert <hash>` the bad commit. Then `dots apply`.
EOF
```

- [ ] **Step 2: Commit**

```bash
cd ~/.local/share/chezmoi
git add SETUP.md
git commit -m "docs: add SETUP.md new-machine walkthrough"
```

## Task 3.7: Write docs/AUDITING.md

**Files:**
- Create: `docs/AUDITING.md`

- [ ] **Step 1: Write**

```bash
cat > ~/.local/share/chezmoi/docs/AUDITING.md <<'EOF'
# Auditing a New AI Tool

When a new AI tool lands on your machine (new `~/.newtool/` directory),
`dots sync` does **not** automatically pick it up. This prevents accidentally
capturing secrets or blowing up the repo with runtime state.

Adding a new tool is a 5-minute review. This doc is the checklist.

## Step 1: Inventory what's there

```bash
ls -la ~/.newtool/
du -sh ~/.newtool/*
```

Identify:
- **Config files** (hand-edited or tool-written settings): sync these
- **Skills/agents/plugins/commands**: sync these
- **Logs, caches, sessions, sqlite DBs**: ignore these
- **Auth tokens, API keys**: 1Password template

## Step 2: Decide the taxonomy

Fill in a mental table like:

| Path | Classification |
|---|---|
| `~/.newtool/config.toml` | SYNC |
| `~/.newtool/skills/` | SYNC |
| `~/.newtool/cache/` | IGNORE |
| `~/.newtool/sessions.db` | IGNORE |
| `~/.newtool/auth.json` | SECRET (1Password) |

## Step 3: Extend `.chezmoiignore`

Add patterns for the IGNORE entries. Pattern scope matters — use
`.newtool/cache/**` not `cache/**`.

```text
# --- ~/.newtool ---
.newtool/cache/**
.newtool/logs/**
.newtool/sessions.db
```

## Step 4: Extend `dots sync`

Open `home/bin/executable_dots`, find the loop:

```bash
for tool_dir in ~/.claude ~/.codex ~/.gemini ~/.cursor; do
```

Add `~/.newtool` to the list.

## Step 5: Handle secrets

If there are auth files, create a 1Password entry and template the file.
Pattern:

1. Move secret to 1Password Secure Note `NewTool auth` in `Personal` vault.
2. Replace file with a `.tmpl` that calls `onepasswordRead`:

```go-template
{{ onepasswordRead "op://Personal/NewTool auth/notesPlain" }}
```

3. Delete the original file from `home/dot_newtool/` before committing.

## Step 6: First capture

```bash
dots sync --dry-run   # preview
dots sync             # commit
```

## Step 7: Verify no secrets leaked

```bash
cd $(chezmoi source-path)
grep -rE 'sk-[A-Za-z0-9]{20,}|ey[A-Za-z0-9-_]{30,}|ghp_[A-Za-z0-9]{30,}' home/dot_newtool/
```

Expected: no output. If anything leaks, you missed a secret in Step 5 —
fix and `git commit --amend` (if you haven't pushed) or follow the
"leaked secret" runbook (not yet written — add if this happens).

## Red flags

- File > 1 MB → probably a cache or DB; IGNORE it.
- SQLite files (`.sqlite`, `.db`) → IGNORE.
- Anything named `*cache*`, `*history*`, `*session*`, `*log*`, `*telemetry*` → IGNORE.
- Any file containing `sk-`, `ey`, `ghp_`, `AKIA`, `Bearer ` → SECRET.
EOF
```

- [ ] **Step 2: Commit**

```bash
cd ~/.local/share/chezmoi
git add docs/AUDITING.md
git commit -m "docs: add AUDITING.md for onboarding new AI tools"
```

## Task 3.8: Write docs/TESTING.md

**Files:**
- Create: `docs/TESTING.md`

- [ ] **Step 1: Write**

```bash
cat > ~/.local/share/chezmoi/docs/TESTING.md <<'EOF'
# Testing & Validation

Layered, fast-feedback-first. Don't boot a VM for every change.

## 1. Template render check (seconds)

When editing a `.tmpl`:

```bash
chezmoi execute-template < home/path/to/file.tmpl
```

Output should be fully rendered (no stray `{{ }}`). Pipe to `shellcheck -s bash -` if it's a shell script.

## 2. Shellcheck (seconds)

```bash
shellcheck home/bin/executable_dots bootstrap.sh
```

## 3. Dry-run apply (~10s)

```bash
chezmoi apply --dry-run -v
```

Tells you what apply would do without doing it. Great for catching regressions.

## 4. `dots doctor` (seconds)

```bash
dots doctor
```

Multi-layer health check. Keep it green.

## 5. Parallels VM integration (30–60 min)

Used for milestone validation, not every change.

### Baseline snapshot

`clean-macos-with-1password` — saved after:
- Fresh macOS install
- Xcode Command Line Tools installed
- 1Password app installed, signed in, CLI integration enabled
- 1Password CLI installed, `op signin` complete

Keep this snapshot sacred. Never overwrite.

### Test procedure

1. In Parallels: Actions → Manage Snapshots → Go To `clean-macos-with-1password`.
2. Open Terminal in the VM.
3. Run:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/jarodtaylor/dotfiles/<branch>/bootstrap.sh | bash
   ```
4. Wait for completion (~30–60 min walkaway).
5. Open a new terminal window.
6. Verify:
   ```bash
   dots doctor
   dots status
   brew bundle check --file=$(chezmoi source-path)/home/Brewfile
   launchctl print "gui/$(id -u)/com.jarodtaylor.dots-sync" | head -5
   ```
7. Induce drift, confirm capture works:
   ```bash
   brew install cowsay
   dots sync --dry-run   # expect to see +cowsay
   dots sync             # commits
   brew uninstall cowsay
   dots sync             # commits removal
   ```
8. If everything passes, revert snapshot (optional) — VM test is complete.

### When to run VM integration

- End of every phase (CP-1, CP-2, CP-3, CP-4)
- Before any merge to `main`
- After any change to `bootstrap.sh`, `.chezmoiscripts/`, or 1Password integration
- After dependency bumps (chezmoi version, brew migration)

### When to skip VM integration

- Small Brewfile additions (a single `brew` line)
- Doc-only changes
- New skill files under `dot_claude/skills/`

## 6. Optional: GitHub Actions CI

Not implemented in Phase 4 — listed as Phase 5 optional. If you want it:

- `shellcheck` all shell files
- `chezmoi execute-template` every `.tmpl`
- `plutil -lint` the launchd plist
- Trigger on PRs to `main`

See `docs/superpowers/specs/2026-04-16-chezmoi-ironclad-design.md` §13 for more.
EOF
```

- [ ] **Step 2: Commit**

```bash
cd ~/.local/share/chezmoi
git add docs/TESTING.md
git commit -m "docs: add TESTING.md with layered validation ladder"
```

## Task 3.9: Refresh root CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Rewrite**

```bash
cat > ~/.local/share/chezmoi/CLAUDE.md <<'EOF'
# CLAUDE.md

Guidance for Claude Code when working in this repo.

## Project

Chezmoi-managed dotfiles for macOS with a **hybrid source-of-truth model**:
- Repo is source of truth for hand-edited configs (nvim, ghostty, zsh, git, etc.).
- Machine is source of truth for mutable inventory (Homebrew, AI tool skills/agents/plugins).
- `dots sync` captures machine → repo. `chezmoi apply` (via `dots apply`) pushes repo → machine.
- Runtime state (logs, caches, sessions, DBs) filtered via `.chezmoiignore`.
- Secrets via 1Password templates at apply time. No plaintext secrets in git.

Source root is `home/` (set by `.chezmoiroot`). All target paths relative to `~`.

## `dots` CLI (`home/bin/executable_dots`)

Single Bash script, the main UX for the repo:
- `dots sync` — capture drift, commit, optionally push
- `dots apply` — `chezmoi apply` + `brew bundle --cleanup`
- `dots doctor` — multi-layer health check
- `dots status` — one-line drift summary
- `dots new-machine` — first-run helper
- `dots edit` — open repo in $EDITOR

launchd agent `com.jarodtaylor.dots-sync` runs `dots sync --push` nightly at 03:00.

## Chezmoi conventions

- **File prefixes**: `dot_` → `.`, `private_` → 0600, `executable_` → 0755, `encrypted_` → decrypted on apply.
- **Scripts**: `run_onchange_before_*` / `run_onchange_after_*` / `run_once_*`. Lexicographic ordering; numeric prefixes control sequence.
- **Template variables**: `.chezmoi.os`, `.chezmoi.arch`, `.brew_prefix`, `.ssh_key`, `.work_ssh_key`, plus `.chezmoi.sourceDir` / `.chezmoi.homeDir`.
- **Script helpers**: `home/.chezmoitemplates/scripts/` has `script_helper` (logging functions), `script_sudo`, `script_eval_brew`. Use these via `{{ template "scripts/script_helper" . }}`.
- **External deps**: `.chezmoiexternal.toml` (e.g., catppuccin zsh-syntax-highlighting).

## Key files

| File | Purpose |
|---|---|
| `bootstrap.sh` | One-liner entry point. Installs Xcode CLT check, brew, chezmoi, then `chezmoi init --apply`. |
| `home/Brewfile` | Declarative package manifest. `dots sync` dumps to it, `chezmoi apply` installs from it. |
| `home/bin/executable_dots` | Main CLI. |
| `home/Library/LaunchAgents/com.jarodtaylor.dots-sync.plist` | Daily auto-sync agent. |
| `home/dot_claude/`, `dot_codex/`, `dot_gemini/`, `dot_cursor/` | Captured AI tool state. |
| `home/.chezmoiignore` | Aggressive filters for AI tool runtime state. |
| `home/.chezmoiscripts/run_onchange_before_10-install-packages.sh.tmpl` | Shrunk to `brew bundle` + mise. |
| `home/.chezmoiscripts/run_onchange_after_20-launchd-reload.sh.tmpl` | Loads the sync agent. |
| `home/.chezmoi.toml.tmpl` | Per-machine config; 1Password integration (SSH keys, age key, work git). |

## Working on this repo

1. Always run `chezmoi diff` before `chezmoi apply` (or just use `dots apply --dry-run`).
2. Edit configs in `home/`, not in `~/.config/` directly.
3. Adding a Homebrew package: just `brew install foo`. `dots sync` captures it.
4. Adding an AI tool skill: just drop the file under `~/.claude/skills/`. `dots sync` captures it.
5. Adding a new AI tool entirely: see `docs/AUDITING.md`.
6. Testing changes: see `docs/TESTING.md`.

## Secrets

Never commit secrets. Templates with `{{ onepasswordRead "op://..." }}` resolve
at `chezmoi apply` time. Current entries in `Personal` vault:
- `Dotfiles Age Key` — chezmoi encryption identity
- `Claude Code env` — Claude Code API env vars
- `Codex auth` — Codex auth JSON
- SSH keys — per-profile

## Templating

All `.tmpl` files use chezmoi's Go template engine.

Debug with:
```bash
chezmoi execute-template < home/path/to/file.tmpl
```

## Homebrew prefix

`/opt/homebrew` on Apple Silicon (arm64), `/usr/local` on Intel. Always use `.brew_prefix` in templates.

## Subdirectory CLAUDE.md files

Module-specific guidance can live in subdirectory `CLAUDE.md` files (e.g., `home/dot_config/nvim/CLAUDE.md`). They load automatically when Claude works in those directories.
EOF
```

- [ ] **Step 2: Commit**

```bash
cd ~/.local/share/chezmoi
git add CLAUDE.md
git commit -m "docs: refresh CLAUDE.md for ironclad architecture"
```

## Task 3.10: VM Checkpoint 3 — one-liner bootstrap in fresh VM

- [ ] **Step 1: Push all Phase 3 commits**

```bash
cd ~/.local/share/chezmoi
git push
```

- [ ] **Step 2: Restore VM to baseline**

In Parallels: Go To `clean-macos-with-1password`.

- [ ] **Step 3: Run the new one-liner**

In VM:

```bash
curl -fsSL https://raw.githubusercontent.com/jarodtaylor/dotfiles/design/chezmoi-ironclad/bootstrap.sh | bash
```

Time it.

- [ ] **Step 4: After completion, open a new terminal in VM and verify**

```bash
dots doctor
dots status
launchctl print "gui/$(id -u)/com.jarodtaylor.dots-sync" | head -5
cat ~/.claude/.env                        # Should show decoded contents
jq . ~/.codex/auth.json | head -5         # Should show valid JSON
```

Expected: `dots doctor` all green (or only minor warnings), status `clean`, launchd agent loaded, secrets resolved.

- [ ] **Step 5: Run the drift capture test from TESTING.md §5 step 7**

Verify end-to-end sync capture works.

- [ ] **Step 6: Record the total bootstrap time**

For `docs/KNOWN_ISSUES.md` / later measurement. Aim for under 60 minutes.

- [ ] **Step 7: If all green, proceed to Phase 4. Else, fix and repeat.**

---

# Phase 4: Validation & Merge

Goal: final confidence pass and merge to `main`. Exit with ironclad setup live on the primary M1 Max.

## Task 4.1: Host `dots doctor`

- [ ] **Step 1: Run on the primary M1 Max host**

```bash
dots doctor
```

Expected: all green. The launchd agent should show "loaded". Any warning = fix before merge.

- [ ] **Step 2: Run `dots status`**

Expected: `clean`. If not, `dots sync` to capture, commit, push.

## Task 4.2: Full VM end-to-end replay

- [ ] **Step 1: Restore VM to baseline**

In Parallels: Go To `clean-macos-with-1password`.

- [ ] **Step 2: Execute full bootstrap**

```bash
curl -fsSL https://raw.githubusercontent.com/jarodtaylor/dotfiles/design/chezmoi-ironclad/bootstrap.sh | bash
```

Track wallclock time from start to completion.

- [ ] **Step 3: Verify "productive" state**

Measure "time to productive" — open a new terminal, run:

```bash
dots doctor           # green
gh auth status        # likely prompts for auth (expected)
ghostty --version     # ghostty installed
claude --version      # claude app installed
op whoami             # still signed in
```

If all these pass, the machine is effectively productive.

## Task 4.3: Record known issues

**Files:**
- Create: `docs/KNOWN_ISSUES.md`

- [ ] **Step 1: Write up any rough edges discovered during VM runs**

```bash
cat > ~/.local/share/chezmoi/docs/KNOWN_ISSUES.md <<'EOF'
# Known Issues

Rough edges discovered during validation. Not blockers — worth fixing opportunistically.

## (Fill in from Phase 4 VM runs)

Format:

### [Short title]
- **Symptom**: what you see
- **Workaround**: quick path around it
- **Root cause**: if known
- **Fix later**: link to tracking issue or phase where this lands properly

EOF
```

- [ ] **Step 2: Fill it in with what you actually hit**

Edit the file. Common suspects to check:
- Did anything require manual intervention during bootstrap?
- Did `op whoami` need a re-signin at some point?
- Did any `mas` (Mac App Store) app fail to install because you weren't signed into the App Store?
- Any Homebrew cask that required post-install permission granting (e.g., Karabiner)?

- [ ] **Step 3: Commit**

```bash
cd ~/.local/share/chezmoi
git add docs/KNOWN_ISSUES.md
git commit -m "docs: record known issues from VM validation"
```

## Task 4.4: Final self-review

- [ ] **Step 1: Read through the whole diff since `main`**

```bash
cd ~/.local/share/chezmoi
git log --oneline main..design/chezmoi-ironclad
git diff --stat main
```

- [ ] **Step 2: Sanity check**

- No plaintext secrets in any committed file.
- No TODO/TBD markers in docs.
- `dots doctor` green.
- VM bootstrap works end-to-end in under 60 min.

## Task 4.5: Merge to main

- [ ] **Step 1: Open PR**

```bash
cd ~/.local/share/chezmoi
gh pr create --title "Chezmoi Ironclad — hybrid source-of-truth refactor" --body "$(cat <<'EOF'
## Summary

Complete overhaul of the chezmoi dotfiles setup. See
`docs/superpowers/specs/2026-04-16-chezmoi-ironclad-design.md` for the
full design.

**Core shift:** hybrid source-of-truth. Machine is authoritative for
installed Homebrew packages and AI tool skills/agents/plugins; repo
is authoritative for hand-edited configs. `dots sync` captures machine
state into the repo; `chezmoi apply` pushes repo configs to machine.
Runtime state (logs, caches, sessions, DBs) filtered via `.chezmoiignore`.
Secrets resolved via 1Password at apply time.

**What's new:**
- `bootstrap.sh` (one-liner entry, replaces `install.sh` which had a
  hardcoded `refactor-simplify` branch reference)
- `home/Brewfile` replacing hardcoded package list in the install script
- `home/bin/executable_dots` — the `dots` CLI with `sync`, `apply`,
  `doctor`, `status`, `new-machine`, `edit`
- `home/Library/LaunchAgents/com.jarodtaylor.dots-sync.plist` — daily
  auto-sync at 03:00
- Captured AI tool state: `home/dot_claude/`, `dot_codex/`, `dot_gemini/`,
  `dot_cursor/`
- `.env` and `auth.json` templated via 1Password; age key migrated
  off disk into 1Password
- Expanded `.chezmoiignore` for AI tool runtime state
- Refreshed docs: `README.md`, `SETUP.md`, `CLAUDE.md`, new
  `docs/AUDITING.md`, `docs/TESTING.md`, `docs/KNOWN_ISSUES.md`

**Removed:**
- `install.sh` (replaced by `bootstrap.sh`)
- `run_onchange_before_20-create-age-key.sh.tmpl` (age key now in 1Password)
- `dot_config/nvim_old/` (dead code)
- `docs/CHEZMOI_SCRIPTS.md` (outdated)
- `package.json`, `package-lock.json` (stubs)
- Old VM testing scripts (`test-local-simulation.sh`, `test-vm-setup.sh`,
  `VM-TESTING-GUIDE.md`) — replaced by `docs/TESTING.md`

## Test plan

- [x] CP-1: Clean VM bootstrap with Phase 1 changes
- [x] CP-2: `dots sync` round-trip in VM
- [x] CP-3: One-liner `bootstrap.sh` in fresh VM
- [x] CP-4: Full end-to-end VM bootstrap under 60 min
- [x] `dots doctor` green on primary M1 Max host
- [x] No plaintext secrets in any committed file
- [x] `shellcheck` clean on all shell scripts
- [x] `chezmoi execute-template` clean on all templates

## Rollout

Merging to `main` updates the one-liner URL. Continue to use `design/chezmoi-ironclad`
branch on M1 Max until merge; M5 Max bootstrap uses `main` after merge.
EOF
)"
```

- [ ] **Step 2: Self-review in the GitHub UI**

Re-read the diff in the PR view. Look for anything that still has a personal path or secret that shouldn't be there.

- [ ] **Step 3: Merge**

```bash
gh pr merge --merge
```

(Prefer `--merge` over `--squash` to preserve phase-level history.)

- [ ] **Step 4: Update local**

```bash
cd ~/.local/share/chezmoi
git checkout main
git pull
git branch -d design/chezmoi-ironclad
```

- [ ] **Step 5: Done**

Your ironclad dotfiles are live on `main`. Next time you buy a Mac, it's a one-liner away.

---

## Appendix: M5 Max setup after merge

When the M5 Max arrives:

1. Finish macOS initial setup.
2. `xcode-select --install` → click through GUI.
3. Install 1Password app, sign in, enable SSH agent + CLI.
4. Install 1Password CLI; `op signin`.
5. Verify the required 1Password entries exist (see `SETUP.md` §3).
6. Run the one-liner:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/jarodtaylor/dotfiles/main/bootstrap.sh | bash
   ```
7. `dots new-machine` → `dots doctor` → done.

If anything drifts between the two laptops, the nightly launchd agent on each
machine will surface it via auto-commit. Pull the changes on the other machine
manually (`cd $(chezmoi source-path) && git pull && dots apply`) or add a
pre-sync hook in Phase 5 if it becomes a frequent pain point.
