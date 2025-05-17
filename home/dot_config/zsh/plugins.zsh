# Correct plugin directory (matches plugin-clone behavior)
ZSH_PLUGIN_DIR="${HOME}/.cache/antidote.lite"

# Source the loader
source "${ZSH_PLUGIN_DIR}/antidote.lite.zsh"

# Define plugins
utils=(
  romkatv/zsh-bench
)

plugins=(
  mattmc3/zfunctions
  rupa/z
  belak/zsh-utils/editor
  belak/zsh-utils/history

  # deferred
  romkatv/zsh-defer
  olets/zsh-abbr
  zdharma-continuum/fast-syntax-highlighting
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-history-substring-search
)

# Clone and load
plugin-clone "$ZSH_PLUGIN_DIR" "${utils[@]}" "${plugins[@]}"
plugin-load --kind path "${utils[@]}"
plugin-load "${plugins[@]}"
