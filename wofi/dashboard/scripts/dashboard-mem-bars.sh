#!/usr/bin/env bash

# RAM/DISC bars only (solid 0–100%).

BAR_SEGMENTS=10
SEGMENT_CHARS=2

COLOR_BASE="#8c3901"
COLOR_FILL="#be5103"

clamp_pct() {
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

repeat_spaces() { printf "%*s" "$1" ""; }

emit_run() {
  local color="$1"
  local count="$2"
  [ "$count" -le 0 ] 2>/dev/null && return 0
  printf "<span background='%s'>%s</span>" "$color" "$(repeat_spaces "$count")"
}

make_bar() {
  local pct
  pct="$(clamp_pct "$1")"
  [ -z "$pct" ] && { printf "N/A"; return 0; }

  local total_chars=$(( BAR_SEGMENTS * SEGMENT_CHARS ))
  local filled=$(( (pct * total_chars + 99) / 100 ))
  [ "$filled" -gt "$total_chars" ] && filled="$total_chars"

  emit_run "$COLOR_FILL" "$filled"
  emit_run "$COLOR_BASE" $(( total_chars - filled ))
}

# RAM used %
RAM_PCT=""
if command -v free >/dev/null 2>&1; then
  read -r _ total used _ < <(free -m 2>/dev/null | awk 'NR==2 {print $1, $2, $3, $4}')
  if [ -n "$total" ] && [ "$total" -gt 0 ] 2>/dev/null; then
    RAM_PCT=$(( used * 100 / total ))
  fi
fi

# Disk used % for root
DISK_PCT=""
if command -v df >/dev/null 2>&1; then
  DISK_PCT="$(df -P / 2>/dev/null | awk 'NR==2 {gsub("%","",$5); print $5}')"
fi

RAM_BAR="$(make_bar "${RAM_PCT:-}")"
DISK_BAR="$(make_bar "${DISK_PCT:-}")"

printf "RAM:  %s    DISC: %s\n" "$RAM_BAR" "$DISK_BAR"

