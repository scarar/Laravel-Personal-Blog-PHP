# Laravel Personal Blog

A modern, super easy-to-install blog application built with Laravel PHP framework.

## Quick Install (One Command!)

1. Open terminal and run this command (sudo password required):
```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/scarar/Laravel-Personal-Blog-PHP/main/get-blog.sh)"
```

⚠️ Note: This script needs sudo access to:
- Install required packages
- Set up web server
- Configure permissions
- Create directories

The installer will:
1. Ask where you want to install the blog
2. Download everything needed
3. Guide you through a simple setup:
   - Choosing your environment (local development or production)
   - Selecting your database (SQLite, MySQL, or PostgreSQL)
   - Setting up domain (optional)
   - Configuring HTTPS/SSL (optional)
   - Setting proper permissions
   - Optimizing for performance

💡 Quick Tip: For local testing, just choose:
   1. "Local development" when asked
   2. "SQLite" as your database
   And you're ready to go!

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

2. The installer will automatically set up:
   - PHP 8.4 and extensions
   - Nginx web server
   - Your choice of database:
     - SQLite (simplest, good for small blogs)
     - MySQL (good for medium to large blogs)
     - PostgreSQL (advanced features)

No need to install anything manually - the installer handles everything!

## Configuration Files

The installer uses pre-configured templates for:
- Nginx HTTP configuration
- Nginx HTTPS configuration
- Database settings
- SSL/TLS settings

All configuration templates are in the `config` directory.

## Need Help?

For support, please create an issue in the GitHub repository.
