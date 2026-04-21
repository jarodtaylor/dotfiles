# CLAUDE.md

Guidance for Claude Code (and any AI pair) working in this repository.

## Project overview

Opinionated macOS dotfiles managed by [chezmoi](https://www.chezmoi.io/).
Hybrid source-of-truth model:

- **Machine is authoritative** for installed packages (Homebrew) and AI
  tool runtime state (skills, agents, plugins under `~/.claude`, `~/.codex`,
  `~/.cursor`).
- **Repo is authoritative** for hand-edited configs (nvim, zsh, git,
  ghostty, starship, etc.).
- **`dot sync`** captures machine drift into the repo.
- **`dot apply`** reconciles machine with the repo (wraps `chezmoi apply`
  + `brew bundle`).
- **Daily launchd agent** (`com.jarodtaylor.dots-sync`) runs `dot sync --push`
  at 03:00 local.

Source dir is `home/` (set via `.chezmoiroot`). All target paths are
relative to `~/`.

## Primary entry points

- [`README.md`](README.md) — user-facing overview + key commands
- [`SETUP.md`](SETUP.md) — new-machine walkthrough (pre + post bootstrap)
- [`bootstrap.sh`](bootstrap.sh) — zero-to-productive one-liner
- [`home/bin/executable_dot`](home/bin/executable_dot) — the `dot` CLI
- [`docs/superpowers/specs/2026-04-16-chezmoi-ironclad-design.md`](docs/superpowers/specs/2026-04-16-chezmoi-ironclad-design.md) — full architecture spec
- [`docs/AUDITING.md`](docs/AUDITING.md) — onboarding a new AI tool
- [`docs/TESTING.md`](docs/TESTING.md) — layered validation workflow

## Chezmoi conventions

- **File prefixes**: `dot_` → `.`, `private_` → `0600`, `executable_` → `0755`,
  `encrypted_` → decrypted on apply
- **Template files**: `.tmpl` suffix; Go text/template syntax with chezmoi
  extensions (`onepasswordRead`, `include`, `includeTemplate`, etc.)
- **Script naming**:
  - `run_onchange_before_*` — runs before apply when rendered content changes
  - `run_onchange_after_*` — runs after apply when rendered content changes
  - `run_once_*` — runs exactly once per machine ever
- **Script ordering**: lexicographic within category; numeric prefixes
  control order (00, 10, 20 …)
- **Template variables** (defined in `.chezmoi.toml.tmpl`):
  `.chezmoi.os`, `.chezmoi.arch`, `.chezmoi.homeDir`, `.chezmoi.username`,
  `.brew_prefix`, `.ssh_key`, `.work_ssh_key`
- **Template helpers**: `home/.chezmoitemplates/scripts/` — reusable
  snippets (`script_helper`, `script_sudo`, `script_eval_brew`)
- **External dependencies**: `home/.chezmoiexternal.toml` pulls repos
  (currently: catppuccin zsh-syntax-highlighting)

## Active scripts (`home/.chezmoiscripts/`)

- `run_onchange_before_10-install-packages.sh.tmpl` — runs `brew bundle`
  against `home/Brewfile`
- `run_onchange_after_00-pam-config.sh.tmpl` — Touch ID / Apple Watch
  sudo via `pam_reattach`; detects missing PAM modules per-machine so
  VMs without Apple Watch don't break sudo
- `run_onchange_after_20-launchd-reload.sh.tmpl` — bootstraps or reloads
  the `com.jarodtaylor.dots-sync` LaunchAgent; re-runs when the plist
  template changes (embedded sha256 hash)

## Secrets (all via 1Password, `Personal` vault)

| Purpose | 1Password entry | Consumed by |
|---|---|---|
| age decryption key | `Dotfiles Age Key` (Secure Note, `notesPlain`) | `.chezmoi.toml.tmpl` (`identityCommand`) |
| Claude Code env | `Claude Code env` (Secure Note, `notesPlain`) | `home/dot_claude/private_dot_env.tmpl` |
| Codex auth | `Codex auth` (Secure Note, `notesPlain`) | `home/dot_codex/private_auth.json.tmpl` |
| Cursor GitHub PAT | `GitHub PAT - cursor mcp` (Secure Note, `notesPlain`) | cursor mcp template |
| Personal SSH key | existing SSH-key entry | `home/private_dot_ssh/config.tmpl` |
| Work SSH key | existing SSH-key entry | `home/private_dot_ssh/config.tmpl` |

Never hardcode secrets. Add new secrets via `onepasswordRead` templates
following the pattern in `docs/AUDITING.md`.

## Languages and formatting

- **Shell / Zsh**: primary scripting language. Zsh config uses `zimfw`
  plugin manager and `zsh-abbr` for abbreviations (not plain aliases).
- **Lua**: Neovim config under `home/dot_config/nvim/lua/`. Formatter:
  `stylua` (2-space indent, 120 column width — see
  `home/dot_config/nvim/stylua.toml`)
- **TOML**: starship, aerospace, mise, yazi configs
- **Go templates**: all `.tmpl` files use chezmoi's template engine

## Working on this repo

- Test template changes with `chezmoi execute-template < file.tmpl`
  before committing
- Dry-run any apply with `chezmoi apply --dry-run -v` (read-only)
- `dot doctor` is the multi-layer health check — keep it green
- Homebrew prefix varies by arch: `/opt/homebrew` (arm64) vs
  `/usr/local` (amd64). Always use `{{ .brew_prefix }}` in templates
- PATH additions must come **before** `mise activate` in the zshrc —
  mise's precmd hook strips additions made after it
- `.chezmoiignore` excludes repo-only files (README, docs, bootstrap.sh)
  from being applied to `~`
- See `docs/TESTING.md` for the layered validation order
  (render-check → shellcheck → dry-run apply → `dot doctor` → VM)

## Subdirectory CLAUDE.md files

Module-specific guidance can live in subdirectory `CLAUDE.md` files
(e.g. `home/dot_config/nvim/CLAUDE.md`). They load automatically when
working in those directories.
