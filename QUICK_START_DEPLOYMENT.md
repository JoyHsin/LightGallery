# Quick Start Deployment Guide

## 🚀 Fast Track to Production

This is a condensed guide for experienced DevOps engineers. For detailed instructions, see `backend/DEPLOYMENT_GUIDE.md`.

---

## Prerequisites Checklist

- [ ] Java 17+
- [ ] Maven 3.6+
- [ ] MySQL 8.0+
- [ ] SSL certificate
- [ ] Apple Developer Account
- [ ] OAuth credentials (WeChat, Alipay, Apple)

---

## 1. Database Setup (5 minutes)

```bash
cd backend
sudo ./setup_production_database.sh
```

This script will:
- Create database and user
- Run schema
- Set up backups
- Save credentials to `/etc/lightgallery/database.credentials`

---

## 2. Environment Configuration (5 minutes)

```bash
# Copy template
sudo cp backend/.env.template /etc/lightgallery/production.env

# Generate JWT secret
openssl rand -base64 64

# Edit configuration
sudo nano /etc/lightgallery/production.env
```

**Required values**:
- `DB_*` - From step 1
- `JWT_SECRET` - Generated above
- `WECHAT_*` - From WeChat Open Platform
- `ALIPAY_*` - From Alipay Open Platform
- `APPLE_*` - From Apple Developer
- `APPLE_IAP_SHARED_SECRET` - From App Store Connect
- `SSL_*` - Your SSL certificate paths

```bash
# Secure the file
sudo chmod 600 /etc/lightgallery/production.env
```

---

## 3. SSL Certificate Setup (5 minutes)

```bash
# Using Let's Encrypt
sudo certbot certonly --standalone -d api.lightgallery.app

# Convert to PKCS12
openssl pkcs12 -export \
  -in /etc/letsencrypt/live/api.lightgallery.app/fullchain.pem \
  -inkey /etc/letsencrypt/live/api.lightgallery.app/privkey.pem \
  -out /etc/lightgallery/keystore.p12 \
  -name lightgallery

# Secure the keystore
sudo chmod 600 /etc/lightgallery/keystore.p12
```

---

## 4. Backend Deployment (5 minutes)

```bash
cd backend
sudo ./deploy.sh
```

This script will:
- Build application
- Create backup
- Deploy to `/opt/lightgallery`
- Set up systemd service
- Start service

**Verify**:
```bash
# Check service
sudo systemctl status lightgallery-backend

# Check health
curl https://api.lightgallery.app/api/v1/health

# View logs
journalctl -u lightgallery-backend -f
```

---

## 5. Apple IAP Setup (15 minutes)

### App Store Connect

1. **Create App**: https://appstoreconnect.apple.com
   - Bundle ID: `joyhisn.LightGallery`
   - Name: LightGallery

2. **Create IAP Products**:
   - `com.lightgallery.pro.monthly` - ¥10/月
   - `com.lightgallery.pro.yearly` - ¥100/年
   - `com.lightgallery.max.monthly` - ¥20/月
   - `com.lightgallery.max.yearly` - ¥200/年

3. **Generate Shared Secret**:
   - App → General → App Information
   - Copy to `APPLE_IAP_SHARED_SECRET` in env file

4. **Configure Webhook**:
   - Subscription Status URL: `https://api.lightgallery.app/api/v1/subscription/webhook`

### iOS App

1. **Enable IAP Capability** in Xcode
2. **Update Backend URL**:
   ```swift
   private let baseURL = "https://api.lightgallery.app/api/v1"
   ```
3. **Build and Archive**
4. **Upload to App Store Connect**

---

## 6. Sandbox Testing (30 minutes)

### Create Test Accounts
- App Store Connect → Users and Access → Sandbox → Testers
- Create 3 test accounts

### Run Tests
```bash
# Use the checklist
open SANDBOX_TESTING_CHECKLIST.md
```

**Critical tests**:
- [ ] Products load
- [ ] Purchase completes
- [ ] Receipt verifies
- [ ] Subscription activates
- [ ] Features unlock
- [ ] Restore works

---

## 7. Production Launch

### Pre-Launch
- [ ] All sandbox tests pass
- [ ] QA sign-off
- [ ] Backend health check passing
- [ ] Monitoring configured
- [ ] Backup verified

### Launch
1. Submit iOS app for review
2. Wait for approval
3. Release to App Store
4. Monitor initial purchases

### Post-Launch
```bash
# Monitor logs
journalctl -u lightgallery-backend -f | grep "subscription"

# Check database
mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME
SELECT COUNT(*) FROM subscriptions WHERE status = 'active';
```

---

## Common Commands

### Service Management
```bash
# Status
sudo systemctl status lightgallery-backend

# Restart
sudo systemctl restart lightgallery-backend

# Stop
sudo systemctl stop lightgallery-backend

# Logs
journalctl -u lightgallery-backend -f
journalctl -u lightgallery-backend -n 100
journalctl -u lightgallery-backend --since "1 hour ago"
```

### Database
```bash
# Connect
mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME

# Backup
mysqldump -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD \
  --single-transaction $DB_NAME | gzip > backup.sql.gz

# Restore
gunzip < backup.sql.gz | mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME
```

### Health Checks
```bash
# Backend health
curl https://api.lightgallery.app/api/v1/health

# SSL certificate
openssl s_client -connect api.lightgallery.app:8080 -showcerts

# Database connection
mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD -e "SELECT 1"
```

---

## Troubleshooting

### Backend won't start
```bash
# Check logs
journalctl -u lightgallery-backend -n 50

# Common issues:
# - Database connection: Check DB_* env vars
# - SSL certificate: Check SSL_* paths
# - Port in use: Check if port 8080 is available
```

### Products not loading
```bash
# Check product IDs match App Store Connect
# Wait 24 hours after creating products
# Verify products are "Ready to Submit"
```

### Receipt verification fails
```bash
# Check backend logs
journalctl -u lightgallery-backend -f | grep "receipt"

# Verify shared secret is correct
# Check using correct environment (sandbox vs production)
```

---

## Rollback

```bash
# Stop service
sudo systemctl stop lightgallery-backend

# Restore backup
sudo cp /opt/lightgallery/backend.jar.backup /opt/lightgallery/backend.jar

# Restore database (if needed)
gunzip < /var/backups/lightgallery/lightgallery_YYYYMMDD_HHMMSS.sql.gz | \
  mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD $DB_NAME

# Start service
sudo systemctl start lightgallery-backend

# Verify
curl https://api.lightgallery.app/api/v1/health
```

---

## Monitoring

### Set up alerts
```bash
# Health check every 5 minutes
echo "*/5 * * * * curl -f https://api.lightgallery.app/api/v1/health || echo 'Health check failed'" | crontab -
```

### Key metrics
- Active subscriptions
- Failed transactions
- Error rate
- Response time
- Database connections

---

## Support

- **Detailed Guide**: `backend/DEPLOYMENT_GUIDE.md`
- **iOS Guide**: `IOS_IAP_DEPLOYMENT_GUIDE.md`
- **Testing**: `SANDBOX_TESTING_CHECKLIST.md`
- **Summary**: `DEPLOYMENT_SUMMARY.md`

---

## Estimated Timeline

| Task | Time |
|------|------|
| Database setup | 5 min |
| Environment config | 5 min |
| SSL setup | 5 min |
| Backend deployment | 5 min |
| Apple IAP setup | 15 min |
| Sandbox testing | 30 min |
| **Total** | **~1 hour** |

---

**Last Updated**: December 7, 2024  
**Version**: 1.0
