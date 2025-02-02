#!/bin/bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print status messages
print_status() {
    echo -e "${YELLOW}[*] $1${NC}"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}[+] $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}[-] $1${NC}"
    exit 1
}

# Function to restore MySQL database
restore_mysql() {
    local DB_NAME=$(grep DB_DATABASE .env | cut -d '=' -f2)
    local DB_USER=$(grep DB_USERNAME .env | cut -d '=' -f2)
    local DB_PASS=$(grep DB_PASSWORD .env | cut -d '=' -f2)
    
    if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ]; then
        print_error "MySQL credentials not found in .env file"
    fi
    
    # Restore from gzipped SQL dump
    gunzip -c "$DB_BACKUP" | mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME"
    print_success "MySQL database restored from $DB_BACKUP"
}

# Function to restore SQLite database
restore_sqlite() {
    cp "$DB_BACKUP" database/database.sqlite
    chown www-data:www-data database/database.sqlite
    chmod 775 database/database.sqlite
    print_success "SQLite database restored from $DB_BACKUP"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root"
fi

# Backup directory
BACKUP_DIR="/var/backups/laravel-blog"

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    print_error "Backup directory not found: $BACKUP_DIR"
fi

# List available backups
print_status "Available backups:"
echo
echo "MySQL database backups:"
ls -1 "$BACKUP_DIR"/database_*.sql.gz 2>/dev/null || echo "No MySQL backups found"
echo
echo "SQLite database backups:"
ls -1 "$BACKUP_DIR"/database_*.sqlite 2>/dev/null || echo "No SQLite backups found"
echo
echo "Upload backups:"
ls -1 "$BACKUP_DIR"/uploads_* 2>/dev/null || echo "No upload backups found"
echo
echo "Environment backups:"
ls -1 "$BACKUP_DIR"/env_* 2>/dev/null || echo "No environment backups found"
echo

# Ask which backup to restore
read -p "Enter the date of the backup to restore (YYYY-MM-DD_HH-MM-SS): " BACKUP_DATE

# Restore environment file first to determine database type
ENV_BACKUP="$BACKUP_DIR/env_$BACKUP_DATE"
if [ ! -f "$ENV_BACKUP" ]; then
    print_error "Environment backup not found for date: $BACKUP_DATE"
fi

# Restore environment file temporarily to check database type
cp "$ENV_BACKUP" .env.restore
DB_CONNECTION=$(grep DB_CONNECTION .env.restore | cut -d '=' -f2)
rm .env.restore

# Set database backup file based on database type
case $DB_CONNECTION in
    mysql)
        DB_BACKUP="$BACKUP_DIR/database_$BACKUP_DATE.sql.gz"
        ;;
    sqlite)
        DB_BACKUP="$BACKUP_DIR/database_$BACKUP_DATE.sqlite"
        ;;
    *)
        print_error "Unsupported database type: $DB_CONNECTION"
        ;;
esac

UPLOADS_BACKUP="$BACKUP_DIR/uploads_$BACKUP_DATE.tar.gz"

# Validate backup files exist
if [ ! -f "$DB_BACKUP" ] || [ ! -f "$UPLOADS_BACKUP" ] || [ ! -f "$ENV_BACKUP" ]; then
    print_error "Complete backup set not found for date: $BACKUP_DATE"
fi

# Confirm restore
echo -e "${RED}WARNING: This will overwrite current data. Make sure you have a backup!${NC}"
read -p "Are you sure you want to proceed? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Restore cancelled by user"
fi

print_status "Starting restore process..."

# Stop web server
print_status "Stopping web server..."
systemctl stop nginx

# Restore environment file
print_status "Restoring environment file..."
cp "$ENV_BACKUP" .env
chown www-data:www-data .env
chmod 644 .env

# Restore database based on type
print_status "Restoring database..."
case $DB_CONNECTION in
    mysql)
        restore_mysql
        ;;
    sqlite)
        restore_sqlite
        ;;
esac

# Restore uploads
print_status "Restoring uploads..."
rm -rf storage/app/public/*
tar -xzf "$UPLOADS_BACKUP" -C storage/app/public/
chown -R www-data:www-data storage/app/public

# Clear Laravel cache
print_status "Clearing Laravel cache..."
php artisan optimize:clear

# Start web server
print_status "Starting web server..."
systemctl start nginx

print_success "Restore completed successfully!"
echo -e "${YELLOW}Notes:${NC}"
echo "1. Database type: $DB_CONNECTION"
echo "2. You may need to run 'php artisan migrate' if database schema has changed"
echo "3. Check application logs for any potential issues"