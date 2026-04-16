# Chezmoi Ironclad — Design Spec

**Author**: Jarod Taylor
**Date**: 2026-04-16
**Status**: Draft (pending user review)
**Scope**: Complete overhaul of `~/.local/share/chezmoi` dotfiles system
**Target machines**: M1 Max MacBook Pro (current), M5 Max MacBook Pro (incoming). YAGNI everything else.

---

## 1. Problem statement

The existing chezmoi-managed dotfiles were last substantially touched in mid-2025. Since then:

- **Package drift**: 19+ Homebrew formulae, 10+ casks, and 4 taps are installed on the machine but not declared in the repo's package script. Every `brew install` since the last edit has silently forked the machine from source.
- **AI tooling explosion**: Claude Code, Codex, Gemini, Cursor, and a long tail of other AI-first tools now live in the home directory (`~/.claude`, `~/.codex`, `~/.gemini`, `~/.cursor`, `~/.openclaw`, `~/.gstack`, `~/.kiro`, `~/.cagent`, `~/.gsd`, etc.). **None are tracked by chezmoi.** `~/.claude/` alone holds 127 skills, 24 agents, 9 hooks, 4 commands, plugin marketplace data, `settings.json`, `CLAUDE.md`, and `statusline.sh`. A nuke today loses hours-to-days of customization.
- **Workflow friction**: Current model forces `edit-template → apply` for every new Homebrew package or AI tool customization. This breaks the "just `brew install`" standard workflow and disincentivizes experimentation.
- **Architectural fault**: The existing design is purely declarative (repo → machine). The user's pain is real — the system blocks the reverse flow (machine → repo for state capture).
- **No multi-machine story**: Only `personal`/`work` git profiles exist; no machine-class profile. An incoming M5 Max MacBook Pro + the M1 Max are treated as duplicates with no explicit modeling.
- **Cruft**: `dot_config/nvim_old/` still in source; four terminal emulators installed (`ghostty`, `kitty`, `wezterm`, `warp`); `ffmpeg`/`libpq` declared but not top-level leaves.

## 2. Goals

**Primary**: Daily workflow friction-free. `brew install foo` and drop-in AI tool customizations work with zero chezmoi ceremony. State captured automatically in the background.

**Secondary (must still work, low frequency)**: Nuke-and-pave recovery or new-machine bootstrap that takes ~30–60 minutes of walkaway time plus a handful of human steps. User runs this "once every other year or so".

**Non-goals**:
- Cross-platform (Linux, Windows) support.
- Profile system for machines that don't exist yet (Mac Mini, Mac Studio). YAGNI.
- Real-time drift capture via shell hooks. Over-engineered for a daily-scale problem.
- Clean git history on the dotfiles repo. Auto-commits with descriptive messages are fine.

## 3. Core principles

1. **The machine is the source of truth for mutable inventory state** — installed packages, AI skill/agent/plugin inventories. The repo is an auto-captured snapshot, not the ledger you hand-edit.
2. **The repo is source of truth for hand-edited configs** — `nvim/`, `ghostty/`, `starship/`, `.zshrc`, `git/config`, etc. Edit in repo, chezmoi applies to machine.
3. **Runtime state never syncs** — logs, caches, session/conversation history, sqlite DBs, telemetry, shell snapshots, backups. Strong `.chezmoiignore` patterns.
4. **Secrets never land in git** — resolved via 1Password template calls at apply time. Expanded beyond today's SSH+git to cover AI tool auth.
5. **Two commands cover 95% of use cases** — `dots sync` (capture + commit + optional push), `dots apply` (chezmoi apply + brew bundle). Everything else is progressive enhancement.
6. **Drift should be loud, not silent** — `dots doctor` surfaces divergence. Optional prompt indicator in a follow-up phase.
7. **YAGNI** — no machine-class profiles, no remote secondary sync targets, no cross-platform templating. Two identical laptops.

## 4. High-level architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                           MACHINE                                    │
│                                                                      │
│  ~/.claude/        ~/.codex/       ~/.config/      Homebrew          │
│  ~/.gemini/        ~/.cursor/      ~/.ssh/         /opt/homebrew     │
│       │                │                │               │            │
│       ▼                ▼                ▼               ▼            │
│  [source of truth for mutable state]  [hand-edited by you / repo]    │
└─────────┬────────────────────────────────────┬────────────┬──────────┘
          │                                    │            │
          │  dots sync                         │ chezmoi    │ chezmoi
          │  (capture → commit + push)         │ apply      │ apply
          ▼                                    │            │
┌─────────────────────────────────────────┐    │            │
│            DOTFILES REPO                │────┘────────────┘
│  ~/.local/share/chezmoi/                │
│   home/                                 │
│    ├─ Brewfile              (captured)  │
│    ├─ dot_claude/           (captured)  │
│    ├─ dot_codex/            (captured)  │
│    ├─ dot_config/nvim/      (authored)  │
│    ├─ dot_config/ghostty/   (authored)  │
│    ├─ private_dot_ssh/      (authored)  │
│    ├─ bin/dots              (the tool)  │
│    └─ .chezmoiscripts/      (minimal)   │
└─────────┬───────────────────────────────┘
          │
          │  launchd (03:00 nightly) + manual `dots sync`
          ▼
                 GitHub (origin)
```

### Data flow

- **Daily dev**: `brew install foo` / skill drop / config edit → works normally.
- **Sync** (03:00 nightly + on-demand): `dots sync` dumps brew state, `chezmoi re-add`s AI-tool dirs, commits, optionally pushes.
- **Apply** (hand edit → machine): `chezmoi apply` (wrapped by `dots apply`).
- **New machine**: `bootstrap.sh` one-liner → chezmoi init → chezmoi apply → done.

## 5. Repo structure

Target layout (all paths under `home/` since `.chezmoiroot = home`):

```
home/
├─ .chezmoiroot                       (unchanged)
├─ .chezmoi.toml.tmpl                 (extend: AI tool auth via 1Password, age identityCommand)
├─ .chezmoidata/                      (unchanged — vscode extensions list)
├─ .chezmoiexternal.toml              (unchanged — catppuccin zsh-syntax-highlighting)
├─ .chezmoiignore                     (EXPAND — aggressive runtime-state filters)
├─ .chezmoiscripts/
│   ├─ run_onchange_before_10-install-packages.sh.tmpl   (SHRINK — delegate to Brewfile)
│   ├─ run_onchange_before_20-create-age-key.sh.tmpl     (REMOVE — age key moves to 1Password)
│   ├─ run_onchange_after_00-pam-config.sh.tmpl          (unchanged)
│   └─ run_onchange_after_20-launchd-reload.sh.tmpl      (NEW — loads sync agent)
├─ .chezmoitemplates/                 (unchanged)
├─ Brewfile                           (NEW — replaces hardcoded list in script)
├─ bin/
│   └─ executable_dots                (NEW — single entry-point CLI)
├─ dot_claude/                        (NEW — captured config from ~/.claude)
│   ├─ CLAUDE.md
│   ├─ settings.json[.tmpl]
│   ├─ statusline.sh
│   ├─ skills/
│   ├─ agents/
│   ├─ commands/
│   ├─ hooks/
│   ├─ dot_env.tmpl                   (1Password-backed)
│   └─ plugins/
│       ├─ installed_plugins.json
│       └─ known_marketplaces.json
├─ dot_codex/                         (NEW — skills, agents, config.toml, memories)
│   ├─ config.toml[.tmpl]
│   ├─ agents/
│   ├─ skills/
│   ├─ memories/
│   ├─ plugins/                       (manifest level only)
│   ├─ version.json
│   └─ auth.json.tmpl                 (1Password-backed)
├─ dot_gemini/                        (NEW — config + skills)
├─ dot_cursor/                        (NEW — settings, keybindings, snippets; extension list via `cursor --list-extensions`)
├─ dot_claude.json.tmpl               (NEW — `~/.claude.json` templated for machine-specific fields)
├─ dot_config/                        (existing; pruned — see §6)
├─ Library/
│   └─ LaunchAgents/
│       └─ com.jarodtaylor.dots-sync.plist   (NEW)
├─ dot_zshenv                         (unchanged)
├─ empty_dot_hushlogin                (unchanged)
└─ private_dot_ssh/                   (unchanged)
```

## 6. Cleanup (audit pass)

Executed as Phase 1 of implementation. Each item decided by explicit review, not blindly.

**Drop outright**:
- `home/dot_config/nvim_old/` — dead code in source
- `docs/CHEZMOI_SCRIPTS.md` — outdated (current CLAUDE.md note already flags this)
- Root `package.json` + `package-lock.json` — 4-byte placeholders, pointless

**Audit keep-or-drop**:

*Terminal emulators*: `ghostty` (primary), `kitty` (config still in repo), `wezterm`, `warp` all installed. Propose: keep `ghostty`, drop the other three from Brewfile + repo config.

*Installed-but-undeclared casks*: `arc`, `beekeeper-studio`, `betterdisplay`, `blackhole-2ch`, `chromedriver`, `docker-desktop`, `microsoft-auto-update`, `todoist-app`.

*Installed-but-undeclared brews*: `aubio`, `cmake`, `curl`, `git-lfs`, `libsamplerate`, `pinentry-mac`, `pipx`, `python@3.9`, `python@3.11`, `python@3.12`, `rust`, `silicon`, `vhs`, `virtualenv`, `yt-dlp`, `zimfw`.

*Undeclared taps in use*: `alltuner/tap`, `elc-online/tap`, `encoredev/tap`, `shopify/shopify`.

*Declared but not top-level leaves*: `ffmpeg`, `libpq` — verify transitive or wanted.

**Audit in execution**: `~/.openclaw/`, `~/.gstack/`, `~/.kiro/`, `~/.cagent/`, `~/.gsd/`, `~/.agent-browser/`, `~/.agents/`, `~/.context7/`. Rule: if a dir contains skills/plugins/config, add to tracked set; if pure cache/runtime, skip.

## 7. Sync boundaries

### Homebrew

- **Mechanism**: `Brewfile` at `home/Brewfile`. Standard format (`tap`, `brew`, `cask`, optional `mas`). Comments group by purpose.
- **Capture**: `brew bundle dump --force --describe --file="$CHEZMOI_SOURCE/home/Brewfile"`
- **Apply**: `brew bundle --file="$CHEZMOI_SOURCE/home/Brewfile" --cleanup`
- **Policy**: Manifest-only. Dump overwrites Brewfile; diff visible in git before commit.
- **Bootstrap list**: post-cleanup, curated to ~60 intended packages (not 125+ drift set).

### Mise

No changes. Already config-driven via `dot_config/mise/config.toml.tmpl` + `dot_default-npm-packages.tmpl` + `dot_default-gems.tmpl`. Validate contents during Phase 1 audit.

### AI tool directories — taxonomy

| Directory | SYNC (into repo) | IGNORE (`.chezmoiignore`) | SECRETS (1Password template) |
|---|---|---|---|
| **`~/.claude/`** | `CLAUDE.md`, `settings.json`, `statusline.sh`, `skills/`, `agents/`, `commands/`, `hooks/`, `plugins/installed_plugins.json`, `plugins/known_marketplaces.json`, `consensus.json` | `cache/`, `history.jsonl`, `projects/`, `sessions/`, `statsig/`, `todos/`, `ide/`, `file-history/`, `session-env/`, `shell-snapshots/`, `telemetry/`, `backups/`, `paste-cache/`, `security_warnings_state_*.json`, `mcp-needs-auth-cache.json`, `stats-cache.json`, `plugins/marketplaces/`, `plugins/cache/`, `plugins/data/`, `cchubber-*`, `*.DS_Store`, `debug/`, `chrome/`, `get-shit-done/`, `gsd-file-manifest.json`, `cchubber-report.html` | `.env` → `op://Personal/Claude Code/env` |
| **`~/.codex/`** | `config.toml`, `agents/`, `skills/`, `memories/`, `plugins/` (manifest level), `version.json` | `.tmp/`, `cache/`, `log/`, `logs_1.sqlite`, `models_cache.json`, `session_index.jsonl`, `sessions/`, `shell_snapshots/`, `state_5.sqlite*`, `tmp/`, `.personality_migration`, `gsd-file-manifest.json`, `get-shit-done/` | `auth.json` → `op://Personal/Codex/auth.json` |
| **`~/.gemini/`** | `GEMINI.md` (if present), `settings.json`, `skills/`, `extensions/` (configs) | caches, logs, session state | auth tokens if present |
| **`~/.cursor/`** | `settings.json`, `keybindings.json`, `snippets/`, extensions list (captured via `cursor --list-extensions`) | `workspaceStorage/`, `logs/`, `CachedData/`, `extensions/` (extension binaries) | none typically |
| **`~/.claude.json`** (at `~`) | Whole file as chezmoi template, with machine-specific paths and auth fields substituted | N/A | Any auth fields → 1Password |

**New tools later**: `dots sync` does **not** auto-discover. Adding a new tracked dir is a one-liner edit to `dots`'s config. Explicit opt-in prevents accidentally capturing secrets from new tools.

### `dots sync` concrete behavior

```
dots sync [--dry-run] [--no-commit] [--push]

1. brew bundle dump --force --describe → home/Brewfile
2. For each tracked AI tool dir in ~/.claude, ~/.codex, ~/.gemini, ~/.cursor:
     chezmoi add --recursive <dir>      # adds new files + updates existing; respects .chezmoiignore
3. git -C $CHEZMOI_SOURCE status --porcelain
   - if empty: exit 0 "no drift"
   - else: show diff stat
4. If --dry-run: stop.
5. git add -A && git commit -m "state sync YYYY-MM-DD: <summary>"
6. If --push: git push origin main
```

## 8. Secrets

Expansion beyond current 1Password scope (SSH keys, work git email):

| Item | Current | Target 1Password entry | Template strategy |
|---|---|---|---|
| SSH keys | 1Password (already) | — | Keep |
| Work git email | 1Password (already) | — | Keep |
| Age decryption key | `~/key.txt` (plaintext on disk) | `op://Personal/Dotfiles/age-key` | `age.identityCommand = ["op", "read", "..."]` — no plaintext key on disk |
| Claude env vars | `~/.claude/.env` | `op://Personal/Claude Code/env` | `dot_claude/dot_env.tmpl` with `onepasswordRead` |
| Codex auth | `~/.codex/auth.json` | `op://Personal/Codex/auth.json` | Template entire JSON; render via `onepasswordRead` |
| `.claude.json` auth fields | inline | Parse, move to op entries, field-substitute | Field-level templating |

**Rule**: if a file contains a secret and isn't in `.chezmoiignore`, it becomes a `.tmpl` with `onepasswordRead` calls.

## 9. Bootstrap (new machine)

**Prereqs (human steps, documented in `SETUP.md`)**:
1. Fresh macOS install completed (user account created).
2. `xcode-select --install` — click install in the GUI prompt, wait for completion.
3. Install 1Password app (App Store or 1password.com), sign in.
4. `brew install --cask 1password 1password-cli` if brew exists, else install brew first.
5. `op account add` — authenticate 1Password CLI with account.

**One-liner** (replaces current `install.sh`). `bootstrap.sh` lives at the **repo root** (not under `home/`) so the `curl | bash` URL stays stable:

```
curl -fsSL https://raw.githubusercontent.com/jarodtaylor/dotfiles/main/bootstrap.sh | bash
```

`bootstrap.sh` does:

1. Install Homebrew if missing.
2. `brew install chezmoi`.
3. `chezmoi init --apply jarodtaylor/dotfiles`.
4. `chezmoi apply` triggers the scripts:
   - `install-packages.sh` → `brew bundle --file=Brewfile --cleanup`
   - Templates render via 1Password (secrets resolved live)
   - `pam-config.sh` → Touch ID sudo
   - `launchd-reload.sh` → load `com.jarodtaylor.dots-sync`
5. Done. Total human interaction: ~5 minutes of clicks + ~30–60 minutes walkaway.

## 10. Drift detection

Three layers, shipped in order:

1. **`dots doctor`** (Phase 2): manual multi-check. Report format:
   ```
   ✓ chezmoi doctor: all green
   ✓ Brewfile in sync with installed
   ⚠ 3 uncommitted changes in repo: home/dot_claude/skills/foo.md (new), home/Brewfile (modified)
   ✓ 1Password signed in
   ✓ dots-sync launchd agent loaded (last run: 2h ago)
   ✓ AI tool dirs healthy
   ```
2. **`dots status`** (Phase 2): one-line summary for shell prompts or quick checks.
3. **Starship/zsh drift indicator** (Phase 5, deferred): prompt segment when drift > N hours old. Low priority given daily auto-sync.

### Auto-sync failure handling

- Log to `~/.local/state/dots-sync/sync.log`.
- If `git push` fails, stash a note in `~/.local/state/dots-sync/pending.txt`.
- Next interactive shell sourcing `.zshrc` displays a one-line warning from that note.
- No silent failures, no infinite retry loops.

## 11. `dots` CLI

**Implementation**: single Bash script at `home/bin/executable_dots` (chezmoi → `~/bin/dots`, +x). No external deps beyond git, chezmoi, brew, op.

**Commands**:
```
dots <command> [flags]

sync          Capture drift into repo, optionally commit + push
apply         chezmoi apply + brew bundle --cleanup
doctor        Multi-layer health check
status        One-line drift summary
new-machine   Interactive bootstrap helper for first-time setup
edit          Open the repo in $EDITOR
help          Show commands with examples

Common flags:
  --dry-run, --no-commit, --push, -v/--verbose
```

Design choice: Bash over Ruby/Python/Go. Thin deps for bootstrap; matches existing script idiom. If a subcommand outgrows Bash, factor to a separate library file first; rewrite only if needed.

## 12. launchd agent

`home/Library/LaunchAgents/com.jarodtaylor.dots-sync.plist`:

- **Label**: `com.jarodtaylor.dots-sync`
- **Program**: `/Users/jarodtaylor/bin/dots`, args `sync --push`
- **Schedule**: daily 03:00 local time (`StartCalendarInterval`)
- **RunAtLoad**: false
- **KeepAlive**: false
- **LowPriorityIO**: true
- **StandardOut/Error**: `~/.local/state/dots-sync/{stdout,stderr}.log`

Loaded automatically by `run_onchange_after_20-launchd-reload.sh.tmpl` via `launchctl bootstrap gui/$(id -u) <plist>` during `chezmoi apply`.

## 13. Testing strategy

Layered, fast feedback first:

| Layer | Tool | Time | When |
|---|---|---|---|
| Template lint | `chezmoi execute-template < file.tmpl` | seconds | Every template edit |
| Shell lint | `shellcheck home/bin/executable_dots home/.chezmoiscripts/*.sh.tmpl` | seconds | Pre-commit |
| Dry-run apply | `chezmoi apply --dry-run -v` | ~10s | Before every real apply |
| `dots doctor` | self | ~2s | Anytime |
| VM integration | Parallels macOS clean VM + `bootstrap.sh` | 30–60 min | Before merging major changes |
| CI (optional, deferred) | GitHub Actions macOS runner: shellcheck + template render + `chezmoi diff` vs fixture home | 2–5 min | Every PR (if enabled) |

**Parallels procedure**: snapshot a clean macOS install with Xcode + 1Password app + 1Password signed in. Each test run restores that snapshot, runs `bootstrap.sh`, measures wallclock. Golden end-to-end confidence builder.

Existing `test-local-simulation.sh` and `test-vm-setup.sh` audited in Phase 1 — modernize if useful, delete if not.

## 14. Phased implementation

**Phase 1 — Audit & cleanup** (~½ day)
- Inventory drift; decide keep/drop for every divergent brew/cask/tap
- Remove `nvim_old`, dead docs, stub files
- Generate intended-state `Brewfile` (curated, not drift-dump)
- Remove `create-age-key.sh`; migrate age key to 1Password
- Verify existing test scripts; remove or modernize
- **Exit criteria**: repo and machine reconciled; `Brewfile` committed; baseline clean

**Phase 2 — Sync infrastructure** (~1 day)
- Build `dots` CLI (`sync`, `apply`, `doctor`, `status`)
- Add AI tool dirs (`dot_claude/`, `dot_codex/`, `dot_gemini/`, `dot_cursor/`) with full `.chezmoiignore` patterns
- Migrate secrets to 1Password templates (`.env`, `auth.json`, `.claude.json` fields)
- Shrink `install-packages.sh` to `brew bundle --file=Brewfile --cleanup`
- **Exit criteria**: `dots sync` works manually; no secrets in git; AI tools bootstrapable from repo

**Phase 3 — Automation & bootstrap** (~½ day)
- launchd agent for daily auto-sync
- `bootstrap.sh` (replaces `install.sh`) with human-step docs
- `dots new-machine` interactive helper
- Refresh `README.md`; write `SETUP.md`
- **Exit criteria**: scheduled sync runs; bootstrap one-liner works in fresh environment

**Phase 4 — Validation** (~½ day)
- Full Parallels VM dry-run from snapshot
- `dots doctor` passes on M1 Max
- Document known issues
- Refresh root `CLAUDE.md`
- **Exit criteria**: VM bootstrap succeeds end-to-end; all docs reflect reality

**Phase 5 (deferred/optional)**: drift prompt integration, GitHub Actions CI, machine-class profiles (when Mac Mini/Studio actually arrive).

## 15. Documentation deliverables

- `README.md` — refreshed: what this is, how to adopt, one-liner bootstrap
- `SETUP.md` — new-machine walkthrough (Xcode, 1Password prereqs, step order, expected time)
- `docs/AUDITING.md` — how to decide sync vs. ignore for a new AI tool
- `docs/TESTING.md` — Parallels snapshot procedure, dry-run recipes, shellcheck usage
- `CLAUDE.md` (repo root) — refreshed architecture, conventions, `dots` command reference

## 16. Open items & assumptions

**Assumptions baked in** (flag for validation during execution):
- Claude Code's `installed_plugins.json` is sufficient to reinstall plugins on a new machine (plugin system re-fetches marketplace code on apply). To verify.
- Cursor's `--list-extensions` output is round-trippable via `cursor --install-extension` (or equivalent). To verify.
- `~/.claude.json`'s sensitive fields can be cleanly substituted with chezmoi variables without breaking the file's JSON structure. To verify.
- 1Password CLI is available and user authenticated before templates render on a fresh machine. Documented in `SETUP.md`.
- `chezmoi add --recursive <path>` is safe to run repeatedly and respects `.chezmoiignore` for both new and existing files. To verify before building `dots sync`.
- Storing `~/.codex/auth.json` (~4.6KB) as a 1Password Secure Note and rendering via `onepasswordRead` produces byte-identical output. To verify.

**Deferred**:
- AI tools in the long tail (`~/.openclaw/`, `~/.gstack/`, etc.) — audited during Phase 1 execution.
- Machine-class profiles — deferred until a non-laptop machine enters the picture.
- Shell-prompt drift indicator — Phase 5.
- CI — Phase 5.

**Not in scope**:
- macOS defaults configuration script (referenced in README but never implemented). Out of scope; could be a follow-up if desired.
- Cross-platform support.
- Multi-user / shared-machine scenarios.
