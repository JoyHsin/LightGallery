# User Authentication and Subscription System - Deployment Guide

## Overview

This guide provides complete deployment instructions for the LightGallery user authentication and subscription system. It covers both backend (Java/Spring Boot) and iOS client deployment.

**Feature**: User Authentication and Subscription Management  
**Spec Location**: `.kiro/specs/user-auth-subscription/`  
**Requirements**: See `requirements.md`  
**Design**: See `design.md`

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Backend Deployment](#backend-deployment)
3. [iOS Application Configuration](#ios-application-configuration)
4. [Environment Variables](#environment-variables)
5. [Database Migration](#database-migration)
6. [Testing and Verification](#testing-and-verification)
7. [Monitoring and Maintenance](#monitoring-and-maintenance)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Backend Requirements
- **Java**: 17 or higher
- **Maven**: 3.6 or higher
- **MySQL**: 8.0 or higher
- **SSL Certificate**: For HTTPS (Let's Encrypt recommended)
- **Server**: Linux server with systemd (Ubuntu 20.04+ or CentOS 8+ recommended)

### iOS Requirements
- **Xcode**: 15.0 or higher
- **macOS**: Ventura or higher
- **Apple Developer Account**: Paid membership required
- **iOS Device**: For testing (simulator has IAP limitations)

### Third-Party Accounts
- **Apple Developer Account**: For Sign in with Apple and IAP
- **WeChat Open Platform Account**: For WeChat OAuth
- **Alipay Open Platform Account**: For Alipay OAuth
- **App Store Connect Access**: For IAP configuration


---

## Backend Deployment

### Step 1: Database Setup

The backend requires a MySQL database with proper schema and user configuration.

#### Automated Setup (Recommended)

```bash
cd backend
sudo ./setup_production_database.sh
```

This script will:
- Prompt for database credentials
- Create the `lightgallery` database
- Create application user with strong password
- Run schema creation script
- Verify tables and indexes
- Save credentials to `/etc/lightgallery/database.credentials`
- Set up automated daily backups

#### Manual Setup

If you prefer manual setup:

```sql
-- Connect to MySQL
mysql -u root -p

-- Create database
CREATE DATABASE lightgallery CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create application user
CREATE USER 'lightgallery_app'@'%' IDENTIFIED BY 'YOUR_STRONG_PASSWORD';
GRANT SELECT, INSERT, UPDATE, DELETE ON lightgallery.* TO 'lightgallery_app'@'%';
FLUSH PRIVILEGES;

-- Exit and run schema
exit
mysql -u lightgallery_app -p lightgallery < backend/src/main/resources/schema.sql
```

#### Verify Database Setup

```sql
USE lightgallery;

-- Check tables exist
SHOW TABLES;
-- Expected: users, subscriptions, transactions, auth_tokens

-- Verify indexes
SHOW INDEX FROM users;
SHOW INDEX FROM subscriptions;
```


### Step 2: Environment Configuration

Create and configure the production environment file.

#### Create Environment File

```bash
# Create configuration directory
sudo mkdir -p /etc/lightgallery

# Copy template
sudo cp backend/.env.template /etc/lightgallery/production.env

# Edit configuration
sudo nano /etc/lightgallery/production.env
```

#### Required Environment Variables

See the [Environment Variables](#environment-variables) section below for complete details.

Key variables to configure:
- Database credentials (from Step 1)
- JWT secret (generate with `openssl rand -base64 64`)
- OAuth provider credentials
- Apple IAP shared secret
- SSL certificate paths

#### Secure the Environment File

```bash
sudo chown root:root /etc/lightgallery/production.env
sudo chmod 600 /etc/lightgallery/production.env
```

### Step 3: SSL Certificate Setup

#### Using Let's Encrypt (Recommended)

```bash
# Install certbot
sudo apt-get install certbot  # Ubuntu/Debian
# or
sudo yum install certbot      # CentOS/RHEL

# Generate certificate
sudo certbot certonly --standalone -d api.lightgallery.app

# Convert to PKCS12 format
sudo openssl pkcs12 -export \
  -in /etc/letsencrypt/live/api.lightgallery.app/fullchain.pem \
  -inkey /etc/letsencrypt/live/api.lightgallery.app/privkey.pem \
  -out /etc/lightgallery/keystore.p12 \
  -name lightgallery \
  -passout pass:YOUR_KEYSTORE_PASSWORD

# Secure the keystore
sudo chmod 600 /etc/lightgallery/keystore.p12
```

#### Update Environment Variables

Add to `/etc/lightgallery/production.env`:

```bash
SSL_KEY_STORE=/etc/lightgallery/keystore.p12
SSL_KEY_STORE_PASSWORD=YOUR_KEYSTORE_PASSWORD
SSL_KEY_ALIAS=lightgallery
```


### Step 4: Deploy Backend Application

#### Automated Deployment (Recommended)

```bash
cd backend
sudo ./deploy.sh
```

This script will:
- Check prerequisites (Java, Maven, MySQL)
- Build the application
- Create backup of existing deployment
- Deploy to `/opt/lightgallery`
- Set up systemd service
- Configure log rotation
- Start the service
- Verify deployment

#### Manual Deployment

If you prefer manual deployment:

```bash
# Build application
cd backend
mvn clean package -DskipTests

# Create directories
sudo mkdir -p /opt/lightgallery
sudo mkdir -p /var/log/lightgallery

# Create application user
sudo useradd -r -s /bin/false -d /opt/lightgallery lightgallery

# Deploy JAR
sudo cp target/backend-1.0.0.jar /opt/lightgallery/backend.jar
sudo chown lightgallery:lightgallery /opt/lightgallery/backend.jar

# Create systemd service (see below)
```

#### Systemd Service Configuration

Create `/etc/systemd/system/lightgallery-backend.service`:

```ini
[Unit]
Description=LightGallery Backend Service
After=network.target mysql.service

[Service]
Type=simple
User=lightgallery
Group=lightgallery
WorkingDirectory=/opt/lightgallery
EnvironmentFile=/etc/lightgallery/production.env
ExecStart=/usr/bin/java -jar /opt/lightgallery/backend.jar --spring.profiles.active=prod
StandardOutput=append:/var/log/lightgallery/application.log
StandardError=append:/var/log/lightgallery/error.log
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable lightgallery-backend
sudo systemctl start lightgallery-backend
```

### Step 5: Verify Backend Deployment

```bash
# Check service status
sudo systemctl status lightgallery-backend

# Check health endpoint
curl https://api.lightgallery.app/api/v1/health

# View logs
journalctl -u lightgallery-backend -f

# Test authentication endpoint
curl -X POST https://api.lightgallery.app/api/v1/auth/oauth/exchange \
  -H "Content-Type: application/json" \
  -d '{"provider":"apple","authCode":"test"}'
```

Expected health response:
```json
{
  "status": "UP",
  "timestamp": "2024-12-07T10:00:00Z"
}
```


---

## iOS Application Configuration

### Step 1: App Store Connect Setup

#### Create App Record

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps** → **+** → **New App**
3. Configure:
   - **Platform**: iOS
   - **Name**: LightGallery
   - **Primary Language**: Chinese (Simplified)
   - **Bundle ID**: joyhisn.LightGallery
   - **SKU**: lightgallery-ios-001

#### Configure In-App Purchases

1. Navigate to: **App** → **Features** → **In-App Purchases**
2. Create Subscription Group: "LightGallery Subscriptions"
3. Create 4 subscription products:

**Pro Monthly** (`com.lightgallery.pro.monthly`):
- Type: Auto-Renewable Subscription
- Duration: 1 Month
- Price: ¥10 (China), $1.49 (US)
- Display Name (Chinese): 专业版（月付）
- Description: 解锁所有专业功能

**Pro Yearly** (`com.lightgallery.pro.yearly`):
- Type: Auto-Renewable Subscription
- Duration: 1 Year
- Price: ¥100 (China), $14.99 (US)
- Display Name (Chinese): 专业版（年付）
- Description: 解锁所有专业功能，年付享受17%折扣

**Max Monthly** (`com.lightgallery.max.monthly`):
- Type: Auto-Renewable Subscription
- Duration: 1 Month
- Price: ¥20 (China), $2.99 (US)
- Display Name (Chinese): 旗舰版（月付）
- Description: 包含所有专业功能，享受优先支持

**Max Yearly** (`com.lightgallery.max.yearly`):
- Type: Auto-Renewable Subscription
- Duration: 1 Year
- Price: ¥200 (China), $29.99 (US)
- Display Name (Chinese): 旗舰版（年付）
- Description: 包含所有旗舰功能，年付享受17%折扣

#### Generate Shared Secret

1. Go to: **App** → **General** → **App Information**
2. Scroll to **App-Specific Shared Secret**
3. Click **Generate**
4. Copy the shared secret (needed for backend configuration)
5. Add to backend environment: `APPLE_IAP_SHARED_SECRET=<your-secret>`

#### Configure Subscription Webhook

1. Go to: **App** → **General** → **App Information**
2. Set **Subscription Status URL**: `https://api.lightgallery.app/api/v1/subscription/webhook`


### Step 2: Xcode Project Configuration

#### Enable In-App Purchase Capability

1. Open `LightGallery.xcodeproj` in Xcode
2. Select **LightGallery** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **In-App Purchase**

#### Update Entitlements

Verify `LightGallery/LightGallery.entitlements` contains:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
    <key>com.apple.developer.in-app-payments</key>
    <array>
        <string>merchant.joyhisn.lightgallery</string>
    </array>
</dict>
</plist>
```

#### Update Backend API URL

In `LightGallery/Services/BackendAPIClient.swift`, update for production:

```swift
#if DEBUG
private let baseURL = "http://localhost:8080/api/v1"
#else
private let baseURL = "https://api.lightgallery.app/api/v1"
#endif
```

#### Verify Product IDs

In `LightGallery/Services/Subscription/AppleIAPManager.swift`:

```swift
private let productIds: Set<String> = [
    "com.lightgallery.pro.monthly",
    "com.lightgallery.pro.yearly",
    "com.lightgallery.max.monthly",
    "com.lightgallery.max.yearly"
]
```

### Step 3: Build and Archive

1. Select **Product** → **Scheme** → **Edit Scheme**
2. Set **Build Configuration** to **Release**
3. Select **Product** → **Archive**
4. Wait for archive to complete
5. In Organizer, select archive and click **Validate App**
6. Fix any validation issues
7. Click **Distribute App** → **App Store Connect**
8. Upload to App Store Connect

### Step 4: Submit for Review

1. Go to App Store Connect
2. Fill in all required information:
   - App Description
   - Screenshots (all required sizes)
   - Privacy Policy URL
   - Support URL
3. Submit for review


---

## Environment Variables

Complete list of required environment variables for backend deployment.

### Database Configuration

```bash
# Database connection
DB_HOST=your-production-db-host.com
DB_PORT=3306
DB_NAME=lightgallery
DB_USERNAME=lightgallery_app
DB_PASSWORD=<generated-strong-password>
```

**Generation**: Use `backend/setup_production_database.sh` to generate automatically.

### JWT Configuration

```bash
# JWT secret (minimum 256 bits)
JWT_SECRET=<your-jwt-secret>
```

**Generation**: 
```bash
openssl rand -base64 64
```

**Security**: 
- Never commit to version control
- Rotate every 90 days
- Minimum 256 bits (64 base64 characters)

### OAuth Configuration - WeChat

```bash
WECHAT_APP_ID=<your-wechat-app-id>
WECHAT_APP_SECRET=<your-wechat-app-secret>
```

**Obtain from**: [WeChat Open Platform](https://open.weixin.qq.com/)

### OAuth Configuration - Alipay

```bash
ALIPAY_APP_ID=<your-alipay-app-id>
ALIPAY_PRIVATE_KEY=<your-alipay-private-key>
ALIPAY_PUBLIC_KEY=<your-alipay-public-key>
```

**Obtain from**: [Alipay Open Platform](https://open.alipay.com/)

### OAuth Configuration - Apple

```bash
APPLE_CLIENT_ID=joyhisn.LightGallery
APPLE_TEAM_ID=P9NDD6BA8Q
APPLE_KEY_ID=<your-apple-key-id>
APPLE_PRIVATE_KEY=<your-apple-private-key>
```

**Obtain from**: [Apple Developer Portal](https://developer.apple.com/)

### Apple IAP Configuration

```bash
# Apple In-App Purchase
APPLE_IAP_SHARED_SECRET=<from-app-store-connect>
APPLE_IAP_ENVIRONMENT=production  # or 'sandbox' for testing
```

**Obtain from**: App Store Connect → App → General → App Information → App-Specific Shared Secret

### SSL/TLS Configuration

```bash
# SSL certificate
SSL_KEY_STORE=/etc/lightgallery/keystore.p12
SSL_KEY_STORE_PASSWORD=<your-keystore-password>
SSL_KEY_ALIAS=lightgallery
```

**Generation**: See Step 3 in Backend Deployment section.

### CORS Configuration

```bash
# Allowed origins (comma-separated)
CORS_ALLOWED_ORIGINS=https://lightgallery.app,https://www.lightgallery.app
```

### Complete Environment File Template

Location: `/etc/lightgallery/production.env`

```bash
# Database Configuration
DB_HOST=your-production-db-host.com
DB_PORT=3306
DB_NAME=lightgallery
DB_USERNAME=lightgallery_app
DB_PASSWORD=your-strong-database-password

# JWT Configuration
JWT_SECRET=your-jwt-secret-at-least-256-bits-long

# OAuth Configuration - WeChat
WECHAT_APP_ID=your-wechat-app-id
WECHAT_APP_SECRET=your-wechat-app-secret

# OAuth Configuration - Alipay
ALIPAY_APP_ID=your-alipay-app-id
ALIPAY_PRIVATE_KEY=your-alipay-private-key
ALIPAY_PUBLIC_KEY=your-alipay-public-key

# OAuth Configuration - Apple
APPLE_CLIENT_ID=joyhisn.LightGallery
APPLE_TEAM_ID=P9NDD6BA8Q
APPLE_KEY_ID=your-apple-key-id
APPLE_PRIVATE_KEY=your-apple-private-key

# Apple IAP Configuration
APPLE_IAP_SHARED_SECRET=your-apple-iap-shared-secret
APPLE_IAP_ENVIRONMENT=production

# SSL Configuration
SSL_KEY_STORE=/etc/lightgallery/keystore.p12
SSL_KEY_STORE_PASSWORD=your-keystore-password
SSL_KEY_ALIAS=lightgallery

# CORS Configuration
CORS_ALLOWED_ORIGINS=https://lightgallery.app,https://www.lightgallery.app
```

**Security**:
```bash
sudo chown root:root /etc/lightgallery/production.env
sudo chmod 600 /etc/lightgallery/production.env
```


---

## Database Migration

### Initial Schema Deployment

The database schema is located at `backend/src/main/resources/schema.sql`.

#### Automated Migration

```bash
cd backend
sudo ./setup_production_database.sh
```

#### Manual Migration

```bash
mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME < backend/src/main/resources/schema.sql
```

### Schema Overview

The schema creates four main tables:

#### 1. users Table

Stores user account information.

```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    provider_user_id VARCHAR(255) NOT NULL,
    auth_provider VARCHAR(50) NOT NULL,
    email VARCHAR(255),
    display_name VARCHAR(255),
    avatar_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,
    UNIQUE KEY idx_provider_id (auth_provider, provider_user_id),
    KEY idx_email (email)
);
```

#### 2. subscriptions Table

Stores subscription status and details.

```sql
CREATE TABLE subscriptions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    tier VARCHAR(50) NOT NULL,
    billing_period VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    start_date TIMESTAMP NOT NULL,
    expiry_date TIMESTAMP NOT NULL,
    auto_renew BOOLEAN DEFAULT TRUE,
    payment_method VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    KEY idx_user_id (user_id),
    KEY idx_status (status),
    KEY idx_expiry (expiry_date)
);
```

#### 3. transactions Table

Audit log for all payment transactions.

```sql
CREATE TABLE transactions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    subscription_id BIGINT,
    transaction_id VARCHAR(255) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(10) NOT NULL,
    status VARCHAR(50) NOT NULL,
    receipt_data TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE SET NULL,
    UNIQUE KEY idx_transaction_id (transaction_id),
    KEY idx_user_id (user_id),
    KEY idx_status (status)
);
```

#### 4. auth_tokens Table

Stores authentication tokens and refresh tokens.

```sql
CREATE TABLE auth_tokens (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    access_token VARCHAR(500) NOT NULL,
    refresh_token VARCHAR(500) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    KEY idx_user_id (user_id),
    KEY idx_access_token (access_token(255)),
    KEY idx_expires_at (expires_at)
);
```

### Verify Migration

```sql
-- Connect to database
mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME

-- Check tables
SHOW TABLES;

-- Verify structure
DESCRIBE users;
DESCRIBE subscriptions;
DESCRIBE transactions;
DESCRIBE auth_tokens;

-- Check indexes
SHOW INDEX FROM users;
SHOW INDEX FROM subscriptions;
SHOW INDEX FROM transactions;
SHOW INDEX FROM auth_tokens;

-- Verify foreign keys
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'lightgallery'
AND REFERENCED_TABLE_NAME IS NOT NULL;
```

### Backup Before Migration

Always backup before running migrations:

```bash
# Create backup
mysqldump -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD \
  --single-transaction \
  --routines \
  --triggers \
  $DB_NAME | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz

# Verify backup
gunzip -c backup_*.sql.gz | head -n 20
```

### Rollback Procedure

If migration fails:

```bash
# Stop backend service
sudo systemctl stop lightgallery-backend

# Restore from backup
gunzip < backup_YYYYMMDD_HHMMSS.sql.gz | \
  mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME

# Verify restoration
mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME -e "SHOW TABLES;"

# Restart service
sudo systemctl start lightgallery-backend
```


---

## Testing and Verification

### Backend Testing

#### 1. Health Check

```bash
curl https://api.lightgallery.app/api/v1/health
```

Expected response:
```json
{
  "status": "UP",
  "timestamp": "2024-12-07T10:00:00Z"
}
```

#### 2. Database Connectivity

```bash
# Check service logs for database connection
journalctl -u lightgallery-backend -n 50 | grep -i "database\|mysql"

# Should see: "Database connection established successfully"
```

#### 3. Authentication Endpoints

Test OAuth token exchange (requires valid credentials):

```bash
curl -X POST https://api.lightgallery.app/api/v1/auth/oauth/exchange \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "apple",
    "authCode": "test_auth_code",
    "identityToken": "test_identity_token"
  }'
```

#### 4. Subscription Endpoints

Test subscription status (requires valid JWT):

```bash
curl -X GET https://api.lightgallery.app/api/v1/subscription/status \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### iOS Sandbox Testing

#### Create Sandbox Test Accounts

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to: **Users and Access** → **Sandbox** → **Testers**
3. Create at least 3 test accounts:
   - tester1@lightgallery.test
   - tester2@lightgallery.test
   - tester3@lightgallery.test

#### Test Procedures

**Test 1: Product Loading**
1. Launch app
2. Navigate to Subscription page
3. Verify all 4 products display with correct prices
4. ✅ Expected: All products load successfully

**Test 2: Purchase Flow**
1. Select "Pro Monthly" subscription
2. Tap "Subscribe"
3. Sign in with sandbox account when prompted
4. Complete purchase
5. ✅ Expected: Purchase completes, subscription activates

**Test 3: Receipt Verification**
1. Make a purchase
2. Check backend logs: `journalctl -u lightgallery-backend -f | grep "receipt"`
3. ✅ Expected: Receipt verified successfully

**Test 4: Feature Access**
1. Purchase subscription
2. Navigate to premium feature (e.g., Smart Clean)
3. ✅ Expected: Feature unlocks and is accessible

**Test 5: Restore Purchases**
1. Purchase on Device A
2. Install app on Device B with same Apple ID
3. Tap "Restore Purchases"
4. ✅ Expected: Subscription restored successfully

**Test 6: Offline Mode**
1. Purchase subscription
2. Enable Airplane Mode
3. Force quit and relaunch app
4. Try to access premium features
5. ✅ Expected: Features accessible using cached subscription

**Test 7: Subscription Cancellation**
1. Purchase subscription
2. Cancel through Settings → Subscriptions
3. ✅ Expected: Access continues until expiry date

**Test 8: Subscription Renewal**
1. Purchase subscription
2. Wait for renewal (accelerated in sandbox: 5 min for monthly)
3. ✅ Expected: Subscription renews automatically

### Complete Testing Checklist

For comprehensive testing, see: `SANDBOX_TESTING_CHECKLIST.md`

- [ ] All 4 products load correctly
- [ ] Purchase flow completes successfully
- [ ] Receipt verification succeeds
- [ ] Subscription syncs to backend
- [ ] Premium features unlock
- [ ] Restore purchases works
- [ ] Offline mode works (< 24h cache)
- [ ] Subscription renewal works
- [ ] Cancellation works correctly
- [ ] Upgrade/downgrade works
- [ ] Error messages display correctly
- [ ] Localization works (Chinese/English)


---

## Monitoring and Maintenance

### Backend Monitoring

#### Service Status

```bash
# Check if service is running
sudo systemctl status lightgallery-backend

# View real-time logs
journalctl -u lightgallery-backend -f

# View error logs only
journalctl -u lightgallery-backend -p err -f

# View logs from last hour
journalctl -u lightgallery-backend --since "1 hour ago"
```

#### Health Monitoring

Set up automated health checks:

```bash
# Create health check script
sudo tee /usr/local/bin/check-lightgallery-health.sh > /dev/null << 'EOF'
#!/bin/bash
HEALTH_URL="https://api.lightgallery.app/api/v1/health"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL)

if [ $RESPONSE -eq 200 ]; then
    echo "$(date): Health check passed"
    exit 0
else
    echo "$(date): Health check failed with status: $RESPONSE"
    # Send alert (configure email/Slack/etc.)
    exit 1
fi
EOF

sudo chmod +x /usr/local/bin/check-lightgallery-health.sh

# Add to crontab (every 5 minutes)
(sudo crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/check-lightgallery-health.sh >> /var/log/lightgallery-health.log 2>&1") | sudo crontab -
```

#### Database Monitoring

```sql
-- Check active connections
SHOW PROCESSLIST;

-- Check table sizes
SELECT 
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS "Size (MB)"
FROM information_schema.TABLES
WHERE table_schema = 'lightgallery'
ORDER BY (data_length + index_length) DESC;

-- Check subscription statistics
SELECT 
    tier,
    status,
    COUNT(*) as count
FROM subscriptions
GROUP BY tier, status;

-- Check recent transactions
SELECT 
    DATE(created_at) as date,
    COUNT(*) as transaction_count,
    SUM(amount) as total_amount
FROM transactions
WHERE created_at > NOW() - INTERVAL 7 DAY
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Check failed transactions
SELECT COUNT(*) as failed_count
FROM transactions
WHERE status = 'failed'
AND created_at > NOW() - INTERVAL 24 HOUR;
```

### Automated Backups

Backups are configured automatically by `setup_production_database.sh`.

#### Verify Backup Configuration

```bash
# Check if backup script exists
ls -l /usr/local/bin/backup-lightgallery-db.sh

# Check crontab
sudo crontab -l | grep backup-lightgallery

# Manually run backup
sudo /usr/local/bin/backup-lightgallery-db.sh

# Verify backup files
ls -lh /var/backups/lightgallery/
```

#### Restore from Backup

```bash
# List available backups
ls -lh /var/backups/lightgallery/

# Restore specific backup
gunzip < /var/backups/lightgallery/lightgallery_YYYYMMDD_HHMMSS.sql.gz | \
  mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME
```

### Log Rotation

Log rotation is configured automatically by `deploy.sh`.

#### Verify Log Rotation

```bash
# Check logrotate configuration
cat /etc/logrotate.d/lightgallery-backend

# Manually test rotation
sudo logrotate -f /etc/logrotate.d/lightgallery-backend

# Check log files
ls -lh /var/log/lightgallery/
```

### Performance Monitoring

#### Key Metrics to Track

1. **Response Time**: Average API response time
2. **Error Rate**: Percentage of failed requests
3. **Active Subscriptions**: Number of active paid subscriptions
4. **Transaction Success Rate**: Percentage of successful payments
5. **Database Connections**: Number of active database connections

#### Monitor Response Time

```bash
# Test API response time
time curl -s https://api.lightgallery.app/api/v1/health > /dev/null
```

#### Monitor Error Rate

```bash
# Count errors in last hour
journalctl -u lightgallery-backend --since "1 hour ago" | grep -i "error" | wc -l
```

### iOS App Analytics

#### App Store Connect Analytics

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to: **Analytics** → **Subscriptions**
3. Monitor:
   - Active Subscriptions
   - New Subscriptions
   - Renewals
   - Cancellations
   - Revenue

#### Key Metrics

- **Conversion Rate**: Free → Paid users
- **Retention Rate**: Monthly/Yearly retention
- **Churn Rate**: Subscription cancellations
- **MRR**: Monthly Recurring Revenue
- **ARPU**: Average Revenue Per User

### Maintenance Tasks

#### Daily
- [ ] Check service status
- [ ] Review error logs
- [ ] Verify backups completed

#### Weekly
- [ ] Review subscription metrics
- [ ] Check database performance
- [ ] Review failed transactions

#### Monthly
- [ ] Update dependencies
- [ ] Review security logs
- [ ] Analyze user feedback

#### Quarterly
- [ ] Rotate JWT secret
- [ ] Security audit
- [ ] Performance optimization review


---

## Troubleshooting

### Backend Issues

#### Service Won't Start

**Symptom**: `systemctl start lightgallery-backend` fails

**Solutions**:

1. Check logs:
```bash
journalctl -u lightgallery-backend -n 50
```

2. Common issues:
   - **Database connection failed**: Verify DB credentials in environment file
   - **Port already in use**: Check if port 8080 is available
   - **SSL certificate error**: Verify certificate paths and permissions
   - **Missing environment variables**: Check `/etc/lightgallery/production.env`

3. Verify environment file:
```bash
sudo cat /etc/lightgallery/production.env
# Check all required variables are set
```

4. Test database connection:
```bash
mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD -e "SELECT 1"
```

#### Health Check Fails

**Symptom**: `curl https://api.lightgallery.app/api/v1/health` returns error

**Solutions**:

1. Check if service is running:
```bash
sudo systemctl status lightgallery-backend
```

2. Check firewall rules:
```bash
sudo ufw status
# Ensure port 8080 is open
sudo ufw allow 8080/tcp
```

3. Check SSL certificate:
```bash
openssl s_client -connect api.lightgallery.app:8080 -showcerts
```

4. Check application logs:
```bash
journalctl -u lightgallery-backend -f
```

#### Database Connection Timeout

**Symptom**: Logs show "Connection timeout" or "Too many connections"

**Solutions**:

1. Check database is running:
```bash
mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD -e "SELECT 1"
```

2. Check active connections:
```sql
SHOW PROCESSLIST;
```

3. Increase connection pool size in `application-prod.yml`:
```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
```

4. Check firewall rules allow database connections

#### Receipt Verification Fails

**Symptom**: IAP purchases complete but subscription doesn't activate

**Solutions**:

1. Check backend logs:
```bash
journalctl -u lightgallery-backend -f | grep "receipt"
```

2. Verify shared secret is correct:
```bash
grep APPLE_IAP_SHARED_SECRET /etc/lightgallery/production.env
```

3. Check environment (sandbox vs production):
```bash
grep APPLE_IAP_ENVIRONMENT /etc/lightgallery/production.env
# Should be 'production' for live app
```

4. Verify network connectivity to Apple servers:
```bash
curl -I https://buy.itunes.apple.com/verifyReceipt
```

### iOS Issues

#### Products Not Loading

**Symptom**: Subscription page shows no products

**Solutions**:

1. Verify product IDs match App Store Connect:
   - Check `AppleIAPManager.swift` product IDs
   - Compare with App Store Connect product IDs

2. Check products are "Ready to Submit" in App Store Connect

3. Wait 24 hours after creating products (Apple propagation delay)

4. Check network connectivity:
```swift
// Add logging in AppleIAPManager
print("Fetching products: \(productIds)")
```

5. Clear app data and reinstall

#### Purchase Fails

**Symptom**: Purchase sheet appears but transaction fails

**Solutions**:

1. Verify signed in with correct account:
   - Sandbox: Use sandbox test account
   - Production: Use real Apple ID

2. Check sandbox account is valid (not expired)

3. Verify products are approved in App Store Connect

4. Check backend logs for errors:
```bash
journalctl -u lightgallery-backend -f | grep "purchase\|receipt"
```

5. Test with different sandbox account

#### Subscription Not Syncing

**Symptom**: Subscription works on one device but not another

**Solutions**:

1. Tap "Restore Purchases" in app

2. Check backend subscription status:
```sql
SELECT * FROM subscriptions WHERE user_id = 'USER_ID';
```

3. Verify same Apple ID on both devices

4. Check network connectivity

5. Clear app cache:
```swift
// In app, clear UserDefaults
UserDefaults.standard.removeObject(forKey: "cachedSubscription")
```

#### Offline Mode Not Working

**Symptom**: Premium features locked when offline

**Solutions**:

1. Check cache timestamp:
```swift
// Verify cache is less than 24 hours old
let cacheAge = Date().timeIntervalSince(cachedDate)
print("Cache age: \(cacheAge / 3600) hours")
```

2. Verify subscription was cached:
```swift
// Check UserDefaults
if let cached = UserDefaults.standard.data(forKey: "cachedSubscription") {
    print("Cache exists")
}
```

3. Ensure subscription was active when cached

### Common Error Messages

#### "JWT secret too short"

**Cause**: JWT_SECRET is less than 256 bits

**Solution**:
```bash
# Generate new secret
openssl rand -base64 64

# Update environment file
sudo nano /etc/lightgallery/production.env
# Set JWT_SECRET=<new-secret>

# Restart service
sudo systemctl restart lightgallery-backend
```

#### "SSL handshake failed"

**Cause**: Invalid or expired SSL certificate

**Solution**:
```bash
# Check certificate expiry
openssl pkcs12 -in /etc/lightgallery/keystore.p12 -nokeys | openssl x509 -noout -dates

# Renew certificate
sudo certbot renew

# Recreate keystore
sudo openssl pkcs12 -export \
  -in /etc/letsencrypt/live/api.lightgallery.app/fullchain.pem \
  -inkey /etc/letsencrypt/live/api.lightgallery.app/privkey.pem \
  -out /etc/lightgallery/keystore.p12 \
  -name lightgallery

# Restart service
sudo systemctl restart lightgallery-backend
```

#### "Receipt verification status 21002"

**Cause**: Using wrong environment (sandbox receipt sent to production URL or vice versa)

**Solution**:
```bash
# For sandbox testing
APPLE_IAP_ENVIRONMENT=sandbox

# For production
APPLE_IAP_ENVIRONMENT=production

# Update and restart
sudo nano /etc/lightgallery/production.env
sudo systemctl restart lightgallery-backend
```

### Getting Help

#### Log Collection

When reporting issues, collect:

1. Backend logs:
```bash
journalctl -u lightgallery-backend -n 200 > backend-logs.txt
```

2. Database status:
```sql
SHOW PROCESSLIST;
SELECT * FROM subscriptions ORDER BY created_at DESC LIMIT 10;
```

3. Environment (sanitized):
```bash
# Remove sensitive values before sharing
grep -v "PASSWORD\|SECRET\|KEY" /etc/lightgallery/production.env
```

4. iOS logs:
   - Xcode → Window → Devices and Simulators
   - Select device → View Device Logs

#### Support Resources

- **Backend Documentation**: `backend/DEPLOYMENT_GUIDE.md`
- **iOS Documentation**: `IOS_IAP_DEPLOYMENT_GUIDE.md`
- **Testing Guide**: `SANDBOX_TESTING_CHECKLIST.md`
- **API Documentation**: `backend/API_DOCUMENTATION.md`

#### Contact Information

- Technical Lead: [To be filled]
- DevOps Team: [To be filled]
- Emergency Hotline: [To be filled]

---

## Appendix

### Quick Reference Commands

#### Backend Management
```bash
# Start service
sudo systemctl start lightgallery-backend

# Stop service
sudo systemctl stop lightgallery-backend

# Restart service
sudo systemctl restart lightgallery-backend

# View status
sudo systemctl status lightgallery-backend

# View logs
journalctl -u lightgallery-backend -f

# View last 100 lines
journalctl -u lightgallery-backend -n 100
```

#### Database Management
```bash
# Connect to database
mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME

# Backup database
mysqldump -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD \
  --single-transaction $DB_NAME | gzip > backup.sql.gz

# Restore database
gunzip < backup.sql.gz | mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME
```

#### Health Checks
```bash
# Backend health
curl https://api.lightgallery.app/api/v1/health

# SSL certificate
openssl s_client -connect api.lightgallery.app:8080 -showcerts

# Database connection
mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD -e "SELECT 1"
```

### Deployment Checklist

#### Pre-Deployment
- [ ] MySQL 8.0+ installed
- [ ] Java 17+ installed
- [ ] Maven 3.6+ installed
- [ ] SSL certificate obtained
- [ ] Domain configured
- [ ] Firewall rules configured
- [ ] OAuth credentials obtained
- [ ] Apple IAP products created

#### Backend Deployment
- [ ] Database created and schema deployed
- [ ] Environment variables configured
- [ ] SSL certificate installed
- [ ] Application deployed
- [ ] Systemd service configured
- [ ] Service started successfully
- [ ] Health check passing
- [ ] Logs reviewed

#### iOS Deployment
- [ ] App Store Connect configured
- [ ] IAP products created
- [ ] Shared secret generated
- [ ] Xcode project configured
- [ ] Backend URL updated
- [ ] App archived and uploaded
- [ ] Submitted for review

#### Testing
- [ ] All sandbox tests passed
- [ ] Backend endpoints tested
- [ ] Database verified
- [ ] Monitoring configured
- [ ] Backups verified

#### Post-Deployment
- [ ] Monitor initial purchases
- [ ] Review error logs
- [ ] Check subscription metrics
- [ ] Verify backups running
- [ ] Document any issues

---

**Document Version**: 1.0  
**Last Updated**: December 7, 2024  
**Maintained By**: LightGallery Development Team

