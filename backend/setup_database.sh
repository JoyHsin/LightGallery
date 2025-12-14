#!/bin/bash

# LightGallery Database Setup Script
# This script creates the database and tables for the authentication and subscription system

set -e

echo "=========================================="
echo "LightGallery Database Setup"
echo "=========================================="
echo ""

# Configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-lightgallery}"
DB_USERNAME="${DB_USERNAME:-root}"
DB_PASSWORD="${DB_PASSWORD:-123456}"

# Check if MySQL is installed
if ! command -v mysql &> /dev/null; then
    echo "❌ Error: MySQL is not installed or not in PATH"
    echo "Please install MySQL first:"
    echo "  macOS: brew install mysql"
    echo "  Linux: sudo apt-get install mysql-server"
    exit 1
fi

# Check if password is provided
if [ -z "$DB_PASSWORD" ]; then
    echo "⚠️  Warning: DB_PASSWORD environment variable is not set"
    echo "You will be prompted for the MySQL password"
    echo ""
    read -s -p "Enter MySQL password for user '$DB_USERNAME': " DB_PASSWORD
    echo ""
fi

echo "📋 Configuration:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  Username: $DB_USERNAME"
echo ""

# Test MySQL connection
echo "🔍 Testing MySQL connection..."
if ! mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT 1;" &> /dev/null; then
    echo "❌ Error: Cannot connect to MySQL server"
    echo "Please check your credentials and ensure MySQL is running"
    exit 1
fi
echo "✅ MySQL connection successful"
echo ""

# Create database if it doesn't exist
echo "📦 Creating database '$DB_NAME'..."
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EOF
echo "✅ Database created or already exists"
echo ""

# Run schema script
echo "🏗️  Creating tables..."
if [ ! -f "src/main/resources/schema.sql" ]; then
    echo "❌ Error: schema.sql not found at src/main/resources/schema.sql"
    echo "Please run this script from the backend directory"
    exit 1
fi

mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_NAME" < src/main/resources/schema.sql

if [ $? -eq 0 ]; then
    echo "✅ Tables created successfully"
else
    echo "❌ Error: Failed to create tables"
    exit 1
fi
echo ""

# Verify tables
echo "🔍 Verifying tables..."
TABLES=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_NAME" -e "SHOW TABLES;" -s)
echo "Tables created:"
echo "$TABLES" | while read table; do
    echo "  ✓ $table"
done
echo ""

# Show table counts
echo "📊 Table statistics:"
for table in users auth_tokens subscriptions transactions; do
    COUNT=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_NAME" -s -e "SELECT COUNT(*) FROM $table;")
    echo "  $table: $COUNT rows"
done
echo ""

echo "=========================================="
echo "✅ Database setup completed successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Update application.yml with your database credentials"
echo "2. Set environment variables:"
echo "   export DB_USERNAME=$DB_USERNAME"
echo "   export DB_PASSWORD=your_password"
echo "3. Run the Spring Boot application:"
echo "   mvn spring-boot:run"
echo ""
