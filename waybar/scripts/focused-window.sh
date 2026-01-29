#!/bin/bash

# Get the active window JSON
FOCUSED=$(hyprctl -j activewindow 2>/dev/null)

# If empty or invalid, show nothing
if [[ -z "$FOCUSED" ]] || [[ "$FOCUSED" == "null" ]] || [[ "$FOCUSED" == "{}" ]]; then
    echo '{"text":"","tooltip":"No focused window"}'
    exit 0
fi

# Extract title and class using jq
TITLE=$(echo "$FOCUSED" | jq -r '.title // ""')
CLASS=$(echo "$FOCUSED" | jq -r '.class // ""')

# Use title if available, else class
TEXT=${TITLE:-$CLASS}

# Truncate to 32 chars
if [[ ${#TEXT} -gt 35 ]]; then
    TEXT="${TEXT:0:32}..."
fi

# Escape JSON safely
JSON_TEXT=$(printf '%s' "$TEXT" | jq -Rs .)
JSON_CLASS=$(printf '%s' "$CLASS" | jq -Rs .)

# Output for Waybar
echo "{\"text\":$JSON_TEXT,\"tooltip\":$JSON_CLASS}"
