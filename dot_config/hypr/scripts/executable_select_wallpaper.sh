#!/bin/bash

# === CONFIG ===
WALL_DIR="$HOME/Pictures/Wallpapers"
ROFI_THEME="$HOME/.config/rofi/theme/select_wallpaper.rasi"
CURRENT_WALLPAPER="$HOME/.config/hypr/.current_wallpaper"

CACHE_DIR="$HOME/.cache/wallpicker"
GIF_CACHE="$CACHE_DIR/gif"
VID_CACHE="$CACHE_DIR/video"

mkdir -p "$GIF_CACHE" "$VID_CACHE"

# === DEPENDENCY CHECK ===
for cmd in rofi awww matugen; do
  command -v $cmd >/dev/null || {
    notify-send "Missing dependency: $cmd"
    exit 1
  }
done

# === WALLPAPER LIST ===
mapfile -d '' FILES < <(find -L "$WALL_DIR" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o \
  -iname "*.gif" -o \
  -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) -print0)

[[ ${#FILES[@]} -eq 0 ]] && {
  notify-send "No wallpapers found"
  exit 1
}

# === PREVIEW BUILDER ===
build_preview() {
  local file="$1"
  local name=$(basename "$file")

  case "$file" in
    *.gif)
      local out="$GIF_CACHE/$name.png"
      [[ ! -f "$out" ]] && magick "$file[0]" -resize 400x400 "$out"
      echo "$out"
      ;;
    *.mp4|*.mkv|*.webm)
      local out="$VID_CACHE/$name.png"
      [[ ! -f "$out" ]] && ffmpeg -loglevel quiet -y -i "$file" -ss 00:00:01 -vframes 1 "$out"
      echo "$out"
      ;;
    *)
      echo "$file"
      ;;
  esac
}

# === ICON SIZE (adaptive) ===
scale_factor=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .scale')
monitor_height=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .height')

icon_size=$(echo "scale=1; ($monitor_height * 3) / ($scale_factor * 150)" | bc)
adjusted_icon_size=$(echo "$icon_size" | awk '{if ($1 < 15) $1 = 20; if ($1 > 25) $1 = 25; print $1}')

ROFI_OVERRIDE="element-icon{size:${adjusted_icon_size}%;}"

# === MENU ===
menu() {
  for file in "${FILES[@]}"; do
    name=$(basename "$file")
    icon=$(build_preview "$file")
    printf "%s\x00icon\x1f%s\n" "$name" "$icon"
  done
}

# === APPLY IMAGE ===
apply_image() {
  local img="$1"

  # start daemon if needed
  pgrep -x awww-daemon >/dev/null || awww-daemon --format xrgb &

  matugen image "$img" --mode dark --source-color-index 0
  
  awww img "$img" \
    --transition-type any \
    --transition-fps 144 \
    --transition-step 255 \
    --transition-bezier .43,1.19,1,.4
  
  ln -sf "$img" "$CURRENT_WALLPAPER"

  notify-send "Wallpaper" "wallpaper changed succesfully."
}

# === APPLY VIDEO ===
apply_video() {
  local vid="$1"

  if ! command -v mpvpaper >/dev/null; then
    notify-send "mpvpaper not installed"
    exit 1
  fi

  pkill mpvpaper 2>/dev/null
  pkill awww-daemon 2>/dev/null

  mpvpaper '*' -o "no-audio --loop" "$vid" &
}

# === MAIN ===
choice=$(menu | rofi -dmenu -i -config "$ROFI_THEME" -theme-str "$ROFI_OVERRIDE")

[[ -z "$choice" ]] && exit 0

selected=$(find "$WALL_DIR" -type f -iname "$choice" | head -n1)

[[ -z "$selected" ]] && {
  notify-send "File not found"
  exit 1
}

case "$selected" in
  *.mp4|*.mkv|*.webm)
    apply_video "$selected"
    ;;
  *)
    apply_image "$selected"
    ;;
esac
