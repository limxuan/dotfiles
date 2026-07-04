#!/usr/bin/env bash

# Helper script for Wofi to display image previews of cliphist clipboard items.
# Usage in Wofi: cliphist list | wofi --dmenu --allow-images --pre-display-cmd "cliphist-wofi-img.sh %s"

# Extract the ID (first tab-separated field)
ID=$(echo "$1" | cut -f1)

# Extract the content description
CONTENT=$(echo "$1" | cut -f2-)

# Check if the content is a binary image
if [[ "$CONTENT" == "[[ binary data"* ]]; then
    THUMB="/tmp/cliphist_thumb_${ID}.png"
    # Decode and cache the thumbnail if not already present
    if [[ ! -f "$THUMB" ]]; then
        cliphist decode "$ID" > "$THUMB" 2>/dev/null
    fi
    # Output the image path to tell Wofi to render it
    echo "$THUMB"
else
    # Output the text content to render normally
    echo "$CONTENT"
fi
