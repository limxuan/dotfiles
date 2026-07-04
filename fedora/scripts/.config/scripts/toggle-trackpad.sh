#!/bin/bash

# State file to track toggle status
STATE_FILE="/tmp/trackpad_state"

# Find all trackpad devices (both ELAN and Synaptics)
TRACKPADS=$(hyprctl devices -j | jq -r '.mice[] | select(.name | test("touchpad|elan.*mouse|synaptics|syna"; "i")) | .name')

if [ -z "$TRACKPADS" ]; then
    notify-send "Trackpad" "No trackpad found"
    exit 1
fi

# Read current state from file (default to enabled if file doesn't exist)
if [ -f "$STATE_FILE" ]; then
    CURRENT_STATE=$(cat "$STATE_FILE")
else
    CURRENT_STATE="enabled"
fi

# Toggle all trackpads
if [ "$CURRENT_STATE" = "enabled" ]; then
    # Disable trackpads
    while IFS= read -r trackpad; do
        hyprctl keyword device[$trackpad]:enabled false >/dev/null 2>&1
    done <<< "$TRACKPADS"
    echo "disabled" > "$STATE_FILE"
    notify-send "Trackpad" "Disabled"
else
    # Enable trackpads
    while IFS= read -r trackpad; do
        hyprctl keyword device[$trackpad]:enabled true >/dev/null 2>&1
    done <<< "$TRACKPADS"
    echo "enabled" > "$STATE_FILE"
    notify-send "Trackpad" "Enabled"
fi
