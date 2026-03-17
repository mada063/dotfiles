#!/usr/bin/env bash

# SYSTEM OVERVIEW

BAR_SEGMENTS=10
SEGMENT_CHARS=2

# Colors
COLOR_BASE="#8c3901"
COLOR_AVG="#be5103"
COLOR_MAX="#ff8c32"

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

make_solid_bar_single() {
  local pct
  pct="$(clamp_pct "$1")"
  [ -z "$pct" ] && { printf "N/A"; return 0; }

  local total_chars=$(( BAR_SEGMENTS * SEGMENT_CHARS ))
  local filled=$(( (pct * total_chars + 99) / 100 ))
  [ "$filled" -gt "$total_chars" ] && filled="$total_chars"

  emit_run "$COLOR_AVG" "$filled"
  emit_run "$COLOR_BASE" $(( total_chars - filled ))
}

make_solid_bar_dual() {
  local avg max
  avg="$(clamp_pct "$1")"
  max="$(clamp_pct "$2")"
  [ -z "$avg" ] || [ -z "$max" ] && { printf "N/A"; return 0; }

  local total_chars=$(( BAR_SEGMENTS * SEGMENT_CHARS ))
  local avg_chars=$(( (avg * total_chars + 99) / 100 ))
  local max_chars=$(( (max * total_chars + 99) / 100 ))
  [ "$avg_chars" -gt "$total_chars" ] && avg_chars="$total_chars"
  [ "$max_chars" -gt "$total_chars" ] && max_chars="$total_chars"

  # Ensure ordering: avg <= max for the color split
  if [ "$avg_chars" -gt "$max_chars" ]; then
    avg_chars="$max_chars"
  fi

  emit_run "$COLOR_AVG" "$avg_chars"
  emit_run "$COLOR_MAX" $(( max_chars - avg_chars ))
  emit_run "$COLOR_BASE" $(( total_chars - max_chars ))
}

make_dual_bar() {
  local avg="$1"
  local max="$2"

  if [ -z "$avg" ] || [ -z "$max" ]; then
    printf "N/A"
    return 0
  fi

  make_solid_bar_dual "$avg" "$max"
}

make_single_bar() {
  local pct="$1"
  if [ -z "$pct" ]; then
    printf "N/A"
    return 0
  fi

  make_solid_bar_single "$pct"
}

# CPU avg/max core usage via /proc/stat (0.5s sample).
get_cpu_lines() { grep '^cpu' /proc/stat 2>/dev/null || true; }
stat1="$(get_cpu_lines)"
sleep 0.5
stat2="$(get_cpu_lines)"

CPU_AVG=""
CPU_MAX=""
if [ -n "$stat1" ] && [ -n "$stat2" ]; then
  results="$(awk -v s1="$stat1" -v s2="$stat2" '
  BEGIN {
      split(s1, a1, "\n"); split(s2, a2, "\n");
      max = 0;
      for (i in a1) {
          split(a1[i], t1); split(a2[i], t2);
          idle1 = t1[5] + t1[6]; non_idle1 = t1[2]+t1[3]+t1[4]+t1[7]+t1[8];
          idle2 = t2[5] + t2[6]; non_idle2 = t2[2]+t2[3]+t2[4]+t2[7]+t2[8];
          total_delta = (idle2 + non_idle2) - (idle1 + non_idle1);
          if (total_delta > 0) {
              usage = (total_delta - (idle2 - idle1)) * 100 / total_delta;
              if (t1[1] == "cpu") avg = usage;
              else if (usage > max) max = usage;
          }
      }
      if (avg == "") avg = 0;
      if (max == "") max = 0;
      printf "%.0f %.0f", avg, max
  }')"
  read -r CPU_AVG CPU_MAX <<<"$results"
fi

# GPU avg/max (utilization.gpu, utilization.memory) with fallbacks.
GPU_AVG=""
GPU_MAX=""
if command -v nvidia-smi >/dev/null 2>&1; then
  read -r GPU_AVG GPU_MAX <<<"$(nvidia-smi --query-gpu=utilization.gpu,utilization.memory --format=csv,noheader,nounits 2>/dev/null | awk -F', ' 'NR==1 {print $1, $2}')"
elif command -v rocm-smi >/dev/null 2>&1; then
  GPU_AVG="$(rocm-smi --showuse 2>/dev/null | grep -oP '\d+(?=%)' | head -1)"
  GPU_MAX="$(rocm-smi --showmemuse 2>/dev/null | grep -oP '\d+(?=%)' | head -1)"
else
  GPU_AVG="$(cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || true)"
  GPU_MAX="$(cat /sys/class/drm/card0/device/mem_busy_percent 2>/dev/null || true)"
fi

# RAM used % (best-effort via free).
RAM_PCT=""
if command -v free >/dev/null 2>&1; then
  read -r _ total used _ < <(free -m 2>/dev/null | awk 'NR==2 {print $1, $2, $3, $4}')
  if [ -n "$total" ] && [ "$total" -gt 0 ] 2>/dev/null; then
    RAM_PCT=$(( used * 100 / total ))
  fi
fi

# Disk used % for root.
DISK_PCT=""
if command -v df >/dev/null 2>&1; then
  DISK_PCT="$(df -P / 2>/dev/null | awk 'NR==2 {gsub("%","",$5); print $5}')"
fi

CPU_BAR="$(make_dual_bar "${CPU_AVG:-}" "${CPU_MAX:-}")"
GPU_BAR="$(make_dual_bar "${GPU_AVG:-}" "${GPU_MAX:-}")"
RAM_BAR="$(make_single_bar "${RAM_PCT:-}")"
DISK_BAR="$(make_single_bar "${DISK_PCT:-}")"

# Connection info: SSID and IP.
SSID="DISCONNECTED"
if command -v nmcli >/dev/null 2>&1; then
  SSID_VAL=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}')
  [ -n "$SSID_VAL" ] && SSID="$SSID_VAL"
fi

IP_ADDR="unknown"
if command -v ip >/dev/null 2>&1; then
  IP_VAL=$(ip route get 1.1.1.1 2>/dev/null | awk '/src/ {print $7; exit}')
  [ -n "$IP_VAL" ] && IP_ADDR="$IP_VAL"
fi

# Truncate SSID to a fixed width and add "..." if too long, then pad so IP lines up.
MAX_SSID_WIDTH=16
SSID_TRUNC="$SSID"
if [ "${#SSID_TRUNC}" -gt "$MAX_SSID_WIDTH" ]; then
  SSID_TRUNC="${SSID_TRUNC:0:$((MAX_SSID_WIDTH-3))}..."
fi

SSID_PADDED=$(printf "%-${MAX_SSID_WIDTH}s" "$SSID_TRUNC")

printf "CPU:  %s    GPU:  %s\n" "$CPU_BAR" "$GPU_BAR"
printf "RAM:  %s    DISC: %s\n" "$RAM_BAR" "$DISK_BAR"
printf "CONNECTION: <span foreground=\"#FF8C32\">%s</span>  IP: <span foreground=\"#FF8C32\">%s</span>\n" "$SSID_PADDED" "$IP_ADDR"

