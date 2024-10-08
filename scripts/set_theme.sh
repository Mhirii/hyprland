#!/usr/bin/env bash

use_mako=false

# config dirs
cf=$HOME/.config
hypr=$cf/hypr
dot=$HOME/dotfiles/.config

themes_dir=$hypr/themes
modules=$hypr/modules

rofi=$modules/rofi
alacritty=$modules/alacritty
waybar=$XDG_CONFIG_HOME/waybar

fish=$dot/fish
mako=$cf/mako
fuzzel=$dot/fuzzel

current_theme_path() {
  echo "$hypr/themes/$1"
}

set_wallaper() {
  wall="$hypr/wallpapers/$1.png"
  ln -sf "$wall" "$hypr/background.png"
  hyprctl hyprpaper wallpaper ", $wall"
}

set_alacritty() {
  ctp=$(current_theme_path "$1")
  file=$ctp/alacritty.toml
  target=$alacritty/current_theme.toml
  ln -sf "$file" "$target"
}
set_fish() {
  sed -i "s/set -x theme .*/set -x theme $1/" "$fish/current_theme.fish"
}
set_mako() {
  ctp=$(current_theme_path "$1")
  file=$ctp/mako
  config=$mako/config
  default=$mako/default
  cp "$default" "$config"
  cat "$file" >>"$config"
}
set_swaync() {
  swaync_style=$cf/swaync/style.css
  sed -i "s/hypr\/theme.*/hypr\/themes\/$1\/waybar.css\";/" "$swaync_style"
}

set_rofi() {
  ctp=$(current_theme_path "$1")
  file=$ctp/rofi.rasi
  ln -sf "$file" "$rofi/theme.rasi"
  ln -sf "$file" "$HOME/.config/rofi/theme.rasi"
}
set_waybar() {
  ctp=$(current_theme_path "$1")
  file=$ctp/waybar.css
  ln -sf "$file" "$waybar/theme.css"
  pkill waybar
  waybar &
}
set_hypr() {
  sed -i "s/theme =.*/theme = $1/" "$hypr/hyprlock.conf"
  sed -i "s/theme =.*/theme = $1/" "$hypr/hyprland.conf"
}
set_starship() {
  sed -i "s/palette =.*/palette = \"$1\"/" "$HOME/.config/starship.toml"
}

remove_hashtag() {
  echo "$1" | sed 's/#//'
}
fuzzel_color() {
  field=$1
  color=$(remove_hashtag "$2")
  if [ -z "$3" ]; then
    opacity="ff"
  else
    opacity=$3
  fi
  color="$color$opacity"
  sed -i "s/$field=.*/$field=$color/" "$fuzzel/fuzzel.ini"
}
set_fuzzel() {
  theme_file="$hypr/themes/$1/theme.sh"
  if [ ! -f "$theme_file" ]; then
    echo "Fuzzel: theme file not found"
    echo "$theme_file"
    return
  fi
  source "$theme_file"

  for color in accent background foreground color8; do
    if [ -z "${!color}" ]; then
      echo "Fuzzel: $color not found"
      return
    fi
  done
  fuzzel_color "background" "$background" "60"
  fuzzel_color "text" "$foreground"
  fuzzel_color "match" "$accent"
  fuzzel_color "selection" "$accent"
  fuzzel_color "selection-text" "$color8"
  fuzzel_color "selection-match" "$background"
  fuzzel_color "border" "$accent"
}

set_theme() {
  set_waybar "$1"
  set_swaync "$1"
  set_alacritty "$1"
  set_fish "$1"
  set_mako "$1"
  set_rofi "$1"
  set_hypr "$1"
  set_wallaper "$1"
  set_starship "$1"
  set_fuzzel "$1"
  if $use_mako; then
    makoctl reload
  else
    pkill swaync && swaync &
  fi
  notify-send -t 3000 "Theme" "Set to $1"
}

check_themes_exist() {
  if [ ! -d "$themes_dir" ]; then
    echo "Themes dir not found"
    exit 1
  fi

  if [ ! -d "$themes_dir/$1" ]; then
    echo
    echo "Theme not found"
    echo
    echo -e "current themes:"
    for dir in "$themes_dir"/*; do
      if [ -d "$dir" ]; then
        echo -e "  \033[35m$(basename "$dir")"
      fi
    done
    exit 1
  fi

  # checks the necessary files
  checks=("$themes_dir/$1/alacritty.toml" "$themes_dir/$1/fish.theme" "$themes_dir/$1/mako" "$themes_dir/$1/rofi.rasi" "$themes_dir/$1/waybar.css")
  for check in "${checks[@]}"; do
    if [ ! -f "$check" ]; then
      echo "Theme missing files"
      exit 1
    fi
  done

}

echo_help() {
  echo
  echo -e "\033[0;34mUsage: set_theme.sh < [theme] | rofi | tui >\033[0m"
  echo
  echo -e "current themes:"
  for dir in "$themes_dir"/*; do
    if [ -d "$dir" ]; then
      echo -e "  \033[35m$(basename "$dir")"
    fi
  done
}

# main

echo_dirs() {
  parent=$themes_dir
  for dir in "$parent"/*; do
    if [ -d "$dir" ]; then
      echo -e "$(basename "$dir")"
    fi
  done
}

if [ -z "$1" ]; then
  echo_help
fi

if [ "$1" == "rofi" ]; then
  themes=$(echo_dirs)
  theme=$(echo -e "$themes" | rofi -dmenu -i -config "$rofi"/config.rasi)
elif [ "$1" == "tui" ]; then
  themes=$(echo_dirs | tr '\n' ' ')
  # WARN: do not add double quotes
  theme=$(gum filter $themes)
else
  theme=$1
fi

check_themes_exist "$theme"
set_theme "$theme"
