#!/usr/bin/env bash
# Claude Code status line
# Receives JSON via stdin with session/model/context/workspace data

input=$(cat)

# --- Model ---
model_id=$(echo "$input" | jq -r '.model.id // empty')
# Shorten model ID: strip "claude-" prefix, keep the rest
model_short="${model_id#claude-}"

# --- Directory ---
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // empty')
# Replace $HOME with ~
home="$HOME"
cwd_display="${cwd/#$home/\~}"

# --- Git branch (no lock contention) ---
git_branch=""
if [ -n "$cwd" ] && [ -d "$cwd/.git" ] || git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
fi

# --- Context usage with visual bar ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_display=""
if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct" 2>/dev/null || echo "0")

  # Color: green < 60%, yellow 60-79%, red >= 80%
  if [ "$used_int" -ge 80 ] 2>/dev/null; then
    CTX_COLOR="\033[31m"
  elif [ "$used_int" -ge 60 ] 2>/dev/null; then
    CTX_COLOR="\033[33m"
  else
    CTX_COLOR="\033[32m"
  fi

  # Filled segments out of 10
  FILLED=$((used_int * 10 / 100))
  [ "$FILLED" -gt 10 ] && FILLED=10
  [ "$FILLED" -lt 0 ] && FILLED=0

  # Build bar: ▓=filled ░=empty │=auto-compact marker at 80%
  BAR_FILLED=""
  BAR_EMPTY=""
  for i in {0..9}; do
    if [ "$i" -eq 8 ]; then
      if [ "$i" -lt "$FILLED" ]; then
        BAR_FILLED="${BAR_FILLED}│"
      else
        BAR_EMPTY="${BAR_EMPTY}│"
      fi
    elif [ "$i" -lt "$FILLED" ]; then
      BAR_FILLED="${BAR_FILLED}▓"
    else
      BAR_EMPTY="${BAR_EMPTY}░"
    fi
  done

  ctx_display=$(printf "${CTX_COLOR}%s\033[2m%s\033[0m ${CTX_COLOR}%s%%\033[0m" "$BAR_FILLED" "$BAR_EMPTY" "$used_int")
fi

# --- Time ---
time_now=$(date +%H:%M:%S)

# --- ANSI colors (will appear dimmed in Claude Code's status line) ---
RESET="\033[0m"
CYAN="\033[36m"
YELLOW="\033[33m"
GREEN="\033[32m"
MAGENTA="\033[35m"
BLUE="\033[34m"
DIM="\033[2m"

# --- Separator ---
SEP="${DIM} · ${RESET}"

# --- Build output ---
parts=()

# Model segment
if [ -n "$model_short" ]; then
  parts+=("$(printf "${CYAN}[%s]${RESET}" "$model_short")")
fi

# Directory segment
if [ -n "$cwd_display" ]; then
  parts+=("$(printf "${YELLOW}%s${RESET}" "$cwd_display")")
fi

# Git branch segment
if [ -n "$git_branch" ]; then
  parts+=("$(printf "${GREEN}git:%s${RESET}" "$git_branch")")
fi

# Context usage segment (colors handled by bar builder)
if [ -n "$ctx_display" ]; then
  parts+=("$ctx_display")
fi

# Time segment
parts+=("$(printf "${BLUE}%s${RESET}" "$time_now")")

# Join with separator
output=""
for i in "${!parts[@]}"; do
  if [ $i -eq 0 ]; then
    output="${parts[$i]}"
  else
    output="${output}${SEP}${parts[$i]}"
  fi
done

printf "%b\n" "$output"
