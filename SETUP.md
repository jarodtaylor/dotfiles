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

## 6. Optional: restart

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
