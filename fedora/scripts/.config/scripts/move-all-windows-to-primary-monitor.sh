#!/usr/bin/env bash

# Target workspace for the migration
TARGET_WS=7

# Source workspaces to migrate from
SOURCE_WORKSPACES=(1 2 3 4 5)

# Process each source workspace
for ws in "${SOURCE_WORKSPACES[@]}"; do
  # Collect window addresses from this workspace
  WINDOWS=$(hyprctl clients -j | jq -r \
    ".[] | select(.workspace.id == $ws) | .address")
  
  # Skip if no windows in this workspace
  [ -z "$WINDOWS" ] && continue
  
  # Move all windows to workspace 7
  for addr in $WINDOWS; do
    hyprctl dispatch movetoworkspace "$TARGET_WS,address:$addr"
  done
  
  # Small delay to let Hyprland process moves
  sleep 0.05
  
  # Move them all back to their original workspace
  for addr in $WINDOWS; do
    hyprctl dispatch movetoworkspace "$ws,address:$addr"
  done
done
