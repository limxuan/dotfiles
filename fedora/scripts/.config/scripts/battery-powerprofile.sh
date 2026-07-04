#!/bin/bash
# === Omarchy theme integration ===
# Path to Omarchy theme file (adjust if your path differs)
theme_file="$HOME/.config/omarchy/current/theme/waybar.css"
# Extract theme colors
omarchy_foreground=$(awk '/@define-color[[:space:]]+foreground/ {print $3}' "$theme_file" | tr -d ';')
omarchy_background=$(awk '/@define-color[[:space:]]+background/ {print $3}' "$theme_file" | tr -d ';')
omarchy_accent=$(awk '/@define-color[[:space:]]+accent/ {print $3}' "$theme_file" | tr -d ';')
# Fallback colors if not found
omarchy_foreground=${omarchy_foreground:-#FFFFFF}
omarchy_background=${omarchy_background:-#000000}
omarchy_accent=${omarchy_accent:-#E2EB34}
# === Battery and power profile info ===
capacity=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
profile=$(/usr/bin/powerprofilesctl get | tr -d '\n')
# === Choose color based on profile ===
case "$profile" in
  "performance")
    color="#FF0A1F"
    ;;
  "balanced")
    color="$omarchy_foreground"
    ;;
  "power-saver")
    color="$omarchy_accent"
    ;;
  *)
    color="$omarchy_foreground"
    ;;
esac
# === Choose prefix based on charging status ===
if [[ "$status" == "Charging" ]]; then
    prefix="^"
else
    prefix=""
fi
# === Output JSON for Waybar ===
echo "{\"text\":\"&#160;<span color='$color'>${prefix}${capacity}%</span>&#160;\",\"tooltip\":\"$capacity% - $profile - $status\"}"
