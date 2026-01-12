#!/bin/bash

# Read JSON from stdin (use cat, not read -r, to capture all input)
json=$(cat)

# Debug: log raw JSON to file (uncomment to debug)
# echo "$json" >> /tmp/claude-statusline-debug.json

# Extract values from JSON
model=$(echo "$json" | jq -r '.model.display_name // "unknown"')
cwd=$(echo "$json" | jq -r '.workspace.current_dir // .cwd // "unknown"' | sed "s|^$HOME|~|")

# Calculate context usage percentage
context_size=$(echo "$json" | jq -r '.context_window.context_window_size // 0')
usage=$(echo "$json" | jq '.context_window.current_usage')

if [ "$usage" != "null" ] && [ "$context_size" -gt 0 ]; then
  # Sum all token types for actual context usage
  current_tokens=$(echo "$usage" | jq '(.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)')

  if [ "$current_tokens" -gt 0 ]; then
    usage_pct=$((current_tokens * 100 / context_size))

    # Set color based on usage percentage
    if [ "$usage_pct" -lt 25 ]; then
      color_code="\033[38;2;0;255;65m"  # bright green
    elif [ "$usage_pct" -lt 50 ]; then
      color_code="\033[38;2;255;165;0m"  # orange
    else
      color_code="\033[38;2;255;192;203m"  # pink
    fi

    context_display=" (${usage_pct}%)"
  else
    color_code="\033[38;2;0;255;65m"  # bright green for 0%
    context_display=" (0%)"
  fi
else
  color_code="\033[38;2;0;255;65m"  # bright green for 0%
  context_display=" (0%)"
fi

# Get git branch
if git rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git branch --show-current 2>/dev/null || echo "no branch")
else
  branch="no git"
fi

# Output status line
printf "👤 %b%s%s\033[0m | 📁 \033[97m%s\033[0m | 🌳 \033[38;2;0;206;200m%s\033[0m\n" "$color_code" "$model" "$context_display" "$cwd" "$branch"
