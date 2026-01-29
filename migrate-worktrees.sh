#!/bin/bash
# Migrate worktree structure from:
#   ~/wealthsimple/<repo>/main/        -> ~/wealthsimple/<repo>/
#   ~/wealthsimple/<repo>/<branch>/    -> ~/wealthsimple/<repo>/.worktrees/<branch>/
#
# Usage: ./migrate-worktrees.sh [--dry-run]

set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "=== DRY RUN MODE ==="
  echo
fi

WS_DIR="${WS_DIR:-$HOME/wealthsimple}"

run() {
  if $DRY_RUN; then
    echo "  [would run] $*"
  else
    "$@"
  fi
}

echo "Migrating worktrees in $WS_DIR"
echo

for repo_dir in "$WS_DIR"/*/; do
  repo_dir="${repo_dir%/}"  # Strip trailing slash
  repo_name=$(basename "$repo_dir")
  main_dir="$repo_dir/main"

  # Skip if no main/ directory (already migrated or not a worktree repo)
  if [[ ! -d "$main_dir" ]]; then
    continue
  fi

  # Skip if main/ doesn't have a real .git directory (not the main worktree)
  if [[ ! -d "$main_dir/.git" ]]; then
    echo "Skipping $repo_name: main/.git is not a directory"
    continue
  fi

  echo "=== Migrating $repo_name ==="

  # Step 1: Find and move feature worktrees to .worktrees/
  echo "  Moving feature worktrees..."
  for worktree_dir in "$repo_dir"/*/; do
    worktree_dir="${worktree_dir%/}"  # Strip trailing slash
    wt_name=$(basename "$worktree_dir")

    # Skip main and .worktrees
    [[ "$wt_name" == "main" ]] && continue
    [[ "$wt_name" == ".worktrees" ]] && continue

    # Check if it's a worktree (has .git file, not directory)
    if [[ -f "$worktree_dir/.git" ]]; then
      echo "  Found feature worktree: $wt_name"
      run mkdir -p "$repo_dir/.worktrees"
      run mv "$worktree_dir" "$repo_dir/.worktrees/$wt_name"
    fi
  done

  # Step 2: Move main/ contents up to repo root
  echo "  Moving main/ contents to repo root..."

  # Move everything from main/ to a temp location, then to repo root
  # We do this because we can't move main/* directly to parent if main exists
  temp_dir="$repo_dir/.migrate-temp-$$"
  run mv "$main_dir" "$temp_dir"

  # Move all contents from temp to repo root
  if ! $DRY_RUN; then
    # Use rsync to handle merging, then remove temp
    rsync -a "$temp_dir/" "$repo_dir/"
    rm -rf "$temp_dir"
  else
    echo "  [would run] mv $temp_dir/* $repo_dir/"
    echo "  [would run] mv $temp_dir/.* $repo_dir/"
    echo "  [would run] rmdir $temp_dir"
  fi

  # Step 3: Repair worktree references using git
  # git worktree repair fixes both directions automatically
  echo "  Repairing worktree references..."
  if [[ -d "$repo_dir/.worktrees" ]]; then
    # Pass all worktree paths to repair
    worktree_paths=("$repo_dir/.worktrees"/*/)
    if ! $DRY_RUN; then
      git -C "$repo_dir" worktree repair "${worktree_paths[@]}" 2>/dev/null || true
    else
      echo "  [would run] git -C $repo_dir worktree repair ${worktree_paths[*]}"
    fi
  fi

  echo "  Done migrating $repo_name"
  echo
done

echo "Migration complete!"
if $DRY_RUN; then
  echo
  echo "This was a dry run. Run without --dry-run to apply changes."
fi
