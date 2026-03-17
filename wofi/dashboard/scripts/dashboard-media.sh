#!/usr/bin/env bash

# MEDIA OVERVIEW – show current song via playerctl when available.

TITLE="Nothing playing"
STATE=""

if command -v playerctl >/dev/null 2>&1; then
  STATE="$(playerctl status 2>/dev/null || true)"
  META="$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || true)"
  [ -n "$META" ] && TITLE="$META"
fi

printf "%s\n" "$TITLE"

if [ "$STATE" = "Playing" ]; then
  printf "<span background=\"#BE510370\" foreground=\"#FF8C32\"> PAUSE </span> PLAY\n"
elif [ "$STATE" = "Paused" ]; then
  printf "PAUSE <span background=\"#BE510370\" foreground=\"#FF8C32\"> PLAY </span>\n"
else
  # Nothing playing / unknown: highlight both actions.
  printf "<span background=\"#BE510370\" foreground=\"#FF8C32\"> PAUSE </span> <span background=\"#BE510370\" foreground=\"#FF8C32\"> PLAY </span>\n"
fi

printf "NEXT\n"
printf "PREVIOUS\n"

