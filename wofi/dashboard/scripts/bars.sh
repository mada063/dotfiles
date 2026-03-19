#!/usr/bin/env bash

# Shared helpers for solid percentage bars (0-100).

bar_clamp_pct() {
  local v="$1"
  if [ -z "$v" ]; then
    printf ""
    return 0
  fi
  if ! [ "$v" -ge 0 ] 2>/dev/null; then
    printf ""
    return 0
  fi
  if [ "$v" -lt 0 ]; then v=0; fi
  if [ "$v" -gt 100 ]; then v=100; fi
  printf "%s" "$v"
}

bar_repeat_spaces() { printf "%*s" "$1" ""; }

bar_emit_run() {
  local color="$1"
  local count="$2"
  [ "$count" -le 0 ] 2>/dev/null && return 0
  printf "<span background='%s'>%s</span>" "$color" "$(bar_repeat_spaces "$count")"
}

# Solid single-value bar.
# Args: pct segments chars_per_segment fill_color base_color
bar_solid_single() {
  local pct segments segchars fill base
  pct="$(bar_clamp_pct "$1")"
  segments="$2"
  segchars="$3"
  fill="$4"
  base="$5"

  [ -z "$pct" ] && { printf "N/A"; return 0; }
  [ -z "$segments" ] && segments=10
  [ -z "$segchars" ] && segchars=2

  local total_chars=$(( segments * segchars ))
  local filled=$(( (pct * total_chars + 99) / 100 ))
  [ "$filled" -gt "$total_chars" ] && filled="$total_chars"

  bar_emit_run "$fill" "$filled"
  bar_emit_run "$base" $(( total_chars - filled ))
}

# Solid dual-value bar where avg<=max:
# - avg: avg_color
# - max-avg: max_color
# - rest: base_color
# Args: avg max segments chars_per_segment avg_color max_color base_color
bar_solid_dual() {
  local avg max segments segchars c_avg c_max c_base
  avg="$(bar_clamp_pct "$1")"
  max="$(bar_clamp_pct "$2")"
  segments="$3"
  segchars="$4"
  c_avg="$5"
  c_max="$6"
  c_base="$7"

  [ -z "$avg" ] || [ -z "$max" ] && { printf "N/A"; return 0; }
  [ -z "$segments" ] && segments=10
  [ -z "$segchars" ] && segchars=2

  local total_chars=$(( segments * segchars ))
  local avg_chars=$(( (avg * total_chars + 99) / 100 ))
  local max_chars=$(( (max * total_chars + 99) / 100 ))
  [ "$avg_chars" -gt "$total_chars" ] && avg_chars="$total_chars"
  [ "$max_chars" -gt "$total_chars" ] && max_chars="$total_chars"
  if [ "$avg_chars" -gt "$max_chars" ]; then
    avg_chars="$max_chars"
  fi

  bar_emit_run "$c_avg" "$avg_chars"
  bar_emit_run "$c_max" $(( max_chars - avg_chars ))
  bar_emit_run "$c_base" $(( total_chars - max_chars ))
}

