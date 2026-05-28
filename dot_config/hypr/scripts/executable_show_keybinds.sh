#!/bin/bash

# GDK BACKEND. Change to either wayland or x11 if having issues
BACKEND=wayland

# Check if rofi or yad is running and kill them if they are
if pidof rofi > /dev/null; then
  pkill rofi
fi

if pidof yad > /dev/null; then
  pkill yad
fi

# Launch yad with calculated width and height
GDK_BACKEND=$BACKEND yad \
    --center \
    --title="Cheat Sheet" \
    --no-buttons \
    --list \
    --column=Key: \
    --column=Description: \
    --column=Command: \
    --timeout-indicator=bottom \
"ESC" "close this app" " " \
" = " "SUPER KEY (Windows Key Button)" "(SUPER KEY)" \
"" "" "" \
"  + H" "Launch this Quick Cheat Sheet" "" \
"  + Enter" "Terminal" "(kitty)" \
"  + ALT + Enter" "Application Launcher" "(rofi-wayland)" \
"  + B" "Launch Browser" "(Default browser)" \
"  + E" "Open File Manager" "(Thunar)" \
"  + Q " "kills an active window" "(kill)" \
"  + W" "Choose wallpaper" "(Wallpaper Menu)" \
"  + R" "Reload Waybar swaync Rofi" "CHECK NOTIFICATION FIRST!!!" \
"  + F" "Fullscreen" "Toggles to full screen" \
"  + J" "Toggle Dwindle | Master Layout" "Hyprland Layout" \
"  + T" "Toggle float" "single window" \
"  + Number" "Switch Workspace" "Switch workspaces with number [0-9]" \
"  + Tab" "Switch Workspace" "Scroll through existing workspaces" \
"  + Mouse Scroll" "Switch Workspace" "Scroll through existing workspaces" \
"" "" "" \
"CTRL + ALT + Delete" "Hyprland Exit" "(NOTE: Hyprland Will exit immediately)" \
"" "" "" \
"More tips:" "https://github.com/rest1ka/dotfiles" ""