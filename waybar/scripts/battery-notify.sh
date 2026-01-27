#!/usr/bin/env bash

cap=$(cat /sys/class/power_supply/BAT*/capacity)
time=$(upower -i $(upower -e | grep BAT) | grep -E "time to" | awk '{print $4,$5}')

notify-send "Battery" "$cap% remaining\nTime: ${time:-unknown}"
