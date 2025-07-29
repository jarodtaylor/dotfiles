gbd() {
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Not in a git repository"
    return 1
  fi
  
  local current_branch=$(git branch --show-current)
  local protected_branches=("main" "int" "develop" "staging" "master")
  
  # Get branches excluding current and protected ones
  local available_branches=$(git branch --format='%(refname:short)' | 
    grep -v "$current_branch" | 
    grep -v -E "^($(IFS='|'; echo "${protected_branches[*]}"))$")
  
  if [[ -z "$available_branches" ]]; then
    echo "No branches available for deletion (excluding current and protected branches)"
    return 0
  fi
  
  local branches_to_delete
  branches_to_delete=$(echo "$available_branches" | 
    fzf --multi \
        --bind 'ctrl-a:select-all' \
        --bind 'ctrl-d:deselect-all' \
        --bind 'ctrl-t:toggle-all' \
        --preview 'git log --oneline --graph --color=always {} | head -10' \
        --preview-window 'right:50%' \
        --header "Select branches to DELETE | TAB=select, Ctrl+A=all, Ctrl+D=none, Ctrl+T=toggle (current: $current_branch)")
  
  if [[ -n "$branches_to_delete" ]]; then
    echo "Current branch: $current_branch (protected)"
    echo "Branches to delete:"
    echo "$branches_to_delete" | sed 's/^/  -  /'
    echo
    read "confirm?Delete these branches? (y/N): "
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      echo "$branches_to_delete" | while read -r branch; do
        if git branch -D "$branch" 2>/dev/null; then
          echo "Deleted: $branch"
        else
          echo "Failed to delete: $branch"
        fi
      done
    else
      echo "Deletion cancelled."
    fi
  else
    echo "No branches selected."
  fi
}
