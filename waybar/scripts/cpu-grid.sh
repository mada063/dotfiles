#!/bin/bash

# 1. Hent data (Sanntid 0.5s måling)
get_stats() { cat /proc/stat | grep '^cpu'; }
stat1=$(get_stats)
sleep 0.5
stat2=$(get_stats)

results=$(awk -v s1="$stat1" -v s2="$stat2" '
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
}')

read avg max <<< "$results"
avg=${avg:-0}; max=${max:-0}

# 2. Farger
color_avg="#ff8c32"    # Lys oransje (Bunn)
color_max="#be5103"    # Mørk oransje (Topp)
color_transparent="#00000001" # Rettet til 8 tegn (helt gjennomsiktig)

grid=""

# 3. Bygg baren med 10% intervaller
for i in {1..10}; do
    threshold=$(( i * 10 ))
    
    has_avg=false
    has_max=false

    if [ "$avg" -ge "$threshold" ]; then has_avg=true; fi
    if [ "$max" -ge "$threshold" ]; then has_max=true; fi

    if $has_avg && $has_max; then
        # Begge over threshold -> Full blokk
        grid+="<span color='$color_avg'>█</span>"
    elif $has_avg; then
        # Kun gjennomsnitt -> Bunn
        grid+="<span color='$color_avg'>█</span>"
    elif $has_max; then
        # Kun maks-kjerne -> Topp
        grid+="<span color='$color_max'>▀</span>"
    else
        # Under threshold -> Gjennomsiktig
        grid+="<span color='$color_transparent'>█</span>"
    fi
done

echo "{\"text\": \"<span size='9pt'>CPU </span>$grid\", \"tooltip\": \"Gjennomsnitt: $avg% | Max kjerne: $max%\"}"