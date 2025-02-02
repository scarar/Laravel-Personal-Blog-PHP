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

print_status "Starting build process..."

# Create build directory
BUILD_DIR="build"
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

# Copy required files
print_status "Copying required files..."
cp -r app config database public resources routes storage tests vendor composer.json composer.lock package.json package-lock.json vite.config.js postcss.config.js tailwind.config.js artisan .env.example $BUILD_DIR/

# Create required directories
mkdir -p $BUILD_DIR/bootstrap/cache
mkdir -p $BUILD_DIR/storage/app/public
mkdir -p $BUILD_DIR/storage/framework/{cache,sessions,testing,views}
mkdir -p $BUILD_DIR/storage/logs

# Install PHP dependencies
print_status "Installing PHP dependencies..."
cd $BUILD_DIR
composer install --no-dev --optimize-autoloader

# Install Node.js dependencies and build assets
print_status "Installing Node.js dependencies and building assets..."
npm install
npm run build

# Remove development files
print_status "Removing development files..."
rm -rf node_modules
rm -rf tests
rm package.json package-lock.json
rm postcss.config.js tailwind.config.js vite.config.js

# Set proper permissions
print_status "Setting proper permissions..."
chown -R www-data:www-data .
find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;
chmod -R 775 storage bootstrap/cache

# Create SQLite database
print_status "Setting up SQLite database..."
touch database/database.sqlite
chmod 775 database/database.sqlite
chown www-data:www-data database/database.sqlite

# Create .env file
print_status "Creating environment file..."
cp .env.example .env
sed -i "s|APP_NAME=Laravel|APP_NAME=\"Personal Blog\"|g" .env
sed -i "s|APP_DEBUG=true|APP_DEBUG=false|g" .env
sed -i "s|APP_ENV=local|APP_ENV=production|g" .env
sed -i "s|DB_CONNECTION=mysql|DB_CONNECTION=sqlite|g" .env
sed -i "s|DB_DATABASE=laravel|DB_DATABASE=database/database.sqlite|g" .env

# Generate application key
print_status "Generating application key..."
php artisan key:generate

# Run migrations
print_status "Running migrations..."
php artisan migrate --force

# Create storage link
print_status "Creating storage link..."
php artisan storage:link

# Optimize Laravel
print_status "Optimizing Laravel..."
php artisan optimize
php artisan view:cache
php artisan config:cache
php artisan route:cache

print_success "Build completed successfully!"
echo -e "${GREEN}The optimized application is now in the '$BUILD_DIR' directory${NC}"