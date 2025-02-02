#!/bin/bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print status messages
print_status() {
    echo -e "${YELLOW}[*] $1${NC}"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}[+] $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}[-] $1${NC}"
    exit 1
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root"
fi

print_status "Starting Tor setup..."

# Install Tor
print_status "Installing Tor..."
apt-get update
apt-get install -y tor

# Backup original torrc
if [ -f "/etc/tor/torrc" ]; then
    print_status "Backing up original torrc..."
    cp /etc/tor/torrc /etc/tor/torrc.backup
fi

# Configure Tor
print_status "Configuring Tor..."
cat > /etc/tor/torrc << EOF
# Basic Tor configuration
RunAsDaemon 1
DataDirectory /var/lib/tor

# Hidden service configuration
HiddenServiceDir /var/lib/tor/hidden_service/
HiddenServicePort 80 127.0.0.1:80

# Security settings
SafeLogging 1
EOF

# Create hidden service directory if it doesn't exist
if [ ! -d "/var/lib/tor/hidden_service/" ]; then
    print_status "Creating hidden service directory..."
    mkdir -p /var/lib/tor/hidden_service/
    chown -R debian-tor:debian-tor /var/lib/tor/hidden_service/
    chmod 700 /var/lib/tor/hidden_service/
fi

# Restart Tor service
print_status "Restarting Tor service..."
systemctl restart tor

# Wait for the hidden service to be ready
print_status "Waiting for hidden service to be ready..."
sleep 5

# Display the .onion address
if [ -f "/var/lib/tor/hidden_service/hostname" ]; then
    ONION_ADDRESS=$(cat /var/lib/tor/hidden_service/hostname)
    print_success "Tor hidden service is ready!"
    echo -e "${GREEN}Your .onion address is: ${ONION_ADDRESS}${NC}"
else
    print_error "Failed to create hidden service"
fi

print_status "Verifying Tor service status..."
systemctl status tor --no-pager

print_success "Tor setup completed successfully!"
echo -e "${YELLOW}Important notes:${NC}"
echo "1. Make sure your web server is configured to listen on 127.0.0.1:80"
echo "2. Keep your .onion address private if you want to maintain anonymity"
echo "3. Consider enabling additional security measures in torrc"
echo "4. Backup /var/lib/tor/hidden_service/hostname and private key"