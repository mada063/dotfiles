#!/bin/bash

# 1. Hent data basert på produsent
if command -v nvidia-smi &> /dev/null; then
    # NVIDIA: Henter bruk og minne-prosent
    read avg max <<< $(nvidia-smi --query-gpu=utilization.gpu,utilization.memory --format=csv,noheader,nounits | awk -F', ' '{print $1, $2}')
elif command -v rocm-smi &> /dev/null; then
    # AMD (rocm): Henter bruk og minne
    avg=$(rocm-smi --showuse | grep -oP '\d+(?=%)' | head -1)
    max=$(rocm-smi --showmemuse | grep -oP '\d+(?=%)' | head -1)
else
    # Failsafe for AMD via sysfs hvis rocm-smi mangler
    avg=$(cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || echo 0)
    max=$(cat /sys/class/drm/card0/device/mem_busy_percent 2>/dev/null || echo 0)
fi

avg=${avg:-0}; max=${max:-0}

# 2. Farger
color_avg="#ff8c32"    # Lys oransje (GPU Load - Bunn)
color_max="#be5103"    # Mørk oransje (VRAM Load - Topp)
color_transparent="#00000001"

grid=""

# 3. Bygg baren med 10% intervaller
for i in {1..10}; do
    threshold=$(( i * 10 ))
    
    has_avg=false
    has_max=false

    if [ "$avg" -ge "$threshold" ]; then has_avg=true; fi
    if [ "$max" -ge "$threshold" ]; then has_max=true; fi

    if $has_avg && $has_max; then
        grid+="<span color='$color_avg'>█</span>"
    elif $has_avg; then
        grid+="<span color='$color_avg'>▄</span>" # Bruker bunn-blokk for GPU load
    elif $has_max; then
        grid+="<span color='$color_max'>▀</span>" # Bruker topp-blokk for VRAM
    else
        grid+="<span color='$color_transparent'>█</span>"
    fi
done

echo "{\"text\": \"<span size='9pt'>GPU </span>$grid\", \"tooltip\": \"GPU Load: $avg% | VRAM Load: $max%\"}"