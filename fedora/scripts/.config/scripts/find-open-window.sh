#!/bin/bash

# Check if running inside terminal
if [ ! -t 0 ]; then
    # Not in terminal, spawn one
    alacritty --class=float-window -e "$0" "$@"
    exit 0
fi

# Get list of windows with their details
windows=$(hyprctl clients -j | jq -r '.[] | "\(.address)|\(.workspace.id)|\(.class)|\(.title)"' | sort -t'|' -k2 -n)

# Format for fzf display and let user select
selected=$(echo "$windows" | awk -F'|' '{printf "WS:%s | %s | %s\n", $2, $3, $4}' | \
    fzf --prompt="Switch to window: " \
        --height=40% \
        --reverse \
        --border \
        --preview-window=hidden)

# Exit if nothing selected
[[ -z "$selected" ]] && exit 0

# Extract the line number of selection and get corresponding address
line_num=$(echo "$windows" | awk -F'|' '{printf "WS:%s | %s | %s\n", $2, $3, $4}' | \
    grep -n "^${selected}$" | cut -d: -f1)

address=$(echo "$windows" | sed -n "${line_num}p" | cut -d'|' -f1)

# Focus the selected window
hyprctl dispatch focuswindow address:$address
