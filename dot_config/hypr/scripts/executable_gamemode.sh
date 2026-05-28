#!/usr/bin/env bash

animations_enabled=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')

enable_gamemode() {
    hyprctl --batch "
        keyword animations:enabled 0;
        keyword decoration:drop_shadow 0;
        keyword decoration:blur:passes 0;
        keyword decoration:rounding 0;
        keyword general:gaps_in 0;
        keyword general:gaps_out 0;
        keyword general:border_size 1;
    "

    hyprctl keyword "windowrule opacity 1 override 1 override 1 override, ^(.*)$"

    notify-send "Gamemode: ON" "minimal visuals"
}

disable_gamemode() {
    hyprctl reload

    notify-send "Gamemode: OFF" "restored config"
}

if [ "$animations_enabled" = "1" ]; then
    enable_gamemode
else
    disable_gamemode
fi
