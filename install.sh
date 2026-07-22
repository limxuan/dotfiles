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
        helium-bin wiremix neovim btop iwd obs-studio

    echo -e "\n${YELLOW}Installing Bitwarden via Flatpak...${NC}"
    if ! command -v flatpak &>/dev/null; then
        sudo dnf install -y flatpak
    fi
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak install -y flathub com.bitwarden.desktop

    echo -e "\n${YELLOW}Installing Snipaste...${NC}"
    if ! command -v Snipaste &>/dev/null; then
        sudo curl -L -o /usr/local/bin/Snipaste https://dl.snipaste.com/linux
        sudo chmod +x /usr/local/bin/Snipaste
    fi

    # Install OpenJDK if not present (needed for Burp Suite)
    if ! command -v java &>/dev/null; then
        echo -e "Installing OpenJDK for Burp Suite..."
        sudo dnf install -y java-17-openjdk
    fi

    # Install Burp Suite Community Edition (Mandatory)
    echo -e "\n${YELLOW}Installing Burp Suite Community Edition...${NC}"
    if [ ! -f "/opt/BurpSuiteCommunity/BurpSuiteCommunity" ]; then
        curl -L -o /tmp/burpsuite_installer.sh "https://portswigger.net/burp/releases/startdownload?product=community&version=&type=Linux"
        chmod +x /tmp/burpsuite_installer.sh
        sudo /tmp/burpsuite_installer.sh -q
        rm -f /tmp/burpsuite_installer.sh

        # Register desktop entry in system applications so it appears in launchers
        if [ -f "/opt/BurpSuiteCommunity/Burp Suite Community Edition.desktop" ]; then
            sudo cp "/opt/BurpSuiteCommunity/Burp Suite Community Edition.desktop" /usr/share/applications/
            sudo chmod 644 "/usr/share/applications/Burp Suite Community Edition.desktop"
            if command -v update-desktop-database &>/dev/null; then
                sudo update-desktop-database /usr/share/applications/
            fi
        fi

        # Create system-wide symlink for the command-line
        sudo ln -sf /opt/BurpSuiteCommunity/BurpSuiteCommunity /usr/local/bin/burpsuite

        # Configure Burp Suite to use Dark Mode by default
        mkdir -p "$HOME/.BurpSuite"
        cat > "$HOME/.BurpSuite/UserConfigCommunity.json" << 'EOF'
{
  "user_options": {
    "user_interface": {
      "look_and_feel": "Dark"
    }
  }
}
EOF
    fi

    # Install NSS tools if not present (needed for certutil)
    if ! command -v certutil &>/dev/null; then
        echo -e "Installing NSS tools for certificate management..."
        sudo dnf install -y nss-tools
    fi

    # Export and import Burp CA certificate if not already present in the database
    if ! { command -v certutil &>/dev/null && certutil -d sql:"$HOME/.pki/nssdb" -L -n "PortSwigger CA" &>/dev/null; }; then
        echo -e "Exporting and importing Burp Suite CA Certificate..."
        BURP_JAR=$(find /opt/BurpSuiteCommunity/ -maxdepth 1 -name "*.jar" 2>/dev/null | head -n 1)
        if [ -n "${BURP_JAR}" ]; then
            # Launch Burp Suite headlessly in the background, automatically accepting EULA
            yes y | java -Djava.awt.headless=true -jar "${BURP_JAR}" --use-defaults &>/dev/null &
            BURP_PID=$!

            # Wait for the proxy listener to start and serve the cert
            echo "Waiting for Burp Suite proxy to start..."
            for i in {1..15}; do
                if curl -s http://127.0.0.1:8080/cert -o /tmp/burp_cert.der &>/dev/null; then
                    echo "Burp Suite CA certificate downloaded successfully."
                    break
                fi
                sleep 1
            done

            # Terminate Burp Suite background process
            kill "${BURP_PID}" 2>/dev/null || true

            # Import the certificate into the Helium / Chromium NSS database
            if [ -f /tmp/burp_cert.der ]; then
                # Initialize nssdb if not present
                mkdir -p "$HOME/.pki/nssdb"
                if [ ! -f "$HOME/.pki/nssdb/cert9.db" ]; then
                    certutil -N -d sql:"$HOME/.pki/nssdb" --empty-password
                fi

                # Add certificate to the database
                certutil -d sql:"$HOME/.pki/nssdb" -A -t "TC,," -n "PortSwigger CA" -i /tmp/burp_cert.der
                echo "Burp Suite CA certificate successfully imported into Helium/Chromium NSS database."
                rm -f /tmp/burp_cert.der
            else
                echo "Warning: Failed to fetch Burp Suite CA certificate."
            fi
        else
            echo "Warning: Could not find Burp Suite jar file under /opt/BurpSuiteCommunity."
        fi
    else
        echo "Burp Suite CA certificate is already trusted in the Helium/Chromium database. Skipping..."
    fi

    # Optional package selection menu
    echo -e "\n${YELLOW}Select optional packages (y/n each):${NC}"
    INSTALL_ANTIGRAVITY=""
    INSTALL_OPENCODE=""
    INSTALL_CODE=""
    if ! command -v agy &>/dev/null; then
        read -rp "  Install Antigravity CLI (agy)? [y/N] " INSTALL_ANTIGRAVITY
    else
        echo "  Antigravity CLI (agy) is already installed. Skipping..."
    fi
    if ! command -v opencode &>/dev/null; then
        read -rp "  Install opencode (AI coding assistant)? [y/N] " INSTALL_OPENCODE
    else
        echo "  opencode (AI coding assistant) is already installed. Skipping..."
    fi
    if ! command -v code &>/dev/null; then
        read -rp "  Install Visual Studio Code? [y/N] " INSTALL_CODE
    else
        echo "  Visual Studio Code is already installed. Skipping..."
    fi
    for pkg in antigravity opencode code; do
            var="INSTALL_$(echo "$pkg" | tr '[:lower:]' '[:upper:]')"
            [ "${!var}" = "y" ] || [ "${!var}" = "Y" ] || [ "${!var}" = "yes" ] || continue
            case "$pkg" in
                antigravity)
                    echo -e "${GREEN}  Installing Antigravity CLI (agy)...${NC}"
                    if ! command -v agy &>/dev/null; then
                        curl -fsSL https://antigravity.google/cli/install.sh | bash
                    fi
                    ;;
                opencode)
                    echo -e "${GREEN}  Installing opencode...${NC}"
                    if ! command -v opencode &>/dev/null; then
                        curl -fsSL https://opencode.ai/install | bash
                    fi
                    ;;
                code)
                    echo -e "${GREEN}  Installing Visual Studio Code...${NC}"
                    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
                    sudo tee /etc/yum.repos.d/vscode.repo > /dev/null << 'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
                    sudo dnf install -y code
                    ;;
            esac
        done

elif [ "${OS}" = "kali" ]; then
    echo -e "\n${YELLOW}[1/6] Running Kali tools installer...${NC}"
    chmod +x kali/install-tools.sh
    ./kali/install-tools.sh

    echo -e "\n${YELLOW}[2/6] Setting up XFCE Desktop keybindings...${NC}"
    chmod +x kali/setup-xfce-keybinds.sh
    ./kali/setup-xfce-keybinds.sh

elif [ "${OS}" = "parrot" ]; then
    echo -e "\n${YELLOW}[1/6] Running Parrot OS tools installer...${NC}"
    chmod +x parrot/install-tools.sh
    ./parrot/install-tools.sh

    echo -e "\n${YELLOW}[2/6] Setting up MATE Desktop keybindings...${NC}"
    chmod +x parrot/setup-mate-keybinds.sh
    ./parrot/setup-mate-keybinds.sh
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

# 3b. Install Fedora-specific TUI apps (Impala & Bluetui) and configure iwd
if [ "${OS}" = "fedora" ]; then
    if ! command -v impala &> /dev/null; then
        echo -e "\n${YELLOW}Installing Impala WiFi TUI manager...${NC}"
        LATEST_IMPALA_URL=$(curl -s https://api.github.com/repos/pythops/impala/releases/latest | grep "browser_download_url" | grep "x86_64-unknown-linux-musl" | cut -d '"' -f 4)
        mkdir -p "$HOME/.local/bin"
        curl -L -o "$HOME/.local/bin/impala" "${LATEST_IMPALA_URL}"
        chmod +x "$HOME/.local/bin/impala"
        echo -e "${GREEN}Impala installed successfully!${NC}"
    fi

    # Configure NetworkManager to use iwd backend for Impala if not already set
    if [ ! -f /etc/NetworkManager/conf.d/iwd.conf ] || ! grep -q "wifi.backend=iwd" /etc/NetworkManager/conf.d/iwd.conf 2>/dev/null; then
        echo -e "\n${YELLOW}Configuring NetworkManager with iwd backend for Impala...${NC}"
        sudo mkdir -p /etc/NetworkManager/conf.d
        sudo tee /etc/NetworkManager/conf.d/iwd.conf > /dev/null << 'IWDCONF'
[device]
wifi.backend=iwd
IWDCONF
        echo -e "${GREEN}NetworkManager configured to use iwd backend!${NC}"
    fi

    # Configure iwd to enable built-in network configuration (DHCP client) and systemd name resolution
    echo -e "\n${YELLOW}Configuring iwd with built-in network configuration (DHCP)...${NC}"
    sudo mkdir -p /etc/iwd
    sudo tee /etc/iwd/main.conf > /dev/null << 'IWDMAIN'
[General]
EnableNetworkConfiguration=true

[Network]
NameResolvingService=systemd
IWDMAIN

    # Disable NetworkManager and wpa_supplicant, and restart iwd to ensure impala works on first try
    echo -e "\n${YELLOW}Disabling NetworkManager/wpa_supplicant and restarting iwd...${NC}"
    sudo systemctl disable --now NetworkManager wpa_supplicant 2>/dev/null || true
    sudo systemctl mask NetworkManager wpa_supplicant 2>/dev/null || true
    sudo systemctl enable --now iwd 2>/dev/null || true
    sudo systemctl restart iwd 2>/dev/null || true

    if ! command -v bluetui &> /dev/null; then
        echo -e "\n${YELLOW}Installing Bluetui Bluetooth TUI manager...${NC}"
        LATEST_BLUETUI_URL=$(curl -s https://api.github.com/repos/pythops/bluetui/releases/latest | grep "browser_download_url" | grep "x86_64-linux-musl" | cut -d '"' -f 4)
        mkdir -p "$HOME/.local/bin"
        curl -L -o "$HOME/.local/bin/bluetui" "${LATEST_BLUETUI_URL}"
        chmod +x "$HOME/.local/bin/bluetui"
        echo -e "${GREEN}Bluetui installed successfully!${NC}"
    fi
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
elif [ "${OS}" = "kali" ] || [ "${OS}" = "parrot" ]; then
    remove_if_real "$HOME/.config/starship.toml"
    remove_if_real "$HOME/.config/scripts"
fi

# 5. Link configurations using Stow
echo -e "\n${YELLOW}[5/6] Linking configuration profiles via Stow...${NC}"

# Link common configurations
stow -d "${DOTFILES_DIR}/common" -t "$HOME" fish kitty nvim tmux

# Link keyd configuration system-wide
if [ "${OS}" = "fedora" ]; then
    echo -e "Deploying Keyd keyboard configuration..."
    if [ -L "/etc/keyd" ]; then
        sudo rm -f /etc/keyd
    fi
    sudo mkdir -p /etc/keyd
    sudo ln -sf "${DOTFILES_DIR}/common/keyd/etc/keyd/default.conf" /etc/keyd/default.conf
    sudo systemctl enable --now keyd.service
fi

if [ "${OS}" = "fedora" ]; then
    echo -e "Linking Fedora configurations..."
    stow -d "${DOTFILES_DIR}/fedora" -t "$HOME" niri noctalia scripts sway waybar swappy applications

    # Deploy GRUB configuration
    echo -e "Deploying GRUB boot configuration..."
    sudo cp "${DOTFILES_DIR}/fedora/grub/etc/default/grub" /etc/default/grub
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg

    # Set GTK dark mode for apps (Nautilus, GTK dialogs, etc.)
    echo -e "Configuring GTK dark mode..."
    mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
    cat > "$HOME/.config/gtk-3.0/settings.ini" << 'GTKEOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
GTKEOF
    cat > "$HOME/.config/gtk-4.0/settings.ini" << 'GTKEOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
GTKEOF
    # Also apply via gsettings (affects some apps directly)
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark 2>/dev/null || true

    # Configure Helium Browser (vertical tabs & extensions)
    echo -e "Configuring Helium Browser..."

    # Clean up obsolete policy files and folders
    sudo rm -f /etc/chromium/policies/managed/helium_extensions.json
    sudo rm -f /etc/helium/policies/managed/helium_extensions.json
    rm -rf "$HOME/.config/net.imput.helium/External Extensions"

    # Helper function to download and install a Chrome extension into the profile
    install_helium_extension() {
        local ext_id="$1"
        local ext_dir="$HOME/.config/net.imput.helium/unpacked-extensions/${ext_id}"

        echo -e "  Installing extension: ${ext_id}..."
        local crx_file="/tmp/${ext_id}.crx"
        curl -L -s -o "${crx_file}" "https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx2,crx3&prodversion=123.0&x=id%3D${ext_id}%26installsource%3Dondemand%26uc"

        local temp_dir="/tmp/${ext_id}_temp"
        rm -rf "${temp_dir}"
        mkdir -p "${temp_dir}"
        unzip -q -o "${crx_file}" -d "${temp_dir}" 2>/dev/null || true

        local version=$(python3 -c "import json; print(json.load(open('${temp_dir}/manifest.json')).get('version', '1.0'))" 2>/dev/null || echo "1.0")
        local final_dir="${ext_dir}/${version}_0"

        rm -rf "${final_dir}"
        mkdir -p "${final_dir}"
        cp -r "${temp_dir}"/* "${final_dir}/"
        rm -rf "${temp_dir}" "${crx_file}"

        echo "${version}"
    }

    # Install extensions locally
    # SponsorBlock: mnjggcdmjocbbbhaepdhchncahnbgone
    # Vimium C: hfjbmagddngcpeloejdejnfgbamkjaeg
    # Dark Reader: eimadpbcbfnmbkopoojfekhnkhdbieeh
    # FoxyProxy: gcknhkkoolaabfmlnjonogaaifnjlfnp
    # Wappalyzer: gppongmhjkpfnbhagpmjfkannfbllamg
    # Bitwarden: nngceckbapebfimnlniiiahkandclblb

    SPONSORBLOCK_VER=$(install_helium_extension "mnjggcdmjocbbbhaepdhchncahnbgone")
    VIMIUMC_VER=$(install_helium_extension "hfjbmagddngcpeloejdejnfgbamkjaeg")
    DARKREADER_VER=$(install_helium_extension "eimadpbcbfnmbkopoojfekhnkhdbieeh")
    FOXYPROXY_VER=$(install_helium_extension "gcknhkkoolaabfmlnjonogaaifnjlfnp")
    WAPPALYZER_VER=$(install_helium_extension "gppongmhjkpfnbhagpmjfkannfbllamg")
    BITWARDEN_VER=$(install_helium_extension "nngceckbapebfimnlniiiahkandclblb")

    # Set vertical tabs and configure extensions in Helium preferences via Python
    python3 << 'EOF'
import json, os

path = os.path.expanduser('~/.config/net.imput.helium/Default/Preferences')
os.makedirs(os.path.dirname(path), exist_ok=True)
data = {}
if os.path.exists(path):
    try:
        with open(path, 'r') as f:
            data = json.load(f)
    except Exception:
        pass

if 'helium' not in data:
    data['helium'] = {}
if 'browser' not in data['helium']:
    data['helium']['browser'] = {}
data['helium']['browser']['layout'] = 2

# Clean up any obsolete registered extension settings to prevent Chromium security integrity checks from deleting them
if 'extensions' in data and 'settings' in data['extensions']:
    for ext_id in ["mnjggcdmjocbbbhaepdhchncahnbgone", "hfjbmagddngcpeloejdejnfgbamkjaeg", "eimadpbcbfnmbkopoojfekhnkhdbieeh", "gcknhkkoolaabfmlnjonogaaifnjlfnp", "gppongmhjkpfnbhagpmjfkannfbllamg", "nngceckbapebfimnlniiiahkandclblb"]:
        data['extensions']['settings'].pop(ext_id, None)

try:
    with open(path, 'w') as f:
        json.dump(data, f, indent=2)
except Exception as e:
    print(f"Failed to save Helium preferences: {e}")
EOF

    # Create system-wide wrapper script for Helium to load extensions automatically
    echo -e "Creating system-wide Helium wrapper script..."
    sudo tee /usr/local/bin/helium > /dev/null << 'WRAPPEREOF'
#!/usr/bin/env bash
EXT_PATHS=()
for ext_id in mnjggcdmjocbbbhaepdhchncahnbgone hfjbmagddngcpeloejdejnfgbamkjaeg eimadpbcbfnmbkopoojfekhnkhdbieeh gcknhkkoolaabfmlnjonogaaifnjlfnp gppongmhjkpfnbhagpmjfkannfbllamg nngceckbapebfimnlniiiahkandclblb; do
    ext_path=$(find "$HOME/.config/net.imput.helium/unpacked-extensions/${ext_id}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -n 1)
    if [ -n "${ext_path}" ]; then
        EXT_PATHS+=("${ext_path}")
    fi
done

if [ ${#EXT_PATHS[@]} -gt 0 ]; then
    EXT_LIST=$(IFS=,; echo "${EXT_PATHS[*]}")
    exec /usr/bin/helium --force-dark-mode --enable-features=WebUIDarkMode --load-extension="${EXT_LIST}" "$@"
else
    exec /usr/bin/helium --force-dark-mode --enable-features=WebUIDarkMode "$@"
fi
WRAPPEREOF
    sudo chmod +x /usr/local/bin/helium

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
    stow -d "${DOTFILES_DIR}/kali" -t "$HOME" starship
    
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
    stow -d "${DOTFILES_DIR}/parrot" -t "$HOME" starship

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
        sudo chsh -s "$FISH_PATH" "$USER"
    fi
fi

# Finalize Neovim plugins
echo -e "\n${YELLOW}Bootstrapping Neovim plugins...${NC}"
nvim --headless "+Lazy! sync" +qa

echo -e "\n${GREEN}===============================================${NC}"
echo -e "${GREEN}      Unified Setup Completed Successfully!     ${NC}"
echo -e "${GREEN}===============================================${NC}"
