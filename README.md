# Laravel Personal Blog

A modern, super easy-to-install blog application built with Laravel PHP framework.

## Quick Install (One Command!)

Download and run the installer with one command:
```bash
curl -s https://raw.githubusercontent.com/scarar/Laravel-Personal-Blog-PHP/main/get-blog.sh | sudo bash
```

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

- PHP 8.4
- Web server (Nginx recommended)
- One of these databases:
  - SQLite (simplest, good for small blogs)
  - MySQL (good for medium to large blogs)
  - PostgreSQL (advanced features)

## Configuration Files

The installer uses pre-configured templates for:
- Nginx HTTP configuration
- Nginx HTTPS configuration
- Database settings
- SSL/TLS settings

All configuration templates are in the `config` directory.

## Need Help?

For support, please create an issue in the GitHub repository.
