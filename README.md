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
   sudo composer install
   # Note: npm is not required for basic deployment
   ```

3. Configure environment:
   ```bash
   sudo cp .env.example .env
   sudo php artisan key:generate
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
   sudo php artisan migrate
   ```

6. Create storage link:
   ```bash
   sudo php artisan storage:link
   ```

7. Build Assets for Production:
   ```bash
   # Build and minify frontend assets
   npm run build
   
   # Configure your web server (Nginx) to point to the /public directory
   # See "Production Deployment" section below for Nginx configuration
   ```

## Quick Deployment

1. Clone the repository wherever you want to install it:
   ```bash
   # Clone to your desired location
   git clone https://github.com/scarar/Laravel-Personal-Blog-PHP.git blog
   cd blog
   ```

2. Run the setup script:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```
   The setup script will:
   - Configure Nginx for your specific installation directory
   - Set up your environment file
   - Install dependencies
   - Set proper permissions
   - Create storage link
   - Run database migrations
   - Optimize Laravel for production

3. Set up SSL (after pointing your domain to the server):
   ```bash
   sudo certbot --nginx -d your-domain.com
   ```

4. Start using your blog:
   ```bash
   # Restart Nginx to apply changes
   sudo systemctl restart nginx
   ```

5. (Optional) Set up automatic backups:
   ```bash
   chmod +x backup.sh
   sudo cp backup.sh /usr/local/bin/blog-backup
   sudo crontab -e
   # Add: 0 2 * * * /usr/local/bin/blog-backup
   ```

## Detailed Deployment

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

#### PHP Configuration
```ini
; PHP Production Settings (/etc/php/8.4/fpm/php.ini)
memory_limit = 256M
max_execution_time = 60
max_input_time = 60
post_max_size = 64M
upload_max_filesize = 32M
display_errors = Off
display_startup_errors = Off
log_errors = On
error_log = /var/log/php8.4-fpm.log
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT

; OpCache Settings
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=10000
opcache.validate_timestamps=0
opcache.revalidate_freq=0
opcache.save_comments=0
```

#### PHP-FPM Configuration
```ini
; /etc/php/8.4/fpm/pool.d/www.conf
[www]
user = www-data
group = www-data
listen = /var/run/php/php8.4-fpm.sock
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500
request_terminate_timeout = 60s
```

#### Nginx Configuration
```nginx
# HTTP - redirect all requests to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name your-domain.com;
    root /path/to/laravel-blog/public;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';";
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=()";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Logging
    access_log /var/log/nginx/your-domain.access.log combined buffer=512k flush=1m;
    error_log /var/log/nginx/your-domain.error.log warn;

    # Index and Character Set
    index index.php;
    charset utf-8;

    # Handle PHP Files
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
        fastcgi_read_timeout 600;
    }

    # Laravel Front Controller Pattern
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # Static File Caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        access_log off;
        add_header Cache-Control "public, no-transform";
    }

    # Deny Access to Sensitive Files
    location ~ /\.(?!well-known) {
        deny all;
    }
    location ~ /composer\.(json|lock)$ {
        deny all;
    }
    location ~ /package(-lock)?.json$ {
        deny all;
    }
    location ~ /phpunit.xml$ {
        deny all;
    }
    location ~ /README.md$ {
        deny all;
    }
    location ~ /vendor/ {
        deny all;
    }
    location ~ \.env$ {
        deny all;
    }

    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/javascript application/xml application/json;
    gzip_disable "MSIE [1-6]\.";

    # Rate Limiting
    limit_req_zone $binary_remote_addr zone=one:10m rate=1r/s;
    limit_req zone=one burst=10 nodelay;
}
```

### 3. Deployment Steps

1. Prepare Production Environment:
   ```bash
   # Install dependencies
   sudo composer install --optimize-autoloader --no-dev

   # Set proper permissions
   sudo chown -R www-data:www-data /path/to/laravel-blog
   sudo find /path/to/laravel-blog -type f -exec chmod 644 {} \;
   sudo find /path/to/laravel-blog -type d -exec chmod 755 {} \;
   sudo chmod -R 775 /path/to/laravel-blog/storage
   sudo chmod -R 775 /path/to/laravel-blog/bootstrap/cache
   ```

2. Configure Production Environment:
   ```bash
   # Set up environment file
   sudo cp .env.example .env
   sudo php artisan key:generate
   ```

   Configure your `.env` file with these production settings:
   ```env
   APP_NAME="Laravel Personal Blog"
   APP_ENV=production
   APP_DEBUG=false
   APP_URL=https://your-domain.com
   APP_KEY=your-generated-key

   LOG_CHANNEL=stack
   LOG_DEPRECATIONS_CHANNEL=null
   LOG_LEVEL=error

   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=your_database
   DB_USERNAME=your_username
   DB_PASSWORD=your_secure_password
   DB_STRICT=true
   DB_ENGINE=InnoDB

   BROADCAST_DRIVER=log
   CACHE_DRIVER=file
   FILESYSTEM_DISK=local
   QUEUE_CONNECTION=sync
   SESSION_DRIVER=file
   SESSION_LIFETIME=120
   SESSION_SECURE_COOKIE=true
   SESSION_DOMAIN=your-domain.com

   MEMCACHED_HOST=127.0.0.1

   MAIL_MAILER=smtp
   MAIL_HOST=your-smtp-server
   MAIL_PORT=587
   MAIL_USERNAME=your-username
   MAIL_PASSWORD=your-password
   MAIL_ENCRYPTION=tls
   MAIL_FROM_ADDRESS="noreply@your-domain.com"
   MAIL_FROM_NAME="${APP_NAME}"
   ```

3. Optimize Laravel:
   ```bash
   sudo php artisan config:cache
   sudo php artisan route:cache
   sudo php artisan view:cache
   sudo php artisan storage:link
   ```

4. Database Setup:
   ```bash
   sudo php artisan migrate --force
   ```

### 4. Security Measures

1. File Permissions:
   ```bash
   sudo find /path/to/laravel-blog -type f -exec chmod 644 {} \;
   sudo find /path/to/laravel-blog -type d -exec chmod 755 {} \;
   sudo chmod -R ug+rwx storage bootstrap/cache
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
   sudo composer update --no-dev
   sudo php artisan migrate
   ```

2. Cache Management:
   ```bash
   sudo php artisan cache:clear
   sudo php artisan config:clear
   sudo php artisan view:clear
   ```

3. Backup Strategy:
   ```bash
   # Database backup
   sudo mysqldump -u user -p database_name > backup.sql
   sudo chown $(whoami):$(whoami) backup.sql

   # Application backup
   sudo tar -czf backup.tar.gz /path/to/laravel-blog
   sudo chown $(whoami):$(whoami) backup.tar.gz
   ```

## Monitoring and Logging

### Log Files

1. Laravel Log Files:
   ```bash
   sudo tail -f storage/logs/laravel.log
   ```

2. Nginx Access/Error Logs:
   ```bash
   sudo tail -f /var/log/nginx/access.log
   sudo tail -f /var/log/nginx/error.log
   ```

3. PHP-FPM Logs:
   ```bash
   sudo tail -f /var/log/php8.4-fpm.log
   ```

### Performance Monitoring

1. Install monitoring tools:
   ```bash
   sudo apt-get install -y htop iotop nethogs
   ```

2. Monitor system resources:
   ```bash
   # CPU and Memory usage
   sudo htop

   # Disk I/O
   sudo iotop

   # Network usage
   sudo nethogs
   ```

3. MySQL monitoring:
   ```bash
   # Monitor MySQL queries
   sudo tail -f /var/log/mysql/mysql-slow.log

   # Check MySQL status
   sudo mysqladmin status
   ```

### Security Monitoring

1. Install security tools:
   ```bash
   sudo apt-get install -y fail2ban logwatch
   ```

2. Configure Fail2ban:
   ```bash
   sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
   sudo nano /etc/fail2ban/jail.local
   ```

   Add to jail.local:
   ```ini
   [nginx-http-auth]
   enabled = true
   port    = http,https
   logpath = /var/log/nginx/error.log

   [php-url-fopen]
   enabled = true
   port    = http,https
   logpath = /var/log/nginx/access.log
   ```

3. Setup daily security reports:
   ```bash
   sudo nano /etc/cron.daily/00logwatch
   ```

   Add to crontab:
   ```bash
   sudo crontab -e
   # Add this line:
   0 0 * * * /usr/sbin/logwatch --output mail --mailto your-email@domain.com --detail high
   ```

### Backup Strategy

1. Database Backups:
   ```bash
   # Create backup script
   sudo nano /usr/local/bin/backup-db.sh
   ```

   Add to script:
   ```bash
   #!/bin/bash
   TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
   BACKUP_DIR="/path/to/backups"
   DB_NAME="your_database"
   
   # Create backup
   sudo mysqldump -u root -p "$DB_NAME" > "$BACKUP_DIR/db_backup_$TIMESTAMP.sql"
   
   # Compress backup
   gzip "$BACKUP_DIR/db_backup_$TIMESTAMP.sql"
   
   # Remove backups older than 30 days
   find "$BACKUP_DIR" -name "db_backup_*.sql.gz" -mtime +30 -delete
   ```

2. File Backups:
   ```bash
   # Create backup script
   sudo nano /usr/local/bin/backup-files.sh
   ```

   Add to script:
   ```bash
   #!/bin/bash
   TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
   BACKUP_DIR="/path/to/backups"
   APP_DIR="/path/to/laravel-blog"
   
   # Create backup
   sudo tar -czf "$BACKUP_DIR/files_backup_$TIMESTAMP.tar.gz" \
       -C "$APP_DIR" \
       --exclude="vendor" \
       --exclude="node_modules" \
       --exclude="storage/logs" \
       --exclude="storage/framework/cache" \
       .
   
   # Remove backups older than 30 days
   find "$BACKUP_DIR" -name "files_backup_*.tar.gz" -mtime +30 -delete
   ```

3. Schedule backups:
   ```bash
   sudo crontab -e
   ```

   Add to crontab:
   ```cron
   # Database backup every 6 hours
   0 */6 * * * /usr/local/bin/backup-db.sh

   # File backup daily at 2 AM
   0 2 * * * /usr/local/bin/backup-files.sh
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
   sudo composer dump-autoload
   ```

## Contributing

Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, please create an issue in the GitHub repository or contact the maintainers.
