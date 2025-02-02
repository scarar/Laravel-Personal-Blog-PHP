# Laravel Personal Blog

A modern, secure, and easy-to-use personal blog system built with Laravel, TailwindCSS, and Alpine.js.

## Quick Installation

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/scarar/Laravel-Personal-Blog-PHP/main/scripts/get-blog.sh)"
```

The installer will guide you through the setup process and handle everything automatically.

## Features

- 🚀 Modern Stack: Laravel 11, PHP 8.4, Node.js 20
- 🎨 Beautiful UI with TailwindCSS
- 📝 Rich Text Editor (TinyMCE)
- 🖼️ Image Upload Support
- 🔒 User Authentication & Authorization
- 👤 Admin Dashboard
- 📱 Fully Responsive Design
- 🔍 SEO Friendly URLs
- 💾 SQLite/MySQL Support
- 🔐 SSL Support
- 🔄 Automatic Backups
- ⚡ Production Optimized

## System Requirements

- PHP 8.4 or higher
- Node.js 20.x or higher
- Nginx
- SQLite or MySQL
- Composer
- Git

All requirements will be checked and installed automatically by the installer.

## Installation Process

1. Run the installer:
```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/scarar/Laravel-Personal-Blog-PHP/main/scripts/get-blog.sh)"
```

2. Follow the prompts:
   - Enter domain name
   - Choose port (80/443)
   - Select installation directory
   - Choose database type (SQLite/MySQL)

3. The installer will:
   - Install required packages
   - Configure PHP and extensions
   - Set up Node.js and npm
   - Install and configure Nginx
   - Set up SSL (if needed)
   - Install Composer
   - Configure the application
   - Build frontend assets
   - Set proper permissions
   - Create database
   - Run migrations
   - Optimize for production

4. After installation:
   - Create admin user: `php artisan make:admin`
   - Access your blog at: http://your-domain
   - Log in and start posting!

## Directory Structure

```
Laravel-Personal-Blog-PHP/
├── app/                # Application code
│   ├── Http/          # Controllers, Middleware
│   ├── Models/        # Database models
│   └── Console/       # Artisan commands
├── config/            # Configuration files
├── database/          # Migrations and seeders
├── public/            # Web root
├── resources/         # Views and assets
│   ├── views/         # Blade templates
│   ├── css/          # Stylesheets
│   └── js/           # JavaScript
├── routes/            # Route definitions
├── scripts/          # Maintenance scripts
│   ├── backup.sh     # Backup utility
│   ├── restore.sh    # Restore utility
│   └── update.sh     # Update script
└── storage/          # Uploads and caches
```

## Maintenance

1. Backup Database:
```bash
sudo ./scripts/backup.sh
```

2. Restore from Backup:
```bash
sudo ./scripts/restore.sh
```

3. Update Application:
```bash
sudo ./scripts/update.sh
```

4. Clear Cache:
```bash
php artisan optimize:clear
```

5. Rebuild Cache:
```bash
php artisan optimize
```

## Security

1. File Permissions:
- Web server user (www-data) ownership
- Restrictive directory permissions (755)
- Restrictive file permissions (644)
- Write permissions only where needed

2. Database Security:
- Prepared statements
- Input validation
- SQLite file permissions
- Regular backups

3. Web Security:
- CSRF protection
- XSS prevention
- SQL injection prevention
- Secure headers
- SSL/TLS support

## Configuration

1. Environment (.env):
```env
APP_NAME="Personal Blog"
APP_ENV=production
APP_DEBUG=false
DB_CONNECTION=sqlite
DB_DATABASE=/path/to/database.sqlite
```

2. Nginx:
- Configuration in: /etc/nginx/sites-available/laravel-blog
- SSL configuration (if enabled)
- Optimized for performance
- Security headers

3. PHP:
- PHP-FPM configuration
- Optimized for production
- Required extensions
- Proper memory limits

## Troubleshooting

1. Permission Issues:
```bash
sudo ./scripts/fix-permissions.sh
```

2. Asset Issues:
```bash
npm install
npm run build
```

3. Cache Issues:
```bash
php artisan optimize:clear
php artisan optimize
```

4. Database Issues:
```bash
php artisan migrate:status
php artisan migrate:fresh
```

## Support

1. Documentation:
- Check this README
- Visit Laravel documentation
- Review installation logs

2. Common Issues:
- Check permissions
- Verify configurations
- Review error logs

3. Get Help:
- Open an issue
- Check existing issues
- Join discussions

## License

This project is open-source software licensed under the MIT license.
