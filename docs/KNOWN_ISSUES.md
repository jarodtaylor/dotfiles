# Known Issues & Gotchas

Things you may hit when running this repo, and how to work around them.
Most are not bugs in the repo — they're macOS constraints, deliberate
scope cuts that favor bootstrap reliability, or upstream quirks.

If you hit something not listed here, open an issue or append to this
file.

---

## Post-bootstrap manual installs

Two packages are deliberately **not** in the Brewfile. Both are
filtered by `dot sync`'s denylist (see `home/bin/executable_dot`), so
they won't sneak back in even if installed on an authoritative host.

### elco (private GitHub tap)

`elco` lives in `elc-online/homebrew-tap`, a private repo requiring
SSH auth. At bootstrap time the 1Password SSH agent isn't reliably
wired up through every shell, so a tap over SSH can fail. Install
manually after bootstrap:

```bash
brew tap elc-online/tap git@github.com:elc-online/homebrew-tap.git
brew install elc-online/tap/elco
```

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

- `docker-desktop`
- `karabiner-elements`
- `microsoft-outlook`, `microsoft-teams`
- `adobe-creative-cloud`
- `blackhole-2ch`
- `zoom`

Plan for ~7 password prompts at the end of the first bootstrap. Note
that the grouping only survives the first `dot sync` — subsequent
syncs flatten the file alphabetically (see below).

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

### First `dot sync` flattens the curated Brewfile

The hand-curated `home/Brewfile` groups packages into sections (Taps,
Core CLI, UI, Interactive installers at end) for human readability and
to bunch prompt-heavy casks. The first time you run `dot sync`, those
section comments are replaced by flat-alphabetized output from
`brew bundle dump`.

This is the acknowledged **B1 trade-off** from the design spec. The
grouping value was one-shot: it helps the *first* bootstrap land
cleanly (prompt bunching). After that, machine state is authoritative
and the flat-alphabetized form is diff-friendlier anyway.

An auto-generated header with denylist rationale is re-prepended on
every `dot sync` so the file stays self-documenting.

### Daily launchd agent and Touch ID

The `com.jarodtaylor.dots-sync` launchd agent runs `dot sync --push`
at 03:00 local. `dot sync` calls `chezmoi re-add`, which renders
templates — and op-gated templates (`.claude/.env.tmpl`, etc.)
need a 1Password session.

The macOS Touch ID prompt requires a foreground user session. At 03:00
with the machine asleep or locked, the prompt never appears and the
`op` call errors out. `dot sync`'s re-add step is wrapped in `|| true`,
so this failure is **non-fatal** — the Brewfile dump still succeeds
and gets committed, but template drift for that night's run won't be
captured.

You'll catch any missed template drift the next time you run `dot sync`
manually from an interactive shell.

### `op` in automation contexts (Claude Code, cron, non-TTY)

The 1Password CLI integration uses Touch ID on-demand, which requires
a TTY-attached foreground process. Non-interactive contexts can't
trigger the prompt:

- Claude Code `!` shells and subagent Bash calls
- `launchd` agents
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

This is why `dot sync` filters them out of captured state (see
`BREWFILE_DENYLIST_CASK` in `home/bin/executable_dot`).

---

## Parallels VM testing

Only relevant if you're validating the bootstrap flow in a VM before
merging changes. See `docs/TESTING.md` for the full workflow.

### Signed commits fail in the VM

`git config --global commit.gpgsign true` is set in the committed
`home/dot_config/git/config`, which expects the 1Password SSH agent
to be available. VMs don't have the host's 1Password agent, so
`dot sync` commits fail with `gpg failed to sign the data`.

**Workaround** in the VM's source directory:

```bash
git -C "$(chezmoi source-path)/.." config --local commit.gpgsign false
```

On the real host with 1Password + Touch ID, signed commits work
normally.

### Per-terminal op session in VMs

macOS Sequoia's App-Data privacy gate combined with no Touch ID
passthrough into Parallels means the 1Password CLI integration can't
persist a session across shells. Every new terminal prompts for
unlock.

**Workaround**: disable 1Password auto-lock in the VM baseline
snapshot so at least a single unlock covers a full test session.

### Baseline snapshot refresh

The existing `clean-macos-with-1password` Parallels snapshot predates
the "disable 1P auto-lock" recommendation above. Consider
re-snapshotting after applying the settings tweak so future VM
bootstraps are quieter.
