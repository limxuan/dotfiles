#!/usr/bin/env bash

# Target the desktop workspace
TARGET_WS=7

# Get current workspace ID
ORIGINAL_WS=$(hyprctl activeworkspace -j | jq -r '.id')

# Collect window addresses from current workspace
WINDOWS=$(hyprctl clients -j | jq -r \
  ".[] | select(.workspace.id == $ORIGINAL_WS) | .address")

# If no windows, exit quietly
[ -z "$WINDOWS" ] && exit 0

# Move all windows to workspace 7
for addr in $WINDOWS; do
  hyprctl dispatch movetoworkspace "$TARGET_WS,address:$addr"
done

# Small delay to let Hyprland process moves
sleep 0.05

# Move them all back to the original workspace
for addr in $WINDOWS; do
  hyprctl dispatch movetoworkspace "$ORIGINAL_WS,address:$addr"
done
