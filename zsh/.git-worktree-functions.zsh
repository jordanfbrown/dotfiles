# Git Worktree Functions
# Streamlined worktree management with copy-on-write support

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

_wt_green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
_wt_yellow() { printf '\033[0;33m%s\033[0m\n' "$1"; }
_wt_red() { printf '\033[0;31m%s\033[0m\n' "$1"; }

# Copy-on-write (assumes APFS)
_wt_cp_cow() {
  /bin/cp -Rc "$1" "$2"
}

# Open correct IDE based on project type
_wt_open_ide() {
  local dir="$1"
  if [[ -f "$dir/Gemfile" ]]; then
    rubymine "$dir"
  elif [[ -f "$dir/package.json" ]]; then
    webstorm "$dir"
  elif [[ -f "$dir/build.gradle" || -f "$dir/build.gradle.kts" ]]; then
    idea "$dir"
  fi
  # Otherwise: no IDE opened
}

# Convert identifier to branch name
# 123 → jb-hhmm-123
# hhmm-123 → jb-hhmm-123
# feature-x → jb-feature-x
_wt_to_branch() {
  local input="$1"
  if [[ "$input" =~ ^[0-9]+$ ]]; then
    echo "jb-hhmm-$input"
  elif [[ "$input" =~ ^hhmm-[0-9]+$ ]]; then
    echo "jb-$input"
  elif [[ "$input" =~ ^jb- ]]; then
    echo "$input"
  else
    echo "jb-$input"
  fi
}

# Get untracked files pattern from git config or defaults
_wt_get_untracked_pattern() {
  if git config --get-all worktree.untrackedfiles > /dev/null 2>&1; then
    git config --get-all worktree.untrackedfiles | tr '\n' '|' | sed 's/|$//'
  else
    echo '\.env|\.envrc|\.env\.local|\.tool-versions|mise\.toml|\.mise\.toml'
  fi
}

# Get the repo parent directory (e.g., ~/wealthsimple/front-end-monorepo)
_wt_repo_parent() {
  local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  [[ -z "$git_root" ]] && return 1
  dirname "$git_root"
}

# Get the main worktree path
_wt_main_path() {
  git rev-parse --show-toplevel 2>/dev/null
}

# =============================================================================
# MAIN FUNCTIONS
# =============================================================================

# wt - Create or switch to a worktree
# Usage: wt [identifier]
#   wt           - FZF selection from existing worktrees
#   wt 123       - Create/switch to jb-hhmm-123
#   wt hhmm-123  - Create/switch to jb-hhmm-123
#   wt feature-x - Create/switch to jb-feature-x
wt() {
  local identifier="$1"

  # Ensure we're in a git repo
  local main_path=$(_wt_main_path)
  if [[ -z "$main_path" ]]; then
    _wt_red "Not in a git repository"
    return 1
  fi

  local repo_parent=$(_wt_repo_parent)

  # No args: FZF selection from existing worktrees
  if [[ -z "$identifier" ]]; then
    local worktrees=$(git worktree list --porcelain | grep '^worktree ' | awk '{print $2}')
    local selected=$(echo "$worktrees" | fzf --prompt="Select worktree: ")
    [[ -z "$selected" ]] && return 0
    cd "$selected"
    _wt_open_ide "$selected"
    return 0
  fi

  local branch=$(_wt_to_branch "$identifier")
  local worktree_path="$repo_parent/$branch"

  # If worktree exists, just switch to it
  if [[ -d "$worktree_path" ]]; then
    _wt_green "Switching to existing worktree: $worktree_path"
    cd "$worktree_path"
    _wt_open_ide "$worktree_path"
    return 0
  fi

  # Create new worktree
  local current_branch=$(git branch --show-current)
  _wt_yellow "Creating $branch from $current_branch..."

  # Fetch latest from origin
  git fetch origin

  # Check if branch exists locally or remotely
  if git show-ref --verify --quiet "refs/heads/$branch"; then
    # Local branch exists
    git worktree add "$worktree_path" "$branch"
  elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    # Remote branch exists
    git worktree add -b "$branch" "$worktree_path" "origin/$branch"
  else
    # Create new branch from current HEAD
    git worktree add -b "$branch" "$worktree_path"
  fi

  # Handle node_modules: pnpm install is faster than copying, npm/yarn benefit from copy
  if [[ -f "$worktree_path/pnpm-lock.yaml" ]]; then
    _wt_yellow "Running pnpm install in background..."
    (cd "$worktree_path" && pnpm install) &
  elif [[ -d "$main_path/node_modules" ]]; then
    _wt_yellow "Copying node_modules in background..."
    /bin/cp -Rc "$main_path/node_modules" "$worktree_path/node_modules" &
  fi

  # Copy untracked files
  local pattern=$(_wt_get_untracked_pattern)
  if command -v fd &>/dev/null; then
    fd -u "^($pattern)$" -E node_modules "$main_path" | while read -r f; do
      local rel_path="${f#$main_path/}"
      mkdir -p "$worktree_path/$(dirname "$rel_path")"
      _wt_cp_cow "$f" "$worktree_path/$rel_path"
    done
  fi

  # direnv allow if .envrc exists
  if [[ -f "$worktree_path/.envrc" ]]; then
    direnv allow "$worktree_path"
  fi

  # mise trust if mise config exists
  if [[ -f "$worktree_path/.mise.toml" || -f "$worktree_path/mise.toml" || -f "$worktree_path/.tool-versions" ]]; then
    mise trust "$worktree_path"
  fi

  # Initialize submodules if they exist
  if [[ -f "$main_path/.gitmodules" ]]; then
    _wt_yellow "Initializing submodules..."
    git -C "$worktree_path" submodule update --init --recursive
  fi

  _wt_green "Created worktree: $worktree_path"
  cd "$worktree_path"
  _wt_open_ide "$worktree_path"
}

# wtd - Delete a worktree
# Usage: wtd [identifier]
#   wtd          - FZF selection from existing worktrees
#   wtd 123      - Delete jb-hhmm-123 worktree
wtd() {
  local identifier="$1"
  local repo_parent=$(_wt_repo_parent)
  local worktree_path
  local branch

  # No args: FZF selection from existing worktrees (excluding main)
  if [[ -z "$identifier" ]]; then
    local worktrees=$(git worktree list --porcelain | grep '^worktree ' | awk '{print $2}' | grep -v '/main$')
    local selected=$(echo "$worktrees" | fzf --prompt="Select worktree to delete: ")
    [[ -z "$selected" ]] && return 0
    worktree_path="$selected"
    branch=$(basename "$selected")
  else
    branch=$(_wt_to_branch "$identifier")
    worktree_path="$repo_parent/$branch"
  fi

  if [[ ! -d "$worktree_path" ]]; then
    _wt_red "Worktree not found: $worktree_path"
    return 1
  fi

  # Confirm deletion
  echo -n "Delete $worktree_path? [y/N] "
  read -q || { echo; return 0; }
  echo

  # If we're in the worktree, move to main first
  if [[ "$PWD" == "$worktree_path"* ]]; then
    cd "$repo_parent/main"
  fi

  _wt_yellow "Removing worktree: $worktree_path"
  # Move to tmp first (instant), then delete in background (slow but non-blocking)
  local tmp_path="/tmp/worktree-delete-$RANDOM"
  mv "$worktree_path" "$tmp_path"
  git worktree prune
  rm -rf "$tmp_path" &

  # Delete the local branch
  git branch -D "$branch" 2>/dev/null && _wt_green "Deleted branch: $branch"

  _wt_green "Worktree removed successfully"
}
