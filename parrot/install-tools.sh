#!/usr/bin/env bash
# install-tools.sh - Install system and custom tools for Parrot OS

set -euo pipefail

echo "[+] Updating apt repositories..."
sudo apt-get update

echo "[+] Installing standard developer utilities..."
sudo apt-get install -y --no-install-recommends \
  stow \
  git \
  tmux \
  fzf \
  ripgrep \
  zoxide \
  eza \
  bat \
  xclip \
  xdotool \
  curl \
  wget \
  neovim \
  kitty \
  build-essential \
  avahi-daemon \
  fd-find \
  gnupg \
  xserver-xorg-input-libinput

# Create fd symlink for fd-find
if [ ! -f /usr/local/bin/fd ] && command -v fdfind &>/dev/null; then
    sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd
fi

# Enable touchpad two-finger scrolling via libinput (MATE desktop)
if command -v xinput &>/dev/null; then
    TOUCHPAD=$(xinput list --short | grep -i touchpad | grep -oP 'id=\K\d+' | head -1)
    if [ -n "$TOUCHPAD" ]; then
        echo "[+] Configuring touchpad scrolling (id=$TOUCHPAD)..."
        xinput set-prop "$TOUCHPAD" "libinput Scrolling Pixel Distance" 15 2>/dev/null || true
        xinput set-prop "$TOUCHPAD" "libinput Natural Scrolling Enabled" 0 2>/dev/null || true
    fi
fi

# Persist touchpad config via X11 conf
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/40-touchpad.conf > /dev/null << 'TOUCHEOF'
Section "InputClass"
    Identifier "touchpad"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "Tapping" "on"
    Option "NaturalScrolling" "false"
    Option "ScrollPixelDistance" "15"
    Option "AccelSpeed" "0.3"
EndSection
TOUCHEOF

# --- Install Starship Prompt ---
if ! command -v starship &>/dev/null; then
  echo "[+] Installing starship prompt..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
else
  echo "[*] Starship is already installed"
fi

# --- Install Sesh (Tmux Session Manager) ---
if ! command -v sesh &>/dev/null; then
  echo "[+] Installing sesh (Tmux session manager)..."
  SESH_VERSION=$(curl -s "https://api.github.com/repos/joshmedeski/sesh/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' || echo "")
  if [ -z "$SESH_VERSION" ]; then
    echo "[!] Failed to fetch latest sesh version from GitHub. Falling back to v2.4.0..."
    SESH_VERSION="2.4.0"
  else
    echo "Found sesh version: v$SESH_VERSION"
  fi
  curl -sLo /tmp/sesh.tar.gz "https://github.com/joshmedeski/sesh/releases/download/v${SESH_VERSION}/sesh_Linux_x86_64.tar.gz"
  tar -xzf /tmp/sesh.tar.gz -C /tmp
  sudo mv /tmp/sesh /usr/local/bin/sesh
  sudo chmod +x /usr/local/bin/sesh
  rm -f /tmp/sesh.tar.gz
  echo "[+] Sesh installed to /usr/local/bin/sesh"
else
  echo "[*] Sesh is already installed"
fi


# --- Install Mise (Runtime manager) ---
if ! command -v mise &>/dev/null; then
  echo "[+] Installing mise (runtime manager) via APT..."
  sudo install -dm 755 /etc/apt/keyrings
  wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg > /dev/null
  echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends mise
  echo "[+] Mise installed"
else
  echo "[*] Mise is already installed"
fi

echo "[+] Parrot OS system tools installation completed successfully!"
