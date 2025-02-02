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

print_status "Starting permission fix..."

# Set ownership
print_status "Setting ownership to www-data..."
chown -R www-data:www-data .

# Set directory permissions
print_status "Setting directory permissions..."
find . -type d -exec chmod 755 {} \;

# Set file permissions
print_status "Setting file permissions..."
find . -type f -exec chmod 644 {} \;

# Set specific permissions for writable directories
print_status "Setting specific permissions for writable directories..."
chmod -R 775 storage
chmod -R 775 bootstrap/cache
chmod -R 775 public/uploads

# Set specific permissions for SQLite database
if [ -f "database/database.sqlite" ]; then
    print_status "Setting SQLite database permissions..."
    chmod 775 database/database.sqlite
    chown www-data:www-data database/database.sqlite
fi

# Make scripts executable
print_status "Making scripts executable..."
chmod +x scripts/*.sh
chmod +x artisan

print_success "Permissions have been fixed successfully!"