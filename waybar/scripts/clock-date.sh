#!/usr/bin/env bash

STATE_FILE="$HOME/.config/waybar/scripts/clock.state"

# default state
[ -f "$STATE_FILE" ] || echo "time" > "$STATE_FILE"

STATE=$(cat "$STATE_FILE")

if [ "$STATE" = "date" ]; then
  date +"D%d M%m Y%y"
else
  date +"%H:%M:%S"
fi
