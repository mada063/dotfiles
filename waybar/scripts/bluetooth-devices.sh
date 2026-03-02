#!/usr/bin/env bash

# Check if Bluetooth is powered
powered=$(bluetoothctl show | grep "Powered" | awk '{print $2}')

if [[ "$powered" != "yes" ]]; then
    echo '{"text":"OFFLINE","tooltip":"Bluetooth is turned off"}'
    exit 0
fi

# Get connected devices
connected=$(bluetoothctl info | grep -B1 "Connected: yes" | grep "Name" | awk -F': ' '{print $2}')

# Get all paired devices
devices=$(bluetoothctl devices | awk '{$1=""; print substr($0,2)}')

# Set text for the bar
if [[ -n "$connected" ]]; then
    text="CONNECTED"
else
    text="BLUETOOTH"
fi

# Build tooltip
tooltip=""

if [[ -n "$connected" ]]; then
    tooltip+="Connected devices:\n"
    while read -r name; do
        [[ -n "$name" ]] && tooltip+=" • $name\n"
    done <<< "$connected"
fi

if [[ -n "$devices" ]]; then
    tooltip+="Paired devices (not connected):\n"
    while read -r name; do
        grep -qx "$name" <<< "$connected" && continue
        [[ -n "$name" ]] && tooltip+=" • $name\n"
    done <<< "$devices"
fi

tooltip=${tooltip:-"No devices"}

# Escape tooltip for JSON
escaped=$(printf '%s' "$tooltip" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')

# Output JSON
echo "{\"text\":\"$text\",\"tooltip\":$escaped}"
