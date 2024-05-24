#!/bin/bash

echo_color() {
	case $2 in
	"red") echo -e "\e[31m$1\e[0m" ;;
	"green") echo -e "\e[32m$1\e[0m" ;;
	"yellow") echo -e "\e[33m$1\e[0m" ;;
	"blue") echo -e "\e[34m$1\e[0m" ;;
	"magenta") echo -e "\e[35m$1\e[0m" ;;
	"cyan") echo -e "\e[36m$1\e[0m" ;;
	"white") echo -e "\e[37m$1\e[0m" ;;
	*) echo "$1" ;;
	esac
}

echo_color "Starting up..." "green"

pkill mako
swaync &

# echo_color "Setting up wallpaper..." "cyan"
# swww init
# swww img --transition-type grow ~/.config/hypr/background.png
# echo_color "Wallpaper set!" "green"

echo_color "Setting up waybar..." "cyan"
ln -s "$XDG_RUNTIME_DIR/hypr" /tmp/hypr
waybar &
echo_color "waybar set!" "green"

echo_color "Initializing tmux..." "cyan"
tmux new -s init &
echo_color "Tmux initialized!" "green"

echo_color "Starting up applications..." "cyan"
hyprctl dispatch exec [workspace special silent] "alacritty -e ~/scripts/tmuxMain.sh"
# hyprctl dispatch exec [workspace 8 silent] alacritty

# if [ "$(acpi -b | awk '{print $4}' | tr -d '%,')" -gt 50 ]; then
if [ "$(acpi -b | sed 's/.*charging, //' | sed 's/%.*//')" -gt 50 ]; then
	hyprctl dispatch exec [workspace 2 silent] "$HOME/scripts/launch.fish" vivaldi
	hyprctl dispatch exec [workspace 5 silent] webcord
	hyprctl dispatch exec [workspace 6 silent] "$HOME/scripts/launch.fish" spotify
fi
echo_color "Starting up clickup..." "blue"
clickup &
echo_color "done!" "green"

echo_color "Applications started!" "green"
