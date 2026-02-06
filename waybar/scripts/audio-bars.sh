#!/bin/bash

# Henter volum og mute-status via pactl
volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '[0-9]+(?=% )' | head -1)
muted=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -Po 'yes|no')

# Beregn antall fylte og tomme barer
filled=$(( (volume + 5) / 10 ))
if [ $filled -gt 10 ]; then filled=10; fi
empty=$(( 10 - filled ))

res=""

if [ "$muted" = "yes" ]; then
    # Når mutet: Lys grå for volum-nivået, mørk grå for resten
    res="<span color='#3a3a41'>"
    for i in $(seq 1 $filled); do res+="|"; done
    res+="</span><span color='#25252c'>"
    for i in $(seq 1 $empty); do res+="|"; done
    res+="</span>"
else
    # Når ikke mutet: Dine originale oransje-farger
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
fi

echo "<span letter_spacing='0' size='9pt'>VOL </span><span>$res</span>"