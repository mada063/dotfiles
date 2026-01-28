#!/bin/bash

# Henter lysstyrke (0-100)
brightness=$(brightnessctl i | grep -Po '[0-9]+(?=%)' | head -1)

# Sikkerhetssjekk
if [ -z "$brightness" ]; then brightness=0; fi

# Beregn stolper
filled=$(( (brightness + 5) / 10 ))
if [ $filled -gt 10 ]; then filled=10; fi
empty=$(( 10 - filled ))

res="<span color='#BE5103'>"
for i in $(seq 1 $filled); do [ $i -le 10 ] && res+="|"; done
res+="</span><span color='#be510380'>"
for i in $(seq 1 $empty); do res+="|"; done
res+="</span>"

# Bruker "LUM" (Luminosity) for å matche "VOL" på 3 bokstaver
echo "<span letter_spacing='0' size='9pt'>LUM </span><span>$res</span>"