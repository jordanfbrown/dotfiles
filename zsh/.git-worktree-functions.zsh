# Git Worktree Functions

# Main wrapper function - shows all available commands
gw() {
  echo "Git Worktree Functions:"
  echo ""
  echo "  gwn <branch-name> [path]    - Create new branch and worktree"
  echo "  gwe <existing-branch> [path] - Create worktree from existing branch"
  echo "  gwb <branch-suffix>         - Create jb/<suffix> branch and worktree"
  echo "  gwl                         - List and navigate to git repos/worktrees (fzf)"
  echo ""
  echo "  gwr <worktree-path>         - Remove a worktree"
  echo "  gwp                         - Prune deleted worktrees"
  echo ""
  echo "All worktrees are created under ~/wealthsimple/worktrees/<repo-name>/"
  echo "Use 'gwl' to quickly navigate between your git repositories and worktrees."
}

# Create new branch and worktree
gwn() {
  local branch_name="$1"
  local custom_path="$2"
  
  if [[ -z "$branch_name" ]]; then
    echo "Usage: gwn <branch-name> [custom-path]"
    echo "Creates new branch and worktree under ~/wealthsimple/worktrees/"
    return 1
  fi
  
  local repo_name=$(basename $(git rev-parse --show-toplevel))
  local worktree_base="$HOME/wealthsimple/worktrees/$repo_name"
  local final_path="${custom_path:-$worktree_base/$branch_name}"
  
  mkdir -p "$worktree_base"
  git worktree add -b "$branch_name" "$final_path"
  cd "$final_path"
}

# Create worktree from existing branch
gwe() {
  local branch_name="$1"
  local custom_path="$2"
  
  if [[ -z "$branch_name" ]]; then
    echo "Usage: gwe <existing-branch-name> [custom-path]"
    echo "Creates worktree from existing branch under ~/wealthsimple/worktrees/"
    return 1
  fi
  
  local repo_name=$(basename $(git rev-parse --show-toplevel))
  local worktree_base="$HOME/wealthsimple/worktrees/$repo_name"
  local final_path="${custom_path:-$worktree_base/$branch_name}"
  
  mkdir -p "$worktree_base"
  git worktree add "$final_path" "$branch_name"
  cd "$final_path"
}

# Create jb/ prefixed branch and worktree
gwb() {
  local branch_suffix="$1"
  if [[ -z "$branch_suffix" ]]; then
    echo "Usage: gwb <branch-suffix>"
    echo "Creates: jb/<branch-suffix> branch in ~/wealthsimple/worktrees/"
    return 1
  fi
  
  local repo_name=$(basename $(git rev-parse --show-toplevel))
  local worktree_base="$HOME/wealthsimple/worktrees/$repo_name"
  local final_path="$worktree_base/jb-${branch_suffix}"
  
  mkdir -p "$worktree_base"
  git worktree add -b "jb/${branch_suffix}" "$final_path"
  cd "$final_path"
}

# List and navigate to git repositories and worktrees
gwl() {
  local all_paths=()
  
  # Add all git repositories in $HOME/wealthsimple
  if [ -d "$HOME/wealthsimple" ]; then
    while IFS= read -r -d '' dir; do
      if [ -d "$dir/.git" ]; then
        all_paths+=("$dir")
        if git -C "$dir" worktree list &>/dev/null; then
          while IFS= read -r wt; do
            all_paths+=("$wt")
          done < <(git -C "$dir" worktree list --porcelain | grep '^worktree ' | awk '{print $2}')
        fi
      fi
    done < <(find "$HOME/wealthsimple" -maxdepth 1 -mindepth 1 -type d -print0)
  fi

  local selected=$(printf '%s\n' "${all_paths[@]}" | sort -u | fzf)
  [ -n "$selected" ] && cd "$selected"
}

# Git worktree aliases
alias gwr="git worktree remove"
alias gwp="git worktree prune" 