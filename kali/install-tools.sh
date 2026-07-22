#!/usr/bin/env bash
# install-tools.sh - Install system and custom tools for Kali Linux

set -euo pipefail

echo "[+] Updating apt repositories..."
sudo apt-get update

echo "[+] Installing standard developer utilities..."
sudo apt-get install -y \
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
  fish \
  kitty \
  build-essential \
  avahi-daemon

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
  # Fetch latest sesh release info and download
  SESH_VERSION=$(curl -s "https://api.github.com/repos/joshmedeski/sesh/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' || echo "")
  if [ -z "$SESH_VERSION" ]; then
    echo "[!] Failed to fetch latest sesh version from GitHub (rate limit or network error). Falling back to v2.4.0..."
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
  curl -fSs https://mise.jdx.dev/gpg-key.pub | sudo tee /etc/apt/keyrings/mise-archive-keyring.pub 1> /dev/null
  echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.pub arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
  sudo apt-get update
  sudo apt-get install -y mise
  echo "[+] Mise installed"
else
  echo "[*] Mise is already installed"
fi


echo "[+] System tools installation completed successfully!"
