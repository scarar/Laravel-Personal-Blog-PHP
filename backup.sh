#!/bin/bash

# Exit on error
set -e

# Configuration
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/var/backups/blog"
APP_DIR="/var/www/html/blog"
DB_NAME="your_database"
DB_USER="your_username"
RETENTION_DAYS=30

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo -e "${GREEN}Starting backup process...${NC}"

# Database backup
echo "Backing up database..."
mysqldump -u "$DB_USER" -p "$DB_NAME" > "$BACKUP_DIR/db_backup_$TIMESTAMP.sql"
gzip "$BACKUP_DIR/db_backup_$TIMESTAMP.sql"

# Application backup
echo "Backing up application files..."
tar -czf "$BACKUP_DIR/files_backup_$TIMESTAMP.tar.gz" \
    -C "$APP_DIR" \
    --exclude="vendor" \
    --exclude="node_modules" \
    --exclude="storage/logs" \
    --exclude="storage/framework/cache" \
    .

# Cleanup old backups
echo "Cleaning up old backups..."
find "$BACKUP_DIR" -name "db_backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "files_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo -e "${GREEN}Backup completed successfully!${NC}"

# List current backups
echo "Current backups:"
ls -lh "$BACKUP_DIR"