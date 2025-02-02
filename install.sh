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

# Function to configure MySQL
configure_mysql() {
    print_status "Configuring MySQL..."
    
    # Install MySQL if not installed
    if ! command -v mysql &> /dev/null; then
        print_status "Installing MySQL..."
        apt-get install -y mysql-server
        systemctl start mysql
        systemctl enable mysql
    fi

    # Secure MySQL installation
    print_status "Securing MySQL installation..."
    mysql_secure_installation

    # Create database and user
    read -p "Enter MySQL database name (default: laravel_blog): " DB_NAME
    DB_NAME=${DB_NAME:-laravel_blog}
    
    read -p "Enter MySQL user (default: laravel_user): " DB_USER
    DB_USER=${DB_USER:-laravel_user}
    
    read -s -p "Enter MySQL password: " DB_PASS
    echo
    
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
    mysql -u root -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
    mysql -u root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
    mysql -u root -e "FLUSH PRIVILEGES;"

    # Update .env file for MySQL
    sed -i "s|DB_CONNECTION=sqlite|DB_CONNECTION=mysql|g" .env
    sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|g" .env
    sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|g" .env
    sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env
}

# Function to configure SQLite
configure_sqlite() {
    print_status "Configuring SQLite..."
    
    # Create SQLite database
    mkdir -p database
    touch database/database.sqlite
    chmod 664 database/database.sqlite
    
    # Update .env file for SQLite
    sed -i "s|DB_CONNECTION=.*|DB_CONNECTION=sqlite|g" .env
    sed -i "s|DB_DATABASE=.*|DB_DATABASE=database/database.sqlite|g" .env
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root"
fi

print_status "Starting Laravel Personal Blog Installation..."

# Install required system packages
print_status "Installing system dependencies..."
apt-get update
apt-get install -y \
    php8.2 \
    php8.2-cli \
    php8.2-fpm \
    php8.2-common \
    php8.2-mysql \
    php8.2-zip \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-curl \
    php8.2-xml \
    php8.2-bcmath \
    php8.2-sqlite3 \
    nginx \
    curl \
    unzip \
    git

# Install Node.js 20.x
print_status "Installing Node.js 20.x..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Install Composer
if ! command -v composer &> /dev/null; then
    print_status "Installing Composer..."
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
fi

# Set up environment file
print_status "Setting up environment file..."
cp .env.example .env
sed -i "s|APP_NAME=Laravel|APP_NAME=\"Personal Blog\"|g" .env
sed -i "s|APP_DEBUG=true|APP_DEBUG=false|g" .env
sed -i "s|APP_URL=http://localhost|APP_URL=http://localhost:${port}|g" .env

# Choose database type
while true; do
    read -p "Choose database type (sqlite/mysql) [sqlite]: " DB_TYPE
    DB_TYPE=${DB_TYPE:-sqlite}
    
    case $DB_TYPE in
        sqlite)
            configure_sqlite
            break
            ;;
        mysql)
            configure_mysql
            break
            ;;
        *)
            echo "Please enter 'sqlite' or 'mysql'"
            ;;
    esac
done

# Install PHP dependencies
print_status "Installing PHP dependencies..."
composer install --no-dev --optimize-autoloader

# Generate application key
print_status "Generating application key..."
php artisan key:generate

# Install Node.js dependencies
print_status "Installing Node.js dependencies..."
npm install

# Build frontend assets
print_status "Building frontend assets..."
npm run build

# Run database migrations
print_status "Running database migrations..."
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

# Set correct permissions
print_status "Setting correct permissions..."
chown -R www-data:www-data .
find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;
chmod -R 775 storage bootstrap/cache
[ "$DB_TYPE" = "sqlite" ] && chmod 775 database/database.sqlite

# Configure Nginx
print_status "Configuring Nginx..."
read -p "Enter your site name (default: personal-blog): " SITE_NAME
SITE_NAME=${SITE_NAME:-personal-blog}

# Create Nginx configuration
cat > /etc/nginx/sites-available/${SITE_NAME} << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;
    root /var/www/html/Laravel-Personal-Blog-PHP/public;

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
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
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
        try_files $uri $uri/ /index.php?$query_string;
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

    # Enable gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml application/javascript;
    gzip_disable "MSIE [1-6]\.";
}
EOF

# Enable the site
print_status "Enabling the site..."
ln -sf /etc/nginx/sites-available/${SITE_NAME} /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Create admin user
print_status "Creating admin user..."
php artisan make:admin

# Restart services
print_status "Restarting services..."
systemctl restart php8.2-fpm
systemctl restart nginx

print_success "Installation completed successfully!"
echo -e "${GREEN}Your blog is now installed and configured!${NC}"
echo -e "${YELLOW}Important notes:${NC}"
echo "1. Database type: ${DB_TYPE}"
if [ "$DB_TYPE" = "mysql" ]; then
    echo "   - Database name: ${DB_NAME}"
    echo "   - Database user: ${DB_USER}"
    echo "   - Remember to securely store your database password"
fi
echo "2. Configure SSL/TLS certificates"
echo "3. Set up regular backups"
echo "4. Configure firewall rules"
echo "5. Keep the system updated"
echo
echo -e "${GREEN}You can access your blog at: http://localhost${NC}"