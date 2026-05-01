#!/usr/bin/env bash
# bootstrap.sh — zero-to-productive macOS setup for this dotfiles repo
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/jarodtaylor/dotfiles/main/bootstrap.sh | bash
#
# Override the branch for pre-merge testing:
#   CHEZMOI_BRANCH=design/chezmoi-ironclad bash bootstrap.sh
#
# Prereqs (not handled here — see SETUP.md):
#   1. macOS with user account created
#   2. Xcode Command Line Tools installed (xcode-select --install)
#   3. 1Password app installed, signed in, SSH agent + CLI enabled
#   4. 1Password CLI (`op`) installed and authenticated (`op signin`)
#
# This script does:
#   1. Preflight: verify Xcode CLT, op CLI, op auth
#   2. Install Homebrew (if missing)
#   3. Install chezmoi + age (age is needed at chezmoi-init time to derive
#      the encryption recipient; installing it via Brewfile alone creates
#      a chicken-and-egg where first apply can't decrypt encrypted_* files)
#   4. chezmoi init --apply from this repo
#      (chezmoi apply then runs Brewfile, resolves 1Password templates,
#      loads the dots-sync launchd agent.)

set -euo pipefail

REPO_USER="jarodtaylor"
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
  warn "Install 1Password.app + enable CLI integration (Preferences → Developer), then re-run."
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

# Put brew on PATH for this shell session (Homebrew installer prints this hint
# but doesn't mutate PATH for the caller).
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  die "Homebrew installed but brew binary not found at /opt/homebrew or /usr/local."
fi

# --- chezmoi + age (both needed at init time) ---
for pkg in chezmoi age; do
  if ! command -v "$pkg" >/dev/null 2>&1; then
    log "installing $pkg..."
    brew install "$pkg"
  else
    ok "$pkg already installed"
  fi
done

# --- SSH known_hosts: preempt github.com prompt ---
# First `git push` (e.g. from `dots sync --push`) connects to github.com
# over SSH via the 1Password agent. If ~/.ssh/known_hosts doesn't have
# github.com, ssh blocks on the yes/no prompt — fine interactively, fatal
# in non-interactive contexts. Idempotent.
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/known_hosts"
chmod 644 "$HOME/.ssh/known_hosts"
if ssh-keygen -F github.com >/dev/null 2>&1; then
  ok "github.com already in known_hosts"
else
  log "adding github.com to ~/.ssh/known_hosts"
  ssh-keyscan -H -t rsa,ecdsa,ed25519 github.com 2>/dev/null >> "$HOME/.ssh/known_hosts"
  ok "github.com pinned in known_hosts"
fi

# --- Age identity from 1Password → on-disk cache ---
# chezmoi's [age] config requires a file path for identity. There's no
# native "fetch from a command at apply time" option, so we materialize
# the 1Password-held age key to ~/.config/chezmoi/key.txt (0600). 1P
# stays authoritative; this file is a derived cache. Rotation is a
# manual `op read > key.txt` until we script it. See KNOWN_ISSUES.md.
mkdir -p "$HOME/.config/chezmoi"
chmod 700 "$HOME/.config/chezmoi"
if [ -s "$HOME/.config/chezmoi/key.txt" ]; then
  ok "age identity already present at ~/.config/chezmoi/key.txt"
else
  log "fetching age identity from 1Password → ~/.config/chezmoi/key.txt"
  if ! op read 'op://Personal/Dotfiles Age Key/notesPlain' \
        > "$HOME/.config/chezmoi/key.txt"; then
    die "failed to fetch age key from 1Password (Personal vault)."
  fi
  chmod 600 "$HOME/.config/chezmoi/key.txt"
  ok "age identity pinned"
fi

# --- init + apply ---
log "running: chezmoi init --apply --branch $BRANCH $REPO_USER"
chezmoi init --apply --verbose --branch "$BRANCH" "$REPO_USER"

ok "bootstrap complete"
log "next: open a new shell; run 'dots doctor' to verify everything is green"
