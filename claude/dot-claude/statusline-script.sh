#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
model_name=$(echo "$input" | jq -r '.model.display_name')

# Display directory name in blue
printf '\033[34m%s\033[0m' "$(basename "$current_dir")"

# Check if we're in a git repository
if git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
    # Get current branch, tag, or commit hash
    branch=$(git -C "$current_dir" branch --show-current 2>/dev/null || \
             git -C "$current_dir" describe --tags --exact-match 2>/dev/null || \
             git -C "$current_dir" rev-parse --short HEAD)
    
    # Check git status for changes
    status=$(git -C "$current_dir" status --porcelain 2>/dev/null)
    
    if [ -n "$status" ]; then
        # Has changes - show branch with [±] indicator
        printf ' \033[33mon %s \033[31m[±]\033[0m' "$branch"
    else
        # Clean - show just branch
        printf ' \033[33mon %s\033[0m' "$branch"
    fi
fi

# Display model name in dim color
printf ' \033[90m(%s)\033[0m' "$model_name"