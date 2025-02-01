#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Checking database configuration..."

# Get database connection from .env
DB_CONNECTION=$(grep DB_CONNECTION .env | cut -d '=' -f2)

case $DB_CONNECTION in
    "sqlite")
        echo -e "\nChecking SQLite setup..."
        
        # Check if sqlite3 is installed
        if ! command -v sqlite3 &> /dev/null; then
            echo -e "${RED}SQLite3 is not installed. Installing...${NC}"
            sudo apt-get update
            sudo apt-get install -y sqlite3 php-sqlite3
        else
            echo -e "${GREEN}✓ SQLite3 is installed${NC}"
        fi
        
        # Check if database file exists
        DB_DATABASE=$(grep DB_DATABASE .env | cut -d '=' -f2)
        if [ ! -f "$DB_DATABASE" ]; then
            echo -e "${RED}Database file not found. Creating...${NC}"
            touch "$DB_DATABASE"
            sudo chmod 777 "$DB_DATABASE"
        fi
        
        # Test database connection
        if sqlite3 "$DB_DATABASE" "SELECT 1;" &> /dev/null; then
            echo -e "${GREEN}✓ Database connection successful${NC}"
        else
            echo -e "${RED}× Database connection failed${NC}"
            echo "Try running these commands:"
            echo "sudo touch $DB_DATABASE"
            echo "sudo chmod 777 $DB_DATABASE"
        fi
        ;;
        
    "mysql")
        echo -e "\nMySQL database selected. Please ensure MySQL is installed and configured."
        ;;
        
    "pgsql")
        echo -e "\nPostgreSQL database selected. Please ensure PostgreSQL is installed and configured."
        ;;
        
    *)
        echo -e "${RED}Unknown database connection: $DB_CONNECTION${NC}"
        ;;
esac