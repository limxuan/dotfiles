#!/bin/bash

# 1. Configuration: Change this to your preferred folder
SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

# 2. Define the final output path with a timestamp
# This ensures files aren't overwritten and have a permanent home
FINAL_SAVE_PATH="$SAVE_DIR/satty_$(date +%Y%m%d_%H%M%S).png"

# Check for dependencies
if ! command -v wl-paste &>/dev/null || ! command -v satty &>/dev/null; then
  notify-send "❌ Missing dependencies: wl-paste or satty not found" -u critical
  exit 1
fi

# Temporary file for the initial clipboard image
TMPFILE=$(mktemp /tmp/satty_clipboard_XXXXXX.png)

# Check if clipboard contains an image
if wl-paste --list-types | grep -q "image/png"; then
  wl-paste > "$TMPFILE"

  # Run Satty
  # Note: --output-filename is now pointing to our permanent path
  satty \
    --filename "$TMPFILE" \
    --output-filename "$FINAL_SAVE_PATH" \
    --early-exit \
    --actions-on-enter save-to-clipboard \
    --save-after-copy \
    --copy-command 'wl-copy'

  # 3. If the file was successfully saved, copy the PATH to the clipboard
  if [ -f "$FINAL_SAVE_PATH" ]; then
    echo -n "$FINAL_SAVE_PATH" | wl-copy
    notify-send "✅ Screenshot Saved" "Path copied to clipboard:\n$FINAL_SAVE_PATH" -t 3000
  fi

  # Clean up the initial temp file
  rm -f "$TMPFILE"
else
  notify-send "❌ Clipboard does not contain an image" -t 3000
  rm -f "$TMPFILE"
  exit 1
fi
