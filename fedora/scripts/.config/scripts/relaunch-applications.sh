#!/bin/bash

# Hyprland Workspace Restart Script with Debug Logging
# Saves current windows, closes them, and reopens in their workspaces

STATE_FILE="$HOME/.config/hypr/workspace_state.json"
LOG_FILE="$HOME/.config/hypr/restart_debug.log"

# Clear previous log
echo "=== Hyprland Restart Script Debug Log ===" > "$LOG_FILE"
echo "Started at: $(date)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Save current window state
echo "Saving current workspace state..."
echo "Step 1: Saving window state" >> "$LOG_FILE"
hyprctl clients -j > "$STATE_FILE"
echo "Saved to: $STATE_FILE" >> "$LOG_FILE"
echo "File contents:" >> "$LOG_FILE"
cat "$STATE_FILE" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Close all windows
echo "Closing all windows..."
echo "Step 2: Closing windows" >> "$LOG_FILE"
hyprctl clients -j | jq -r '.[].address' | while read -r addr; do
    echo "Closing: $addr" >> "$LOG_FILE"
    hyprctl dispatch closewindow "address:$addr"
    sleep 0.1
done
sleep 2

# Restore windows
echo "Restoring windows..."
echo "Step 3: Restoring windows" >> "$LOG_FILE"

# Check if file exists and is readable
if [ ! -f "$STATE_FILE" ]; then
    echo "ERROR: State file not found!" | tee -a "$LOG_FILE"
    exit 1
fi

# Count windows to restore
window_count=$(jq '. | length' "$STATE_FILE")
echo "Found $window_count windows to restore" | tee -a "$LOG_FILE"

# Parse and restore each window
counter=0
jq -c '.[]' "$STATE_FILE" | while read -r window; do
    counter=$((counter + 1))
    workspace=$(echo "$window" | jq -r '.workspace.id')
    class=$(echo "$window" | jq -r '.class')
    title=$(echo "$window" | jq -r '.title')
    
    echo "" >> "$LOG_FILE"
    echo "Window $counter:" >> "$LOG_FILE"
    echo "  Class: $class" >> "$LOG_FILE"
    echo "  Title: $title" >> "$LOG_FILE"
    echo "  Workspace: $workspace" >> "$LOG_FILE"
    
    echo "Restoring: $class on workspace $workspace"
    
    # Move to target workspace
    hyprctl dispatch workspace "$workspace" >> "$LOG_FILE" 2>&1
    sleep 0.3
    
    # Launch application based on class
    launch_cmd=""
    
    # Handle Chrome PWAs (Progressive Web Apps)
    if [[ "$class" == chrome-* ]]; then
        # Extract URL from class name (e.g., chrome-claude.ai__new-Default -> claude.ai/new)
        url=$(echo "$class" | sed 's/chrome-//;s/__/\//g;s/-Default$//')
        launch_cmd="omarchy-launch-webapp https://$url"
        echo "  Detected Chrome PWA for: $url" >> "$LOG_FILE"
    else
        case "$class" in
            "kitty")
                launch_cmd="kitty"
                ;;
            "Alacritty")
                launch_cmd="alacritty"
                ;;
            "foot")
                launch_cmd="foot"
                ;;
            "firefox"|"Firefox")
                launch_cmd="firefox"
                ;;
            "Google-chrome"|"google-chrome"|"Google Chrome")
                launch_cmd="google-chrome"
                ;;
            "Chromium")
                launch_cmd="chromium"
                ;;
            "Code"|"code-oss")
                launch_cmd="code"
                ;;
            "Spotify")
                launch_cmd="spotify"
                ;;
            "discord"|"Discord")
                launch_cmd="discord"
                ;;
            "thunar"|"Thunar")
                launch_cmd="thunar"
                ;;
            "nautilus"|"Nautilus")
                launch_cmd="nautilus"
                ;;
            "VSCodium")
                launch_cmd="codium"
                ;;
            "brave-browser"|"Brave-browser")
                launch_cmd="brave"
                ;;
            *)
                # Try to launch by class name (lowercase)
                launch_cmd="${class,,}"
                ;;
        esac
    fi
    
    echo "  Launch command: $launch_cmd" >> "$LOG_FILE"
    
    # Try to launch
    echo "  Launching..." >> "$LOG_FILE"
    eval "$launch_cmd" >> "$LOG_FILE" 2>&1 &
    echo "  PID: $!" >> "$LOG_FILE"
    
    sleep 0.7
done

echo ""
echo "Restoration complete!"
echo "Check log file for details: $LOG_FILE"
echo "" >> "$LOG_FILE"
echo "Completed at: $(date)" >> "$LOG_FILE"
