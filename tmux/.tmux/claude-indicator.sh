#!/bin/bash
# Claude status indicator for a single tmux pane
# Usage: claude-indicator.sh <pane_id>
# Returns colored indicator or empty string

pane_id="$1"
[[ -z "$pane_id" ]] && exit 0

# Sanitize pane_id for filename (replace % and . with _)
safe_pane="${pane_id//[%.]/_}"
status_file="/tmp/claude-pane-$safe_pane"

[[ ! -f "$status_file" ]] && exit 0

status=$(cat "$status_file" 2>/dev/null)
# Status emoji indicators
case "$status" in
  permission)
    echo -n " 🔴 "
    ;;
  done)
    echo -n " ✅ "
    ;;
  working)
    echo -n " ⏳ "
    ;;
esac
