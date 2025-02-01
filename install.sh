#!/bin/bash

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Please run with sudo:"
    echo "sudo bash $0"
    exit 1
fi

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

clear
echo -e "${BLUE}Laravel Blog Installer${NC}"
echo "====================="
echo

# Check requirements
echo -e "${GREEN}Checking requirements...${NC}"
REQUIREMENTS_MET=true

if ! command_exists php; then
    echo -e "${RED}✗ PHP is not installed${NC}"
    REQUIREMENTS_MET=false
fi

if ! command_exists composer; then
    echo -e "${RED}✗ Composer is not installed${NC}"
    REQUIREMENTS_MET=false
fi

if ! command_exists nginx; then
    echo -e "${YELLOW}⚠ Nginx is not installed${NC}"
    echo "Would you like to install Nginx? (y/n)"
    read -p "Choice: " INSTALL_NGINX
    if [ "$INSTALL_NGINX" = "y" ]; then
        sudo apt-get update
        sudo apt-get install -y nginx
    else
        echo -e "${YELLOW}⚠ Skipping Nginx installation${NC}"
    fi
fi

if [ "$REQUIREMENTS_MET" = false ]; then
    echo -e "${RED}Please install the missing requirements and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All requirements met${NC}"
echo

# 1. Ask about environment
echo -e "${GREEN}Step 1:${NC} Are you installing for:"
echo "1) Local development (localhost)"
echo "2) Production server (with domain)"
read -p "Enter choice [1-2]: " ENV_CHOICE

case $ENV_CHOICE in
    2)
        echo -e "\nEnter your domain name:"
        echo "Example: myblog.com"
        read -p "Domain: " DOMAIN_NAME
        IS_LOCAL=false
        ;;
    *)
        DOMAIN_NAME="localhost"
        IS_LOCAL=true
        ;;
esac
echo

# 2. Database Selection
echo -e "${GREEN}Step 2:${NC} Choose your database:"
echo "1) SQLite (Simplest, good for small blogs)"
echo "2) MySQL (Good for medium to large blogs)"
echo "3) PostgreSQL (Advanced features, good for large blogs)"
read -p "Enter choice [1-3]: " DB_CHOICE

case $DB_CHOICE in
    1)
        DB_CONNECTION="sqlite"
        echo -e "\nUsing SQLite database..."
        touch database/database.sqlite
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
        ;;
esac

# 3. Ask about SSL (skip for local development)
if [ "$IS_LOCAL" = true ]; then
    USE_SSL="n"
    echo -e "\n${BLUE}Local development:${NC} Using HTTP for localhost"
else
    echo -e "\n${GREEN}Step 3:${NC} Do you want to set up HTTPS/SSL? (y/n)"
    read -p "Choice: " USE_SSL
fi

# Get current directory
CURRENT_DIR=$(pwd)

echo
echo -e "${GREEN}Starting installation...${NC}"
echo "This might take a few minutes..."
echo

# Basic setup
echo "→ Setting up Laravel..."
cp .env.example .env
composer install --quiet

# Update .env file based on database choice
sed -i "s|APP_URL=.*|APP_URL=https://$DOMAIN_NAME|" .env
sed -i "s|DB_CONNECTION=.*|DB_CONNECTION=$DB_CONNECTION|" .env

if [ "$DB_CONNECTION" = "sqlite" ]; then
    # Configure for SQLite
    sed -i "s|DB_HOST=.*|DB_HOST=|" .env
    sed -i "s|DB_PORT=.*|DB_PORT=|" .env
    sed -i "s|DB_DATABASE=.*|DB_DATABASE=$CURRENT_DIR/database/database.sqlite|" .env
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
sudo chown -R $USER:www-data .
sudo find . -type f -exec chmod 664 {} \;
sudo find . -type d -exec chmod 775 {} \;
sudo chmod -R 775 storage bootstrap/cache

# Configure Nginx
echo "→ Setting up Nginx..."

# Choose template based on SSL preference
if [ "$USE_SSL" = "y" ]; then
    TEMPLATE="config/nginx/https.conf.template"
else
    TEMPLATE="config/nginx/http.conf.template"
fi

# Replace placeholders in template
sed "s|{{domain}}|$DOMAIN_NAME|g; s|{{path}}|$CURRENT_DIR|g" "$TEMPLATE" | \
    sudo tee "/etc/nginx/sites-available/$DOMAIN_NAME" > /dev/null

# Enable the site
sudo ln -sf "/etc/nginx/sites-available/$DOMAIN_NAME" "/etc/nginx/sites-enabled/"

# Test and restart Nginx
if sudo nginx -t; then
    sudo systemctl restart nginx
    echo -e "${GREEN}✓ Nginx configuration successful${NC}"
else
    echo -e "${RED}✗ Nginx configuration failed. Please check the error above.${NC}"
fi

# Optimize Laravel
echo "→ Optimizing Laravel..."
php artisan config:cache --quiet
php artisan route:cache --quiet
php artisan view:cache --quiet

# Done!
echo
echo -e "${GREEN}Installation complete!${NC}"
echo
echo "Your blog has been installed with:"
echo -e "• Database: ${BLUE}$DB_CONNECTION${NC}"
if [ "$DB_CONNECTION" = "sqlite" ]; then
    echo -e "• Database location: ${BLUE}$CURRENT_DIR/database/database.sqlite${NC}"
else
    echo -e "• Database name: ${BLUE}$DB_NAME${NC}"
fi
echo -e "• Web root: ${BLUE}$CURRENT_DIR${NC}"
echo -e "• Nginx config: ${BLUE}/etc/nginx/sites-available/$DOMAIN_NAME${NC}"
echo

if [ "$IS_LOCAL" = true ]; then
    echo -e "${GREEN}Local Development Setup Complete!${NC}"
    echo "Your blog is now accessible at: http://localhost"
    echo
    echo "To start using your blog:"
    echo "1. Make sure port 80 is available (stop other web servers if needed)"
    echo "2. Visit http://localhost in your browser"
    echo
    echo "To stop the server later:"
    echo "sudo systemctl stop nginx"
else
    if [ "$USE_SSL" = "y" ]; then
        echo "Next steps:"
        echo "1. Point your domain ($DOMAIN_NAME) to this server"
        echo "2. Install SSL certificate by running:"
        echo "   sudo certbot --nginx -d $DOMAIN_NAME"
        echo
        echo "To install certbot:"
        echo "sudo apt-get update"
        echo "sudo apt-get install -y certbot python3-certbot-nginx"
    else
        echo "Your blog is now accessible at: http://$DOMAIN_NAME"
        echo "To enable HTTPS later, run: sudo certbot --nginx -d $DOMAIN_NAME"
    fi
fi

echo
echo -e "${BLUE}Thank you for using Laravel Blog!${NC}"