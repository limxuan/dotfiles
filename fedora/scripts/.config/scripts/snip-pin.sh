#!/usr/bin/env bash

# Helper script to capture a screenshot region and pin it on screen
# (mimicking Snipaste using grim, slurp, and imv on Sway/Wayland)

# Create a unique temporary file path for the screenshot
TEMP_IMG="/tmp/snip_pin_$(date +%s).png"

# Capture a region selected by the user
if grim -g "$(slurp)" "$TEMP_IMG"; then
    # Copy the screenshot to the clipboard
    wl-copy < "$TEMP_IMG"
    
    # Send a user notification
    notify-send "Screenshot Pinned" "Copied to clipboard and pinned on screen. Press 'q' or 'Esc' to dismiss."
    
    # Open the image in the background with imv
    imv "$TEMP_IMG" &
fi
