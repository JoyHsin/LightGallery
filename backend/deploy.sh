#!/bin/bash

# LightGallery Backend Deployment Script
# This script automates the deployment process for the backend service

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="lightgallery-backend"
APP_USER="lightgallery"
APP_GROUP="lightgallery"
INSTALL_DIR="/opt/lightgallery"
CONFIG_DIR="/etc/lightgallery"
LOG_DIR="/var/log/lightgallery"
BACKUP_DIR="/var/backups/lightgallery"

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check Java
    if ! command -v java &> /dev/null; then
        print_error "Java is not installed. Please install Java 17 or higher."
        exit 1
    fi
    
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
    if [ "$JAVA_VERSION" -lt 17 ]; then
        print_error "Java 17 or higher is required. Current version: $JAVA_VERSION"
        exit 1
    fi
    
    print_info "Java version: $JAVA_VERSION ✓"
    
    # Check MySQL
    if ! command -v mysql &> /dev/null; then
        print_warn "MySQL client is not installed. Database operations may fail."
    else
        print_info "MySQL client found ✓"
    fi
    
    # Check Maven
    if ! command -v mvn &> /dev/null; then
        print_error "Maven is not installed. Please install Maven 3.6 or higher."
        exit 1
    fi
    
    print_info "Maven found ✓"
}

create_directories() {
    print_info "Creating directories..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$BACKUP_DIR"
    
    print_info "Directories created ✓"
}

create_user() {
    print_info "Creating application user..."
    
    if id "$APP_USER" &>/dev/null; then
        print_info "User $APP_USER already exists ✓"
    else
        useradd -r -s /bin/false -d "$INSTALL_DIR" "$APP_USER"
        print_info "User $APP_USER created ✓"
    fi
}

build_application() {
    print_info "Building application..."
    
    if [ ! -f "pom.xml" ]; then
        print_error "pom.xml not found. Please run this script from the backend directory."
        exit 1
    fi
    
    mvn clean package -DskipTests
    
    if [ ! -f "target/backend-1.0.0.jar" ]; then
        print_error "Build failed. JAR file not found."
        exit 1
    fi
    
    print_info "Application built successfully ✓"
}

backup_existing() {
    if [ -f "$INSTALL_DIR/backend.jar" ]; then
        print_info "Backing up existing application..."
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        cp "$INSTALL_DIR/backend.jar" "$BACKUP_DIR/backend_$TIMESTAMP.jar"
        print_info "Backup created: $BACKUP_DIR/backend_$TIMESTAMP.jar ✓"
    fi
}

deploy_application() {
    print_info "Deploying application..."
    
    cp target/backend-1.0.0.jar "$INSTALL_DIR/backend.jar"
    chown "$APP_USER:$APP_GROUP" "$INSTALL_DIR/backend.jar"
    chmod 755 "$INSTALL_DIR/backend.jar"
    
    print_info "Application deployed ✓"
}

setup_environment() {
    print_info "Setting up environment configuration..."
    
    if [ ! -f "$CONFIG_DIR/production.env" ]; then
        print_warn "Environment file not found at $CONFIG_DIR/production.env"
        print_warn "Please create it using the template: backend/.env.template"
        
        read -p "Do you want to copy the template now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [ -f ".env.template" ]; then
                cp .env.template "$CONFIG_DIR/production.env"
                print_info "Template copied. Please edit $CONFIG_DIR/production.env with your values."
                print_warn "Deployment paused. Edit the file and run this script again."
                exit 0
            else
                print_error "Template file not found."
                exit 1
            fi
        else
            print_error "Environment file is required for deployment."
            exit 1
        fi
    fi
    
    # Set proper permissions
    chown root:root "$CONFIG_DIR/production.env"
    chmod 600 "$CONFIG_DIR/production.env"
    
    print_info "Environment configuration set up ✓"
}

setup_systemd() {
    print_info "Setting up systemd service..."
    
    cat > /etc/systemd/system/$APP_NAME.service << EOF
[Unit]
Description=LightGallery Backend Service
After=network.target mysql.service

[Service]
Type=simple
User=$APP_USER
Group=$APP_GROUP
WorkingDirectory=$INSTALL_DIR
EnvironmentFile=$CONFIG_DIR/production.env
ExecStart=/usr/bin/java -jar $INSTALL_DIR/backend.jar --spring.profiles.active=prod
StandardOutput=append:$LOG_DIR/application.log
StandardError=append:$LOG_DIR/error.log
Restart=always
RestartSec=10
SuccessExitStatus=143

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$LOG_DIR

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable $APP_NAME
    
    print_info "Systemd service configured ✓"
}

setup_log_rotation() {
    print_info "Setting up log rotation..."
    
    cat > /etc/logrotate.d/$APP_NAME << EOF
$LOG_DIR/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 $APP_USER $APP_GROUP
    sharedscripts
    postrotate
        systemctl reload $APP_NAME > /dev/null 2>&1 || true
    endscript
}
EOF
    
    print_info "Log rotation configured ✓"
}

start_service() {
    print_info "Starting service..."
    
    systemctl start $APP_NAME
    
    # Wait for service to start
    sleep 5
    
    if systemctl is-active --quiet $APP_NAME; then
        print_info "Service started successfully ✓"
    else
        print_error "Service failed to start. Check logs: journalctl -u $APP_NAME -n 50"
        exit 1
    fi
}

verify_deployment() {
    print_info "Verifying deployment..."
    
    # Check service status
    if systemctl is-active --quiet $APP_NAME; then
        print_info "Service is running ✓"
    else
        print_error "Service is not running"
        return 1
    fi
    
    # Wait for application to be ready
    print_info "Waiting for application to be ready..."
    sleep 10
    
    # Check health endpoint
    HEALTH_URL="http://localhost:8080/api/v1/health"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL 2>/dev/null || echo "000")
    
    if [ "$RESPONSE" = "200" ]; then
        print_info "Health check passed ✓"
    else
        print_warn "Health check failed (HTTP $RESPONSE). Service may still be starting..."
        print_warn "Check logs: journalctl -u $APP_NAME -f"
    fi
}

show_status() {
    echo ""
    echo "=========================================="
    echo "Deployment Summary"
    echo "=========================================="
    echo "Application: $APP_NAME"
    echo "Install Directory: $INSTALL_DIR"
    echo "Config Directory: $CONFIG_DIR"
    echo "Log Directory: $LOG_DIR"
    echo "Service Status: $(systemctl is-active $APP_NAME)"
    echo ""
    echo "Useful Commands:"
    echo "  View logs: journalctl -u $APP_NAME -f"
    echo "  Restart: systemctl restart $APP_NAME"
    echo "  Stop: systemctl stop $APP_NAME"
    echo "  Status: systemctl status $APP_NAME"
    echo "=========================================="
}

# Main deployment flow
main() {
    print_info "Starting LightGallery Backend Deployment"
    echo ""
    
    check_root
    check_prerequisites
    create_directories
    create_user
    build_application
    backup_existing
    deploy_application
    setup_environment
    setup_systemd
    setup_log_rotation
    start_service
    verify_deployment
    show_status
    
    print_info "Deployment completed successfully! 🎉"
}

# Run main function
main
