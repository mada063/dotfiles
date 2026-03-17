#!/usr/bin/env bash

# Main Wofi dashboard – composes separate component scripts.

DASH_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$DASH_DIR/scripts"

system_script="$SCRIPTS_DIR/dashboard-cpu-gpu.sh"
date_script="$SCRIPTS_DIR/dashboard-calendar.sh"
media_script="$SCRIPTS_DIR/dashboard-media.sh"
weather_script="$SCRIPTS_DIR/dashboard-weather.sh"
power_menu_script="$SCRIPTS_DIR/dashboard-power-menu.sh"
cpu_detail_script="$SCRIPTS_DIR/dashboard-cpu-detail.sh"
mem_detail_script="$SCRIPTS_DIR/dashboard-mem-detail.sh"

system_block="$(bash "$system_script" 2>/dev/null)"
date_block="$(bash "$date_script" 2>/dev/null)"
media_block="$(bash "$media_script" 2>/dev/null)"
weather_block="$(bash "$weather_script" 2>/dev/null)"

dashboard_content=$(cat <<EOF
<span background="#BE510370" foreground="#FF8C32">DASHBOARD <span foreground="#FF8C32" font-weight="bold">01</span></span>

[SYSTEM OVERVIEW]
$system_block

[DATE]
$date_block
[MEDIA OVERVIEW]
$media_block

$weather_block

[POWERMENU]
EOF
)

choice="$(printf "%s\n" "$dashboard_content" | wofi \
  --normal-window \
  --dmenu \
  --hide-search \
  --hide-scroll \
  --allow-markup \
  --style "$DASH_DIR/style.css" \
  --prompt "" \
  --width 40% \
  --height 80% \
  --lines 30 \
  --cache-file=/dev/null)"

case "$choice" in
  CPU:*)
    bash "$cpu_detail_script"
    ;;
  RAM:*)
    bash "$mem_detail_script"
    ;;
  "CPU/GPU DETAILS"*)
    bash "$cpu_detail_script"
    ;;
  "RAM/DISC DETAILS"*)
    bash "$mem_detail_script"
    ;;
  "[Powermenu]")
    "$power_menu_script"
    ;;
  NEXT)
    if command -v playerctl >/dev/null 2>&1; then
      playerctl next
    fi
    ;;
  PREVIOUS)
    if command -v playerctl >/dev/null 2>&1; then
      playerctl previous
    fi
    ;;
  *PAUSE*PLAY*)
    if command -v playerctl >/dev/null 2>&1; then
      playerctl play-pause
    fi
    ;;
  *)
    # All other lines are non-interactive.
    ;;
esac

