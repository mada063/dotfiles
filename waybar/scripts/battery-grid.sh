#!/bin/bash

# Test-logikk
if [ -z "$1" ]; then
    [ -d /sys/class/power_supply/BAT0 ] && PATH_BAT="/sys/class/power_supply/BAT0"
    [ -d /sys/class/power_supply/BAT1 ] && PATH_BAT="/sys/class/power_supply/BAT1"
    percent=$(cat "$PATH_BAT/capacity")
    status=$(cat "$PATH_BAT/status")
else
    percent=$1
    status="Discharging"
fi

active_color="#BE5103"
inactive_color="#be510380"
[ "$status" = "Charging" ] && active_color="#ff8c32"

# Funksjon for aktive prikker (fra bunn til topp)
get_active_braille() {
    local p=$1
    if [ "$p" -ge 18 ]; then echo "⣿";
    elif [ "$p" -ge 15 ]; then echo "⣷";
    elif [ "$p" -ge 13 ]; then echo "⣶";
    elif [ "$p" -ge 10 ]; then echo "⣤";
    elif [ "$p" -ge 8 ];  then echo "⣄";
    elif [ "$p" -ge 5 ];  then echo "⣀";
    elif [ "$p" -ge 2 ];  then echo "⡀";
    else echo "⠀"; fi # Tomt tegn (blank Braille)
}

grid=""
for i in {0..4}; do
    start_range=$(( i * 20 ))
    end_range=$(( (i + 1) * 20 ))
    
    if [ "$percent" -ge "$end_range" ]; then
        # Hele blokka lyser
        grid+="<span color='$active_color'>⣿</span>"
    elif [ "$percent" -le "$start_range" ]; then
        # Hele blokka er mørk (bakteppet)
        grid+="<span color='$inactive_color'>⣿</span>"
    else
        # DELVIS FYLLING MED OVERLAY:
        fill_level=$(( percent - start_range ))
        active_part=$(get_active_braille $fill_level)
        
        # 1. Tegn den mørke "rammen" (alle 8 prikker)
        # 2. Rykk tilbake med negativ spacing (må matche fontbredden din)
        # 3. Tegn de aktive prikkene oppå
        grid+="<span color='$inactive_color' letter_spacing='-15600'>⣿</span><span color='$active_color'>$active_part</span>"
    fi
    grid+=" "
done

display_text="<span letter_spacing='0' size='9pt' font_weight='400'>BAT </span><span >$grid</span>"
echo "{\"text\": \"$display_text\", \"tooltip\": \"Batteri: $percent% ($status)\", \"percentage\": $percent}"