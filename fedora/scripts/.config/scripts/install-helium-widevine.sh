#!/usr/bin/env bash

# Install/Update Widevine DRM Content Decryption Module for Helium Browser on Fedora.
# Extracts Widevine from the official Google Chrome package.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}        Helium Widevine DRM Installer          ${NC}"
echo -e "${BLUE}===============================================${NC}"

TMP_DIR="/tmp/widevine_extract"
HELIUM_DIR="/opt/helium"

# Verify Helium installation
if [ ! -d "${HELIUM_DIR}" ]; then
    echo -e "${RED}Error: Helium browser installation not found at ${HELIUM_DIR}.${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/4] Preparing temporary extraction directory...${NC}"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"
cd "${TMP_DIR}"

echo -e "\n${YELLOW}[2/4] Downloading Google Chrome stable package...${NC}"
wget -q --show-progress -c https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

echo -e "\n${YELLOW}[3/4] Extracting Widevine CDM components...${NC}"
ar x google-chrome-stable_current_amd64.deb
tar -xf data.tar.xz

if [ ! -d "opt/google/chrome/WidevineCdm" ]; then
    echo -e "${RED}Error: WidevineCdm directory not found in Chrome package.${NC}"
    rm -rf "${TMP_DIR}"
    exit 1
fi

echo -e "\n${YELLOW}[4/4] Installing Widevine to Helium...${NC}"
sudo rm -rf "${HELIUM_DIR}/WidevineCdm"
sudo cp -r opt/google/chrome/WidevineCdm "${HELIUM_DIR}/"

# Clean up
cd /
rm -rf "${TMP_DIR}"

echo -e "\n${GREEN}===============================================${NC}"
echo -e "${GREEN}  Widevine DRM Installed Successfully for Helium!${NC}"
echo -e "${GREEN}  Please restart your Helium browser to apply.  ${NC}"
echo -e "${GREEN}===============================================${NC}"
