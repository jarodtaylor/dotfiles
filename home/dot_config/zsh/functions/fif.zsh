# fif - Find In Files: Search text in files with interactive preview
# 
# Tags: ripgrep, rg, search, grep, fzf, fuzzy, text, find, pattern
#
# Purpose: Search for text patterns across files using ripgrep, with live preview and direct editing
# Usage: fif <search-pattern> [ripgrep-options]
# 
# Features:
# - Fast text search across all files using ripgrep
# - Interactive selection with syntax-highlighted preview
# - Jump directly to the matching line in your editor
# - Supports all ripgrep options (case sensitivity, file types, etc.)
#
# Examples:
#   # Basic text search
#   fif "function search"           # Find exact phrase
#   fif "TODO"                      # Find all TODOs
#   fif "console.log"               # Find debug statements
#   
#   # Case sensitivity
#   fif -i "api"                    # Case-insensitive search
#   fif -s "API"                    # Case-sensitive search (default)
#   
#   # File type filtering
#   fif "import" --type js          # Search only JavaScript files
#   fif "class" --type py           # Search only Python files
#   fif "SELECT" --type sql         # Search only SQL files
#   fif "component" -t tsx -t jsx   # Search React component files
#   
#   # Regex patterns
#   fif "function.*search"          # Functions containing "search"
#   fif "export (const|let|var)"    # Find exports
#   fif "\b[A-Z]{2,}\b"            # Find UPPERCASE words
#   fif "https?://[^\s]+"          # Find URLs
#   
#   # Directory control
#   fif "config" --glob "!node_modules/**"  # Exclude node_modules
#   fif "test" --glob "**/*.test.*"         # Only test files
#   fif "api" -g "!*.min.js"               # Exclude minified files
#   
#   # Advanced searches
#   fif -A 2 -B 2 "error"          # Show 2 lines before/after matches
#   fif -w "log"                    # Whole word matches only
#   fif -v "deprecated"             # Invert match (lines NOT containing)
#   fif --multiline "import.*\n.*from"     # Multi-line patterns
#   
#   # Development workflows
#   fif "FIXME\|TODO\|HACK"         # Find all code annotations
#   fif "process\.env"              # Find environment variable usage
#   fif "useState\|useEffect"       # Find React hooks
#   fif "fmt\.Print"                # Find Go print statements
#   fif "def test_"                 # Find Python test functions
#   
#   # Configuration hunting
#   fif "port.*3000"                # Find port configurations
#   fif "database.*url"             # Find database connection strings
#   fif "secret\|password\|token"   # Find potential secrets (be careful!)
#
# Dependencies: rg (ripgrep), fzf, bat, nvim (or $EDITOR)

fif() {
  if [ -z "$1" ]; then
    echo "Usage: fif <search-pattern> [ripgrep-options]"
    return 1
  fi

  local search_display="🔍 Original: '$1'"
  if [ $# -gt 1 ]; then
    search_display="$search_display ${*:2}"
  fi

  local result
  result=$(rg --ignore-case --color=always --line-number --no-heading "$@" |
    fzf --ansi \
        --prompt "Filter results > " \
        --header "$search_display
Type to filter these results further • CTRL-/ (toggle preview) • CTRL-O (open file)" \
        --header-lines=0 \
        --color 'hl:-1:underline,hl+:-1:underline:reverse' \
        --delimiter ':' \
        --preview 'echo "File: {1}" && echo "Line: {2}" && echo "Content: {3}" && echo "---" && bat --color=always {1} --style=numbers --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --bind 'ctrl-/:change-preview-window(down|hidden|)' \
        --bind 'ctrl-o:execute(open {1})')
  
  if [[ -n "$result" ]]; then
    local file linenumber
    file=${result%%:*}
    linenumber=$(echo "${result}" | cut -d: -f2)
    ${EDITOR:-nvim} +"${linenumber}" "$file"
  fi
}
