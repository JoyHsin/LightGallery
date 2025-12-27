#!/bin/bash

# LightGallery Production Database Setup Script
# This script sets up the production database with proper security

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Prompt for database credentials
prompt_credentials() {
    print_step "Database Configuration"
    echo ""
    
    read -p "Database Host [localhost]: " DB_HOST
    DB_HOST=${DB_HOST:-localhost}
    
    read -p "Database Port [3306]: " DB_PORT
    DB_PORT=${DB_PORT:-3306}
    
    read -p "Database Name [declutter]: " DB_NAME
    DB_NAME=${DB_NAME:-declutter}
    
    read -p "Admin Username [root]: " ADMIN_USER
    ADMIN_USER=${ADMIN_USER:-root}
    
    read -sp "Admin Password: " ADMIN_PASS
    echo ""
    
    read -p "Application Username [declutter_app]: " APP_USER
    APP_USER=${APP_USER:-declutter_app}
    
    # Generate strong password for app user
    print_info "Generating strong password for application user..."
    APP_PASS=$(openssl rand -base64 32)
    
    echo ""
    print_info "Configuration:"
    echo "  Host: $DB_HOST:$DB_PORT"
    echo "  Database: $DB_NAME"
    echo "  Admin User: $ADMIN_USER"
    echo "  App User: $APP_USER"
    echo "  App Password: $APP_PASS"
    echo ""
    
    read -p "Proceed with this configuration? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Setup cancelled by user"
        exit 1
    fi
}

# Test database connection
test_connection() {
    print_step "Testing database connection..."
    
    if mysql -h "$DB_HOST" -P "$DB_PORT" -u "$ADMIN_USER" -p"$ADMIN_PASS" -e "SELECT 1" > /dev/null 2>&1; then
        print_info "Database connection successful ✓"
    else
        print_error "Failed to connect to database"
        print_error "Please check your credentials and try again"
        exit 1
    fi
}

# Create database
create_database() {
    print_step "Creating database..."
    
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$ADMIN_USER" -p"$ADMIN_PASS" << EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;
EOF
    
    if [ $? -eq 0 ]; then
        print_info "Database '$DB_NAME' created successfully ✓"
    else
        print_error "Failed to create database"
        exit 1
    fi
}

# Create application user
create_app_user() {
    print_step "Creating application user..."
    
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$ADMIN_USER" -p"$ADMIN_PASS" << EOF
-- Drop user if exists
DROP USER IF EXISTS '$APP_USER'@'%';

-- Create new user
CREATE USER '$APP_USER'@'%' IDENTIFIED BY '$APP_PASS';

-- Grant necessary privileges
GRANT SELECT, INSERT, UPDATE, DELETE ON $DB_NAME.* TO '$APP_USER'@'%';

-- Flush privileges
FLUSH PRIVILEGES;
EOF
    
    if [ $? -eq 0 ]; then
        print_info "Application user '$APP_USER' created successfully ✓"
    else
        print_error "Failed to create application user"
        exit 1
    fi
}

# Run schema script
run_schema() {
    print_step "Running database schema..."
    
    if [ ! -f "src/main/resources/schema.sql" ]; then
        print_error "Schema file not found: src/main/resources/schema.sql"
        print_error "Please run this script from the backend directory"
        exit 1
    fi
    
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$ADMIN_USER" -p"$ADMIN_PASS" "$DB_NAME" < src/main/resources/schema.sql
    
    if [ $? -eq 0 ]; then
        print_info "Database schema created successfully ✓"
    else
        print_error "Failed to create database schema"
        exit 1
    fi
}

# Verify schema
verify_schema() {
    print_step "Verifying database schema..."
    
    TABLES=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$ADMIN_USER" -p"$ADMIN_PASS" -N -B -e "USE $DB_NAME; SHOW TABLES;")
    
    EXPECTED_TABLES=("users" "subscriptions" "transactions" "auth_tokens")
    
    for table in "${EXPECTED_TABLES[@]}"; do
        if echo "$TABLES" | grep -q "^$table$"; then
            print_info "Table '$table' exists ✓"
        else
            print_error "Table '$table' not found"
            exit 1
        fi
    done
    
    print_info "All tables verified ✓"
}

# Verify indexes
verify_indexes() {
    print_step "Verifying indexes..."
    
    # Check users table indexes
    USERS_INDEXES=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$ADMIN_USER" -p"$ADMIN_PASS" -N -B -e "USE $DB_NAME; SHOW INDEX FROM users WHERE Key_name != 'PRIMARY';")
    
    if echo "$USERS_INDEXES" | grep -q "idx_email"; then
        print_info "Index 'idx_email' on users table exists ✓"
    else
        print_warn "Index 'idx_email' on users table not found"
    fi
    
    if echo "$USERS_INDEXES" | grep -q "idx_provider_id"; then
        print_info "Index 'idx_provider_id' on users table exists ✓"
    else
        print_warn "Index 'idx_provider_id' on users table not found"
    fi
    
    # Check subscriptions table indexes
    SUBS_INDEXES=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$ADMIN_USER" -p"$ADMIN_PASS" -N -B -e "USE $DB_NAME; SHOW INDEX FROM subscriptions WHERE Key_name != 'PRIMARY';")
    
    if echo "$SUBS_INDEXES" | grep -q "idx_user_id"; then
        print_info "Index 'idx_user_id' on subscriptions table exists ✓"
    else
        print_warn "Index 'idx_user_id' on subscriptions table not found"
    fi
    
    if echo "$SUBS_INDEXES" | grep -q "idx_status"; then
        print_info "Index 'idx_status' on subscriptions table exists ✓"
    else
        print_warn "Index 'idx_status' on subscriptions table not found"
    fi
}

# Save credentials
save_credentials() {
    print_step "Saving credentials..."
    
    CREDS_FILE="/etc/declutter/database.credentials"
    
    # Create directory if it doesn't exist
    if [ ! -d "/etc/declutter" ]; then
        print_warn "/etc/declutter directory doesn't exist"
        print_info "Creating directory..."
        sudo mkdir -p /etc/declutter
    fi
    
    # Save credentials
    sudo tee "$CREDS_FILE" > /dev/null << EOF
# LightGallery Database Credentials
# Generated: $(date)
# WARNING: Keep this file secure!

DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_USERNAME=$APP_USER
DB_PASSWORD=$APP_PASS
EOF
    
    # Set proper permissions
    sudo chmod 600 "$CREDS_FILE"
    sudo chown root:root "$CREDS_FILE"
    
    print_info "Credentials saved to: $CREDS_FILE ✓"
    print_warn "Keep this file secure! It contains sensitive information."
}

# Setup backup script
setup_backup() {
    print_step "Setting up automated backups..."
    
    BACKUP_SCRIPT="/usr/local/bin/backup-declutter-db.sh"
    
    sudo tee "$BACKUP_SCRIPT" > /dev/null << EOF
#!/bin/bash
# LightGallery Database Backup Script
# Generated: $(date)

BACKUP_DIR="/var/backups/declutter"
DATE=\$(date +%Y%m%d_%H%M%S)
DB_HOST="$DB_HOST"
DB_PORT="$DB_PORT"
DB_NAME="$DB_NAME"
DB_USER="$APP_USER"
DB_PASS="$APP_PASS"

# Create backup directory
mkdir -p \$BACKUP_DIR

# Perform backup
mysqldump -h \$DB_HOST -P \$DB_PORT -u \$DB_USER -p\$DB_PASS \\
  --single-transaction \\
  --routines \\
  --triggers \\
  --events \\
  \$DB_NAME | gzip > \$BACKUP_DIR/declutter_\$DATE.sql.gz

# Check if backup was successful
if [ \$? -eq 0 ]; then
    echo "[\$(date)] Backup successful: declutter_\$DATE.sql.gz"
    
    # Keep only last 30 days of backups
    find \$BACKUP_DIR -name "declutter_*.sql.gz" -mtime +30 -delete
else
    echo "[\$(date)] Backup failed!" >&2
    exit 1
fi
EOF
    
    sudo chmod +x "$BACKUP_SCRIPT"
    
    print_info "Backup script created: $BACKUP_SCRIPT ✓"
    
    # Add to crontab
    read -p "Add daily backup to crontab? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        (sudo crontab -l 2>/dev/null; echo "0 2 * * * $BACKUP_SCRIPT >> /var/log/declutter-backup.log 2>&1") | sudo crontab -
        print_info "Daily backup scheduled at 2:00 AM ✓"
    fi
}

# Display summary
display_summary() {
    echo ""
    echo "=========================================="
    echo "Database Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Database Information:"
    echo "  Host: $DB_HOST:$DB_PORT"
    echo "  Database: $DB_NAME"
    echo "  Username: $APP_USER"
    echo "  Password: $APP_PASS"
    echo ""
    echo "Credentials saved to: /etc/declutter/database.credentials"
    echo ""
    echo "Next Steps:"
    echo "  1. Update backend environment variables:"
    echo "     export DB_HOST=$DB_HOST"
    echo "     export DB_PORT=$DB_PORT"
    echo "     export DB_NAME=$DB_NAME"
    echo "     export DB_USERNAME=$APP_USER"
    echo "     export DB_PASSWORD=$APP_PASS"
    echo ""
    echo "  2. Or add to /etc/declutter/production.env:"
    echo "     DB_HOST=$DB_HOST"
    echo "     DB_PORT=$DB_PORT"
    echo "     DB_NAME=$DB_NAME"
    echo "     DB_USERNAME=$APP_USER"
    echo "     DB_PASSWORD=$APP_PASS"
    echo ""
    echo "  3. Test connection:"
    echo "     mysql -h $DB_HOST -P $DB_PORT -u $APP_USER -p$APP_PASS $DB_NAME"
    echo ""
    echo "  4. Run backend application"
    echo "=========================================="
}

# Main setup flow
main() {
    echo ""
    echo "=========================================="
    echo "LightGallery Production Database Setup"
    echo "=========================================="
    echo ""
    
    prompt_credentials
    test_connection
    create_database
    create_app_user
    run_schema
    verify_schema
    verify_indexes
    save_credentials
    setup_backup
    display_summary
    
    print_info "Setup completed successfully! 🎉"
}

# Run main function
main
