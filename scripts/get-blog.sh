#!/bin/bash

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Please run with sudo:"
    echo "sudo bash $0"
    exit 1
fi

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

clear
echo -e "${BLUE}Laravel Blog - One Command Installer${NC}"
echo "================================"
echo

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Installing git...${NC}"
    sudo apt-get update
    sudo apt-get install -y git
fi

# Ask for installation directory
echo -e "${GREEN}Where would you like to install the blog?${NC}"
echo "1) Current directory ($(pwd))"
echo "2) Create new directory here"
echo "3) Specify custom path"
read -p "Choose [1-3]: " DIR_CHOICE

case $DIR_CHOICE in
    2)
        read -p "Enter directory name: " DIR_NAME
        sudo mkdir -p "$DIR_NAME"
        INSTALL_DIR="$(pwd)/$DIR_NAME"
        ;;
    3)
        read -p "Enter full path: " CUSTOM_PATH
        sudo mkdir -p "$CUSTOM_PATH"
        INSTALL_DIR="$CUSTOM_PATH"
        ;;
    *)
        INSTALL_DIR="$(pwd)"
        ;;
esac

# Clone the repository
echo -e "\n${BLUE}Cloning repository...${NC}"
sudo git clone https://github.com/scarar/Laravel-Personal-Blog-PHP.git "$INSTALL_DIR"
sudo chown -R $USER:$USER "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Make installer executable and run it
chmod +x scripts/install.sh
./scripts/install.sh