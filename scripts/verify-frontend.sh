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

print_status "Starting frontend verification..."

# Check required files exist
print_status "Checking required files..."

FILES_TO_CHECK=(
    "resources/css/app.css"
    "resources/js/app.js"
    "resources/js/bootstrap.js"
    "vite.config.js"
    "tailwind.config.js"
    "postcss.config.js"
    "package.json"
)

for file in "${FILES_TO_CHECK[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "Missing required file: $file"
    fi
done

print_success "All required files present"

# Check package.json dependencies
print_status "Checking package.json dependencies..."

REQUIRED_DEPS=(
    "@tailwindcss/forms"
    "@tailwindcss/typography"
    "alpinejs"
    "autoprefixer"
    "axios"
    "flowbite"
    "laravel-vite-plugin"
    "postcss"
    "sass"
    "tailwindcss"
    "vite"
)

for dep in "${REQUIRED_DEPS[@]}"; do
    if ! grep -q "\"$dep\":" package.json; then
        print_error "Missing required dependency: $dep"
    fi
done

print_success "All required dependencies present"

# Verify Tailwind configuration
print_status "Checking Tailwind configuration..."

if ! grep -q "@tailwindcss/typography" tailwind.config.js || \
   ! grep -q "@tailwindcss/forms" tailwind.config.js || \
   ! grep -q "flowbite/plugin" tailwind.config.js; then
    print_error "Missing required Tailwind plugins"
fi

print_success "Tailwind configuration verified"

# Test build process
print_status "Testing build process..."

# Clean any existing build
rm -rf public/build

# Run build
if ! npm run build; then
    print_error "Build process failed"
fi

# Verify build output
if [ ! -d "public/build" ] || [ ! -f "public/build/manifest.json" ]; then
    print_error "Build verification failed"
fi

print_success "Build process verified"

# Check for CSS classes
print_status "Checking for required CSS classes..."

REQUIRED_CLASSES=(
    "@tailwind"
    "prose"
    "form-input"
    "btn"
    "card"
    "alert"
    "nav-link"
    "table"
    "pagination"
)

for class in "${REQUIRED_CLASSES[@]}"; do
    if ! grep -q "$class" resources/css/app.css; then
        print_error "Missing required CSS class: $class"
    fi
done

print_success "All required CSS classes present"

# Check JavaScript functionality
print_status "Checking JavaScript functionality..."

REQUIRED_JS=(
    "Alpine"
    "flowbite"
    "flashMessage"
    "confirmAction"
    "validateForm"
)

for func in "${REQUIRED_JS[@]}"; do
    if ! grep -q "$func" resources/js/app.js; then
        print_error "Missing required JavaScript functionality: $func"
    fi
done

print_success "All required JavaScript functionality present"

print_success "Frontend verification completed successfully!"
echo -e "${YELLOW}Notes:${NC}"
echo "1. All required files are present"
echo "2. All dependencies are installed"
echo "3. Build process works correctly"
echo "4. Required CSS classes are defined"
echo "5. Required JavaScript functionality is present"