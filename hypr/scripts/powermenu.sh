op1="LOCK"
op2="LOGOUT"
op3="RESTART"
op4="SHUTDOWN"

options="$op1\n$op2\n$op3\n$op4"

chosen=$(echo -e "$options" |
  wofi --dmenu \
       --sort-order=default \
       --hide-search \
       --width=200 \
       --height=125 \
       --no-history \
       --prompt '' \
       --style ~/.config/wofi/power.css)

case $chosen in
    $op1) hyprlock ;;
    $op2) hyprctl dispatch exit ;;
    $op3) systemctl reboot ;;
    $op4) systemctl poweroff ;;
esac
