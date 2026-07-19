#!/usr/bin/env bash

# Unified cross-platform dotfiles installer for Fedora and Kali Linux.
# Organizes configuration using modular GNU Stow packages.

set -e

# Color codes for pretty printing
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}         Unified Dotfiles Setup Script         ${NC}"
echo -e "${BLUE}===============================================${NC}"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${DOTFILES_DIR}"
echo -e "${GREEN}Detected dotfiles directory: ${DOTFILES_DIR}${NC}"

# 1. Detect Operating System
if [ -f /etc/fedora-release ]; then
    OS="fedora"
elif [ -f /etc/kali-version ] || grep -qi "kali" /etc/os-release 2>/dev/null; then
    OS="kali"
elif [ -f /etc/parrot-version ] || grep -qi "parrot" /etc/os-release 2>/dev/null; then
    OS="parrot"
else
    echo -e "${RED}Error: Unsupported operating system (Only Fedora, Kali, and Parrot OS are supported).${NC}"
    exit 1
fi
echo -e "${GREEN}Detected OS profile: ${OS}${NC}"

# 2. OS-Specific Setup (Repositories & Package Installations)
if [ "${OS}" = "fedora" ]; then
    echo -e "\n${YELLOW}[1/6] Setting up Fedora repositories...${NC}"
    sudo dnf copr enable alternateved/keyd -y
    sudo dnf copr enable lionheartp/Hyprland -y
    sudo dnf copr enable atim/starship -y
    sudo dnf copr enable imput/helium -y
    if [ ! -f /etc/yum.repos.d/mise.repo ]; then
        sudo curl -o /etc/yum.repos.d/mise.repo https://mise.jdx.dev/rpm/mise.repo
    fi

    echo -e "\n${YELLOW}[2/6] Installing Fedora desktop packages via DNF...${NC}"
    sudo dnf install -y \
        niri sway keyd stow kitty nautilus noctalia-git fish jetbrains-mono-fonts \
        starship mise ripgrep fzf eza zoxide wofi cliphist brightnessctl \
        SwayNotificationCenter grimshot sway-contrib swappy fuse-libs network-manager-applet pavucontrol wtype \
        helium-bin

elif [ "${OS}" = "kali" ]; then
    echo -e "\n${YELLOW}[1/6] Running Kali tools installer...${NC}"
    chmod +x kali/install-tools.sh
    ./kali/install-tools.sh

    echo -e "\n${YELLOW}[2/6] Setting up XFCE Desktop keybindings...${NC}"
    chmod +x kali/setup-xfce-keybinds.sh
    ./kali/setup-xfce-keybinds.sh

elif [ "${OS}" = "parrot" ]; then
    echo -e "\n${YELLOW}[1/6] Installing Parrot OS packages via APT...${NC}"
    sudo apt-get update
    sudo apt-get install -y fish kitty stow starship zoxide eza gnupg wget curl nvim tmux fzf fd-find keyd
    
    # Create fd symlink for fd-find
    if [ ! -f /usr/local/bin/fd ] && command -v fdfind &>/dev/null; then
        sudo ln -s /usr/bin/fdfind /usr/local/bin/fd
    fi

    # Install mise repo and packages
    echo -e "\n${YELLOW}[2/6] Setting up Mise tool manager...${NC}"
    sudo install -dm 755 /etc/apt/keyrings
    wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
    sudo apt-get update
    sudo apt-get install -y mise
fi

# 3. Download Shared Binaries (Sesh & Tmux Plugin Manager)
if ! command -v sesh &> /dev/null; then
    echo -e "\n${YELLOW}[3/6] Installing Sesh terminal assistant...${NC}"
    LATEST_SESH_URL=$(curl -s https://api.github.com/repos/joshmedeski/sesh/releases/latest | grep "browser_download_url" | grep "Linux_x86_64.tar.gz" | cut -d '"' -f 4)
    curl -L -o /tmp/sesh.tar.gz "${LATEST_SESH_URL}"
    tar -xzf /tmp/sesh.tar.gz -C /tmp
    sudo mv /tmp/sesh /usr/local/bin/
    rm -f /tmp/sesh.tar.gz
    echo -e "${GREEN}Sesh installed successfully!${NC}"
fi

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo -e "\n${YELLOW}Installing Tmux Plugin Manager (TPM)...${NC}"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# 4. Clean up conflicting config paths to prevent Stow linking errors
remove_if_real() {
    local path="$1"
    if [ -L "$path" ]; then
        echo "  - Removing existing symlink $path..."
        rm -f "$path"
    elif [ -e "$path" ]; then
        echo "  - Backing up existing folder/file $path..."
        local backup_path="${path}.bak.$(date +%s)"
        mv "$path" "$backup_path" 2>/dev/null || rm -rf "$path"
    fi
}

echo -e "\n${YELLOW}[4/6] Preparing user configuration directories...${NC}"
remove_if_real "$HOME/.config/fish"
remove_if_real "$HOME/.config/nvim"
remove_if_real "$HOME/.config/tmux"
remove_if_real "$HOME/.config/kitty"

if [ "${OS}" = "fedora" ]; then
    remove_if_real "$HOME/.config/niri"
    remove_if_real "$HOME/.config/noctalia"
    remove_if_real "$HOME/.config/scripts"
    remove_if_real "$HOME/.config/sway"
    remove_if_real "$HOME/.config/waybar"
elif [ "${OS}" = "kali" ]; then
    remove_if_real "$HOME/.config/alacritty"
    remove_if_real "$HOME/.config/starship.toml"
fi

# 5. Link configurations using Stow
echo -e "\n${YELLOW}[5/6] Linking configuration profiles via Stow...${NC}"

# Link common configurations
stow -d "${DOTFILES_DIR}/common" -t "$HOME" fish kitty nvim tmux

# Link keyd configuration system-wide
echo -e "Deploying Keyd keyboard configuration..."
if [ -L "/etc/keyd" ]; then
    sudo rm -f /etc/keyd
fi
sudo mkdir -p /etc/keyd
sudo ln -sf "${DOTFILES_DIR}/common/keyd/etc/keyd/default.conf" /etc/keyd/default.conf
sudo systemctl enable --now keyd.service

if [ "${OS}" = "fedora" ]; then
    echo -e "Linking Fedora configurations..."
    stow -d "${DOTFILES_DIR}/fedora" -t "$HOME" niri noctalia scripts sway waybar swappy

    # Deploy GRUB configuration
    echo -e "Deploying GRUB boot configuration..."
    sudo cp "${DOTFILES_DIR}/fedora/grub/etc/default/grub" /etc/default/grub
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg

    # Configure DNS-over-TLS globally via systemd-resolved
    echo -e "Configuring systemd-resolved for Cloudflare DNS..."
    sudo tee /etc/systemd/resolved.conf > /dev/null <<EOF
[Resolve]
DNS=1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001
FallbackDNS=8.8.8.8 8.8.4.4
Domains=~.
DNSOverTLS=yes
EOF
    sudo chmod 644 /etc/systemd/resolved.conf
    sudo chown root:root /etc/systemd/resolved.conf
    if command -v restorecon &> /dev/null; then
        sudo restorecon -v /etc/systemd/resolved.conf
    fi
    echo -e "Restarting systemd-resolved..."
    sudo systemctl restart systemd-resolved

elif [ "${OS}" = "kali" ]; then
    echo -e "Linking Kali configurations..."
    stow -d "${DOTFILES_DIR}/kali" -t "$HOME" alacritty starship
    
    echo -e "Enabling Avahi daemon for mDNS resolution..."
    sudo systemctl enable --now avahi-daemon

    # Setup SSH authorized keys
    echo -e "Configuring SSH authorized keys..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    touch "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"
    SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFxkC9AWoLNhjeaDXB/pE7iK1cYrpyfMds8r0OAbesFT"
    if ! grep -qF "$SSH_KEY" "$HOME/.ssh/authorized_keys"; then
        echo "$SSH_KEY" >> "$HOME/.ssh/authorized_keys"
        echo "  - Added public key to authorized_keys"
    fi

elif [ "${OS}" = "parrot" ]; then
    echo -e "Linking Parrot OS configurations..."
    stow -d "${DOTFILES_DIR}/common" -t "$HOME" fish kitty nvim tmux
    if [ -d "${DOTFILES_DIR}/parrot" ]; then
        stow -d "${DOTFILES_DIR}" -t "$HOME" parrot
    fi

    # Setup SSH authorized keys
    echo -e "Configuring SSH authorized keys..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    touch "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"
    SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFxkC9AWoLNhjeaDXB/pE7iK1cYrpyfMds8r0OAbesFT"
    if ! grep -qF "$SSH_KEY" "$HOME/.ssh/authorized_keys"; then
        echo "$SSH_KEY" >> "$HOME/.ssh/authorized_keys"
        echo "  - Added public key to authorized_keys"
    fi
fi


# 6. Change default shell to Fish safely
FISH_PATH=$(which fish 2>/dev/null || echo "/usr/bin/fish")
if [ -f "$FISH_PATH" ]; then
    if ! grep -qxF "$FISH_PATH" /etc/shells; then
        echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
    fi
    if [ "$FISH_PATH" = "/usr/bin/fish" ] && [ -f "/bin/fish" ] && ! grep -qxF "/bin/fish" /etc/shells; then
        echo "/bin/fish" | sudo tee -a /etc/shells > /dev/null
    fi
    if [ "${SHELL:-}" != "$FISH_PATH" ]; then
        echo -e "\n${YELLOW}[6/6] Changing default shell to Fish...${NC}"
        chsh -s "$FISH_PATH"
    fi
fi

# Finalize Neovim plugins
echo -e "\n${YELLOW}Bootstrapping Neovim plugins...${NC}"
nvim --headless "+Lazy! sync" +qa

echo -e "\n${GREEN}===============================================${NC}"
echo -e "${GREEN}      Unified Setup Completed Successfully!     ${NC}"
echo -e "${GREEN}===============================================${NC}"
