#!/usr/bin/env bash
cap=$(cat /sys/class/power_supply/BAT*/capacity)
status=$(cat /sys/class/power_supply/BAT*/status)
time=$(upower -i $(upower -e | grep BAT) | grep -E "time to" | awk '{print $4,$5}')

notify-send -u normal "Battery Status" "Capacity: $cap%\nStatus: $status\nTime: ${time:-N/A}"