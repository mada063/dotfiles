#!/usr/bin/env bash

# RAM/DISC detail menu: more granular memory + filesystem view.

DASH_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$DASH_DIR/scripts"
summary_script="$SCRIPTS_DIR/dashboard-cpu-gpu.sh"
summary="$(bash "$summary_script" 2>/dev/null | sed -n '2p')"

mem_info="$(free -h 2>/dev/null || echo "free not available")"
disk_info="$(df -h 2>/dev/null || echo "df not available")"

content=$(cat <<EOF
[RAM/DISC DETAILS]

$summary

MEMORY:
$mem_info

FILESYSTEMS:
$disk_info

[Back]
EOF
)

choice="$(printf "%s\n" "$content" | wofi \
  --normal-window \
  --dmenu \
  --hide-search \
  --hide-scroll \
  --allow-markup \
  --prompt "" \
  --width 70% \
  --height 80% \
  --lines 30 \
  --cache-file=/dev/null)"

if [ "$choice" = "[Back]" ]; then
  "$DASH_DIR/wofi-dashboard.sh"
fi

exit 0

