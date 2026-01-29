#!/bin/bash

# Henter volum og mute-status via pactl
volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '[0-9]+(?=% )' | head -1)
muted=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -Po 'yes|no')

if [ "$muted" = "yes" ]; then
    echo "MUTED"
else
    filled=$(( (volume + 5) / 10 ))
    if [ $filled -gt 10 ]; then filled=10; fi
    empty=$(( 10 - filled ))
    
    res=""
    for i in $(seq 1 $filled); do 
        if [ $i -ge 8 ]; then
            res+="<span color='#ff8c32'>|</span>"
        else
            res+="<span color='#BE5103'>|</span>"
        fi
    done

    res+="<span color='#be510380'>"
    for i in $(seq 1 $empty); do res+="|"; done
    res+="</span>"

    echo "<span letter_spacing='0' size='9pt'>VOL </span><span>$res</span>"
fi