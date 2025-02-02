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

print_status "Starting update process..."

# Create backup before update
print_status "Creating backup before update..."
./scripts/backup.sh || print_error "Backup failed"

# Pull latest changes
print_status "Pulling latest changes from repository..."
git pull origin main || print_error "Failed to pull latest changes"

# Install/update PHP dependencies
print_status "Updating PHP dependencies..."
composer install --no-dev --optimize-autoloader || print_error "Failed to update PHP dependencies"

# Install/update Node.js dependencies
print_status "Updating Node.js dependencies..."
npm install || print_error "Failed to update Node.js dependencies"

# Build frontend assets
print_status "Building frontend assets..."
npm run build || print_error "Failed to build frontend assets"

# Run database migrations
print_status "Running database migrations..."
php artisan migrate --force || print_error "Failed to run migrations"

# Clear and rebuild cache
print_status "Optimizing Laravel..."
php artisan optimize:clear
php artisan optimize
php artisan view:cache
php artisan config:cache
php artisan route:cache

# Fix permissions
print_status "Fixing permissions..."
./scripts/fix-permissions.sh || print_error "Failed to fix permissions"

print_success "Update completed successfully!"
echo -e "${YELLOW}Note: Check the application to ensure everything is working correctly${NC}"