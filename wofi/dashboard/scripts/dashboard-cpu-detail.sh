#!/usr/bin/env bash

# CPU/GPU detail menu: more granular view in a separate Wofi.

DASH_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$DASH_DIR/scripts"
base_script="$SCRIPTS_DIR/dashboard-cpu-gpu.sh"

# Reuse the existing summary line for consistency.
summary="$(bash "$base_script" 2>/dev/null | head -n 2)"

cpu_info="$(lscpu 2>/dev/null || echo "lscpu not available")"

gpu_info="GPU info not available"
if command -v nvidia-smi >/dev/null 2>&1; then
  gpu_info="$(nvidia-smi --query-gpu=name,utilization.gpu,utilization.memory,memory.total,memory.used --format=csv,noheader 2>/dev/null)"
elif command -v rocm-smi >/dev/null 2>&1; then
  gpu_info="$(rocm-smi --showproductname --showuse --showmemuse 2>/dev/null)"
fi

content=$(cat <<EOF
[CPU/GPU DETAILS]

$summary

CPU:
$cpu_info

GPU:
$gpu_info

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
  --width 60% \
  --height 80% \
  --lines 30 \
  --cache-file=/dev/null)"

if [ "$choice" = "[Back]" ]; then
  "$DASH_DIR/wofi-dashboard.sh"
fi

exit 0

