#!/usr/bin/env bash

# Power menu component – launched from the main dashboard.

options=$(cat <<EOF
Shutdown
Reboot
Lock
Logout
EOF
)

choice="$(printf "%s\n" "$options" | wofi --dmenu --hide-search --prompt "Power" --cache-file=/dev/null)"

case "$choice" in
  "Shutdown")
    systemctl poweroff
    ;;
  "Reboot")
    systemctl reboot
    ;;
  "Lock")
    if command -v swaylock >/dev/null 2>&1; then
      swaylock
    elif command -v hyprlock >/dev/null 2>&1; then
      hyprlock
    else
      notify-send "Lock" "No lock command configured"
    fi
    ;;
  "Logout")
    loginctl terminate-user "$USER"
    ;;
  *)
    ;;
esac

