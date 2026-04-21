# Personal Dotfiles (Chezmoi)

Opinionated macOS dotfiles managed by [chezmoi](https://www.chezmoi.io/).
Hybrid source-of-truth model: the machine is authoritative for installed
packages and AI tool state; the repo is authoritative for hand-edited configs.

> **Fair Warning**: highly personal setup. Fork and adapt — don't expect a
> plug-and-play experience on a different person's workflow.

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

- Installs Homebrew, chezmoi, and age (needed at init time)
- Clones this repo + runs `chezmoi apply`
- Brewfile installs ~115 packages (66 brew formulae + 47 casks + 4 taps)
- Configs are rendered with secrets pulled from 1Password
- The `com.jarodtaylor.dots-sync` launchd agent is loaded (runs daily at 03:00)

Total: ~5 minutes of active clicks + 30–60 minutes walkaway.

## Daily workflow

```bash
brew install <anything>        # just works — no chezmoi edit needed

# ... add a skill to ~/.claude/skills/ ...
# ... edit ~/.claude/CLAUDE.md ...

dot sync                       # capture machine drift into repo and commit
dot sync --push                # + push to origin
```

The launchd agent runs `dot sync --push` nightly at 03:00. You rarely need
to run it manually unless you want an immediate save point.

## Key commands

| Command | Purpose |
|---|---|
| `dot sync` | Capture drift into repo; commit (and optionally push) |
| `dot apply` | Reconcile machine with repo (`chezmoi apply` + `brew bundle`) |
| `dot doctor` | Multi-layer health check |
| `dot status` | One-line drift summary (exit 1 if drift) |
| `dot new-machine` | First-run helper after `bootstrap.sh` |
| `dot edit` | Open the source repo in `$EDITOR` |

## Architecture

Full design: [`docs/superpowers/specs/2026-04-16-chezmoi-ironclad-design.md`](docs/superpowers/specs/2026-04-16-chezmoi-ironclad-design.md).

Short version:

- **Machine is source of truth for mutable state.** Installed brew packages
  and AI tool skills/agents/plugins are captured via `dot sync`.
- **Repo is source of truth for authored configs.** `nvim`, `ghostty`,
  `starship`, `zsh`, `git`, etc. Edit in the repo; `dot apply` reconciles
  to the machine.
- **Runtime state never syncs.** Logs, caches, session history, sqlite DBs —
  filtered in `.chezmoiignore`.
- **Secrets via 1Password.** SSH keys, work git email, age decryption key,
  Claude/Codex auth tokens. No secrets on disk outside of 1Password-served
  templates.

## Key layout

```
bootstrap.sh                                        one-liner entry
home/                                                chezmoi source root
├── Brewfile                                         package manifest (tap/brew/cask)
├── bin/executable_dot                               the `dot` CLI
├── Library/LaunchAgents/
│   └── com.jarodtaylor.dots-sync.plist.tmpl         daily sync agent
├── dot_claude/, dot_codex/, dot_cursor/             captured AI tool state
├── dot_config/                                      authored configs (nvim, ghostty, etc.)
├── private_dot_ssh/                                 SSH config (1Password-backed)
├── .chezmoiscripts/                                 runtime scripts (packages, pam, launchd)
└── .chezmoi.toml.tmpl                               per-machine config, 1Password integration
```

## Related docs

- [`SETUP.md`](SETUP.md) — detailed new-machine walkthrough
- [`docs/AUDITING.md`](docs/AUDITING.md) — how to decide sync vs. ignore for a new AI tool
- [`docs/TESTING.md`](docs/TESTING.md) — Parallels VM workflow, dry-run recipes
- [`docs/KNOWN_ISSUES.md`](docs/KNOWN_ISSUES.md) — known rough edges (password prompts, manual installs, etc.)

## Inspiration

- [Tom Payne's dotfiles](https://github.com/twpayne/dotfiles) — chezmoi's creator, clean reference implementation
- [Chezmoi documentation](https://www.chezmoi.io/)
