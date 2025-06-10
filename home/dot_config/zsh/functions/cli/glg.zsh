# glg - Git Log Grep: Interactive Git History Search
#
# Tags: git, search, history, pattern, fzf, fuzzy, commit, archaeology, time
#
# Purpose: Search for patterns across entire Git history and interactively explore results
# Usage: glg <search-pattern>
#
# What it does:
# 1. Searches for the given pattern in all git commits (including file content changes)
# 2. Presents matching commits + files in an interactive fzf interface with preview
# 3. Allows you to view file content, open in editor, or create worktree for exploration
#
# Dependencies: git, fzf, awk, bat (for syntax highlighting), nvim (optional)
#
# Examples:
#   glg "function myFunction"  # Find when/where a function was introduced/modified
#   glg "TODO"                # Find all TODOs added/removed throughout history
#   glg "bug fix"             # Find commits mentioning "bug fix"

glg() {
  # Validate input - require search pattern
  if [ -z "$1" ]; then
    echo "Usage: glg <search-pattern>"
    return 1
  fi

  # Main pipeline: Search git history for pattern and prepare for interactive selection
  selection=$(
    # Get full git log with patches, showing only commit hashes
    git log -p --pretty=format:"%H" |
      # Search for pattern in log output, extract matching commit hashes
      awk -v pattern="$1" '/^[a-f0-9]{40}/ {commit=$1} $0 ~ pattern {print commit}' |
      # Remove duplicate commits (pattern might appear multiple times per commit)
      sort -u |
      # For each matching commit, get list of changed files
      while read sha; do
        # Get commit hash and list of files changed in that commit
        git show --name-only --pretty=format:"%H" "$sha" | awk 'NR==1 {commit=$0} NR>1 {print commit, $0}'
      done |
      # Launch interactive fuzzy finder with live preview
      fzf --preview '
        # Parse selection: extract commit hash and filename
        set -- $(echo {} | awk "{print \$1, substr(\$0, index(\$0, \$2))}")
        sha="$1"
        file="$2"

        # Get commit metadata for rich display
        commit_info=$(git show --no-patch --pretty=format:"%ai|%ar|%an|%s" "$sha" 2>/dev/null)
        if [ -n "$commit_info" ]; then
          date_iso=$(echo "$commit_info" | cut -d"|" -f1)
          date_rel=$(echo "$commit_info" | cut -d"|" -f2)
          author=$(echo "$commit_info" | cut -d"|" -f3)
          subject=$(echo "$commit_info" | cut -d"|" -f4)

          # Display rich metadata header
          echo "Date: $date_iso ($date_rel)"
          echo "Author: $author"
          echo "Subject: $subject"
          echo "File: $file"
          echo "Commit: $sha"
          echo ""
          echo "═══════════════════════════════════════════"
          echo ""
        fi

        # Try to show file content from that specific commit
        if git show "$sha:$file" >/dev/null 2>&1; then
          # File exists in this commit - show it with syntax highlighting
          git show "$sha:$file" | bat --color=always --style=numbers --paging=never --file-name="$file"
        else
          # File doesnt exist in this commit - show what changed instead
          echo "❌ File $file does not exist in commit $sha"
          echo "Showing changes made to this file in this commit:"
          echo ""
          git show --color=always -p "$sha" -- "$file" 2>/dev/null || {
            echo "No changes to $file in this commit."
            echo "Showing full commit diff:"
            echo ""
            git show --color=always --stat "$sha"
          }
        fi
      '
  )

  # Handle case where user cancelled selection (ESC in fzf)
  if [ -z "$selection" ]; then
    return 0
  fi

  # Parse the selected result: extract commit hash and filename
  sha=$(echo "$selection" | awk '{print $1}')
  file=$(echo "$selection" | awk '{print substr($0, index($0, $2))}')

  # Interactive menu: Ask user what they want to do with the selected commit+file
  echo "Selected: $sha $file"
  echo "Options:"
  echo "  [1] Show details (default)"
  echo "  [2] Open in Neovim"
  echo "  [3] Explore full repo at this commit (git worktree)"
  echo "  [4] Exit"
  echo -n "Choose an option: "
  read choice

  # Execute user's choice
  case "$choice" in
    2)
      # Option 2: Open file content from specific commit in read-only Neovim
      git show "$sha:$file" | nvim -R -
      ;;
    3)
      # Option 3: Create temporary worktree to explore entire repo state at that commit
      worktree_path="/tmp/git-worktree-$sha"
      echo "Creating worktree at: $worktree_path"
      git worktree add "$worktree_path" "$sha"
      cd "$worktree_path" || exit
      echo "You are now in a read-only version of the repo at commit $sha."
      echo "Use 'cd $worktree_path' to navigate."
      ;;
    *)
      # Option 1 (default) or 4: Just show the commit hash and filename
      echo "$sha $file"
      ;;
  esac
}
