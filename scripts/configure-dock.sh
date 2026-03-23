#!/usr/bin/env bash

set -euo pipefail

if ! command -v dockutil >/dev/null 2>&1; then
  echo "dockutil not found — skipping dock configuration"
  exit 0
fi

# Start clean
dockutil --remove all --no-restart

# Apps — only add if installed
add_if_present() { [[ -d "$1" ]] && dockutil --add "$1" --no-restart; }
add_if_present "/Applications/Spark.app"
add_if_present "/Applications/Arc.app"
add_if_present "/Applications/Slack.app"
add_if_present "/Applications/Ghostty.app"
add_if_present "/Applications/Cursor.app"
add_if_present "/Applications/Sublime Text.app"
add_if_present "/Applications/DataGrip.app"
add_if_present "/Applications/Spotify.app"

# Apply all changes in one restart
killall Dock
