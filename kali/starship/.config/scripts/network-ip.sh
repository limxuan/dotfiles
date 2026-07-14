#!/usr/bin/env bash

# Discover absolute path of ip binary
if [ -x /usr/sbin/ip ]; then
  IP_CMD=/usr/sbin/ip
elif [ -x /sbin/ip ]; then
  IP_CMD=/sbin/ip
else
  IP_CMD=ip
fi

# 1. Prioritize VPN interfaces (tun*, tap*, wg*)
vpn_info=$($IP_CMD -4 -o addr show | grep -E ' (tun|tap|wg)' | head -n 1)
if [ -n "$vpn_info" ]; then
  ip=$(echo "$vpn_info" | awk '{print $4}' | cut -d/ -f1)
  echo "$ip"
  exit 0
fi

# 2. Fallback to default route interface
route_info=$($IP_CMD route get 1.1.1.1 2>/dev/null)
ip=$(echo "$route_info" | grep -oP 'src \K[\d.]+')

if [ -n "$ip" ]; then
  echo "$ip"
  exit 0
fi

# 3. Last fallback: first active non-loopback interface
fallback_info=$($IP_CMD -4 -o addr show | grep -v ' lo ' | head -n 1)
if [ -n "$fallback_info" ]; then
  ip=$(echo "$fallback_info" | awk '{print $4}' | cut -d/ -f1)
  echo "$ip"
fi
