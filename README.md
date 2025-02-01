# Laravel Personal Blog

A professional blog application built with Laravel, featuring user authentication, post management, and a modern responsive design. This README provides comprehensive setup and deployment instructions for both development and production environments.

## Features

- User authentication and authorization
- Blog post CRUD operations with image support
- Responsive design using Tailwind CSS
- SEO-friendly URLs with post slugs
- Image upload and management
- Role-based access control
- Modern and clean UI

## System Requirements

- PHP 8.4
- Nginx or Apache web server
- MySQL/PostgreSQL/SQLite database
- Composer (Dependency Manager)
- Node.js & NPM (for frontend assets)
- SSL certificate (for production)

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/scarar/Laravel-Personal-Blog-PHP.git
   cd Laravel-Personal-Blog-PHP
   ```

2. Install dependencies:
   ```bash
   composer install
   npm install
   ```

3. Configure environment:
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```

4. Set up database in `.env`:
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=your_database
   DB_USERNAME=your_username
   DB_PASSWORD=your_password
   ```

5. Run migrations:
   ```bash
   php artisan migrate
   ```

6. Create storage link:
   ```bash
   php artisan storage:link
   ```

7. Build Assets for Production:
   ```bash
   # Build and minify frontend assets
   npm run build
   
   # Configure your web server (Nginx) to point to the /public directory
   # See "Production Deployment" section below for Nginx configuration
   ```

## Production Deployment

### 1. Server Requirements

- Nginx web server
- PHP 8.4 with extensions:
  - php8.4-fpm
  - php8.4-mysql
  - php8.4-mbstring
  - php8.4-xml
  - php8.4-bcmath
  - php8.4-curl
  - php8.4-zip

### 2. Server Configuration

#### Nginx Configuration
```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    root /path/to/laravel-blog/public;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

### 3. Deployment Steps

1. Prepare Production Environment:
   ```bash
   # Install dependencies
   composer install --optimize-autoloader --no-dev
   npm install
   npm run build

   # Set proper permissions
   chown -R www-data:www-data storage bootstrap/cache
   chmod -R 775 storage bootstrap/cache
   ```

2. Configure Production Environment:
   ```bash
   # Set up environment file
   cp .env.example .env
   php artisan key:generate

   # Update .env with production settings
   APP_ENV=production
   APP_DEBUG=false
   APP_URL=https://your-domain.com
   ```

3. Optimize Laravel:
   ```bash
   php artisan config:cache
   php artisan route:cache
   php artisan view:cache
   php artisan storage:link
   ```

4. Database Setup:
   ```bash
   php artisan migrate --force
   ```

### 4. Security Measures

1. File Permissions:
   ```bash
   find /path/to/laravel-blog -type f -exec chmod 644 {} \;
   find /path/to/laravel-blog -type d -exec chmod 755 {} \;
   chmod -R ug+rwx storage bootstrap/cache
   ```

2. Secure Important Files:
   ```nginx
   location ~ /\.env {
       deny all;
   }
   location ~ /composer\.(lock|json)$ {
       deny all;
   }
   ```

3. Enable HTTPS Only:
   ```php
   // In config/session.php
   'secure' => true,
   'same_site' => 'lax',
   ```

### 5. Maintenance

1. Regular Updates:
   ```bash
   composer update --no-dev
   npm update
   php artisan migrate
   ```

2. Cache Management:
   ```bash
   php artisan cache:clear
   php artisan config:clear
   php artisan view:clear
   ```

3. Backup Strategy:
   ```bash
   # Database backup
   mysqldump -u user -p database_name > backup.sql

   # Application backup
   tar -czf backup.tar.gz /path/to/laravel-blog
   ```

## Monitoring and Logging

1. Laravel Log Files:
   ```bash
   tail -f storage/logs/laravel.log
   ```

2. Nginx Access/Error Logs:
   ```bash
   tail -f /var/log/nginx/access.log
   tail -f /var/log/nginx/error.log
   ```

3. PHP-FPM Logs:
   ```bash
   tail -f /var/log/php8.4-fpm.log
   ```

## Troubleshooting

1. Permission Issues:
   ```bash
   sudo chown -R www-data:www-data storage bootstrap/cache
   sudo chmod -R 775 storage bootstrap/cache
   ```

2. Cache Issues:
   ```bash
   php artisan cache:clear
   php artisan config:cache
   php artisan view:clear
   ```

3. Composer Issues:
   ```bash
   composer dump-autoload
   ```

## Contributing

Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, please create an issue in the GitHub repository or contact the maintainers.
