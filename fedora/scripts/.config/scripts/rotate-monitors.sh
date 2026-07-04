#!/bin/bash

monitor="eDP-1"
pos="0x0"

# Get current monitor info
monitor_info=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$monitor\")")
current=$(echo "$monitor_info" | jq -r ".transform // 0")
current=$((current))
scale=$(echo "$monitor_info" | jq -r ".scale")

width=$(echo "$monitor_info" | jq -r ".width")
height=$(echo "$monitor_info" | jq -r ".height")
refresh=$(echo "$monitor_info" | jq -r ".refreshRate")
res="${width}x${height}@${refresh}"

case "$1" in
  left)
    next=$(( (current + 3) % 4 ))
    ;;
  right)
    next=$(( (current + 1) % 4 ))
    ;;
  *)
    echo "Usage: $0 {left|right}"
    exit 1
    ;;
esac

hyprctl --batch "
keyword monitor $monitor,$res,$pos,$scale,transform,$next;
keyword input:touchdevice:transform $next;
keyword input:tablet:transform $next
"
