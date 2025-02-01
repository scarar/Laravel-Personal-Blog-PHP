#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

clear
echo -e "${BLUE}Laravel Blog Installer${NC}"
echo "====================="
echo

# 1. Ask for domain name
echo -e "${GREEN}Step 1:${NC} What's your domain name?"
echo "Example: myblog.com"
read -p "Domain: " DOMAIN_NAME
echo

# 2. Ask for database info
echo -e "${GREEN}Step 2:${NC} Database setup"
read -p "Database name (example: blog): " DB_NAME
read -p "Database username: " DB_USER
read -p "Database password: " DB_PASS
echo

# 3. Start installation
echo -e "${GREEN}Starting installation...${NC}"
echo "This might take a few minutes..."
echo

# Get current directory
CURRENT_DIR=$(pwd)

# Basic setup
echo "→ Setting up Laravel..."
cp .env.example .env
composer install --quiet
php artisan key:generate --quiet

# Update .env file
sed -i "s|APP_URL=.*|APP_URL=https://$DOMAIN_NAME|" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=$DB_NAME|" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=$DB_USER|" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|" .env

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
sudo tee /etc/nginx/sites-available/$DOMAIN_NAME > /dev/null << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NAME;
    root $CURRENT_DIR/public;

    index index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/

# Test and restart Nginx
sudo nginx -t && sudo systemctl restart nginx

# Optimize Laravel
echo "→ Optimizing Laravel..."
php artisan config:cache --quiet
php artisan route:cache --quiet
php artisan view:cache --quiet

# Done!
echo
echo -e "${GREEN}Installation complete!${NC}"
echo
echo "Next steps:"
echo "1. Point your domain ($DOMAIN_NAME) to this server"
echo "2. Install SSL certificate by running:"
echo "   sudo certbot --nginx -d $DOMAIN_NAME"
echo
echo -e "${BLUE}Your blog is installed at: $CURRENT_DIR${NC}"
echo "Thank you for using Laravel Blog!"