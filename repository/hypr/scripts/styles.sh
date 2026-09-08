#!/bin/bash
waybarLayout() {
  options=("kazumi" "akane" "delan")

  layouts=$(for item in "${options[@]}"; do
    echo "$item"
  done | rofi -dmenu)

  if [ -n "$layouts" ]; then
    cat "$HOME/.config/waybar/layouts/${layouts}.jsonc" >"$HOME/.config/waybar/config.jsonc"
    cat "$HOME/.config/waybar/styles/${layouts}.css" >"$HOME/.config/waybar/style.css"
    killall waybar && hyprctl dispatch exec waybar
  fi
}
colors() {
  options=("catpuccin" "tokyoNight" "wallust")

  color_options=$(for item in "${options[@]}"; do
    echo "$item"
  done | rofi -dmenu)

  if [ -n "$color_options" ]; then
    if [[ "$color_options" != "wallust" ]]; then
      cat "$HOME/.config/wallust/base_themes/${color_options}/rofi.rasi" >"$HOME/.config/rofi/colors.rasi"
      cat "$HOME/.config/wallust/base_themes/${color_options}/kitty.conf" >"$HOME/.config/kitty/colors.conf"
      cat "$HOME/.config/wallust/base_themes/${color_options}/dunst.conf" >"$HOME/.config/dunst/dunstrc.d/color.conf"
      cat "$HOME/.config/wallust/base_themes/${color_options}/waybar.css" >"$HOME/.config/waybar/colors.css"
      cat "$HOME/.config/wallust/base_themes/${color_options}/wlogout.css" >"$HOME/.config/wlogout/colors.css"
      cat "$HOME/.config/wallust/base_themes/${color_options}/hyprcolors.conf" >"$HOME/.config/hypr/sources/hyprcolors.conf"

      pkill -SIGUSR2 waybar
      kill -SIGUSR1 $(pgrep kitty)
      hyprctl reload
      dunstctl reload

    else

      CURRENT_WALLPAPER_FILE=$(basename "$(awww query | awk '{print $NF}')")
      wallust run "$HOME/Pictures/wallpapers/$CURRENT_WALLPAPER_FILE"
      pkill -SIGUSR2 waybar
      kill -SIGUSR1 $(pgrep kitty)
      hyprctl reload
      dunstctl reload
    fi
  fi
}
options=("waybar layouts" "colors" "wallpapers")

selection=$(for item in "${options[@]}"; do
  echo "$item"
done | rofi -dmenu)

case "$selection" in
"waybar layouts") waybarLayout ;;
"wallpapers") sh -c $HOME/.config/rofi/wallpaper/swww.sh ;;
"colors") colors ;;
esac
