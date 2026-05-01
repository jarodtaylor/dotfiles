# New Machine Setup

The one-liner in the README does the heavy lifting. This doc covers the
pre-one-liner steps (things that can't be automated yet) and post-bootstrap
verification.

Total time: ~5 minutes of active clicks + 30–60 minutes walkaway.

## 0. Physical setup

Fresh macOS install, user account created, connected to wifi. Sign into your
Apple ID (or skip; not strictly required for the dotfiles flow).

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

Download the `.pkg` installer from
[1password.com/downloads/command-line](https://1password.com/downloads/command-line/).
(You could install `1password-cli` via Homebrew after bootstrap, but the
bootstrap script needs `op` present before it runs, so install the pkg first.)

Verify:

```bash
op --version
# Expected: a 2.x version string
```

### 2c. Authenticate

```bash
op account add   # paste sign-in URL, email, secret key
op signin        # unlock session
op whoami        # verify
```

## 3. Verify required 1Password entries exist

Templates expect these entries in your `Personal` vault:

| Entry name | Type | Field read |
|---|---|---|
| `Dotfiles Age Key` | Secure Note | `notesPlain` (full `age-keygen` output: comments + secret) |
| `Claude Code env` | Secure Note | `notesPlain` (plaintext of `~/.claude/.env`) |
| `Codex auth` | Secure Note | `notesPlain` (plaintext of `~/.codex/auth.json`) |
| `GitHub PAT - cursor mcp` | Secure Note | `notesPlain` (single `ghp_…` token) |
| (existing) Personal SSH key | SSH key | `public key` |
| (existing) Work SSH key | SSH key | `public key` |

Spot-check:

```bash
op item list --vault Personal | grep -E 'Age Key|Claude Code env|Codex auth|cursor mcp'
```

If any is missing, create it (see spec §8) before running bootstrap.

## 4. Run the one-liner

### Just-in-time: verify 1Password CLI session

**Even if step 2c succeeded earlier**, `op` sessions expire (default 30
days, shorter if you've locked the app or rebooted). The bootstrap
script's preflight will abort if the session is stale — save yourself
the round-trip:

```bash
op whoami
```

If it errors with "not currently signed in" (or similar), refresh:

```bash
op signin
```

Then proceed.

### Run

```bash
curl -fsSL https://raw.githubusercontent.com/jarodtaylor/dotfiles/main/bootstrap.sh | bash
```

For pre-merge testing against a branch:

```bash
CHEZMOI_BRANCH=design/chezmoi-ironclad bash <(curl -fsSL \
  https://raw.githubusercontent.com/jarodtaylor/dotfiles/design/chezmoi-ironclad/bootstrap.sh)
```

Walkaway time: 30–60 minutes.

**Expect a burst of password prompts near the end.** Adobe, Docker Desktop,
Karabiner Elements, Microsoft Outlook, Microsoft Teams, Zoom, and
BlackHole all ship pkg installers that trigger macOS Authorization Services
prompts. These cannot be suppressed via sudo priming (Auth Services has no
timestamp concept) — they're grouped at the end of the Brewfile so they
arrive back-to-back rather than scattering. Stand by when the Brewfile
reaches the `# Casks — interactive installers` section.

When bootstrap finishes, close the terminal and open a new one (so the new
PATH and zsh config load).

## 5. Verify

```bash
dots doctor
```

Expect everything green. If anything warns or errors, see
[`docs/KNOWN_ISSUES.md`](docs/KNOWN_ISSUES.md) or follow the hint in the
warning itself.

## 6. Post-bootstrap setup (manual)

The bootstrap installs apps and applies configs. Several things still
need human hands — most are once-per-machine. Work through these in
order; the whole pass is usually 15–30 minutes.

### 6a. Sign into Mac App Store, then re-apply

If you skipped App Store sign-in during bootstrap, every `mas "..."`
entry in the Brewfile failed silently. Open the App Store app, sign
in with your Apple ID, then:

```bash
dots apply
```

The next `brew bundle install` picks them up.

### 6b. Sign into apps that need accounts

The Brewfile installs the apps; you still log in by hand. In this
setup, account-required apps include:

- **Dev tools** — Cursor, GitHub Desktop, Postman, VS Code (if used)
- **Chat & meetings** — Slack, Discord, Telegram, Microsoft Teams, Zoom
- **AI tools** — ChatGPT, Claude, Granola
- **Productivity** — Notion, Obsidian, Spotify
- **Creative** — Adobe Creative Cloud (sign in, then install the apps you actually use via the launcher)

> Forkers: replace this list with whatever GUI apps your own Brewfile
> installs that need credentials.

### 6c. Grant macOS permissions

Apps that hook into UI events, screen capture, audio devices, or
kernel extensions need explicit grants in System Settings →
**Privacy & Security**. Each app prompts on first launch and hands
you off to the right pane; drag the app into the toggle list and
re-launch.

In this setup:

| App | Permission(s) |
|---|---|
| Raycast | Accessibility, Screen Recording, Input Monitoring |
| CleanShot X | Screen Recording, Accessibility |
| Karabiner-Elements | Input Monitoring + **kernel extension approval** (one-time; requires reboot after Allow) |
| Aerospace | Accessibility |
| Shortcat | Accessibility |
| BlackHole-2ch | Audio device kext approval |

> Forkers: anything that automates UI, captures the screen, or hooks
> keyboard/mouse/audio will need similar grants. Check each app's
> first-run prompts.

### 6d. First-launch (and Open-at-Login) for utilities

Several apps don't auto-start after `brew bundle install` — macOS
won't register them as Login Items until you open them at least
once. Open each, grant any permission prompts (see 6c), then their
"start at login" preference (or the equivalent in `~/.config/...`)
takes effect on subsequent reboots.

- **Aerospace** — `open -a Aerospace`. Grant Accessibility when
  prompted. The config at `~/.config/aerospace/aerospace.toml`
  already sets `start-at-login = true`, so it'll auto-start after
  the first manual launch.
- **Karabiner-Elements** — `open -a 'Karabiner-Elements'`. Approve
  the kernel extension in System Settings → Privacy & Security
  (one-time, requires a reboot). Config at
  `~/.config/karabiner/karabiner.json` is already shipped (Caps Lock
  → Control, Right Cmd → Hyper, etc.).
- **Sketchybar** — auto-launches when Aerospace starts (via
  Aerospace's `after-startup-command`). If the bar is empty or you
  rebuild helpers later, force a reload:
  `pkill sketchybar; sketchybar &` — or use Karabiner **Hyper+S+R**
  (Right Cmd+S then R) which runs the full
  `aerospace reload-config && pkill sketchybar && sketchybar` chord.
  Aerospace's `after-startup-command` only fires once at Aerospace
  startup; it does *not* monitor or respawn sketchybar.
- **Raycast** — Settings → General → "Launch Raycast at login".
  Cmd+Space is freed from Spotlight by `30-macos-defaults`, but the
  release only fully applies after a logout/login. If Cmd+Space still
  triggers Spotlight after first launch, log out and back in (or
  reboot once) and Raycast will claim it.
- **CleanShot X** — Settings → General → "Launch at login"
- **1Password** — auto-enabled after install; verify it's on

> Forkers: this is whatever menu-bar / utility apps you want
> auto-launching. Most need to be opened once before macOS treats
> their "start at login" toggle as effective.

### 6e. Manual installs (not in the Brewfile)

A few packages are deliberately excluded from the Brewfile because
they need SSH credentials, manual licensing, or have flaky unattended
installs. Run these by hand once 1Password's SSH agent is active:

```bash
# elco — private GitHub tap (SSH-only; needs 1P agent live)
brew tap elc-online/tap git@github.com:elc-online/homebrew-tap.git
brew install elc-online/tap/elco

# ExpressVPN — cask's LaunchDaemon install is historically flaky
open https://www.expressvpn.com/latest
```

See [`docs/KNOWN_ISSUES.md`](docs/KNOWN_ISSUES.md) §"Post-bootstrap
manual installs" for the full rationale.

> Forkers: list anything your Brewfile *can't* handle (private taps,
> flaky casks, apps needing manual licensing or config before install).

### 6f. Optional: GitHub CLI authentication

If you use `gh`:

```bash
gh auth login
```

The 1Password SSH agent handles `git push` over SSH; `gh`'s HTTPS API
calls need their own token.

## 7. Optional: restart

Once, to ensure login items and brew services pick up cleanly.

---

## Troubleshooting

**`op whoami` fails after restart.** The 1Password CLI session expired. Run
`op signin` again. Chezmoi templates that read from op will fail until you
do.

**`chezmoi apply` says "recipient mismatch" for age.** The public key
embedded in `.chezmoi.toml.tmpl` doesn't match the private key in 1Password.
Verify the `Dotfiles Age Key` entry contains the full keyfile (two lines:
the `# created:` comment line and the `AGE-SECRET-KEY-…` line).

**Something broke after a sync.** Roll back:

```bash
cd $(chezmoi source-path)
git log --oneline | head
git revert <bad-hash>
dots apply
```
