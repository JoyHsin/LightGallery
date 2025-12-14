# LightGallery Backend Deployment Guide

## Overview

This guide covers the deployment of the LightGallery backend service to production, including database configuration, environment variable setup, and Apple IAP configuration.

## Prerequisites

- Java 17 or higher
- Maven 3.6+
- MySQL 8.0+ (production instance)
- SSL certificate for HTTPS
- Apple Developer Account (for IAP)
- WeChat Developer Account (for OAuth)
- Alipay Developer Account (for OAuth)

## 1. Production Database Configuration

### 1.1 Create Production Database

Connect to your production MySQL server:

```bash
mysql -h your-production-host -u admin -p
```

Create the production database:

```sql
CREATE DATABASE lightgallery CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create dedicated user for the application
CREATE USER 'lightgallery_app'@'%' IDENTIFIED BY 'STRONG_PASSWORD_HERE';

-- Grant necessary privileges
GRANT SELECT, INSERT, UPDATE, DELETE ON lightgallery.* TO 'lightgallery_app'@'%';

-- Flush privileges
FLUSH PRIVILEGES;
```

### 1.2 Run Database Schema

Execute the schema creation script:

```bash
mysql -h your-production-host -u lightgallery_app -p lightgallery < backend/src/main/resources/schema.sql
```

### 1.3 Verify Database Setup

```sql
USE lightgallery;

-- Check tables
SHOW TABLES;

-- Verify indexes
SHOW INDEX FROM users;
SHOW INDEX FROM subscriptions;
SHOW INDEX FROM transactions;
SHOW INDEX FROM auth_tokens;
```

Expected tables:
- `users`
- `subscriptions`
- `transactions`
- `auth_tokens`

### 1.4 Database Backup Configuration

Set up automated backups:

```bash
# Create backup script
cat > /usr/local/bin/backup-lightgallery-db.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/lightgallery"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

mysqldump -h your-production-host -u lightgallery_app -p \
  --single-transaction \
  --routines \
  --triggers \
  lightgallery | gzip > $BACKUP_DIR/lightgallery_$DATE.sql.gz

# Keep only last 30 days of backups
find $BACKUP_DIR -name "lightgallery_*.sql.gz" -mtime +30 -delete
EOF

chmod +x /usr/local/bin/backup-lightgallery-db.sh

# Add to crontab (daily at 2 AM)
echo "0 2 * * * /usr/local/bin/backup-lightgallery-db.sh" | crontab -
```

## 2. Environment Variables Configuration

### 2.1 Required Environment Variables

Create a production environment file:

```bash
# /etc/lightgallery/production.env

# Database Configuration
DB_HOST=your-production-db-host.com
DB_PORT=3306
DB_NAME=lightgallery
DB_USERNAME=lightgallery_app
DB_PASSWORD=your-strong-database-password

# JWT Configuration (CRITICAL: Use a strong secret)
# Generate with: openssl rand -base64 64
JWT_SECRET=your-jwt-secret-at-least-256-bits-long

# OAuth Configuration - WeChat
WECHAT_APP_ID=your-wechat-app-id
WECHAT_APP_SECRET=your-wechat-app-secret

# OAuth Configuration - Alipay
ALIPAY_APP_ID=your-alipay-app-id
ALIPAY_PRIVATE_KEY=your-alipay-private-key
ALIPAY_PUBLIC_KEY=your-alipay-public-key

# OAuth Configuration - Apple
APPLE_CLIENT_ID=com.lightgallery.app
APPLE_TEAM_ID=your-apple-team-id
APPLE_KEY_ID=your-apple-key-id
APPLE_PRIVATE_KEY=your-apple-private-key

# SSL Configuration
SSL_KEY_STORE=/etc/lightgallery/keystore.p12
SSL_KEY_STORE_PASSWORD=your-keystore-password
SSL_KEY_ALIAS=lightgallery

# CORS Configuration
CORS_ALLOWED_ORIGINS=https://lightgallery.app,https://www.lightgallery.app

# Apple IAP Configuration
APPLE_IAP_SHARED_SECRET=your-apple-iap-shared-secret
APPLE_IAP_ENVIRONMENT=production
```

### 2.2 Secure Environment File

```bash
# Set proper permissions
sudo chown root:root /etc/lightgallery/production.env
sudo chmod 600 /etc/lightgallery/production.env
```

### 2.3 Generate JWT Secret

```bash
# Generate a secure JWT secret
openssl rand -base64 64
```

Copy the output and set it as `JWT_SECRET` in your environment file.

### 2.4 Load Environment Variables

For systemd service:

```bash
# Create systemd service file
sudo cat > /etc/systemd/system/lightgallery-backend.service << 'EOF'
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
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Enable service
sudo systemctl enable lightgallery-backend

# Start service
sudo systemctl start lightgallery-backend

# Check status
sudo systemctl status lightgallery-backend
```

## 3. SSL/TLS Configuration

### 3.1 Generate SSL Certificate

For production, use a certificate from a trusted CA (Let's Encrypt, DigiCert, etc.):

```bash
# Using Let's Encrypt (certbot)
sudo certbot certonly --standalone -d api.lightgallery.app
```

### 3.2 Convert Certificate to PKCS12

```bash
# Convert PEM to PKCS12
openssl pkcs12 -export \
  -in /etc/letsencrypt/live/api.lightgallery.app/fullchain.pem \
  -inkey /etc/letsencrypt/live/api.lightgallery.app/privkey.pem \
  -out /etc/lightgallery/keystore.p12 \
  -name lightgallery \
  -passout pass:your-keystore-password

# Set proper permissions
sudo chown lightgallery:lightgallery /etc/lightgallery/keystore.p12
sudo chmod 600 /etc/lightgallery/keystore.p12
```

### 3.3 Verify SSL Configuration

```bash
# Test SSL connection
openssl s_client -connect api.lightgallery.app:8080 -tls1_2

# Check certificate
openssl pkcs12 -info -in /etc/lightgallery/keystore.p12
```

## 4. Apple IAP Production Configuration

### 4.1 App Store Connect Setup

1. **Create App in App Store Connect**
   - Go to https://appstoreconnect.apple.com
   - Create new app with bundle ID: `joyhisn.LightGallery`
   - Fill in app information

2. **Configure In-App Purchases**
   - Navigate to: App → Features → In-App Purchases
   - Create the following products:

   **Pro Monthly:**
   - Product ID: `com.lightgallery.pro.monthly`
   - Type: Auto-Renewable Subscription
   - Price: ¥10/month
   - Subscription Group: LightGallery Subscriptions

   **Pro Yearly:**
   - Product ID: `com.lightgallery.pro.yearly`
   - Type: Auto-Renewable Subscription
   - Price: ¥100/year
   - Subscription Group: LightGallery Subscriptions

   **Max Monthly:**
   - Product ID: `com.lightgallery.max.monthly`
   - Type: Auto-Renewable Subscription
   - Price: ¥20/month
   - Subscription Group: LightGallery Subscriptions

   **Max Yearly:**
   - Product ID: `com.lightgallery.max.yearly`
   - Type: Auto-Renewable Subscription
   - Price: ¥200/year
   - Subscription Group: LightGallery Subscriptions

3. **Generate Shared Secret**
   - Go to: App → General → App Information
   - Under "App-Specific Shared Secret", click "Generate"
   - Copy the shared secret and add to environment variables

4. **Configure Subscription Groups**
   - Create subscription group: "LightGallery Subscriptions"
   - Add all four products to this group
   - Set upgrade/downgrade paths:
     - Pro Monthly ↔ Pro Yearly (crossgrade)
     - Max Monthly ↔ Max Yearly (crossgrade)
     - Pro → Max (upgrade)
     - Max → Pro (downgrade)

### 4.2 iOS App Configuration

Update the iOS app's StoreKit configuration file:

```swift
// LightGallery/Services/Subscription/AppleIAPManager.swift

// Update product IDs for production
private let productIds = [
    "com.lightgallery.pro.monthly",
    "com.lightgallery.pro.yearly",
    "com.lightgallery.max.monthly",
    "com.lightgallery.max.yearly"
]
```

### 4.3 Enable In-App Purchase Capability

In Xcode:
1. Select LightGallery target
2. Go to "Signing & Capabilities"
3. Click "+ Capability"
4. Add "In-App Purchase"

Update entitlements file:

```xml
<!-- LightGallery/LightGallery.entitlements -->
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

### 4.4 Backend Receipt Verification Configuration

Update backend to use production Apple servers:

```yaml
# backend/src/main/resources/application-prod.yml

apple:
  iap:
    # Production receipt verification URL
    verification-url: https://buy.itunes.apple.com/verifyReceipt
    # Fallback to sandbox for testing
    sandbox-url: https://sandbox.itunes.apple.com/verifyReceipt
    shared-secret: ${APPLE_IAP_SHARED_SECRET}
    environment: production
```

## 5. Sandbox Testing

### 5.1 Create Sandbox Test Accounts

1. Go to App Store Connect → Users and Access → Sandbox Testers
2. Create test accounts:
   - tester1@lightgallery.test
   - tester2@lightgallery.test
   - tester3@lightgallery.test

### 5.2 Configure iOS App for Sandbox Testing

Create a StoreKit configuration file for local testing:

```bash
# In Xcode: File → New → File → StoreKit Configuration File
# Name: LightGallery.storekit
```

Add products to the configuration file:

```json
{
  "identifier" : "LightGallery",
  "nonRenewingSubscriptions" : [],
  "products" : [],
  "settings" : {
    "locale" : "zh_CN"
  },
  "subscriptionGroups" : [
    {
      "id" : "lightgallery_subscriptions",
      "localizations" : [],
      "name" : "LightGallery Subscriptions",
      "subscriptions" : [
        {
          "adHocOffers" : [],
          "codeOffers" : [],
          "displayPrice" : "10",
          "familyShareable" : false,
          "groupNumber" : 1,
          "internalID" : "pro_monthly",
          "introductoryOffer" : null,
          "localizations" : [
            {
              "description" : "专业版月付订阅",
              "displayName" : "专业版（月付）",
              "locale" : "zh_CN"
            }
          ],
          "productID" : "com.lightgallery.pro.monthly",
          "recurringSubscriptionPeriod" : "P1M",
          "referenceName" : "Pro Monthly",
          "subscriptionGroupID" : "lightgallery_subscriptions",
          "type" : "RecurringSubscription"
        },
        {
          "adHocOffers" : [],
          "codeOffers" : [],
          "displayPrice" : "100",
          "familyShareable" : false,
          "groupNumber" : 1,
          "internalID" : "pro_yearly",
          "introductoryOffer" : null,
          "localizations" : [
            {
              "description" : "专业版年付订阅",
              "displayName" : "专业版（年付）",
              "locale" : "zh_CN"
            }
          ],
          "productID" : "com.lightgallery.pro.yearly",
          "recurringSubscriptionPeriod" : "P1Y",
          "referenceName" : "Pro Yearly",
          "subscriptionGroupID" : "lightgallery_subscriptions",
          "type" : "RecurringSubscription"
        },
        {
          "adHocOffers" : [],
          "codeOffers" : [],
          "displayPrice" : "20",
          "familyShareable" : false,
          "groupNumber" : 2,
          "internalID" : "max_monthly",
          "introductoryOffer" : null,
          "localizations" : [
            {
              "description" : "旗舰版月付订阅",
              "displayName" : "旗舰版（月付）",
              "locale" : "zh_CN"
            }
          ],
          "productID" : "com.lightgallery.max.monthly",
          "recurringSubscriptionPeriod" : "P1M",
          "referenceName" : "Max Monthly",
          "subscriptionGroupID" : "lightgallery_subscriptions",
          "type" : "RecurringSubscription"
        },
        {
          "adHocOffers" : [],
          "codeOffers" : [],
          "displayPrice" : "200",
          "familyShareable" : false,
          "groupNumber" : 2,
          "internalID" : "max_yearly",
          "introductoryOffer" : null,
          "localizations" : [
            {
              "description" : "旗舰版年付订阅",
              "displayName" : "旗舰版（年付）",
              "locale" : "zh_CN"
            }
          ],
          "productID" : "com.lightgallery.max.yearly",
          "recurringSubscriptionPeriod" : "P1Y",
          "referenceName" : "Max Yearly",
          "subscriptionGroupID" : "lightgallery_subscriptions",
          "type" : "RecurringSubscription"
        }
      ]
    }
  ],
  "version" : {
    "major" : 1,
    "minor" : 0
  }
}
```

### 5.3 Sandbox Testing Procedure

**Test Case 1: Purchase Flow**
1. Sign out of App Store on test device
2. Launch LightGallery app
3. Navigate to Subscription page
4. Select Pro Monthly subscription
5. When prompted, sign in with sandbox test account
6. Complete purchase
7. Verify subscription is activated in app
8. Check backend logs for receipt verification

**Test Case 2: Receipt Verification**
1. Make a purchase in sandbox
2. Check backend logs for verification request:
   ```
   INFO: Verifying Apple IAP receipt
   INFO: Receipt verification successful
   INFO: Subscription activated for user
   ```

**Test Case 3: Subscription Renewal**
1. Purchase a subscription
2. Wait for auto-renewal (accelerated in sandbox)
3. Verify renewal is processed correctly
4. Check subscription expiry date is extended

**Test Case 4: Subscription Cancellation**
1. Purchase a subscription
2. Cancel through App Store settings
3. Verify access continues until expiry
4. Verify access is revoked after expiry

**Test Case 5: Restore Purchases**
1. Purchase subscription on device A
2. Install app on device B
3. Sign in with same Apple ID
4. Tap "Restore Purchases"
5. Verify subscription is restored

### 5.4 Backend Sandbox Configuration

For testing, configure backend to use sandbox:

```yaml
# backend/src/main/resources/application-dev.yml

apple:
  iap:
    # Use sandbox for development
    verification-url: https://sandbox.itunes.apple.com/verifyReceipt
    shared-secret: ${APPLE_IAP_SHARED_SECRET}
    environment: sandbox
```

### 5.5 Testing Checklist

- [ ] All four subscription products load correctly
- [ ] Purchase flow completes successfully
- [ ] Receipt verification succeeds
- [ ] Subscription status syncs to backend
- [ ] Subscription status displays correctly in app
- [ ] Premium features unlock after purchase
- [ ] Restore purchases works correctly
- [ ] Subscription renewal works
- [ ] Subscription cancellation works
- [ ] Expired subscriptions lock premium features
- [ ] Offline mode uses cached subscription (< 24 hours)
- [ ] Subscription upgrade/downgrade works
- [ ] Error messages display correctly

## 6. Deployment Checklist

### Pre-Deployment
- [ ] Database schema created in production
- [ ] Database user created with proper permissions
- [ ] All environment variables configured
- [ ] SSL certificate generated and configured
- [ ] JWT secret generated (256+ bits)
- [ ] OAuth credentials obtained (WeChat, Alipay, Apple)
- [ ] Apple IAP products created in App Store Connect
- [ ] Apple IAP shared secret generated
- [ ] Sandbox testing completed successfully

### Deployment
- [ ] Build production JAR: `mvn clean package -Pprod`
- [ ] Copy JAR to production server
- [ ] Copy SSL certificate to production server
- [ ] Set up systemd service
- [ ] Start backend service
- [ ] Verify health endpoint: `curl https://api.lightgallery.app/api/v1/health`
- [ ] Check logs for errors: `journalctl -u lightgallery-backend -f`

### Post-Deployment
- [ ] Test authentication endpoints
- [ ] Test subscription endpoints
- [ ] Test payment verification
- [ ] Monitor error logs for 24 hours
- [ ] Set up monitoring/alerting
- [ ] Configure log rotation
- [ ] Document rollback procedure

### iOS App Deployment
- [ ] Update backend API URL to production
- [ ] Update IAP product IDs
- [ ] Enable In-App Purchase capability
- [ ] Update entitlements
- [ ] Build for App Store
- [ ] Submit for review
- [ ] Test with TestFlight

## 7. Monitoring and Maintenance

### 7.1 Log Monitoring

```bash
# View real-time logs
journalctl -u lightgallery-backend -f

# View error logs only
journalctl -u lightgallery-backend -p err -f

# View logs from last hour
journalctl -u lightgallery-backend --since "1 hour ago"
```

### 7.2 Database Monitoring

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
```

### 7.3 Health Checks

Set up automated health checks:

```bash
# Create health check script
cat > /usr/local/bin/check-lightgallery-health.sh << 'EOF'
#!/bin/bash
HEALTH_URL="https://api.lightgallery.app/api/v1/health"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL)

if [ $RESPONSE -eq 200 ]; then
    echo "Health check passed"
    exit 0
else
    echo "Health check failed with status: $RESPONSE"
    # Send alert (email, Slack, etc.)
    exit 1
fi
EOF

chmod +x /usr/local/bin/check-lightgallery-health.sh

# Add to crontab (every 5 minutes)
echo "*/5 * * * * /usr/local/bin/check-lightgallery-health.sh" | crontab -
```

## 8. Troubleshooting

### Database Connection Issues

```bash
# Test database connection
mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD -e "SELECT 1"

# Check if database exists
mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD -e "SHOW DATABASES LIKE 'lightgallery'"
```

### SSL Certificate Issues

```bash
# Verify certificate
openssl s_client -connect api.lightgallery.app:8080 -showcerts

# Check certificate expiry
openssl pkcs12 -in /etc/lightgallery/keystore.p12 -nokeys | openssl x509 -noout -dates
```

### Apple IAP Issues

- **Receipt verification fails**: Check shared secret is correct
- **Products not loading**: Verify product IDs match App Store Connect
- **Sandbox purchases fail**: Ensure using sandbox test account
- **Production purchases fail**: Verify app is approved and live

### Common Errors

**Error: "JWT secret too short"**
- Solution: Generate a longer secret (256+ bits)

**Error: "Database connection timeout"**
- Solution: Check firewall rules, verify database is running

**Error: "SSL handshake failed"**
- Solution: Verify certificate is valid and not expired

**Error: "Apple receipt verification failed"**
- Solution: Check shared secret, verify using correct environment (sandbox/production)

## 9. Security Best Practices

1. **Never commit secrets to version control**
2. **Use strong passwords** (20+ characters, mixed case, numbers, symbols)
3. **Rotate JWT secret** every 90 days
4. **Monitor failed authentication attempts**
5. **Keep dependencies updated** (run `mvn versions:display-dependency-updates`)
6. **Enable database audit logging**
7. **Use read replicas** for reporting queries
8. **Implement rate limiting** on authentication endpoints
9. **Set up intrusion detection**
10. **Regular security audits**

## 10. Rollback Procedure

If deployment fails:

```bash
# Stop the service
sudo systemctl stop lightgallery-backend

# Restore previous version
sudo cp /opt/lightgallery/backend.jar.backup /opt/lightgallery/backend.jar

# Restore database if needed
gunzip < /var/backups/lightgallery/lightgallery_YYYYMMDD_HHMMSS.sql.gz | \
  mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD lightgallery

# Start the service
sudo systemctl start lightgallery-backend

# Verify
curl https://api.lightgallery.app/api/v1/health
```

## Support

For deployment issues, contact:
- Technical Lead: [email]
- DevOps Team: [email]
- Emergency Hotline: [phone]
