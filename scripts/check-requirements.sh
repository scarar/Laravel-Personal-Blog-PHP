#!/bin/bash

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
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check PHP version
check_php_version() {
    if command_exists php; then
        PHP_VERSION=$(php -r "echo PHP_VERSION;")
        if [[ "$PHP_VERSION" > "8.2" ]]; then
            print_success "PHP version $PHP_VERSION is installed (required: 8.2+)"
            return 0
        else
            print_error "PHP version $PHP_VERSION is installed but 8.2+ is required"
            return 1
        fi
    else
        print_error "PHP is not installed"
        return 1
    fi
}

# Function to check PHP extensions
check_php_extensions() {
    local MISSING_EXTENSIONS=()
    local REQUIRED_EXTENSIONS=(
        "bcmath"
        "ctype"
        "curl"
        "dom"
        "fileinfo"
        "json"
        "mbstring"
        "openssl"
        "pdo"
        "tokenizer"
        "xml"
        "sqlite3"
    )

    for ext in "${REQUIRED_EXTENSIONS[@]}"; do
        if php -m | grep -q "^$ext$"; then
            print_success "PHP extension $ext is installed"
        else
            print_error "PHP extension $ext is missing"
            MISSING_EXTENSIONS+=("$ext")
        fi
    done

    if [ ${#MISSING_EXTENSIONS[@]} -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Function to check Node.js version
check_nodejs() {
    if command_exists node; then
        NODE_VERSION=$(node -v)
        if [[ "$NODE_VERSION" > "v20" ]]; then
            print_success "Node.js $NODE_VERSION is installed (required: 20+)"
            return 0
        else
            print_error "Node.js $NODE_VERSION is installed but 20+ is required"
            return 1
        fi
    else
        print_error "Node.js is not installed"
        return 1
    fi
}

# Function to check npm
check_npm() {
    if command_exists npm; then
        NPM_VERSION=$(npm -v)
        print_success "npm $NPM_VERSION is installed"
        return 0
    else
        print_error "npm is not installed"
        return 1
    fi
}

# Function to check Composer
check_composer() {
    if command_exists composer; then
        COMPOSER_VERSION=$(composer --version | cut -d' ' -f3)
        print_success "Composer $COMPOSER_VERSION is installed"
        return 0
    else
        print_error "Composer is not installed"
        return 1
    fi
}

# Function to check web server
check_webserver() {
    if command_exists nginx; then
        NGINX_VERSION=$(nginx -v 2>&1 | cut -d'/' -f2)
        print_success "Nginx $NGINX_VERSION is installed"
        return 0
    else
        print_error "Nginx is not installed"
        return 1
    fi
}

# Function to check SQLite
check_sqlite() {
    if command_exists sqlite3; then
        SQLITE_VERSION=$(sqlite3 --version | cut -d' ' -f1)
        print_success "SQLite $SQLITE_VERSION is installed"
        return 0
    else
        print_error "SQLite is not installed"
        return 1
    fi
}

# Function to check directory permissions
check_permissions() {
    local WRITABLE_DIRS=(
        "storage"
        "storage/app"
        "storage/framework"
        "storage/logs"
        "bootstrap/cache"
    )

    for dir in "${WRITABLE_DIRS[@]}"; do
        if [ -d "$dir" ] && [ -w "$dir" ]; then
            print_success "Directory $dir is writable"
        else
            print_error "Directory $dir is not writable or doesn't exist"
            return 1
        fi
    done
    return 0
}

# Main check function
main() {
    print_status "Checking system requirements..."
    echo

    local ERROR_COUNT=0

    print_status "Checking PHP..."
    check_php_version || ((ERROR_COUNT++))
    echo

    print_status "Checking PHP extensions..."
    check_php_extensions || ((ERROR_COUNT++))
    echo

    print_status "Checking Node.js and npm..."
    check_nodejs || ((ERROR_COUNT++))
    check_npm || ((ERROR_COUNT++))
    echo

    print_status "Checking Composer..."
    check_composer || ((ERROR_COUNT++))
    echo

    print_status "Checking web server..."
    check_webserver || ((ERROR_COUNT++))
    echo

    print_status "Checking SQLite..."
    check_sqlite || ((ERROR_COUNT++))
    echo

    print_status "Checking directory permissions..."
    check_permissions || ((ERROR_COUNT++))
    echo

    if [ $ERROR_COUNT -eq 0 ]; then
        print_success "All requirements are met!"
        exit 0
    else
        print_error "Found $ERROR_COUNT requirement issues that need to be fixed"
        exit 1
    fi
}

# Run main function
main