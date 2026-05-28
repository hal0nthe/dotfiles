#!/bin/bash
# Script for waybar styles

set -euo pipefail
IFS=$'\n\t'

# Define directories
waybar_styles="$HOME/.config/waybar/layouts"
waybar_style="$HOME/.config/waybar/config.jsonc"
SCRIPTSDIR="$HOME/.config/waybar/scripts"
rofi_config="$HOME/.config/rofi/theme/select_waybar.rasi"

# Function to display menu options
menu() {
    options=()
    while IFS= read -r file; do
        if [ -f "$waybar_styles/$file" ]; then
            options+=("$(basename "$file" .jsonc)")
        fi
    done < <(find "$waybar_styles" -maxdepth 1 -type f -name '*.jsonc' -exec basename {} \; | sort)
    
    printf '%s\n' "${options[@]}"
}

# Apply selected style
apply_style() {
    ln -sf "$waybar_styles/$1.jsonc" "$waybar_style"
    "${SCRIPTSDIR}/launch.sh" &
}

# Main function
main() {
    choice=$(menu | rofi -i -dmenu -config "$rofi_config")

    if [[ -z "$choice" ]]; then
        echo "No option selected. Exiting."
        exit 0
    fi

    apply_style "$choice"
}

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
    exit 0
fi

main
