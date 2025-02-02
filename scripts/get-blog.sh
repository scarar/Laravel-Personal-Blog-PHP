#!/bin/bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
DEFAULT_PORT=80
PHP_VERSION="8.4"
NODE_VERSION="20"
INSTALL_DIR=""
DOMAIN_NAME=""
PORT=""

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

# Function to install system packages
install_system_packages() {
    print_status "Installing system packages..."
    
    # Update package list
    apt-get update
    
    # Install basic requirements
    apt-get install -y \
        software-properties-common \
        curl \
        wget \
        git \
        unzip \
        acl \
        imagemagick \
        build-essential \
        supervisor

    # Add PHP repository
    if ! grep -q "^deb .*ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
        add-apt-repository -y ppa:ondrej/php
        apt-get update
    fi

    # Add Node.js repository
    if ! grep -q "^deb .*nodesource" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
        curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | bash -
        apt-get update
    fi
}

# Function to install and configure PHP
install_php() {
    print_status "Installing PHP ${PHP_VERSION} and extensions..."
    
    # Install PHP and extensions
    apt-get install -y \
        "php${PHP_VERSION}" \
        "php${PHP_VERSION}-fpm" \
        "php${PHP_VERSION}-cli" \
        "php${PHP_VERSION}-common" \
        "php${PHP_VERSION}-mysql" \
        "php${PHP_VERSION}-sqlite3" \
        "php${PHP_VERSION}-pgsql" \
        "php${PHP_VERSION}-gd" \
        "php${PHP_VERSION}-curl" \
        "php${PHP_VERSION}-xml" \
        "php${PHP_VERSION}-zip" \
        "php${PHP_VERSION}-bcmath" \
        "php${PHP_VERSION}-intl" \
        "php${PHP_VERSION}-readline" \
        "php${PHP_VERSION}-ldap" \
        "php${PHP_VERSION}-msgpack" \
        "php${PHP_VERSION}-igbinary" \
        "php${PHP_VERSION}-redis" \
        "php${PHP_VERSION}-swoole" \
        "php${PHP_VERSION}-memcached" \
        "php${PHP_VERSION}-pcov" \
        "php${PHP_VERSION}-xdebug" \
        "php${PHP_VERSION}-mbstring"

    # Configure PHP
    PHP_INI_PATH="/etc/php/${PHP_VERSION}/fpm/php.ini"
    sed -i 's/upload_max_filesize = .*/upload_max_filesize = 10M/' "$PHP_INI_PATH"
    sed -i 's/post_max_size = .*/post_max_size = 10M/' "$PHP_INI_PATH"
    sed -i 's/memory_limit = .*/memory_limit = 256M/' "$PHP_INI_PATH"
    sed -i 's/max_execution_time = .*/max_execution_time = 60/' "$PHP_INI_PATH"

    # Configure PHP-FPM
    PHP_FPM_POOL="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
    sed -i 's/pm.max_children = .*/pm.max_children = 10/' "$PHP_FPM_POOL"
    sed -i 's/pm.start_servers = .*/pm.start_servers = 3/' "$PHP_FPM_POOL"
    sed -i 's/pm.min_spare_servers = .*/pm.min_spare_servers = 2/' "$PHP_FPM_POOL"
    sed -i 's/pm.max_spare_servers = .*/pm.max_spare_servers = 5/' "$PHP_FPM_POOL"

    # Restart PHP-FPM
    systemctl restart "php${PHP_VERSION}-fpm"
}

# Function to install and configure Node.js
install_nodejs() {
    print_status "Installing Node.js and npm..."
    
    # Install Node.js
    apt-get install -y nodejs

    # Install global npm packages
    npm install -g npm@latest
    npm install -g yarn
    npm install -g vite
}

# Function to install and configure web server
install_webserver() {
    print_status "Installing and configuring Nginx..."
    
    # Install Nginx
    apt-get install -y nginx

    # Configure Nginx
    cat > /etc/nginx/conf.d/gzip.conf << 'EOF'
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_types text/plain text/css text/xml application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;
EOF

    # Configure SSL (if needed)
    if [ "$PORT" = "443" ]; then
        apt-get install -y certbot python3-certbot-nginx
    fi

    # Restart Nginx
    systemctl restart nginx
}

# Function to install Composer
install_composer() {
    print_status "Installing Composer..."
    
    EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
        rm composer-setup.php
        print_error "Composer installer corrupt"
    fi

    php composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer
    rm composer-setup.php
}

# Function to check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Install system packages
    install_system_packages
    
    # Install PHP
    install_php
    
    # Install Node.js
    install_nodejs
    
    # Install web server
    install_webserver
    
    # Install Composer
    install_composer

    # Verify installations
    PHP_VERSION_INSTALLED=$(php -r "echo PHP_VERSION;" 2>/dev/null || echo "0")
    NODE_VERSION_INSTALLED=$(node -v 2>/dev/null || echo "v0")
    
    if [[ "$PHP_VERSION_INSTALLED" < "${PHP_VERSION}" ]]; then
        print_error "PHP version must be ${PHP_VERSION} or higher (current: $PHP_VERSION_INSTALLED)"
    fi
    
    if [[ "$NODE_VERSION_INSTALLED" != *"${NODE_VERSION}"* ]]; then
        print_error "Node.js version must be ${NODE_VERSION} (current: $NODE_VERSION_INSTALLED)"
    fi
    
    if ! command -v composer &> /dev/null; then
        print_error "Composer is not installed"
    fi
    
    if ! command -v nginx &> /dev/null; then
        print_error "Nginx is not installed"
    fi
}

# Function to get deployment path
get_deployment_path() {
    clear
    echo -e "${BLUE}Laravel Blog - One Command Installer${NC}"
    echo "================================"
    echo
    
    # Get domain name and port
    read -p "Enter your domain name (e.g., blog.example.com): " DOMAIN_NAME
    read -p "Enter port number [80/443] (default: 80): " PORT
    PORT=${PORT:-$DEFAULT_PORT}
    
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
            INSTALL_DIR="$CURRENT_DIR"
            ;;
        2)
            read -p "Enter directory name: " dir_name
            INSTALL_DIR="$CURRENT_DIR/$dir_name"
            if [ -d "$INSTALL_DIR" ] && [ "$(ls -A $INSTALL_DIR)" ]; then
                print_error "Directory $dir_name already exists and is not empty"
            fi
            mkdir -p "$INSTALL_DIR"
            ;;
        3)
            read -p "Enter full path: " custom_path
            # Convert relative path to absolute
            if [[ "$custom_path" != /* ]]; then
                INSTALL_DIR="$CURRENT_DIR/$custom_path"
            else
                INSTALL_DIR="$custom_path"
            fi
            if [ -d "$INSTALL_DIR" ] && [ "$(ls -A $INSTALL_DIR)" ]; then
                print_error "Directory $INSTALL_DIR already exists and is not empty"
            fi
            mkdir -p "$INSTALL_DIR"
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
}

# Function to configure application
configure_application() {
    print_status "Configuring application..."
    
    # Create .env file
    cp .env.example .env
    
    # Generate app key
    php artisan key:generate
    
    # Configure database
    sed -i "s|DB_CONNECTION=.*|DB_CONNECTION=sqlite|g" .env
    sed -i "s|DB_DATABASE=.*|DB_DATABASE=$INSTALL_DIR/database/database.sqlite|g" .env
    
    # Configure application
    sed -i "s|APP_NAME=.*|APP_NAME=\"Personal Blog\"|g" .env
    sed -i "s|APP_ENV=.*|APP_ENV=production|g" .env
    sed -i "s|APP_DEBUG=.*|APP_DEBUG=false|g" .env
    sed -i "s|APP_URL=.*|APP_URL=http://${DOMAIN_NAME}|g" .env
    
    # Create SQLite database
    touch database/database.sqlite
    chmod 775 database/database.sqlite
    chown www-data:www-data database/database.sqlite
    
    # Run migrations
    php artisan migrate --force
    
    # Create storage link
    php artisan storage:link
    
    # Optimize application
    php artisan optimize
    php artisan view:cache
    php artisan config:cache
    php artisan route:cache
}

# Function to configure web server
configure_webserver() {
    print_status "Configuring web server..."
    
    # Create Nginx configuration
    cat > /etc/nginx/sites-available/laravel-blog << EOF
server {
    listen ${PORT};
    listen [::]:{$PORT};
    server_name ${DOMAIN_NAME};
    root ${INSTALL_DIR}/public;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    add_header Permissions-Policy "geolocation=(),midi=(),sync-xhr=(),microphone=(),camera=(),magnetometer=(),gyroscope=(),fullscreen=(self),payment=()";

    index index.php;
    charset utf-8;

    # Handle PHP files
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
    }

    # Handle static files
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires max;
        log_not_found off;
        access_log off;
        add_header Cache-Control "public, no-transform";
    }

    # Main location block
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
        gzip_static on;
    }

    # Deny access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location = /favicon.ico { 
        access_log off; 
        log_not_found off; 
    }
    
    location = /robots.txt  { 
        access_log off; 
        log_not_found off; 
    }
}
EOF

    # Enable site
    ln -sf /etc/nginx/sites-available/laravel-blog /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test configuration
    nginx -t
    
    # Restart Nginx
    systemctl restart nginx
}

# Function to set up SSL (if needed)
setup_ssl() {
    if [ "$PORT" = "443" ]; then
        print_status "Setting up SSL..."
        certbot --nginx -d "$DOMAIN_NAME" --non-interactive --agree-tos --email "admin@${DOMAIN_NAME}" --redirect
    fi
}

# Main installation process
main() {
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then 
        print_error "Please run as root (sudo)"
    fi
    
    # Check requirements
    check_requirements
    
    # Get deployment path and configuration
    get_deployment_path
    
    # Clone repository
    print_status "Cloning repository..."
    git clone https://github.com/scarar/Laravel-Personal-Blog-PHP.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
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
    
    # Configure application
    configure_application
    
    # Configure web server
    configure_webserver
    
    # Set up SSL if needed
    setup_ssl
    
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