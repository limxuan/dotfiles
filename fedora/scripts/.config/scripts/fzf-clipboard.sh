#!/usr/bin/env bash

# Temporary file to store fzf selection
tmpfile=$(mktemp /tmp/fzf-clip-out-XXXXXX)

# Run fzf inside kitty to select a clipboard item
kitty --class fzf-clip -o font_size=10 -e sh -c "cliphist list | fzf -d '\t' --with-nth 2 --preview-window=right:50% --preview '~/.config/scripts/fzf-cliphist-preview.sh {}' > '$tmpfile'"

# Check if a selection was made
if [ -s "$tmpfile" ]; then
    # Decode selection and copy back to clipboard
    cat "$tmpfile" | cliphist decode | wl-copy
fi

# Clean up
rm -f "$tmpfile"
