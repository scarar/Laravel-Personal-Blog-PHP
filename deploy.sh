#!/bin/bash

# Exit on error
set -e

# Configuration
APP_DIR="$(pwd)"  # Use current directory
BACKUP_DIR="/var/backups/blog"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Starting deployment...${NC}"

# Create backup
echo "Creating backup..."
mkdir -p "$BACKUP_DIR"
if [ -d "$APP_DIR" ]; then
    tar -czf "$BACKUP_DIR/backup_$TIMESTAMP.tar.gz" -C "$APP_DIR" .
fi

# Pull latest changes
echo "Pulling latest changes..."
cd "$APP_DIR"
git pull origin main

# Install/update dependencies
echo "Installing dependencies..."
sudo composer install --optimize-autoloader --no-dev

# Environment setup
echo "Setting up environment..."
if [ ! -f .env ]; then
    sudo cp .env.example .env
    sudo php artisan key:generate
fi

# Clear caches
echo "Clearing caches..."
sudo php artisan cache:clear
sudo php artisan config:clear
sudo php artisan route:clear
sudo php artisan view:clear

# Rebuild caches
echo "Rebuilding caches..."
sudo php artisan config:cache
sudo php artisan route:cache
sudo php artisan view:cache

# Run migrations
echo "Running migrations..."
sudo php artisan migrate --force

# Create storage link if not exists
if [ ! -L public/storage ]; then
    echo "Creating storage link..."
    sudo php artisan storage:link
fi

# Set permissions
echo "Setting permissions..."
sudo chown -R www-data:www-data .
sudo chown -R $USER:$USER .
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache

# Restart services
echo "Restarting services..."
sudo systemctl restart php8.4-fpm
sudo systemctl restart nginx

echo -e "${GREEN}Deployment completed successfully!${NC}"