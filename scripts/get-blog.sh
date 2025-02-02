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
        sudo apt-get install -y php8.4 php8.4-cli php8.4-fpm php8.4-common php8.4-mysql \
            php8.4-zip php8.4-gd php8.4-mbstring php8.4-curl php8.4-xml php8.4-bcmath \
            php8.4-sqlite3 unzip
    fi
    
    PHP_VERSION=$(php -r "echo PHP_VERSION;")
    if [[ "$PHP_VERSION" < "8.4" ]]; then
        print_error "PHP version must be 8.4 or higher (current: $PHP_VERSION)"
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
    
    # Store current directory
    CURRENT_DIR=$(pwd)
    
    echo -e "${GREEN}Where would you like to install the blog?${NC}"
    echo "1) Current directory ($CURRENT_DIR)"
    echo "2) Create new directory here"
    echo "3) Specify custom path"
    read -p "Choose [1-3]: " choice
    
    case $choice in
        1)
            # Check if directory is empty
            if [ "$(ls -A $CURRENT_DIR)" ]; then
                print_error "Current directory is not empty. Please choose an empty directory."
            fi
            echo "$CURRENT_DIR"
            ;;
        2)
            read -p "Enter directory name: " dir_name
            FULL_PATH="$CURRENT_DIR/$dir_name"
            if [ -d "$FULL_PATH" ] && [ "$(ls -A $FULL_PATH)" ]; then
                print_error "Directory $dir_name already exists and is not empty"
            fi
            mkdir -p "$FULL_PATH"
            echo "$FULL_PATH"
            ;;
        3)
            read -p "Enter full path: " custom_path
            # Convert relative path to absolute
            if [[ "$custom_path" != /* ]]; then
                custom_path="$CURRENT_DIR/$custom_path"
            fi
            if [ -d "$custom_path" ] && [ "$(ls -A $custom_path)" ]; then
                print_error "Directory $custom_path already exists and is not empty"
            fi
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
    
    # Install and build frontend assets
    print_status "Setting up frontend assets..."
    
    # Create package.json if it doesn't exist
    if [ ! -f "package.json" ]; then
        cat > package.json << 'EOF'
{
    "private": true,
    "type": "module",
    "scripts": {
        "dev": "vite",
        "build": "vite build"
    },
    "devDependencies": {
        "@tailwindcss/forms": "^0.5.7",
        "@tailwindcss/typography": "^0.5.10",
        "alpinejs": "^3.13.3",
        "autoprefixer": "^10.4.16",
        "axios": "^1.6.2",
        "laravel-vite-plugin": "^1.0.0",
        "postcss": "^8.4.32",
        "tailwindcss": "^3.4.0",
        "vite": "^5.0.10"
    }
}
EOF
    fi
    
    # Install dependencies
    npm install
    
    # Create Vite config if it doesn't exist
    if [ ! -f "vite.config.js" ]; then
        cat > vite.config.js << 'EOF'
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
    ],
});
EOF
    fi
    
    # Ensure resources directory exists
    mkdir -p resources/css resources/js
    
    # Create basic CSS file if it doesn't exist
    if [ ! -f "resources/css/app.css" ]; then
        echo "@tailwind base;
@tailwind components;
@tailwind utilities;" > resources/css/app.css
    fi
    
    # Create basic JS file if it doesn't exist
    if [ ! -f "resources/js/app.js" ]; then
        echo "import './bootstrap';" > resources/js/app.js
    fi
    
    # Create Tailwind config if it doesn't exist
    if [ ! -f "tailwind.config.js" ]; then
        cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./resources/**/*.blade.php",
        "./resources/**/*.js",
        "./resources/**/*.vue",
    ],
    theme: {
        extend: {
            typography: {
                DEFAULT: {
                    css: {
                        maxWidth: '100ch',
                        color: 'inherit',
                        a: {
                            color: '#3182ce',
                            '&:hover': {
                                color: '#2c5282',
                            },
                        },
                    },
                },
            },
        },
    },
    plugins: [
        require('@tailwindcss/typography'),
        require('@tailwindcss/forms')
    ],
}
EOF
    fi
    
    # Create PostCSS config if it doesn't exist
    if [ ! -f "postcss.config.js" ]; then
        cat > postcss.config.js << 'EOF'
export default {
    plugins: {
        tailwindcss: {},
        autoprefixer: {},
    },
}
EOF
    fi
    
    # Build assets
    print_status "Building frontend assets..."
    npm run build
    
    # Verify build
    if [ ! -d "public/build" ]; then
        mkdir -p public/build
    fi
    
    # Check if build was successful
    if [ ! -f "public/build/manifest.json" ]; then
        print_error "Asset build failed. Check npm and Vite configuration."
    fi
    
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
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
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
    systemctl restart php8.4-fpm
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