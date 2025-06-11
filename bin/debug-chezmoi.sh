#!/bin/bash

# Standalone chezmoi debug script
# Usage: ./debug-chezmoi.sh

echo "🔍 CHEZMOI DEBUG INFORMATION"
echo "============================="
echo ""

echo "📍 Environment:"
echo "  PWD: $(pwd)"
echo "  USER: $USER"
echo "  HOME: $HOME"
echo "  ONEPASSWORD_AVAILABLE: ${ONEPASSWORD_AVAILABLE:-not set}"
echo ""

echo "🛠️  Tool availability:"
echo "  chezmoi: $(command -v chezmoi || echo 'NOT FOUND')"
echo "  op: $(command -v op || echo 'NOT FOUND')"
echo "  git: $(command -v git || echo 'NOT FOUND')"
echo ""

if command -v chezmoi &>/dev/null; then
  echo "📋 Chezmoi configuration:"
  echo "  Source dir: $("$HOME/bin/chezmoi" source-path 2>/dev/null || echo 'ERROR')"
  echo "  Config file: $("$HOME/bin/chezmoi" config-file 2>/dev/null || echo 'ERROR')"
  echo ""

  echo "📊 Chezmoi status:"
  ONEPASSWORD_AVAILABLE="${ONEPASSWORD_AVAILABLE:-false}" "$HOME/bin/chezmoi" status 2>&1 || echo "❌ Status command failed"
  echo ""

  echo "🗂️  Source directory contents:"
  if [ -d "$HOME/.local/share/chezmoi" ]; then
    find "$HOME/.local/share/chezmoi/home" -type f | head -20
  else
    echo "❌ Source directory doesn't exist"
  fi

  echo ""
  echo "🧪 Testing key templates:"

  # Test .chezmoi.toml.tmpl
  if [ -f "$HOME/.local/share/chezmoi/home/.chezmoi.toml.tmpl" ]; then
    echo "  Testing .chezmoi.toml.tmpl:"
    cd "$HOME/.local/share/chezmoi" && ONEPASSWORD_AVAILABLE="${ONEPASSWORD_AVAILABLE:-false}" chezmoi execute-template < home/.chezmoi.toml.tmpl >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo "    ✅ Template renders successfully"
    else
      echo "    ❌ Template has errors"
      echo "    Error output:"
      cd "$HOME/.local/share/chezmoi" && ONEPASSWORD_AVAILABLE="${ONEPASSWORD_AVAILABLE:-false}" chezmoi execute-template < home/.chezmoi.toml.tmpl 2>&1 | head -5 | sed 's/^/      /'
    fi
  fi
else
  echo "❌ chezmoi not found"
fi

echo ""
echo "📁 Current ~/.config contents:"
find "$HOME/.config" -maxdepth 1 -type d 2>/dev/null | sort || echo "❌ Can't read ~/.config"

echo ""
echo "🔑 Key files status:"
for file in .zshrc .zshenv .ssh/config; do
  if [ -f "$HOME/$file" ]; then
    echo "  ✅ ~/$file exists"
  else
    echo "  ❌ ~/$file missing"
  fi
done

echo ""
echo "🔧 Manual recovery suggestions:"
echo "  1. Try: ONEPASSWORD_AVAILABLE=false ~/bin/chezmoi init --apply --verbose jarodtaylor"
echo "  2. Check specific template: cd ~/.local/share/chezmoi && chezmoi execute-template < home/.chezmoi.toml.tmpl"
echo "  3. Reset and retry: rm -rf ~/.cache/chezmoi ~/.config/chezmoi && ~/bin/chezmoi init --apply jarodtaylor"
