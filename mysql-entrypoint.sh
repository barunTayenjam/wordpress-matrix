#!/bin/bash
# MySQL Database Initialization Script
# Creates databases for WordPress sites automatically

set -e

# Function to create database if it doesn't exist
create_db_if_not_exists() {
    local db_name="$1"
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`$db_name\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
}

# Wait for MySQL to be ready
until mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1;" &>/dev/null; do
    echo "Waiting for MySQL to be ready..."
    sleep 2
done

echo "MySQL is ready. Initializing databases..."

# Create main database if it doesn't exist
create_db_if_not_exists "wp_main"

echo "Database initialization complete."