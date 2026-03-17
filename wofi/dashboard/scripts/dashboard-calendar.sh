#!/usr/bin/env bash

# DATE section: calendar

# Get current day (no leading zero).
today_day="$(date +%-d)"

# Calendar with current day highlighted using a background + font color (Pango markup).
calendar="$(cal | sed -E "s/(^|[^0-9])(${today_day})([^0-9]|\$)/\\1<span background=\"#BE510370\" foreground=\"#FF8C32\">\\2<\\/span>\\3/")"

# Highlight SA and SU in the weekday header.
calendar="$(printf "%s\n" "$calendar" | sed -E "s/SA/<span background=\"#BE510370\" foreground=\"#FF8C32\">SA<\\/span>/; s/SU/<span background=\"#BE510370\" foreground=\"#FF8C32\">SU<\\/span>/")"

printf "%s\n\n" "$calendar"

