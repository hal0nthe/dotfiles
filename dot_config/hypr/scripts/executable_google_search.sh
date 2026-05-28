rofi_theme="$HOME/.config/rofi/theme/google_search.rasi"

if pgrep -x "rofi" >/dev/null; then
  pkill rofi
  exit 0
fi

echo "" | rofi -dmenu -config "$rofi_theme" -p "Search:" | xargs -I{} xdg-open "https://www.google.com/search?q={}"
