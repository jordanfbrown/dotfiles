#!/bin/bash
# Claude status indicator for tmux status bar
# Reads status files written by Claude Code hooks and outputs colored indicators

# Get all windows in current session
tmux list-windows -F '#{window_index}:#{window_name}:#{window_active}' | while IFS=':' read -r win_idx win_name is_active; do
  # Get the first pane of each window to check for Claude status
  pane_id=$(tmux list-panes -t "$win_idx" -F '#{pane_id}' 2>/dev/null | head -1)

  if [[ -n "$pane_id" ]]; then
    # Sanitize pane_id for filename (replace % and . with _)
    safe_pane="${pane_id//[%.]/_}"
    status_file="/tmp/claude-pane-$safe_pane"

    indicator=""
    if [[ -f "$status_file" ]]; then
      status=$(cat "$status_file" 2>/dev/null)
      case "$status" in
        working)    indicator=" #[fg=green]⋯#[default]" ;;
        permission) indicator=" #[fg=yellow]◐#[default]" ;;
        done)       indicator=" #[fg=magenta]●#[default]" ;;
      esac
    fi

    # Highlight active window
    if [[ "$is_active" == "1" ]]; then
      echo -n "#[fg=cyan,bold][$win_name$indicator#[fg=cyan,bold]]#[default] "
    else
      echo -n "[$win_name$indicator] "
    fi
  else
    echo -n "[$win_name] "
  fi
done
