#!/bin/bash
# Notify user only if they're not focused on this terminal pane

# Get the frontmost application
FRONT_APP=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')

# Use project dir or fall back to current directory
PROJECT_NAME=$(basename "${CLAUDE_PROJECT_DIR:-$PWD}")

# If iTerm2 is not frontmost, notify (user is in another app)
if [ "$FRONT_APP" != "iTerm2" ]; then
  say "Your agent in $PROJECT_NAME needs you"
  exit 0
fi

# iTerm2 is frontmost - check if we're in tmux and if this pane is active
if [ -n "$TMUX" ]; then
  PANE_ACTIVE=$(tmux display-message -p '#{pane_active}')
  if [ "$PANE_ACTIVE" != "1" ]; then
    # User is in a different tmux pane
    say "Your agent in $PROJECT_NAME needs you"
  fi
  # else: pane is active, user is watching - stay silent
fi
