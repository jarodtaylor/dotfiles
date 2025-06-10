# fgc - Find Git Commit: Interactive git commit browser with preview
# 
# Tags: git, commit, log, history, fzf, fuzzy, diff, branch, merge
#
# Purpose: Browse git commits interactively with live preview and multiple viewing options
# Usage: fgc [git-log-options]
# 
# Features:
# - Interactive git log browser with colored output and live preview
# - Multi-select commits for comparison
# - Toggle between commit details and diffs
# - Copy commit hashes, browse files, and more
# - Supports all git log options (branches, date ranges, paths, etc.)
#
# Keyboard shortcuts:
# - Enter: Show full commit details in pager
# - CTRL-D: Show diff between selected commits  
# - CTRL-F: Browse files changed in commit
# - CTRL-Y: Copy commit hash to clipboard
# - CTRL-/: Toggle preview window
# - ` (backtick): Toggle sort order
# - Tab/Shift-Tab: Multi-select commits
#
# Examples:
#   # Basic browsing
#   fgc                           # Browse all commits
#   fgc -10                       # Show last 10 commits
#   fgc --oneline                 # Compact view
#   
#   # Time-based filtering  
#   fgc --since="1 week"          # Recent commits
#   fgc --since="2023-01-01"      # Since specific date
#   fgc --until="1 month ago"     # Before specific time
#   fgc --since="1 week" --author="john"  # Recent commits by author
#   
#   # Branch and merge analysis
#   fgc main..develop             # Commits between branches
#   fgc feature-branch..main      # What's new in main
#   fgc --merge                   # Only merge commits
#   fgc --no-merges               # Exclude merge commits
#   
#   # File and path specific
#   fgc -- src/components/        # Commits affecting specific directory
#   fgc -- "*.js" "*.ts"          # Commits affecting JS/TS files
#   fgc --follow -- package.json  # Follow file through renames
#   
#   # Author and content filtering
#   fgc --author="jane"           # Commits by specific author
#   fgc --grep="fix"              # Commits with "fix" in message
#   fgc --grep="feat\|fix"        # Commits with feat OR fix
#   fgc -S "function search"      # Commits that add/remove specific code
#   
#   # Advanced workflows
#   fgc --first-parent main       # Only direct commits to main
#   fgc --ancestry-path feat..main # Path from feature to main
#   fgc --cherry-pick main...dev  # Find equivalent commits
#
# Dependencies: git, fzf, less, pbcopy (optional)

fgc() {
  local out shas sha q k
  
  # Enhanced git log format with more info
  local git_log_format="%C(auto)%h%d %s %C(blue)%an %C(black)%C(bold)%cr"
  
  # Interactive loop for git log browsing  
  while out=$(
      git log --graph --color=always --format="$git_log_format" "$@" |
      fzf --ansi --multi --no-sort --reverse --query="$q" \
          --print-query --expect=ctrl-d,ctrl-f,ctrl-y \
          --toggle-sort=\` \
          --preview 'git show --color=always --stat --patch {1}' \
          --preview-window 'right:60%' \
          --bind 'ctrl-/:change-preview-window(down|hidden|)' \
          --header 'Enter (show), CTRL-D (diff), CTRL-F (files), CTRL-Y (copy hash), CTRL-/ (preview), ` (sort)'
  ); do
    
    # Parse fzf output
    q=$(head -1 <<< "$out")          # Current query  
    k=$(head -2 <<< "$out" | tail -1) # Key pressed
    shas=$(sed '1,2d;s/^[^a-z0-9]*//;/^$/d' <<< "$out" | awk '{print $1}') # Selected commit hashes
    
    # Exit if no commits selected and no special key pressed
    [ -z "$shas" ] && [ "$k" != "ctrl-d" ] && [ "$k" != "ctrl-f" ] && [ "$k" != "ctrl-y" ] && continue
    
    # Handle user actions
    case "$k" in
      ctrl-d)
        # Show diff between selected commits
        if [ $(echo "$shas" | wc -w) -gt 1 ]; then
          git diff --color=always $shas | less -R
        else
          echo "Select multiple commits with Tab to compare diffs"
          sleep 2
        fi
        ;;
      ctrl-f)
        # Browse files changed in the commit
        if [ -n "$shas" ]; then
          sha=$(echo "$shas" | head -1)
          git show --name-only --pretty=format: "$sha" | \
            grep -v '^$' | \
            fzf --preview "git show --color=always $sha -- {}" \
                --header "Files changed in commit $sha"
        fi
        ;;
      ctrl-y)
        # Copy commit hash to clipboard
        if [ -n "$shas" ]; then
          sha=$(echo "$shas" | head -1)
          echo "$sha" | pbcopy 2>/dev/null || echo "$sha" | xclip -selection clipboard 2>/dev/null || echo "$sha"
          echo "Copied $sha to clipboard"
          sleep 1
        fi
        ;;
      *)
        # Default: Show commit details for each selected commit
        for sha in $shas; do
          git show --color=always "$sha" | less -R
        done
        ;;
    esac
  done
}
