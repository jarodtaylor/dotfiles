# Chezmoi Ironclad — Session Resumption Notes

**Last updated**: 2026-04-20, end of Phase 2 work.
**Branch**: `design/chezmoi-ironclad`
**Spec**: `docs/superpowers/specs/2026-04-16-chezmoi-ironclad-design.md`
**Plan**: `docs/superpowers/plans/2026-04-16-chezmoi-ironclad.md`

## Current state

- **Phase 0 (VM baseline)** — complete. Parallels VM has `clean-macos-with-1password` snapshot (fresh macOS + Xcode CLT + 1Password app + CLI signed in).
- **Phase 1 (audit & cleanup)** — complete. CP-1 validated in VM. `post-cp1-bootstrap` snapshot was taken but sudo_local ended up broken there (`pam_watchid.so.2` missing in VM). Fixed in Phase 2; new CP-2 state should be re-snapshotted next session.
- **Phase 2 (sync infrastructure)** — code complete on host, validated 95% in VM. `dot sync` round-trip works (CP-2 verified brew bundle dump writes Brewfile correctly after a VM state reset).
- **Phase 3 (launchd + bootstrap.sh + docs)** — NOT STARTED.
- **Phase 4 (final validation + merge)** — NOT STARTED.

## What's on the branch (commits since `main`)

Run `git log --oneline main..design/chezmoi-ironclad` for the real list. Highlights:
- Design spec + plan docs
- Curated Brewfile (replaces hardcoded list)
- `dot` CLI (renamed from `dots` to avoid conflict with user's zsh-abbr)
- `~/.claude`, `~/.codex`, `~/.cursor` captures (~/.gemini intentionally skipped)
- Templates for secrets via 1Password (`Dotfiles Age Key`, `Claude Code env`, `Codex auth`, `GitHub PAT - cursor mcp`)
- Templates for machine-portable paths via `{{ .chezmoi.homeDir }}` / `{{ .chezmoi.username }}`
- Age key migrated from `~/key.txt` to 1Password
- Expanded `.chezmoiignore` (AI tool runtime state, gstack symlink skills, etc.)
- Many fixes discovered in VM testing (see below)

## Known fixes applied during Phase 1/2 VM testing

These are all committed. Don't re-do.
- `brew bundle --no-lock` flag removed (newer Homebrew dropped it)
- Non-core tap casks use tap-qualified names (`nikitabobko/tap/aerospace`)
- `elco` and `expressvpn` dropped from bootstrap Brewfile (see `docs/KNOWN_ISSUES.md` next session)
- `sudo -v` priming in `script_sudo` is non-fatal
- `pam-config` only emits lines for PAM modules that actually exist on the machine
- `pam-config` uses `script_eval_brew` so `brew` is in PATH
- `ONEPASSWORD_AVAILABLE` env var gate replaced with `op whoami` runtime probe
- `.chezmoi.toml.tmpl` uses `identityCommand` via 1Password (no on-disk age key)
- `$HOME/bin` added to PATH (was missing; `~/bin` was unreachable)
- **PATH exports must come BEFORE `mise activate` in zshrc** (mise's precmd hook strips post-activate PATH additions)
- `dot sync` uses `chezmoi re-add` (not `add --recursive`) so template files stay templates and don't prompt every sync

## Phase 3 next-session work (in `docs/superpowers/plans/2026-04-16-chezmoi-ironclad.md`)

- **Task 3.1**: `home/Library/LaunchAgents/com.jarodtaylor.dots-sync.plist` (launchd agent, daily 03:00 `dot sync --push`)
- **Task 3.2**: `run_onchange_after_20-launchd-reload.sh.tmpl` (loads agent on `chezmoi apply`)
- **Task 3.3**: `bootstrap.sh` at repo root (replaces `install.sh`, points at `main` branch, includes pre-flight for Xcode CLT + op auth + pre-installs `age` so templates can render encryption config on first pass)
- **Task 3.4**: `dot new-machine` implementation (partly done in the CLI — walkthrough + doctor)
- **Task 3.5**: README refresh
- **Task 3.6**: `SETUP.md` new-machine walkthrough
- **Task 3.7**: `docs/AUDITING.md`
- **Task 3.8**: `docs/TESTING.md`
- **Task 3.9**: Refresh root `CLAUDE.md`
- **Task 3.10**: CP-3 in VM

## Phase 4

- **Task 4.1**: `dot doctor` green on primary M1 Max host (NOT the VM — the user's real machine)
- **Task 4.2**: Full Parallels VM end-to-end replay from `clean-macos-with-1password`
- **Task 4.3**: `docs/KNOWN_ISSUES.md` (capture all the rough edges listed below + whatever's left)
- **Task 4.4**: Final self-review
- **Task 4.5**: Merge to `main`

## Known gotchas to fix properly in Phase 3/4

- **Chicken-and-egg**: `.chezmoi.toml.tmpl` needs `age-keygen` to derive recipient, but `age` is installed by Brewfile (after init). First bootstrap skips encryption, requires a second `chezmoi init --apply` to pick it up. Fix in Phase 3 `bootstrap.sh`: install `age` (and `1password-cli` if needed) before first `chezmoi init`.
- **`chezmoi init` standalone doesn't re-render cached `~/.config/chezmoi/chezmoi.toml`** when op signin state changes. Workaround during CP-1 was `cp /tmp/rendered.toml ~/.config/chezmoi/chezmoi.toml`. Phase 3 bootstrap should ensure op is live before init, so this shouldn't bite.
- **Work git config `config-work` decryption**: source uses a pre-existing pattern where age-encrypted ciphertext is embedded as literal text in a `.tmpl`. Chezmoi renders the template but never decrypts the blob. Needs migration to chezmoi's `encrypted_` file-prefix convention (see spec §8). Was deferred from Phase 1.
- **Post-bootstrap manual installs** (to document in `KNOWN_ISSUES.md`):
  - `elco` (private GitHub tap): `brew tap elc-online/tap git@github.com:elc-online/homebrew-tap.git && brew install elco`
  - `expressvpn`: download from expressvpn.com (cask's LaunchDaemon install is flaky)
- **SSH first-connection prompt**: bootstrap.sh should `ssh-keyscan github.com >> ~/.ssh/known_hosts` pre-emptively.
- **Password prompts from cask pkg installers**: unavoidable (karabiner, microsoft-*, adobe, docker-desktop, fonts). Document.
- **CP-2 stray Brewfile**: at some point during VM testing, a `Brewfile` got committed at repo ROOT (not just `home/Brewfile`). Check `git log -- Brewfile` next session and clean if present.

## How to resume

1. Read this file + the spec + the plan.
2. Verify branch state: `git log --oneline main..HEAD`, `git status`, `dot doctor` (on host).
3. Start Phase 3 Task 3.1 (launchd plist) following the plan verbatim.
4. VM testing: revert Parallels to `clean-macos-with-1password`. Re-run bootstrap. Validate CP-2 + CP-3 end-to-end.

## Key files / locations

- Source: `~/.local/share/chezmoi/` (this repo)
- `dot` CLI source: `home/bin/executable_dot`
- Brewfile: `home/Brewfile`
- AI tool captures: `home/dot_claude/`, `home/dot_codex/`, `home/dot_cursor/`
- Chezmoi meta: `home/.chezmoi.toml.tmpl`, `home/.chezmoiignore`
- Scripts: `home/.chezmoiscripts/`
- Script helpers: `home/.chezmoitemplates/scripts/`
- Plan + spec: `docs/superpowers/{specs,plans}/`

## 1Password entries required (all in Personal vault)

- `Dotfiles Age Key` (Secure Note, notesPlain = full `age-keygen` output — 3 lines incl. comments + secret)
- `Claude Code env` (Secure Note, notesPlain = `~/.claude/.env` plaintext)
- `Codex auth` (Secure Note, notesPlain = `~/.codex/auth.json` plaintext)
- `GitHub PAT - cursor mcp` (Secure Note, notesPlain = just the `ghp_...` token)
- Pre-existing: personal SSH key + work SSH key items
