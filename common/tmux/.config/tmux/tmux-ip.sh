#!/usr/bin/env bash

# Find active VPN
interface=$(ip -4 -o addr show | grep -E ' (tun|tap|wg)[0-9]+ ' | awk '{print $2}' | head -n 1)
ip=$(ip -4 -o addr show | grep -v ' lo ' | grep -E ' (tun|tap|wg)[0-9]+ ' | awk '{print $4}' | cut -d/ -f1 | head -n 1)

# If no VPN, check internet routing interface
if [ -z "$interface" ] || [ -z "$ip" ]; then
  route_info=$(ip route get 1.1.1.1 2>/dev/null || true)
  interface=$(echo "$route_info" | grep -oP 'dev \K\S+')
  ip=$(echo "$route_info" | grep -oP 'src \K[\d.]+')
fi

# Fallback to first non-loopback interface with an IP
if [ -z "$interface" ] || [ -z "$ip" ]; then
  interface=$(ip -4 -o addr show | grep -v ' lo ' | awk '{print $2}' | head -n 1)
  ip=$(ip -4 -o addr show | grep -v ' lo ' | awk '{print $4}' | cut -d/ -f1 | head -n 1)
fi

if [ -n "$interface" ] && [ -n "$ip" ]; then
  echo "[kali - $interface:$ip]"
else
  echo "[kali]"
fi
