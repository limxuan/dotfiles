#!/bin/bash

STATE_FILE="/tmp/trackpad_state"

# Read current state from file (default to enabled if file doesn't exist)
if [ -f "$STATE_FILE" ]; then
    CURRENT_STATE=$(cat "$STATE_FILE")
else
    CURRENT_STATE="enabled"
fi

if [ "$CURRENT_STATE" = "enabled" ]; then
    echo '{"text": "󰟸", "class": "enabled", "tooltip": "Trackpad Enabled"}'
else
    echo '{"text": "", "class": "disabled", "tooltip": ""}'
fi
