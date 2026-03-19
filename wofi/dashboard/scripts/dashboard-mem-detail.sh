#!/usr/bin/env bash

# RAM/DISC detail menu: more granular memory + filesystem view.

DASH_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$DASH_DIR/scripts"
bars_lib="$SCRIPTS_DIR/bars.sh"

COLOR_BASE="#8c3901"
COLOR_FILL="#be5103"

source "$bars_lib"

# RAM used % (0-100)
RAM_PCT=""
if command -v free >/dev/null 2>&1; then
  read -r _ total used _ < <(free -m 2>/dev/null | awk 'NR==2 {print $1, $2, $3, $4}')
  if [ -n "$total" ] && [ "$total" -gt 0 ] 2>/dev/null; then
    RAM_PCT=$(( used * 100 / total ))
  fi
fi

# Disk used % for root (0-100)
DISK_PCT=""
if command -v df >/dev/null 2>&1; then
  DISK_PCT="$(df -P / 2>/dev/null | awk 'NR==2 {gsub("%","",$5); print $5}')"
fi

RAM_BAR="$(bar_solid_single "${RAM_PCT:-}" 22 2 "$COLOR_FILL" "$COLOR_BASE")"
DISK_BAR="$(bar_solid_single "${DISK_PCT:-}" 22 2 "$COLOR_FILL" "$COLOR_BASE")"

mem_info="$(free -h 2>/dev/null || echo "free not available")"
mem_info="$(printf "%s\n" "$mem_info" | sed -E 's/\btotal\b/TOTAL/g; s/\bused\b/USED/g; s/\bfree\b/FREE/g; s/\bshared\b/SHARED/g; s/\bbuff\/cache\b/BUFF\/CACHE/g; s/\bavailable\b/AVAILABLE/g')"
mem_info="$(printf "%s\n" "$mem_info" | sed -E 's/^Mem:/MEM:/; s/^Swap:/SWAP:/')"

disk_info="$(df -h 2>/dev/null || echo "df not available")"
# Uppercase df header row only
disk_info="$(printf "%s\n" "$disk_info" | awk 'NR==1 {print toupper($0); next} {print}')"

# Per-mount mini bars (exclude tmpfs/devtmpfs)
mount_bars=""
MOUNT_LABEL_WIDTH=12
MINI_SEGMENTS=20
if command -v df >/dev/null 2>&1; then
  while IFS= read -r line; do
    fs="$(printf "%s" "$line" | awk '{print $1}')"
    case "$fs" in
      tmpfs|devtmpfs) continue ;;
    esac
    pct="$(printf "%s" "$line" | awk '{gsub("%","",$5); print $5}')"
    mnt="$(printf "%s" "$line" | awk '{print $6}')"
    # Fixed-width label so the mini bars don't shift
    label="$mnt"
    if [ "${#label}" -gt "$MOUNT_LABEL_WIDTH" ]; then
      label="${label:0:$((MOUNT_LABEL_WIDTH-3))}..."
    fi
    label="$(printf "%-${MOUNT_LABEL_WIDTH}s" "$label")"
    # Half-height style mini bar using lower-half blocks
    pct_clamped="$(bar_clamp_pct "$pct")"
    if [ -z "$pct_clamped" ]; then
      mini="N/A"
    else
      filled=$(( (pct_clamped * MINI_SEGMENTS + 99) / 100 ))
      [ "$filled" -gt "$MINI_SEGMENTS" ] && filled="$MINI_SEGMENTS"
      mini=""
      if [ "$filled" -gt 0 ]; then
        mini+="<span color='${COLOR_FILL}'>"
        for ((i=0; i<filled; i++)); do mini+="▄"; done
        mini+="</span>"
      fi
      empty=$(( MINI_SEGMENTS - filled ))
      if [ "$empty" -gt 0 ]; then
        mini+="<span color='${COLOR_BASE}'>"
        for ((i=0; i<empty; i++)); do mini+="▄"; done
        mini+="</span>"
      fi
    fi
    mount_bars+="${label} ${mini}\n"
  done < <(df -P 2>/dev/null | awk 'NR>1 {print}')
fi

content=$(cat <<EOF
<span background="#BE510370" foreground="#FF8C32">DASHBOARD <span foreground="#FF8C32" font-weight="bold">03</span></span>

[MEMORY]
RAM:  $RAM_BAR

$mem_info

[FILESYSTEMS]
DISC: $DISK_BAR

$([ -n "$mount_bars" ] && printf "%b" "$mount_bars")

$disk_info

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
  --width 70% \
  --height 80% \
  --lines 30 \
  --cache-file=/dev/null)"

if [ "$choice" = "BACK" ]; then
  "$DASH_DIR/wofi-dashboard.sh"
fi

exit 0

