# Known Issues & Gotchas

Things you may hit when running this repo, and how to work around them.
Most are not bugs in the repo — they're macOS constraints, deliberate
scope cuts that favor bootstrap reliability, or upstream quirks.

If you hit something not listed here, open an issue or append to this
file.

---

## Post-bootstrap manual installs

A few things are deliberately **not** in the Brewfile (Brewfile is
hand-edited; nothing auto-captures into it). Install these by hand
after bootstrap:

### ExpressVPN

The `expressvpn` cask installs a LaunchDaemon that's historically
flaky under unattended `brew bundle` runs (fails partway, leaves the
daemon half-loaded, requires a reboot). Install from
[expressvpn.com](https://www.expressvpn.com/latest) instead.

---

## First bootstrap gotchas

### Password prompt burst from cask installers

Several casks ship as `.pkg` installers that invoke macOS Authorization
Services (a sudo-style native GUI prompt that cannot be suppressed or
primed). The Brewfile groups these together so they fire back-to-back
at the end of `brew bundle install` instead of being scattered across
a 30-minute run:

- `adobe-creative-cloud`
- `blackhole-2ch`
- `docker-desktop`
- `karabiner-elements`
- `microsoft-auto-update`
- `microsoft-teams`
- `zoom`

Plan for ~7 password prompts at the end of the first bootstrap.
(Microsoft Outlook is now installed via the App Store, so it doesn't
appear here.)

### 1Password authorization timeout

If you step away during a long `brew bundle install` and the
1Password app auto-locks, the next `onepasswordRead` template call
will time out:

```
[ERROR] authorization timeout
```

**Recovery**: unlock 1Password, then re-run:

```bash
chezmoi apply -v
```

Previously installed packages won't reinstall — the `brew bundle`
step is content-gated on the Brewfile's sha256 via the
`run_onchange_before_10-install-packages.sh.tmpl` script.

**Prevention (recommended for first bootstrap)**: disable 1Password
auto-lock in Settings → Security for the duration of the install, then
re-enable.

### Mac App Store apps require Apple ID signed in

The Brewfile includes a handful of `mas "..."` entries (Amphetamine,
Numbers, Pages, HP Smart, etc). `mas install` will fail if the App
Store isn't signed in with an Apple ID. Sign in via the App Store app
before running bootstrap, or expect those entries to report failures
during `brew bundle install` (non-fatal, brew continues).

---

## Day-to-day operations

### `op` in automation contexts (Claude Code, cron, non-TTY)

The 1Password CLI integration uses Touch ID on-demand, which requires
a TTY-attached foreground process. Non-interactive contexts can't
trigger the prompt:

- Claude Code `!` shells and subagent Bash calls
- `cron`
- CI

In these contexts, `op` calls fail with `account is not signed in`.
The fix is either:

1. Use the tool from an interactive terminal where `op` works (most
   dotfiles operations are user-initiated anyway), or
2. For truly automated flows, use a 1Password service account and
   `OP_SERVICE_ACCOUNT_TOKEN` (not configured in this repo).

---

## Preflight prerequisites (never add to Brewfile)

### 1Password app + 1Password CLI

Install these **before** running `bootstrap.sh`, via the official
signed installers from 1password.com:

- `1Password-<version>.pkg` (the app)
- `op` CLI (enabled via *Settings → Developer → Integrate with
  1Password CLI* in the app)

Do **not** put `cask "1password"` or `cask "1password-cli"` in the
Brewfile. During `brew bundle install` they race the pkg installers
and leave the user with two `op` binaries on PATH, where only one
holds the CLI-integration entitlement. The symptom is cryptic:
`op whoami` reports signed in but `onepasswordRead` templates fail.

### `op whoami` says "not signed in" but `op read` works

With CLI integration enabled (above), `op` authenticates per-command via the
app's biometric prompt and keeps **no token session**, so `op whoami` reports
"account is not signed in" even though `op read` / `onepasswordRead` succeed.
chezmoi's config template (`home/.chezmoi.toml.tmpl`) therefore probes 1Password
with a real `op read`, not `op whoami`, and `dots doctor` falls back the same
way. You do **not** need `op signin` for `chezmoi init`/`apply` under
integration; `op signin` (a token session) is only required by `bootstrap.sh`'s
preflight on a fresh machine.

### Age identity: on-disk cache at `~/.config/chezmoi/key.txt`

chezmoi's `[age]` config requires an identity **file path** —
`identity`, `identities`, or `identityFile`+`passphrase`. There is no
native "fetch from a command at apply time" option. To decrypt the
`encrypted_*` files in this repo (e.g., the work git config),
`bootstrap.sh` materializes the 1Password-held age key to
`~/.config/chezmoi/key.txt` with `0600` permissions.

**Security posture**: same as pre-refactor `~/key.txt` — an on-disk
secret in user-space. 1Password remains the authoritative copy
(survives machine loss, syncs across devices). The file is a derived
cache.

**Rotation**: update the `Dotfiles Age Key` entry in 1Password, then
re-run:

```bash
op read 'op://Personal/Dotfiles Age Key/notesPlain' \
  > ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt
```

If you lose the local cache (e.g., after `rm -rf ~/.config/chezmoi/`),
re-run `bootstrap.sh` — it detects the missing file and re-fetches.

