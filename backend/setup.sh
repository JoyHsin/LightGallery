#!/bin/bash

# LightGallery Backend Setup Script

echo "==================================="
echo "LightGallery Backend Setup"
echo "==================================="

# Check Java version
echo "Checking Java version..."
java -version 2>&1 | grep -q "version \"17"
if [ $? -ne 0 ]; then
    echo "❌ Java 17 is required but not found"
    echo "Please install Java 17 or higher"
    exit 1
fi
echo "✅ Java 17+ detected"

# Check Maven
echo "Checking Maven..."
if ! command -v mvn &> /dev/null; then
    echo "❌ Maven is not installed"
    echo "Please install Maven 3.6+"
    exit 1
fi
echo "✅ Maven detected"

# Check MySQL
echo "Checking MySQL..."
if ! command -v mysql &> /dev/null; then
    echo "⚠️  MySQL client not found in PATH"
    echo "Please ensure MySQL 8.0+ is installed and running"
else
    echo "✅ MySQL client detected"
fi

# Create database
echo ""
echo "Do you want to create the database? (y/n)"
read -r create_db

if [ "$create_db" = "y" ]; then
    echo "Enter MySQL root password:"
    read -s mysql_password
    
    mysql -u root -p"$mysql_password" -e "CREATE DATABASE IF NOT EXISTS lightgallery CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Database 'lightgallery' created successfully"
    else
        echo "❌ Failed to create database. Please create it manually:"
        echo "   CREATE DATABASE lightgallery CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    fi
fi

# Install dependencies
echo ""
echo "Installing Maven dependencies..."
mvn clean install -DskipTests

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully"
else
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo ""
echo "==================================="
echo "Setup Complete!"
echo "==================================="
echo ""
echo "To run the application:"
echo "  Development: mvn spring-boot:run"
echo "  Production:  mvn clean package && java -jar target/backend-1.0.0.jar --spring.profiles.active=prod"
echo ""
echo "Health check: curl http://localhost:8080/api/v1/health"
echo ""
