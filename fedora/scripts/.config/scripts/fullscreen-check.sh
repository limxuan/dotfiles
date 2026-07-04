#!/bin/bash

# Check if active window is fullscreen
hyprctl activewindow -j | jq -r '.fullscreen' | grep -q 'true\|1' && echo '{"text": "  ", "class": "fullscreen", "tooltip": "Fullscreen Mode Active"}' || echo '{"text": "", "class": "normal", "tooltip": ""}'
