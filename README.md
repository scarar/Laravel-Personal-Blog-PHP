# Laravel Personal Blog

A modern, super easy-to-install blog application built with Laravel PHP framework.

## Quick Install (One Command!)

1. Open terminal and run this command (sudo password required):
```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/scarar/Laravel-Personal-Blog-PHP/main/scripts/get-blog.sh)"
```

⚠️ Note: This script needs sudo access to:
- Install required packages
- Set up web server
- Configure permissions
- Create directories

The smart installer will:
1. Check your system requirements
2. Ask where you want to install the blog
3. Guide you through setup:
   - Choose environment (local or production)
   - Select database (SQLite, MySQL, PostgreSQL)
   - Configure for your needs

💡 Quick Start (Local Development):
1. Choose "Local development"
2. Select "SQLite" database
3. Run `./start-server.sh`
And you're ready to go!

🔧 Features:
- Smart detection of installed packages
- Asks before installing anything new
- Built-in PHP server for local development
- No nginx needed for localhost
- Automatic permission handling

## Features

- ✨ Modern, clean design
- 📱 Fully responsive
- 🔒 User authentication
- 📝 Rich text editor
- 🖼️ Image upload support
- 🔍 SEO friendly URLs
- ⚡ Fast and optimized
- 💾 Multiple database support
- 🔐 Easy SSL setup

## Requirements

1. System Requirements:
   - Linux/Unix system with sudo access
   - Curl installed (`sudo apt-get install curl`)
   - For SQLite (if chosen):
     ```bash
     sudo apt-get install sqlite3 php-sqlite3
     ```

2. The installer will automatically set up:
   - PHP 8.4 and extensions
   - Nginx web server
   - Your choice of database:
     - SQLite (simplest, good for small blogs)
     - MySQL (good for medium to large blogs)
     - PostgreSQL (advanced features)

No need to install anything manually - the installer handles everything!

## Project Structure

```
Laravel-Personal-Blog-PHP/
├── config/             # Configuration templates
│   ├── nginx/         # Nginx server configs
│   └── ...           # Other config templates
├── scripts/           # Installation & maintenance scripts
│   ├── get-blog.sh   # One-command installer
│   ├── install.sh    # Main installation script
│   ├── backup.sh     # Backup utility
│   └── ...          # Other utilities
└── ... Laravel application files
```

All configuration templates and scripts are included - no manual setup needed!

## Maintenance Commands

All commands need to be run with sudo:

1. Update the installation:
```bash
# Pull latest changes
sudo git pull origin main

# Update dependencies
sudo composer install

# Clear caches
sudo php artisan optimize:clear

# Rebuild caches
sudo php artisan optimize
```

2. Common tasks:
```bash
# View routes
sudo php artisan route:list

# Clear specific caches
sudo php artisan cache:clear
sudo php artisan config:clear
sudo php artisan route:clear
sudo php artisan view:clear

# Create storage link
sudo php artisan storage:link
```

3. Database commands:
```bash
# Run migrations
sudo php artisan migrate

# Rollback migrations
sudo php artisan migrate:rollback

# Fresh install (caution: deletes data)
sudo php artisan migrate:fresh
```

## Need Help?

For support, please create an issue in the GitHub repository.
