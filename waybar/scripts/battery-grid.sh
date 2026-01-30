#!/bin/bash

# --- BATTERI STATUS OG VARSLING ---
if [ -z "$1" ]; then
    [ -d /sys/class/power_supply/BAT0 ] && PATH_BAT="/sys/class/power_supply/BAT0"
    [ -d /sys/class/power_supply/BAT1 ] && PATH_BAT="/sys/class/power_supply/BAT1"
    percent=$(cat "$PATH_BAT/capacity")
    status=$(cat "$PATH_BAT/status")
else
    percent=$1
    status="Discharging"
fi

# Logikk for automatiske varsler
state_file="/tmp/battery_notif_state"

send_alert() {
    local level_name=$1
    local urgency=$2
    local message=$3
    if [ ! -f "$state_file" ] || [ "$(cat $state_file)" != "$level_name" ]; then
        notify-send -u "$urgency" "Battery $level_name" "$message"
        echo "$level_name" > "$state_file"
    fi
}

if [ "$status" = "Full" ] || [ "$percent" -eq 100 ]; then
    send_alert "Full" "normal" "Batteriet er nå fullladet."
elif [ "$status" = "Discharging" ]; then
    if [ "$percent" -le 10 ]; then
        send_alert "Critical" "critical" "Kritisk lavt batteri: $percent%"
    elif [ "$percent" -le 33 ]; then
        send_alert "Low" "normal" "Batteriet begynner å bli lavt: $percent%"
    fi
elif [ "$status" = "Charging" ]; then
    # Nullstill varsling når vi lader, så de kommer på nytt ved neste utlading
    [ -f "$state_file" ] && rm "$state_file"
fi


# --- GRID VISUALISERING ---
active_color="#BE5103"
inactive_color="#be510380"
[ "$status" = "Charging" ] && active_color="#ff8c32"

get_active_braille() {
    local p=$1
    if [ "$p" -ge 18 ]; then echo "⣿";
    elif [ "$p" -ge 15 ]; then echo "⣷";
    elif [ "$p" -ge 13 ]; then echo "⣶";
    elif [ "$p" -ge 10 ]; then echo "⣤";
    elif [ "$p" -ge 8 ];  then echo "⣄";
    elif [ "$p" -ge 5 ];  then echo "⣀";
    elif [ "$p" -ge 2 ];  then echo "⡀";
    else echo "⠀"; fi
}

grid=""
for i in {0..4}; do
    start_range=$(( i * 20 ))
    end_range=$(( (i + 1) * 20 ))
    
    current_active=$active_color
    if [ $i -eq 4 ] && [ "$status" != "Charging" ]; then
        current_active="#ff8c32"
    fi

    if [ "$percent" -ge "$end_range" ]; then
        grid+="<span color='$current_active'>⣿</span>"
    elif [ "$percent" -le "$start_range" ]; then
        grid+="<span color='$inactive_color'>⣿</span>"
    else
        fill_level=$(( percent - start_range ))
        active_part=$(get_active_braille $fill_level)
        grid+="<span color='$inactive_color' letter_spacing='-15600'>⣿</span><span color='$current_active'>$active_part</span>"
    fi
    grid+=" "
done

display_text="<span letter_spacing='0' size='9pt' font_weight='400'>BAT </span><span >$grid</span>"
echo "{\"text\": \"$display_text\", \"tooltip\": \"Batteri: $percent% ($status)\", \"percentage\": $percent}"