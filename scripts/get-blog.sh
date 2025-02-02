#!/bin/bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print status messages
print_status() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

# Function to check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check PHP version
    if ! command -v php &> /dev/null; then
        print_status "Installing PHP and extensions..."
        sudo apt-get update
        sudo apt-get install -y software-properties-common
        sudo add-apt-repository -y ppa:ondrej/php
        sudo apt-get update
        sudo apt-get install -y php8.2 php8.2-cli php8.2-fpm php8.2-common php8.2-mysql \
            php8.2-zip php8.2-gd php8.2-mbstring php8.2-curl php8.2-xml php8.2-bcmath \
            php8.2-sqlite3 unzip
    fi
    
    PHP_VERSION=$(php -r "echo PHP_VERSION;")
    if [[ "$PHP_VERSION" < "8.2" ]]; then
        print_error "PHP version must be 8.2 or higher (current: $PHP_VERSION)"
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_status "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed"
    fi
    
    # Check Composer
    if ! command -v composer &> /dev/null; then
        print_status "Installing Composer..."
        curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
    fi
    
    # Check Nginx
    if ! command -v nginx &> /dev/null; then
        print_status "Installing Nginx..."
        sudo apt-get install -y nginx
    fi
    
    # Check git
    if ! command -v git &> /dev/null; then
        print_status "Installing git..."
        sudo apt-get install -y git
    fi
}

# Function to get deployment path
get_deployment_path() {
    clear
    echo -e "${BLUE}Laravel Blog - One Command Installer${NC}"
    echo "================================"
    echo
    
    echo -e "${GREEN}Where would you like to install the blog?${NC}"
    echo "1) Current directory ($(pwd))"
    echo "2) Create new directory here"
    echo "3) Specify custom path"
    read -p "Choose [1-3]: " choice
    
    case $choice in
        1)
            echo "$(pwd)"
            ;;
        2)
            read -p "Enter directory name: " dir_name
            mkdir -p "$dir_name"
            echo "$(pwd)/$dir_name"
            ;;
        3)
            read -p "Enter full path: " custom_path
            mkdir -p "$custom_path"
            echo "$custom_path"
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
}

# Main installation process
main() {
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then 
        print_error "Please run as root (sudo)"
    fi
    
    # Check requirements
    check_requirements
    
    # Get deployment path
    DEPLOY_PATH=$(get_deployment_path)
    
    # Clone repository
    print_status "Cloning repository..."
    git clone https://github.com/scarar/Laravel-Personal-Blog-PHP.git "$DEPLOY_PATH"
    cd "$DEPLOY_PATH"
    
    # Install PHP dependencies
    print_status "Installing PHP dependencies..."
    composer install --no-dev --optimize-autoloader
    
    # Install Node.js dependencies globally
    print_status "Installing Node.js dependencies..."
    sudo npm install -g vite
    npm install
    
    # Build assets
    print_status "Building assets for production..."
    export PATH="$DEPLOY_PATH/node_modules/.bin:$PATH"
    npm run build
    
    # Deploy to production directory
    print_status "Deploying to production directory..."
    mkdir -p public/build
    cp -r public/build/* public/
    
    # Clean up
    print_status "Cleaning up unnecessary files and directories..."
    rm -rf node_modules .git .gitattributes .gitignore
    
    # Configure web server
    print_status "Configuring web server..."
    read -p "Enter your domain name (e.g., myblog.com or onion address): " DOMAIN_NAME
    
    # Create Nginx configuration
    cat > /etc/nginx/sites-available/laravel-blog << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NAME;
    root $DEPLOY_PATH/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";

    index index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
        gzip_static on;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/laravel-blog /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Set permissions
    print_status "Setting permissions..."
    chown -R www-data:www-data .
    find . -type f -exec chmod 644 {} \;
    find . -type d -exec chmod 755 {} \;
    chmod -R 775 storage bootstrap/cache
    
    # Create SQLite database
    print_status "Setting up database..."
    touch database/database.sqlite
    chmod 775 database/database.sqlite
    chown www-data:www-data database/database.sqlite
    
    # Configure environment
    print_status "Configuring environment..."
    cp .env.example .env
    sed -i "s|APP_NAME=Laravel|APP_NAME=\"Personal Blog\"|g" .env
    sed -i "s|APP_DEBUG=true|APP_DEBUG=false|g" .env
    sed -i "s|APP_ENV=local|APP_ENV=production|g" .env
    sed -i "s|DB_CONNECTION=mysql|DB_CONNECTION=sqlite|g" .env
    sed -i "s|DB_DATABASE=laravel|DB_DATABASE=database/database.sqlite|g" .env
    
    # Generate key and optimize
    php artisan key:generate
    php artisan storage:link
    php artisan migrate --force
    php artisan optimize
    
    # Restart services
    print_status "Restarting services..."
    systemctl restart php8.2-fpm
    systemctl restart nginx
    
    print_success "Installation completed successfully!"
    echo -e "${GREEN}Your blog is now available at: http://$DOMAIN_NAME${NC}"
    echo -e "${YELLOW}Important notes:${NC}"
    echo "1. Set up SSL/TLS for production use"
    echo "2. Configure regular backups"
    echo "3. Keep the system updated"
    echo "4. Default database: SQLite"
    echo "5. Create admin user: php artisan make:admin"
}

# Run main installation
main