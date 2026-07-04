#!/usr/bin/env fish
# Find existing ssh-agent socket or start a new one
set agent_sock (find /tmp -name "agent.*" -user $USER 2>/dev/null | head -1)

if test -n "$agent_sock"
    # echo "[*] Found existing ssh-agent socket"
    set -gx SSH_AUTH_SOCK $agent_sock
else if pgrep -u $USER ssh-agent > /dev/null
    # echo "[*] ssh-agent running but socket not found, starting new one..."
    eval (ssh-agent -c) > /dev/null
else
    # echo "[*] Starting ssh-agent..."
    eval (ssh-agent -c) > /dev/null
end

# Add all SSH keys from ~/.ssh/
# echo "[*] Adding SSH keys..."
set key_count 0

for key in ~/.ssh/id_* ~/.ssh/*_key
    # Skip public keys and known_hosts
    if string match -q "*.pub" $key; or string match -q "*known_hosts*" $key
        continue
    end
    
    if test -f $key
        # echo "[+] Adding $key"
        ssh-add $key 2>/dev/null
        and set key_count (math $key_count + 1)
    end
end
