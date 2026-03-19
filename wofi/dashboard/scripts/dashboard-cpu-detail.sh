#!/usr/bin/env bash

# CPU/GPU detail menu: more granular view in a separate Wofi.

DASH_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$DASH_DIR/scripts"
base_script="$SCRIPTS_DIR/dashboard-cpu-gpu.sh"

bars_lib="$SCRIPTS_DIR/bars.sh"

# Colors (match dashboard)
COLOR_BASE="#8c3901"
COLOR_AVG="#be5103"
COLOR_MAX="#ff8c32"

source "$bars_lib"

# CPU summary (avg + max core) from /proc/stat (0.5s sample)
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
      printf "%.0f %.0f", avg, max
  }')"
  read -r CPU_AVG CPU_MAX <<<"$results"
fi

CPU_BAR="$(bar_solid_dual "${CPU_AVG:-}" "${CPU_MAX:-}" 22 2 "$COLOR_AVG" "$COLOR_MAX" "$COLOR_BASE")"

# Per-core mini bars
core_lines=()
if [ -n "$stat1" ] && [ -n "$stat2" ]; then
  while IFS= read -r line; do
    core_lines+=("$line")
  done < <(awk -v s1="$stat1" -v s2="$stat2" '
  BEGIN {
      split(s1, a1, "\n"); split(s2, a2, "\n");
      for (i in a1) {
          split(a1[i], t1); split(a2[i], t2);
          if (t1[1] ~ /^cpu[0-9]+$/) {
              idle1 = t1[5] + t1[6]; non_idle1 = t1[2]+t1[3]+t1[4]+t1[7]+t1[8];
              idle2 = t2[5] + t2[6]; non_idle2 = t2[2]+t2[3]+t2[4]+t2[7]+t2[8];
              total_delta = (idle2 + non_idle2) - (idle1 + non_idle1);
              if (total_delta > 0) {
                  usage = (total_delta - (idle2 - idle1)) * 100 / total_delta;
                  printf "%s %.0f\n", t1[1], usage;
              }
          }
      }
  }')
fi

make_mini_half_bar() {
  local pct="$1"
  local segments="${2:-20}"
  local pct_clamped
  pct_clamped="$(bar_clamp_pct "$pct")"
  if [ -z "$pct_clamped" ]; then
    printf "N/A"
    return 0
  fi

  local filled=$(( (pct_clamped * segments + 99) / 100 ))
  [ "$filled" -gt "$segments" ] && filled="$segments"
  local empty=$(( segments - filled ))

  local out=""
  if [ "$filled" -gt 0 ]; then
    out+="<span color='${COLOR_AVG}'>"
    for ((i=0; i<filled; i++)); do out+="▄"; done
    out+="</span>"
  fi
  if [ "$empty" -gt 0 ]; then
    out+="<span color='${COLOR_BASE}'>"
    for ((i=0; i<empty; i++)); do out+="▄"; done
    out+="</span>"
  fi
  printf "%s" "$out"
}

# GPU usage + VRAM (best-effort)
GPU_USE=""
VRAM_PCT=""
VRAM_USED=""
VRAM_TOTAL=""

if command -v nvidia-smi >/dev/null 2>&1; then
  read -r GPU_USE VRAM_PCT VRAM_USED VRAM_TOTAL <<<"$(nvidia-smi --query-gpu=utilization.gpu,utilization.memory,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | awk -F', ' 'NR==1 {print $1, $2, $3, $4}')"
  VRAM_USED="${VRAM_USED}MiB"
  VRAM_TOTAL="${VRAM_TOTAL}MiB"
elif command -v rocm-smi >/dev/null 2>&1; then
  GPU_USE="$(rocm-smi --showuse 2>/dev/null | grep -oP '\d+(?=%)' | head -1)"
  VRAM_PCT="$(rocm-smi --showmemuse 2>/dev/null | grep -oP '\d+(?=%)' | head -1)"
fi

GPU_BAR="$(bar_solid_dual "${GPU_USE:-}" "${VRAM_PCT:-}" 22 2 "$COLOR_AVG" "$COLOR_MAX" "$COLOR_BASE")"

cpu_info="$(lscpu 2>/dev/null || echo "lscpu not available")"

gpu_info="GPU info not available"
if command -v nvidia-smi >/dev/null 2>&1; then
  gpu_info="$(nvidia-smi --query-gpu=name,utilization.gpu,utilization.memory,memory.total,memory.used --format=csv,noheader 2>/dev/null)"
elif command -v rocm-smi >/dev/null 2>&1; then
  gpu_info="$(rocm-smi --showproductname --showuse --showmemuse 2>/dev/null)"
fi

content=$(cat <<EOF
<span background="#BE510370" foreground="#FF8C32">DASHBOARD <span foreground="#FF8C32" font-weight="bold">02</span></span>

[CPU]
CPU:  $CPU_BAR
$(for c in "${core_lines[@]}"; do
  core="${c%% *}"
  pct="${c#* }"
  mini="$(make_mini_half_bar "$pct" 20)"
  printf "%s %s\n" "$core:" "$mini"
done)

$cpu_info

[GPU]
GPU:  $GPU_BAR
VRAM: ${VRAM_USED:-N/A}/${VRAM_TOTAL:-N/A}

$gpu_info

BACK
EOF
)

choice="$(printf "%s\n" "$content" | wofi \
  --normal-window \
  --dmenu \
  --hide-search \
  --hide-scroll \
  --allow-markup \
  --style "$DASH_DIR/style.css" \
  --prompt "" \
  --width 60% \
  --height 80% \
  --lines 30 \
  --cache-file=/dev/null)"

if [ "$choice" = "BACK" ]; then
  "$DASH_DIR/wofi-dashboard.sh"
fi

exit 0

