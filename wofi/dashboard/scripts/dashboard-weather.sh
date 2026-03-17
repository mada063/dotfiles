#!/usr/bin/env bash

# WEATHER section – show [WEATHER] plus compact wttr.in block (no colors).

printf "[WEATHER]\n"

if command -v curl >/dev/null 2>&1; then
  # ?0T => 0: no location line, T: plain-text (no ANSI colors).
  # Drop the first 2 lines of the compact block, keep the next 5.
  # Highlight heavy wind/rain by coloring only the numeric value.
  curl -s 'https://wttr.in?0T' 2>/dev/null | head -n 7 | tail -n 5 | awk '
    function wrap(v) { return "<span foreground=\"#FF8C32\">" v "</span>" }
    {
      line=$0

      # Wind line contains "km/h" (highlight only the number).
      if (match(line, /[0-9]+[ ]*km\/h/)) {
        s = RSTART
        l = RLENGTH
        chunk = substr(line, s, l)
        if (match(chunk, /^[0-9]+/)) {
          num = substr(chunk, 1, RLENGTH)
          if (num + 0 >= 20) {
            pre  = substr(line, 1, s - 1)
            post = substr(line, s + l)
            rest = substr(chunk, length(num) + 1)  # includes " km/h"
            print pre wrap(num) rest post
            next
          }
        }
      }

      # Rain line contains "mm" (highlight only the number).
      if (match(line, /[0-9]+(\.[0-9]+)?[ ]*mm/)) {
        s = RSTART
        l = RLENGTH
        chunk = substr(line, s, l)
        if (match(chunk, /^[0-9]+(\.[0-9]+)?/)) {
          num = substr(chunk, 1, RLENGTH)
          if (num + 0 >= 1.0) {
            pre  = substr(line, 1, s - 1)
            post = substr(line, s + l)
            rest = substr(chunk, length(num) + 1)  # includes " mm"
            print pre wrap(num) rest post
            next
          }
        }
      }

      print line
    }'
else
  printf "Weather data unavailable (curl not found)\n"
fi

