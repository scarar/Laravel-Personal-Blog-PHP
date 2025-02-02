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

# Function to backup MySQL database
backup_mysql() {
    local DB_NAME=$(grep DB_DATABASE .env | cut -d '=' -f2)
    local DB_USER=$(grep DB_USERNAME .env | cut -d '=' -f2)
    local DB_PASS=$(grep DB_PASSWORD .env | cut -d '=' -f2)
    
    if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ]; then
        print_error "MySQL credentials not found in .env file"
    fi
    
    mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/database_$DATE.sql"
    gzip "$BACKUP_DIR/database_$DATE.sql"
    print_success "MySQL database backed up to $BACKUP_DIR/database_$DATE.sql.gz"
}

# Function to backup SQLite database
backup_sqlite() {
    if [ -f "database/database.sqlite" ]; then
        cp database/database.sqlite "$BACKUP_DIR/database_$DATE.sqlite"
        print_success "SQLite database backed up to $BACKUP_DIR/database_$DATE.sqlite"
    else
        print_error "SQLite database file not found"
    fi
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root"
fi

# Create backup directory if it doesn't exist
BACKUP_DIR="/var/backups/laravel-blog"
mkdir -p "$BACKUP_DIR"

# Get current date for backup file names
DATE=$(date +%Y-%m-%d_%H-%M-%S)

print_status "Starting backup process..."

# Check database type and backup accordingly
if [ -f ".env" ]; then
    DB_CONNECTION=$(grep DB_CONNECTION .env | cut -d '=' -f2)
    
    print_status "Detected database type: $DB_CONNECTION"
    print_status "Backing up database..."
    
    case $DB_CONNECTION in
        mysql)
            backup_mysql
            ;;
        sqlite)
            backup_sqlite
            ;;
        *)
            print_error "Unsupported database type: $DB_CONNECTION"
            ;;
    esac
else
    print_error "Environment file not found"
fi

# Backup uploads
print_status "Backing up uploads..."
if [ -d "storage/app/public" ]; then
    tar -czf "$BACKUP_DIR/uploads_$DATE.tar.gz" storage/app/public/
    print_success "Uploads backed up to $BACKUP_DIR/uploads_$DATE.tar.gz"
else
    print_error "Uploads directory not found"
fi

# Backup configuration
print_status "Backing up configuration..."
if [ -f ".env" ]; then
    cp .env "$BACKUP_DIR/env_$DATE"
    print_success "Environment file backed up to $BACKUP_DIR/env_$DATE"
else
    print_error "Environment file not found"
fi

# Clean old backups (keep last 7 days)
print_status "Cleaning old backups..."
find "$BACKUP_DIR" -type f -mtime +7 -delete

# Set proper permissions on backup directory
chown -R root:root "$BACKUP_DIR"
chmod -R 600 "$BACKUP_DIR"

print_success "Backup completed successfully!"
echo -e "${GREEN}Backup files are stored in: $BACKUP_DIR${NC}"
echo -e "${YELLOW}Notes:${NC}"
echo "1. Only the last 7 days of backups are kept"
echo "2. Database type: $DB_CONNECTION"
echo "3. Backup location: $BACKUP_DIR"