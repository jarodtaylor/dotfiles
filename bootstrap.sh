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

# --- init + apply ---
log "running: chezmoi init --apply --branch $BRANCH $REPO_USER"
chezmoi init --apply --verbose --branch "$BRANCH" "$REPO_USER"

ok "bootstrap complete"
log "next: open a new shell; run 'dot doctor' to verify everything is green"
