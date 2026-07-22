#!/usr/bin/env bash
# setup-mate-keybinds.sh - Set keyboard shortcuts for MATE workspace switching on Parrot OS

set -euo pipefail

echo "[+] Configuring MATE Workspace keyboard shortcuts..."

if command -v gsettings &>/dev/null; then
  # Ensure we have 6 workspaces in MATE Marco window manager
  gsettings set org.mate.Marco.general num-workspaces 6 2>/dev/null || true

  # Bind keys for workspaces 1..6:
  # Switch Workspace: Super + 1..6
  # Move Window to Workspace: Super + Shift + 1..6
  for i in {1..6}; do
    echo "  - Mapping Workspace $i shortcuts (Switch & Move)"
    gsettings set org.mate.Marco.global-keybindings switch-to-workspace-$i "<Super>$i" 2>/dev/null || true
    gsettings set org.mate.Marco.window-keybindings move-to-workspace-$i "<Super><Shift>$i" 2>/dev/null || true
  done

  # Add custom application shortcuts
  echo "[+] Configuring custom application shortcuts..."
  gsettings set org.mate.Marco.global-keybindings run-command-1 "<Super>Return" 2>/dev/null || true
  gsettings set org.mate.Marco.keybinding-commands command-1 "kitty" 2>/dev/null || true

  gsettings set org.mate.Marco.global-keybindings run-command-2 "<Super>b" 2>/dev/null || true
  gsettings set org.mate.Marco.keybinding-commands command-2 "x-www-browser" 2>/dev/null || true

  echo "[+] MATE keyboard shortcuts successfully configured!"
else
  echo "[!] gsettings not found; skipping MATE keybindings configuration."
fi
