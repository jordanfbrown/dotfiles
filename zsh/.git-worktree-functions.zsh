# Git Worktree Functions
# Streamlined worktree management with copy-on-write support

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

_wt_green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
_wt_yellow() { printf '\033[0;33m%s\033[0m\n' "$1"; }
_wt_red() { printf '\033[0;31m%s\033[0m\n' "$1"; }

# Require tmux, return 1 if not in tmux
_wt_require_tmux() {
  if [[ -z "$TMUX" ]]; then
    _wt_red "Error: This command requires tmux. Run inside a tmux session."
    return 1
  fi
}

# Create worktree from branch (handles local, remote, or new)
# Args: $1=main_path, $2=worktree_path, $3=branch, $4=allow_new (true/false)
_wt_create_from_branch() {
  local main_path="$1"
  local worktree_path="$2"
  local branch="$3"
  local allow_new="${4:-true}"

  if git -C "$main_path" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$main_path" worktree add "$worktree_path" "$branch"
  elif git -C "$main_path" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    git -C "$main_path" worktree add -b "$branch" "$worktree_path" "origin/$branch"
  elif [[ "$allow_new" == "true" ]]; then
    git -C "$main_path" worktree add -b "$branch" "$worktree_path"
  else
    _wt_red "Error: Branch '$branch' not found locally or on origin"
    return 1
  fi
}

# Setup worktree environment (copy untracked files, IDE settings, etc.)
# Args: $1=main_path, $2=worktree_path, $3=dir_name
_wt_setup_environment() {
  local main_path="$1"
  local worktree_path="$2"
  local dir_name="$3"

  # Copy untracked files
  local pattern=$(_wt_get_untracked_pattern)
  if command -v fd &>/dev/null; then
    fd -u "^($pattern)$" -E node_modules "$main_path" | while read -r f; do
      local rel_path="${f#$main_path/}"
      mkdir -p "$worktree_path/$(dirname "$rel_path")"
      _wt_cp_cow "$f" "$worktree_path/$rel_path"
    done
  fi

  # Copy safe .idea settings
  if [[ -d "$main_path/.idea" ]]; then
    _wt_yellow "Copying IDE settings..."
    local main_dir_name=$(basename "$main_path")
    _wt_copy_idea_settings "$main_path/.idea" "$worktree_path/.idea" "$main_dir_name" "$dir_name"
  fi

  # Copy CLAUDE.local.md
  [[ -f "$main_path/CLAUDE.local.md" ]] && _wt_cp_cow "$main_path/CLAUDE.local.md" "$worktree_path/CLAUDE.local.md"

  # direnv allow
  [[ -f "$worktree_path/.envrc" ]] && direnv allow "$worktree_path"

  # Submodules
  if [[ -f "$main_path/.gitmodules" ]]; then
    _wt_yellow "Initializing submodules..."
    git -C "$worktree_path" submodule update --init --recursive
  fi
}

# Copy-on-write (assumes APFS)
_wt_cp_cow() {
  /bin/cp -Rc "$1" "$2"
}

# Copy safe .idea settings (excludes files with absolute paths that break search indexing)
_wt_copy_idea_settings() {
  local src_idea="$1"
  local dst_idea="$2"
  local src_dir_name="$3"  # e.g., "main"
  local dst_dir_name="$4"  # e.g., "jb-hhmm-857"

  [[ ! -d "$src_idea" ]] && return

  mkdir -p "$dst_idea"

  # Copy safe directories (no absolute paths)
  for dir in codeStyles inspectionProfiles scopes dictionaries fileTemplates runConfigurations jsLinters; do
    [[ -d "$src_idea/$dir" ]] && _wt_cp_cow "$src_idea/$dir" "$dst_idea/$dir"
  done

  # Copy and rename .iml file to match new worktree name
  # .iml files use $MODULE_DIR$ so exclusions are relative and safe
  # Find the .iml file dynamically (name matches project, not directory)
  local src_iml=$(find "$src_idea" -maxdepth 1 -name "*.iml" -type f | head -1)
  if [[ -n "$src_iml" ]]; then
    _wt_cp_cow "$src_iml" "$dst_idea/$dst_dir_name.iml"
  fi

  # Create modules.xml pointing to correctly-named .iml
  if [[ -f "$dst_idea/$dst_dir_name.iml" ]]; then
    cat > "$dst_idea/modules.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="ProjectModuleManager">
    <modules>
      <module fileurl="file://\$PROJECT_DIR\$/.idea/$dst_dir_name.iml" filepath="\$PROJECT_DIR\$/.idea/$dst_dir_name.iml" />
    </modules>
  </component>
</project>
EOF
  fi

  # Copy individual safe files
  for file in misc.xml vcs.xml prettier.xml .gitignore; do
    [[ -f "$src_idea/$file" ]] && _wt_cp_cow "$src_idea/$file" "$dst_idea/$file"
  done

  # Skip: workspace.xml (absolute paths to open files, window state, search indexes)
}

# Open correct IDE based on project type
_wt_open_ide() {
  local dir="$1"
  if [[ -f "$dir/Gemfile" ]]; then
    rubymine "$dir"
  elif [[ -f "$dir/package.json" ]]; then
    webstorm "$dir"
  elif [[ -f "$dir/build.gradle" || -f "$dir/build.gradle.kts" || -f "$dir/pom.xml" ]]; then
    idea "$dir"
  fi
  # Otherwise: no IDE opened
}

# Close IDE window for a worktree path
_wt_close_ide() {
  local dir="$1"
  local project_name=$(basename "$dir")

  # JetBrains IDEs show project name in window title (e.g., "jb-hhmm-828 – file.ts")
  # Use System Events to close windows via close button (button 1)
  local ides=("webstorm" "rubymine" "intellij idea")

  for ide_process in "${ides[@]}"; do
    osascript <<EOF 2>/dev/null
      tell application "System Events"
        if exists process "$ide_process" then
          tell process "$ide_process"
            repeat with w in (every window whose name contains "$project_name")
              try
                click button 1 of w
              end try
            end repeat
          end tell
        end if
      end tell
EOF
  done
}

# Close tmux window for a worktree
_wt_close_tmux_window() {
  local worktree_path="$1"
  local window_name=$(_wt_window_name "$worktree_path")

  # Check if we're in tmux and the window exists
  if [[ -n "$TMUX" ]]; then
    if tmux list-windows -F '#{window_name}' | grep -qx "$window_name"; then
      tmux kill-window -t "$window_name" 2>/dev/null
    fi
  fi
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

# Get the repo parent directory (e.g., ${WS_DIR:-~/wealthsimple}/front-end-monorepo)
_wt_repo_parent() {
  local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  [[ -z "$git_root" ]] && return 1
  dirname "$git_root"
}

# Get the main worktree path
_wt_main_path() {
  git rev-parse --show-toplevel 2>/dev/null
}

# Find the main worktree from any worktree path
_wt_find_main_from_worktree() {
  local worktree_path="$1"
  # Use git worktree list to find the main worktree (always first in list)
  git -C "$worktree_path" worktree list --porcelain 2>/dev/null | awk '/^worktree / {print $2; exit}'
}

# Find a worktree globally across all repos in ~/wealthsimple
_wt_find_global() {
  local branch="$1"
  for repo_dir in ${WS_DIR:-~/wealthsimple}/*/; do
    local candidate="$repo_dir$branch"
    if [[ -d "$candidate" && -e "$candidate/.git" ]]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

# List all worktrees across all repos in ~/wealthsimple
_wt_list_all_worktrees() {
  for repo_dir in ${WS_DIR:-~/wealthsimple}/*/main; do
    if [[ -d "$repo_dir/.git" ]]; then
      git -C "$repo_dir" worktree list --porcelain 2>/dev/null | grep '^worktree ' | awk '{print $2}'
    fi
  done
}

# Get tmux window name from worktree path: <repo>/<branch>
_wt_window_name() {
  local worktree_path="$1"
  local repo=$(basename "$(dirname "$worktree_path")")
  local branch=$(basename "$worktree_path")
  echo "$repo/$branch"
}

# Switch to or create a tmux window for the worktree
_wt_tmux_switch() {
  local window_name="$1"
  local worktree_path="$2"

  # Check if window exists in current session
  if tmux list-windows -F '#{window_name}' | grep -qx "$window_name"; then
    tmux select-window -t "$window_name"
  else
    # Create new window with name, starting in worktree_path
    tmux new-window -n "$window_name" -c "$worktree_path"
    tmux split-window -v -c "$worktree_path"  # Split top/bottom
    tmux select-pane -t 0                      # Select top pane
    tmux send-keys 'c' Enter                   # Run claude
    tmux select-pane -t 1                      # Focus bottom pane
  fi
}

# Parse GitHub PR URL to extract owner, repo, and PR number
_wt_parse_pr_url() {
  local url="$1"

  # Match pattern: https://github.com/owner/repo/pull/123[/files]
  if [[ "$url" =~ ^https://github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
    echo "${match[1]}" "${match[2]}" "${match[3]}"
    return 0
  else
    return 1
  fi
}

# Fetch branch name and PR title using gh CLI
_wt_fetch_pr_details() {
  local owner="$1"
  local repo="$2"
  local pr_number="$3"

  # Unset GITHUB_TOKEN to use keyring auth
  local output
  output=$(unset GITHUB_TOKEN && gh pr view "$pr_number" \
    --repo "$owner/$repo" \
    --json headRefName,title \
    --jq '[.headRefName, .title] | join("|")' 2>&1)

  if [[ $? -ne 0 ]]; then
    _wt_red "Error: Failed to fetch PR details"
    _wt_red "$output"
    return 1
  fi

  echo "$output"
  return 0
}

# Map GitHub repo name to local worktree path
_wt_map_repo_to_path() {
  local owner="$1"
  local repo="$2"

  # Try direct match first
  local direct_path="$HOME/$owner/$repo/main"
  if [[ -d "$direct_path/.git" ]]; then
    echo "$direct_path"
    return 0
  fi

  # Fallback: FZF picker from all repos
  _wt_yellow "Repo not found at $direct_path"
  local repos=$(find ~/wealthsimple -maxdepth 2 -name main -type d 2>/dev/null | grep '/main$')
  local selected=$(echo "$repos" | fzf --prompt="Select repo for $owner/$repo: ")

  if [[ -z "$selected" ]]; then
    return 1
  fi

  echo "$selected"
  return 0
}

# Create or switch to tmux window with code review command
_wt_tmux_review() {
  local window_name="$1"
  local worktree_path="$2"
  local pr_number="$3"
  local repo_name="$4"
  local pr_title="$5"

  # Check if window exists
  if tmux list-windows -F '#{window_name}' | grep -qx "$window_name"; then
    # Window exists - just switch to it (preserve existing session)
    tmux select-window -t "$window_name"
  else
    # Create new window with review command
    tmux new-window -n "$window_name" -c "$worktree_path"
    tmux split-window -v -c "$worktree_path"
    tmux select-pane -t 0
    # Send review request with PR context
    tmux send-keys "claude \"Review PR #$pr_number in $repo_name. The branch is checked out locally in a git worktree, so read files directly instead of using the gh API. Do NOT run tests or builds - the worktree is not set up for that.\"" Enter
    tmux select-pane -t 1
  fi
}

# =============================================================================
# MAIN FUNCTIONS
# =============================================================================

# wt - Create or switch to a worktree
# Usage: wt [identifier]
#   wt           - FZF selection from ALL worktrees globally
#   wt 123       - Switch to jb-hhmm-123 (global search) or create in current repo
#   wt hhmm-123  - Create/switch to jb-hhmm-123
#   wt feature-x - Create/switch to jb-feature-x
wt() {
  local identifier="$1"

  _wt_require_tmux || return 1

  # No args: FZF selection from ALL worktrees globally (excluding main)
  if [[ -z "$identifier" ]]; then
    local worktrees=$(_wt_list_all_worktrees | grep -v '/main$')
    local selected=$(echo "$worktrees" | fzf --prompt="Select worktree: ")
    [[ -z "$selected" ]] && return 0
    local window_name=$(_wt_window_name "$selected")
    _wt_tmux_switch "$window_name" "$selected"
    _wt_open_ide "$selected"
    return 0
  fi

  local branch=$(_wt_to_branch "$identifier")

  # Search globally for existing worktree
  local global_match=$(_wt_find_global "$branch")
  if [[ -n "$global_match" ]]; then
    _wt_green "Switching to existing worktree: $global_match"
    local window_name=$(_wt_window_name "$global_match")
    _wt_tmux_switch "$window_name" "$global_match"
    _wt_open_ide "$global_match"
    return 0
  fi

  # No global match - need to create
  local main_path=$(_wt_main_path)
  local repo_parent
  local worktree_path

  if [[ -z "$main_path" ]]; then
    # Not in a repo - let user pick which repo to create in
    local repos=$(find ~/wealthsimple -maxdepth 2 -name main -type d 2>/dev/null | grep '/main$')
    local selected=$(echo "$repos" | fzf --prompt="Create '$branch' in which repo? ")
    [[ -z "$selected" ]] && return 0
    main_path="$selected"
    repo_parent="$(dirname "$selected")"
    worktree_path="$repo_parent/$branch"
  else
    repo_parent=$(_wt_repo_parent)
    worktree_path="$repo_parent/$branch"
  fi

  # Create new worktree
  local current_branch=$(git -C "$main_path" branch --show-current)
  _wt_yellow "Creating $branch from $current_branch..."

  # Fetch latest from origin
  git -C "$main_path" fetch origin

  # Create worktree (allows new branches)
  _wt_create_from_branch "$main_path" "$worktree_path" "$branch" true

  # Handle dependencies based on project type
  if [[ -f "$worktree_path/Gemfile" ]]; then
    _wt_yellow "Running bundle install in background..."
    (cd "$worktree_path" && bundle install) &
  elif [[ -f "$worktree_path/pnpm-lock.yaml" ]]; then
    _wt_yellow "Running pnpm install in background..."
    (cd "$worktree_path" && pnpm install) &
  elif [[ -d "$main_path/node_modules" ]]; then
    _wt_yellow "Copying node_modules in background..."
    /bin/cp -Rc "$main_path/node_modules" "$worktree_path/node_modules" &
  fi

  # Setup environment (untracked files, IDE settings, CLAUDE.local.md, direnv, submodules)
  _wt_setup_environment "$main_path" "$worktree_path" "$branch"

  # mise trust if mise config exists (wt only, not wtr)
  if [[ -f "$worktree_path/.mise.toml" || -f "$worktree_path/mise.toml" || -f "$worktree_path/.tool-versions" ]]; then
    mise trust "$worktree_path"
  fi

  _wt_green "Created worktree: $worktree_path"
  local window_name=$(_wt_window_name "$worktree_path")
  _wt_tmux_switch "$window_name" "$worktree_path"
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

  # No args: FZF selection from ALL worktrees globally (excluding main)
  if [[ -z "$identifier" ]]; then
    local worktrees=$(_wt_list_all_worktrees | grep -v '/main$')
    local selected=$(echo "$worktrees" | fzf --prompt="Select worktree to delete: ")
    [[ -z "$selected" ]] && return 0
    worktree_path="$selected"
    branch=$(basename "$selected")
  else
    branch=$(_wt_to_branch "$identifier")
    # Search globally for the worktree
    local global_match=$(_wt_find_global "$branch")
    if [[ -n "$global_match" ]]; then
      worktree_path="$global_match"
    elif [[ -n "$repo_parent" ]]; then
      worktree_path="$repo_parent/$branch"
    else
      _wt_red "Worktree '$branch' not found"
      return 1
    fi
  fi

  if [[ ! -d "$worktree_path" ]]; then
    _wt_red "Worktree not found: $worktree_path"
    return 1
  fi

  # Get the repo's main directory for git commands
  local repo_main=$(_wt_find_main_from_worktree "$worktree_path")
  if [[ -z "$repo_main" ]]; then
    _wt_red "Error: Could not find main worktree"
    return 1
  fi

  # Confirm deletion
  echo -n "Delete $worktree_path? [y/N] "
  read -q || { echo; return 0; }
  echo

  # Close IDE and tmux windows
  _wt_yellow "Closing IDE and tmux windows..."
  _wt_close_ide "$worktree_path"
  _wt_close_tmux_window "$worktree_path"

  # If we're in the worktree, move to main first
  if [[ "$PWD" == "$worktree_path"* ]]; then
    cd "$repo_main"
  fi

  _wt_yellow "Removing worktree: $worktree_path"
  # Move to tmp first (instant), then delete in background (slow but non-blocking)
  local tmp_path="/tmp/worktree-delete-$RANDOM"
  mv "$worktree_path" "$tmp_path"
  git -C "$repo_main" worktree prune
  rm -rf "$tmp_path" &

  # Delete the local branch
  git -C "$repo_main" branch -D "$branch" 2>/dev/null && _wt_green "Deleted branch: $branch"

  _wt_green "Worktree removed successfully"
}

# wtr - Create or switch to worktree for PR code review
# Usage: wtr <github-pr-url>
#   wtr https://github.com/wealthsimple/fort-knox/pull/21493
#   wtr https://github.com/wealthsimple/fort-knox/pull/21493/files
wtr() {
  local pr_url="$1"

  _wt_require_tmux || return 1

  # Require URL argument
  if [[ -z "$pr_url" ]]; then
    _wt_red "Error: GitHub PR URL required"
    _wt_yellow "Usage: wtr https://github.com/owner/repo/pull/123"
    return 1
  fi

  # Parse PR URL
  local parsed=($(_wt_parse_pr_url "$pr_url"))
  if [[ $? -ne 0 || ${#parsed[@]} -ne 3 ]]; then
    _wt_red "Error: Invalid GitHub PR URL format"
    _wt_yellow "Expected: https://github.com/owner/repo/pull/123"
    return 1
  fi

  local owner="${parsed[1]}"
  local repo="${parsed[2]}"
  local pr_number="${parsed[3]}"
  local repo_name="$owner/$repo"

  _wt_yellow "Fetching PR details from $repo_name #$pr_number..."

  # Fetch branch and title from GitHub
  local pr_details=$(_wt_fetch_pr_details "$owner" "$repo" "$pr_number")
  if [[ $? -ne 0 ]]; then
    return 1
  fi

  local branch="${pr_details%%|*}"
  local pr_title="${pr_details#*|}"

  _wt_green "PR: $pr_title"
  _wt_green "Branch: $branch"

  # Sanitize branch name for directory (replace slashes with dashes)
  local worktree_dir="${branch//\//-}"

  # Check if worktree already exists globally
  local existing_worktree=$(_wt_find_global "$worktree_dir")
  if [[ -n "$existing_worktree" ]]; then
    _wt_green "Switching to existing worktree: $existing_worktree"
    local window_name=$(_wt_window_name "$existing_worktree")
    _wt_tmux_review "$window_name" "$existing_worktree" "$pr_number" "$repo_name" "$pr_title"
    _wt_open_ide "$existing_worktree"
    return 0
  fi

  # Worktree doesn't exist - map repo and create it
  _wt_yellow "Mapping repository path..."
  local main_path=$(_wt_map_repo_to_path "$owner" "$repo")
  if [[ -z "$main_path" ]]; then
    _wt_red "Error: Could not determine repository path"
    return 1
  fi

  local repo_parent=$(dirname "$main_path")
  local worktree_path="$repo_parent/$worktree_dir"

  _wt_yellow "Creating worktree for $branch..."

  # Fetch latest from origin
  git -C "$main_path" fetch origin

  # Create worktree (don't allow new branches for PR review)
  _wt_create_from_branch "$main_path" "$worktree_path" "$branch" false || return 1

  # Setup environment (untracked files, IDE settings, CLAUDE.local.md, direnv, submodules)
  # Note: Skip mise trust for review worktrees to avoid symlink conflicts
  _wt_setup_environment "$main_path" "$worktree_path" "$worktree_dir"

  _wt_green "Created review worktree: $worktree_path"
  local window_name=$(_wt_window_name "$worktree_path")
  _wt_tmux_review "$window_name" "$worktree_path" "$pr_number" "$repo_name" "$pr_title"
  _wt_open_ide "$worktree_path"
}
