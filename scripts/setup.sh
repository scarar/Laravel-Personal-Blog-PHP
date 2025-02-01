#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Laravel Blog Setup Script${NC}"
echo "--------------------------------"

# Get the current directory
CURRENT_DIR=$(pwd)

# 1. Configure Nginx
echo -e "\n${GREEN}Configuring Nginx...${NC}"
echo "Current directory is: $CURRENT_DIR"

# Create a temporary nginx configuration file
TMP_NGINX_CONF=$(mktemp)
cat nginx.conf.example | sed "s|/path/to/your/cloned/directory|$CURRENT_DIR|g" > "$TMP_NGINX_CONF"

# Ask for domain name
read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME
sed -i "s/your-domain.com/$DOMAIN_NAME/g" "$TMP_NGINX_CONF"

# Move the configuration file
sudo cp "$TMP_NGINX_CONF" "/etc/nginx/sites-available/$DOMAIN_NAME"
rm "$TMP_NGINX_CONF"

# Create symbolic link if it doesn't exist
if [ ! -f "/etc/nginx/sites-enabled/$DOMAIN_NAME" ]; then
    sudo ln -s "/etc/nginx/sites-available/$DOMAIN_NAME" "/etc/nginx/sites-enabled/"
fi

# 2. Configure Environment
echo -e "\n${GREEN}Configuring environment...${NC}"

# Copy .env file if it doesn't exist
if [ ! -f ".env" ]; then
    cp .env.example .env
    
    # Generate application key
    php artisan key:generate
    
    # Configure database
    read -p "Enter database name: " DB_NAME
    read -p "Enter database username: " DB_USER
    read -p "Enter database password: " DB_PASS
    
    # Update .env file
    sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env
    sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" .env
    sed -i "s|APP_URL=.*|APP_URL=https://$DOMAIN_NAME|" .env
fi

# 3. Install Dependencies
echo -e "\n${GREEN}Installing dependencies...${NC}"
composer install --optimize-autoloader --no-dev

# 4. Set Permissions
echo -e "\n${GREEN}Setting permissions...${NC}"
sudo chown -R $USER:www-data .
sudo find . -type f -exec chmod 664 {} \;
sudo find . -type d -exec chmod 775 {} \;
sudo chmod -R 775 storage bootstrap/cache

# 5. Create storage link
echo -e "\n${GREEN}Creating storage link...${NC}"
php artisan storage:link

# 6. Run Migrations
echo -e "\n${GREEN}Running database migrations...${NC}"
php artisan migrate --force

# 7. Optimize Laravel
echo -e "\n${GREEN}Optimizing Laravel...${NC}"
php artisan config:cache
php artisan route:cache
php artisan view:cache

# 8. Test Nginx configuration
echo -e "\n${GREEN}Testing Nginx configuration...${NC}"
sudo nginx -t

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}Setup completed successfully!${NC}"
    echo -e "Next steps:"
    echo -e "1. Review the Nginx configuration at /etc/nginx/sites-available/$DOMAIN_NAME"
    echo -e "2. Make sure your domain points to this server"
    echo -e "3. Set up SSL with: sudo certbot --nginx -d $DOMAIN_NAME"
    echo -e "4. Restart Nginx with: sudo systemctl restart nginx"
else
    echo -e "\n${RED}Nginx configuration test failed. Please check the configuration.${NC}"
fi