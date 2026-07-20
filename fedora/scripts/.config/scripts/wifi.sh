#!/usr/bin/env bash

# Check if any ethernet interface is UP and has a carrier
ETH_UP=false
for eth in /sys/class/net/en* /sys/class/net/eth*; do
    if [ -d "$eth" ] && [ "$(cat "$eth/operstate" 2>/dev/null)" = "up" ]; then
        ETH_UP=true
        break
    fi
done

if [ "$ETH_UP" = "true" ]; then
    echo "ETH  CONNECTED"
else
    # Find the first wireless interface, cleaning ANSI escape codes from iwctl output
    WLAN_IFACE=$(iwctl device list | sed 's/\x1b\[[0-9;]*m//g' | awk '/station/ {print $1}' | head -n 1)
    if [ -n "$WLAN_IFACE" ]; then
        STATE=$(iwctl station "$WLAN_IFACE" show | sed 's/\x1b\[[0-9;]*m//g' | awk '/State/ {print $2}' 2>/dev/null)
        if [ "$STATE" = "connected" ]; then
            SSID=$(iwctl station "$WLAN_IFACE" show | sed 's/\x1b\[[0-9;]*m//g' | awk '/Connected network/ { $1=$2=""; print $0 }' 2>/dev/null | xargs)
            echo "WIFI  $SSID"
        elif [ "$STATE" = "connecting" ]; then
            echo "WIFI  CONNECTING"
        else
            echo "OFFLINE"
        fi
    else
        echo "OFFLINE"
    fi
fi
