#!/bin/bash

# Read JSON from stdin (use cat, not read -r, to capture all input)
json=$(cat)

# Debug: log raw JSON to file (uncomment to debug)
# echo "$json" >> /tmp/claude-statusline-debug.json

# Extract values from JSON
model=$(echo "$json" | jq -r '.model.display_name // "unknown"')
cwd=$(echo "$json" | jq -r '.workspace.current_dir // .cwd // "unknown"' | sed "s|^$HOME|~|")

# Get context usage percentage (available in Claude 2.1.6+)
usage_pct=$(echo "$json" | jq -r '.context_window.used_percentage // 0' | cut -d'.' -f1)

# Set color based on usage percentage
if [ "$usage_pct" -lt 25 ]; then
  color_code="\033[38;2;0;255;65m"  # bright green
elif [ "$usage_pct" -lt 50 ]; then
  color_code="\033[38;2;255;165;0m"  # orange
else
  color_code="\033[38;2;255;192;203m"  # pink
fi

context_display=" (${usage_pct}%)"

# Get git branch
if git rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git branch --show-current 2>/dev/null || echo "no branch")
else
  branch="no git"
fi

# Output status line
printf "👤 %b%s%s\033[0m | 📁 \033[97m%s\033[0m | 🌳 \033[38;2;0;206;200m%s\033[0m\n" "$color_code" "$model" "$context_display" "$cwd" "$branch"
