# ffe - Fast File Edit: Interactive file finder with preview
# 
# Tags: fzf, fuzzy, files, finder, fd, bat, editor, preview, open
#
# Purpose: Find and open files using fd + fzf with intelligent preview and editing
# Usage: ffe
# 
# Features:
# - Searches all files (including hidden) while excluding common build/cache dirs
# - Smart preview: syntax highlighting for text files, file info for binaries
# - Multiple interaction options via keyboard shortcuts
# - Scroll through preview without opening files
# - Copy paths and open with system default apps
# - Opens selection in your preferred editor
#
# Keyboard shortcuts:
# - CTRL-/ : Toggle preview window visibility
# - CTRL-O : Open file with system default application
# - CTRL-Y : Copy file path to clipboard
# - CTRL-D/U : Scroll down/up in preview window
#
# Dependencies: fd, fzf, bat, file, nvim (or $EDITOR)
# Optional: open (macOS), pbcopy (macOS) - for system integration features

ffe() {
  local file preview_cmd
  
  # Smart preview: use bat for text files, file info for others
  preview_cmd='
    if file {} | grep -q "text\|ASCII\|Unicode"; then
      bat --style=numbers --color=always --line-range :300 {}
    else
      file {} && echo "---" && ls -la {}
    fi
  '
  
  file=$(fd --type f --hidden --follow \
    --exclude .git --exclude node_modules --exclude .venv \
    --exclude __pycache__ --exclude .next --exclude dist --exclude build | \
  fzf \
    --preview "$preview_cmd" \
    --preview-window 'right:60%' \
    --bind 'ctrl-/:change-preview-window(down|hidden|)' \
    --bind 'ctrl-o:execute(open {})' \
    --bind 'ctrl-y:execute-silent(echo {} | pbcopy)' \
    --bind 'ctrl-d:preview-down,ctrl-u:preview-up' \
    --header 'CTRL-/ (preview), CTRL-O (open), CTRL-Y (copy), CTRL-D/U (scroll)' \
  ) && [[ -n "$file" ]] && ${EDITOR:-nvim} "$file"
}
