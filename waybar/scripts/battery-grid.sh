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


# --- GRID VISUALISERING (4 kolonner smooth) ---

active_color="#BE5103"
inactive_color="#be510380"

# Charging override
[ "$status" = "Charging" ] && active_color="#ff8c32"

get_braille_level() {
    local value=$1

    if   [ "$value" -ge 22 ]; then echo "⣿"
    elif [ "$value" -ge 19 ]; then echo "⣷"
    elif [ "$value" -ge 16 ]; then echo "⣶"
    elif [ "$value" -ge 13 ]; then echo "⣤"
    elif [ "$value" -ge 10 ]; then echo "⣄"
    elif [ "$value" -ge 7  ]; then echo "⣀"
    elif [ "$value" -ge 4  ]; then echo "⡀"
    else echo "⠀"
    fi
}

grid=""
columns=4
step=25

for ((i=0; i<columns; i++)); do
    start=$(( i * step ))
    end=$(( start + step ))

    if [ "$percent" -ge "$end" ]; then
        # full kolonne
        char="⣿"
        color="$active_color"

    elif [ "$percent" -le "$start" ]; then
        # tom kolonne
        char="⣿"
        color="$inactive_color"

    else
        # smooth progress i denne kolonnen
        local_value=$(( percent - start ))
        char=$(get_braille_level "$local_value")
        color="$active_color"
    fi

    grid+="<span color='$color'>$char</span> "
done

display_text="<span letter_spacing='0' size='9pt' font_weight='400'>BAT </span><span >$grid</span>"
echo "{\"text\": \"$display_text\", \"tooltip\": \"Batteri: $percent% ($status)\", \"percentage\": $percent}"