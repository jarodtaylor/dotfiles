# Catppuccin Mocha theme configuration
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--border rounded \
--preview-window 'right:60%' \
--bind 'ctrl-/:toggle-preview' \
--bind 'ctrl-y:execute-silent(echo {} | pbcopy)' \
--multi"

# Enhanced preview options
# CTRL-T configuration: Preview file contents with bat
export FZF_CTRL_T_OPTS="
  --preview 'bat --style=numbers --color=always {}' \
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

# ALT-C configuration: Preview directory tree with eza
export FZF_ALT_C_OPTS="
  --preview 'eza --tree --level=2 --color=always {}' \
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
