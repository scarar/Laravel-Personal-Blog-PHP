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

# Install Node.js dependencies
print_status "Installing Node.js dependencies..."
npm install

# Build frontend assets
print_status "Building frontend assets..."
export NODE_ENV=production
npm run build

# Verify build directory exists
if [ ! -d "public/build" ]; then
    mkdir -p public/build
fi

# Verify assets were built
if [ ! -f "public/build/manifest.json" ]; then
    print_error "Asset compilation failed. No manifest.json found."
fi

# Copy additional assets
print_status "Copying additional assets..."
if [ -d "resources/images" ]; then
    cp -r resources/images public/images
fi

# Optimize images if optipng is available
if command -v optipng &> /dev/null; then
    print_status "Optimizing images..."
    find public/images -type f -name "*.png" -exec optipng -o5 {} \;
fi

# Verify and clean up
print_status "Verifying asset build..."
if [ ! -d "public/build" ] || [ ! -f "public/build/manifest.json" ]; then
    print_error "Asset verification failed"
fi

# Remove source maps in production
find public/build -name "*.map" -delete

# Create .env file before optimization
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

# Create SQLite database
print_status "Setting up SQLite database..."
touch database/database.sqlite
chmod 775 database/database.sqlite

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

# Remove development files
print_status "Removing development files..."
rm -rf node_modules
rm -rf tests
rm package.json package-lock.json postcss.config.js tailwind.config.js vite.config.js

# Set proper permissions
print_status "Setting proper permissions..."
chown -R www-data:www-data .
find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;
chmod -R 775 storage bootstrap/cache
chmod 775 database/database.sqlite

print_success "Build completed successfully!"
echo -e "${GREEN}The optimized application is now in the '$BUILD_DIR' directory${NC}"
echo -e "${YELLOW}Important notes:${NC}"
echo "1. Frontend assets are in public/build/"
echo "2. Database file is at database/database.sqlite"
echo "3. Storage link has been created"
echo "4. All caches have been optimized"
echo "5. Permissions have been set correctly"