#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check PHP version
check_php_version() {
    if command_exists php; then
        PHP_VERSION=$(php -v | head -n 1 | cut -d " " -f 2 | cut -d "." -f 1,2)
        echo $PHP_VERSION
    else
        echo "0"
    fi
}

# Function to ask yes/no questions
ask_yes_no() {
    while true; do
        read -p "$1 [y/n]: " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes (y) or no (n).";;
        esac
    done
}

clear
echo -e "${BLUE}Laravel Blog Installer${NC}"
echo "====================="
echo

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run with sudo:${NC}"
    echo "sudo bash $0"
    exit 1
fi

# 1. Domain Name
read -p "Enter your domain name (e.g., myblog.com or onion address): " DOMAIN_NAME
read -p "Enter the port number to use (default 80): " PORT_NUMBER
PORT_NUMBER=
IS_LOCAL=false

# 2. Check and Install Requirements
echo -e "\n${GREEN}Checking requirements...${NC}"

# Check PHP
CURRENT_PHP_VERSION=$(check_php_version)
if [ "$CURRENT_PHP_VERSION" = "0" ]; then
    echo -e "${RED}PHP is not installed.${NC}"
    if ask_yes_no "Would you like to install PHP 8.2 (stable version)?"; then
        sudo apt-get update
        sudo apt-get install -y php8.2-fpm php8.2-cli php8.2-common php8.2-mbstring php8.2-xml php8.2-curl
    else
        echo -e "${RED}PHP is required. Installation cannot continue.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ PHP $CURRENT_PHP_VERSION is installed${NC}"
fi

# Check Composer
if ! command_exists composer; then
    echo -e "${RED}Composer is not installed.${NC}"
    if ask_yes_no "Would you like to install Composer?"; then
        php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
        php composer-setup.php --install-dir=/usr/local/bin --filename=composer
        php -r "unlink('composer-setup.php');"
    else
        echo -e "${RED}Composer is required. Installation cannot continue.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Composer is installed${NC}"
fi

# 3. Database Selection
echo -e "\n${GREEN}Step 2:${NC} Choose your database:"
echo "1) SQLite (Simplest, good for small blogs)"
echo "2) MySQL (Good for medium to large blogs)"
echo "3) PostgreSQL (Advanced features)"
read -p "Enter choice [1-3]: " DB_CHOICE

case $DB_CHOICE in
    1)
        DB_CONNECTION="sqlite"
        if ! command_exists sqlite3; then
            echo -e "${YELLOW}SQLite is not installed.${NC}"
            if ask_yes_no "Would you like to install SQLite?"; then
                sudo apt-get update
                sudo apt-get install -y sqlite3 php8.*-sqlite3
            fi
        else
            echo -e "${GREEN}✓ SQLite is already installed${NC}"
        fi
        echo -e "\nCreating SQLite database..."
        mkdir -p database
        touch database/database.sqlite
        chmod 777 database/database.sqlite
        ;;
    2)
        DB_CONNECTION="mysql"
        echo -e "\nMySQL database setup:"
        read -p "Database name (example: blog): " DB_NAME
        read -p "Database username: " DB_USER
        read -p "Database password: " DB_PASS
        ;;
    3)
        DB_CONNECTION="pgsql"
        echo -e "\nPostgreSQL database setup:"
        read -p "Database name (example: blog): " DB_NAME
        read -p "Database username: " DB_USER
        read -p "Database password: " DB_PASS
        ;;
    *)
        echo -e "${YELLOW}Invalid choice. Using SQLite as default.${NC}"
        DB_CONNECTION="sqlite"
        touch database/database.sqlite
        chmod 777 database/database.sqlite
        ;;
esac

# 4. Application Setup
echo -e "\n${GREEN}Setting up Laravel application...${NC}"

# Basic setup
if ask_yes_no "Composer plugins have been disabled for safety in this non-interactive session. Would you like to allow plugins to run as root/super user?"; then
    export COMPOSER_ALLOW_SUPERUSER=1
fi
cp .env.example .env
composer install --no-interaction

# Install and build frontend assets
echo -e "\n${GREEN}Installing and building frontend assets...${NC}"
if ! command_exists npm; then
    echo -e "${YELLOW}npm is not installed.${NC}"
    if ask_yes_no "Would you like to install Node.js and npm?"; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    else
        echo -e "${RED}npm is required for building frontend assets. Installation cannot continue.${NC}"
        exit 1
    fi
fi

# Install npm dependencies and build
npm install
npm run build

# Update .env file
sed -i "s|APP_ENV=.*|APP_ENV=production|" .env
sed -i "s|APP_DEBUG=.*|APP_DEBUG=false|" .env
sed -i "s|APP_URL=.*|APP_URL=http://$DOMAIN_NAME|" .env
sed -i "s|DB_CONNECTION=.*|DB_CONNECTION=$DB_CONNECTION|" .env

if [ "$DB_CONNECTION" = "sqlite" ]; then
    # Configure for SQLite
    sed -i "s|DB_HOST=.*|DB_HOST=|" .env
    sed -i "s|DB_PORT=.*|DB_PORT=|" .env
    sed -i "s|DB_DATABASE=.*|DB_DATABASE=$PWD/database/database.sqlite|" .env
    sed -i "s|DB_USERNAME=.*|DB_USERNAME=|" .env
    sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=|" .env
else
    # Configure for MySQL/PostgreSQL
    sed -i "s|DB_DATABASE=.*|DB_DATABASE=$DB_NAME|" .env
    sed -i "s|DB_USERNAME=.*|DB_USERNAME=$DB_USER|" .env
    sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|" .env
fi

# Generate application key
php artisan key:generate --quiet

# Set up database
echo "→ Setting up database..."
php artisan migrate --force --quiet

# Set up storage
echo "→ Setting up file storage..."
php artisan storage:link --quiet

# Set permissions
echo "→ Setting correct permissions..."
chown -R $SUDO_USER:www-data .
find . -type f -exec chmod 664 {} \;
find . -type d -exec chmod 775 {} \;
chmod -R 775 storage bootstrap/cache

# Configure web server
if [ "$IS_LOCAL" = true ]; then
    echo -e "\n${GREEN}Local Development Setup${NC}"
    echo "To start the development server:"
    echo "php artisan serve"
    
    # Create a convenient start script
    echo '#!/bin/bash' > start-server.sh
    echo 'php artisan serve --host=0.0.0.0 --port=8000' >> start-server.sh
    chmod +x start-server.sh
else
    echo "→ Setting up Nginx..."
    if ! command_exists nginx; then
        if ask_yes_no "Nginx is not installed. Would you like to install it?"; then
            sudo apt-get update
            sudo apt-get install -y nginx
        fi
    fi
    
    # Configure Nginx only if installed
    if command_exists nginx; then
        echo "Enter the path where you want to place the built website (e.g., /var/www/myblog):"
        read -p "Path: " WEBSITE_PATH
        
        # Create Nginx configuration
        cat <<EOL > "/etc/nginx/sites-available/$DOMAIN_NAME"
server {
    listen ${PORT_NUMBER:-80} default_server;
    listen [::]:${PORT_NUMBER:-80} default_server;
    server_name $DOMAIN_NAME;

    root $WEBSITE_PATH/public;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

        # Enable the site
        ln -sf "/etc/nginx/sites-available/$DOMAIN_NAME" "/etc/nginx/sites-enabled/"
        
        # Test and restart Nginx
        nginx -t && systemctl restart nginx
    fi
fi

# Set permissions for public directory
echo "→ Setting permissions for public directory..."
sudo chown -R www-data:www-data $PWD/public
sudo chmod -R 755 $PWD/public

# Optimize Laravel
echo "→ Optimizing Laravel..."
php artisan config:cache --quiet
php artisan route:cache --quiet
php artisan view:cache --quiet

# Add build command
echo "#!/bin/bash" > build-assets.sh
echo "npm run build" >> build-assets.sh
chmod +x build-assets.sh

# Done!
echo
echo -e "${GREEN}Installation complete!${NC}"
echo
echo "Your blog has been installed with:"
echo -e "• Database: ${BLUE}$DB_CONNECTION${NC}"
if [ "$DB_CONNECTION" = "sqlite" ]; then
    echo -e "• Database location: ${BLUE}$PWD/database/database.sqlite${NC}"
else
    echo -e "• Database name: ${BLUE}$DB_NAME${NC}"
fi
echo -e "• Installation directory: ${BLUE}$PWD${NC}"

echo -e "\n${GREEN}To rebuild assets, run: ./build-assets.sh${NC}"

if [ "$IS_LOCAL" = true ]; then
    echo -e "\n${GREEN}To start your blog:${NC}"
    echo "1. Run: ./start-server.sh"
    echo "2. Visit: http://localhost:8000"
else
    if command_exists nginx; then
        echo -e "\n${GREEN}To access your blog:${NC}"
        echo "1. Point your domain ($DOMAIN_NAME) to this server"
        echo "2. Visit: http://$DOMAIN_NAME"
        echo -e "\nTo set up SSL:"
        echo "sudo certbot --nginx -d $DOMAIN_NAME"
    else
        echo -e "\n${YELLOW}Note: Nginx was not installed.${NC}"
        echo "You'll need to set up a web server manually or use PHP's built-in server:"
        echo "./start-server.sh"
    fi
fi

echo -e "\n${BLUE}Thank you for using Laravel Blog!${NC}"