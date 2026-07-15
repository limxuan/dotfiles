#!/bin/bash

monitor="eDP-1"

# Get current monitor transform under Sway
current_transform=$(swaymsg -t get_outputs | jq -r ".[] | select(.name==\"$monitor\") | .transform")

# Map transform string to integer 0-3
case "$current_transform" in
  normal)      current=0 ;;
  90)          current=1 ;;
  180)         current=2 ;;
  270)         current=3 ;;
  *)           current=0 ;;
esac

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

# Map integer 0-3 back to Sway transform value
case "$next" in
  0) transform="normal" ;;
  1) transform="90" ;;
  2) transform="180" ;;
  3) transform="270" ;;
esac

# Rotate monitor output
swaymsg output "$monitor" transform "$transform"
