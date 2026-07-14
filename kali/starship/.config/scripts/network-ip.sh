#!/usr/bin/env bash

# Discover absolute path of ip binary
if [ -x /usr/sbin/ip ]; then
  IP_CMD=/usr/sbin/ip
elif [ -x /sbin/ip ]; then
  IP_CMD=/sbin/ip
else
  IP_CMD=ip
fi

route_info=$($IP_CMD route get 1.1.1.1 2>/dev/null)
interface=$(echo "$route_info" | grep -oP 'dev \K\S+')
ip=$(echo "$route_info" | grep -oP 'src \K[\d.]+')

if [ -n "$interface" ] && [ -n "$ip" ]; then
  echo "$interface:$ip"
else
  # Offline fallback
  interface=$($IP_CMD -4 -o addr show | grep -v ' lo ' | awk '{print $2}' | head -n 1)
  ip=$($IP_CMD -4 -o addr show | grep -v ' lo ' | awk '{print $4}' | cut -d/ -f1 | head -n 1)
  if [ -n "$interface" ] && [ -n "$ip" ]; then
    echo "$interface:$ip"
  fi
fi
