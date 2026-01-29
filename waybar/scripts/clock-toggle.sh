#!/usr/bin/env bash

STATE_FILE="$HOME/.config/waybar/scripts/clock.state"

if [ "$(cat "$STATE_FILE")" = "time" ]; then
  echo "date" > "$STATE_FILE"
else
  echo "time" > "$STATE_FILE"
fi

pkill -SIGRTMIN+1 waybar
