# iOS Apple IAP Deployment Guide

## Overview

This guide covers the complete setup and testing of Apple In-App Purchases (IAP) for the Declutter iOS app, including sandbox testing and production configuration.

## Prerequisites

- Apple Developer Account (paid membership required)
- Xcode 15.0 or higher
- iOS device for testing (simulator has limitations)
- App Store Connect access
- Bundle ID: `joyhisn.Declutter`
- Team ID: `P9NDD6BA8Q`

## 1. App Store Connect Configuration

### 1.1 Create App Record

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to: **My Apps** → **+** → **New App**
3. Fill in app information:
   - **Platform**: iOS
   - **Name**: Declutter
   - **Primary Language**: Chinese (Simplified)
   - **Bundle ID**: joyhisn.Declutter
   - **SKU**: lightgallery-ios-001

### 1.2 Configure In-App Purchases

Navigate to: **App** → **Features** → **In-App Purchases**

#### Create Subscription Group

1. Click **+** next to "Subscription Groups"
2. **Reference Name**: Declutter Subscriptions
3. **Group Display Name** (Chinese): Declutter 订阅服务

#### Create Subscription Products

**Product 1: Pro Monthly**
- Click **+** in the subscription group
- **Type**: Auto-Renewable Subscription
- **Reference Name**: Pro Monthly Subscription
- **Product ID**: `com.lightgallery.pro.monthly`
- **Subscription Duration**: 1 Month
- **Subscription Prices**:
  - China: ¥10
  - US: $1.49 (equivalent)
- **Localization** (Chinese):
  - **Display Name**: 专业版（月付）
  - **Description**: 解锁所有专业功能，包括智能清理、照片增强、格式转换等
- **Review Information**:
  - **Screenshot**: Upload subscription screen
  - **Review Notes**: Monthly subscription for professional features

**Product 2: Pro Yearly**
- **Type**: Auto-Renewable Subscription
- **Reference Name**: Pro Yearly Subscription
- **Product ID**: `com.lightgallery.pro.yearly`
- **Subscription Duration**: 1 Year
- **Subscription Prices**:
  - China: ¥100
  - US: $14.99 (equivalent)
- **Localization** (Chinese):
  - **Display Name**: 专业版（年付）
  - **Description**: 解锁所有专业功能，年付享受17%折扣
- **Promotional Offer**: First month free (optional)

**Product 3: Max Monthly**
- **Type**: Auto-Renewable Subscription
- **Reference Name**: Max Monthly Subscription
- **Product ID**: `com.lightgallery.max.monthly`
- **Subscription Duration**: 1 Month
- **Subscription Prices**:
  - China: ¥20
  - US: $2.99 (equivalent)
- **Localization** (Chinese):
  - **Display Name**: 旗舰版（月付）
  - **Description**: 包含所有专业功能，享受优先支持和独家功能

**Product 4: Max Yearly**
- **Type**: Auto-Renewable Subscription
- **Reference Name**: Max Yearly Subscription
- **Product ID**: `com.lightgallery.max.yearly`
- **Subscription Duration**: 1 Year
- **Subscription Prices**:
  - China: ¥200
  - US: $29.99 (equivalent)
- **Localization** (Chinese):
  - **Display Name**: 旗舰版（年付）
  - **Description**: 包含所有旗舰功能，年付享受17%折扣

### 1.3 Configure Subscription Group Settings

1. Select the subscription group
2. Configure upgrade/downgrade paths:
   - **Pro Monthly** ↔ **Pro Yearly**: Crossgrade
   - **Max Monthly** ↔ **Max Yearly**: Crossgrade
   - **Pro** → **Max**: Upgrade (immediate)
   - **Max** → **Pro**: Downgrade (at end of period)

3. Set subscription group ranking:
   - Level 1: Pro Monthly, Pro Yearly
   - Level 2: Max Monthly, Max Yearly

### 1.4 Generate App-Specific Shared Secret

1. Go to: **App** → **General** → **App Information**
2. Scroll to **App-Specific Shared Secret**
3. Click **Generate**
4. Copy the shared secret (you'll need this for backend configuration)
5. Store securely (never commit to version control)

### 1.5 Configure Subscription Notifications

1. Go to: **App** → **General** → **App Information**
2. Scroll to **Subscription Status URL**
3. Enter: `https://api.lightgallery.app/api/v1/subscription/webhook`
4. This allows Apple to notify your backend of subscription changes

## 2. Xcode Project Configuration

### 2.1 Enable In-App Purchase Capability

1. Open `Declutter.xcodeproj` in Xcode
2. Select **Declutter** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **In-App Purchase**

### 2.2 Update Entitlements

Update `Declutter/Declutter.entitlements`:

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

### 2.3 Update Product IDs

Verify product IDs in `Declutter/Services/Subscription/AppleIAPManager.swift`:

```swift
private let productIds: Set<String> = [
    "com.lightgallery.pro.monthly",
    "com.lightgallery.pro.yearly",
    "com.lightgallery.max.monthly",
    "com.lightgallery.max.yearly"
]
```

### 2.4 Configure Backend API URL

Update for production in `Declutter/Services/BackendAPIClient.swift`:

```swift
// Development
private let baseURL = "http://localhost:8080/api/v1"

// Production (update before release)
private let baseURL = "https://api.lightgallery.app/api/v1"
```

Or use build configurations:

```swift
#if DEBUG
private let baseURL = "http://localhost:8080/api/v1"
#else
private let baseURL = "https://api.lightgallery.app/api/v1"
#endif
```

## 3. Sandbox Testing Setup

### 3.1 Create Sandbox Test Accounts

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to: **Users and Access** → **Sandbox** → **Testers**
3. Click **+** to add testers
4. Create at least 3 test accounts:

**Tester 1:**
- Email: tester1@lightgallery.test
- Password: Test@123456
- First Name: Test
- Last Name: User One
- Country: China

**Tester 2:**
- Email: tester2@lightgallery.test
- Password: Test@123456
- First Name: Test
- Last Name: User Two
- Country: China

**Tester 3:**
- Email: tester3@lightgallery.test
- Password: Test@123456
- First Name: Test
- Last Name: User Three
- Country: United States

### 3.2 Configure Test Device

On your iOS test device:

1. **Sign out of App Store**:
   - Settings → [Your Name] → Media & Purchases → Sign Out
   - Or Settings → App Store → Sign Out

2. **Do NOT sign in with sandbox account yet**
   - The app will prompt you when making a purchase

3. **Enable Sandbox Testing** (iOS 15+):
   - Settings → App Store → Sandbox Account
   - Sign in with sandbox test account

### 3.3 Create StoreKit Configuration File (Local Testing)

For testing without App Store Connect:

1. In Xcode: **File** → **New** → **File**
2. Select **StoreKit Configuration File**
3. Name it: `Declutter.storekit`
4. Add products (see DEPLOYMENT_GUIDE.md for full JSON)

5. Enable StoreKit configuration:
   - **Product** → **Scheme** → **Edit Scheme**
   - **Run** → **Options**
   - **StoreKit Configuration**: Select `Declutter.storekit`

## 4. Sandbox Testing Procedures

### 4.1 Test Case 1: Product Loading

**Objective**: Verify all subscription products load correctly

**Steps**:
1. Launch app
2. Navigate to Subscription page
3. Verify all 4 products are displayed:
   - Pro Monthly (¥10/月)
   - Pro Yearly (¥100/年)
   - Max Monthly (¥20/月)
   - Max Yearly (¥200/年)

**Expected Result**:
- All products display with correct prices
- Localized names in Chinese
- No loading errors

### 4.2 Test Case 2: Purchase Flow

**Objective**: Complete a subscription purchase

**Steps**:
1. Tap on "Pro Monthly" subscription
2. Tap "Subscribe" button
3. When prompted, sign in with sandbox account
4. Confirm purchase with Face ID/Touch ID
5. Wait for purchase to complete

**Expected Result**:
- Purchase sheet appears
- Sandbox account prompt appears
- Purchase completes successfully
- Subscription status updates in app
- Premium features unlock

**Backend Verification**:
```bash
# Check backend logs
journalctl -u lightgallery-backend -f | grep "receipt verification"

# Expected log entries:
# INFO: Verifying Apple IAP receipt for user: [user_id]
# INFO: Receipt verification successful
# INFO: Subscription activated: tier=pro, period=monthly
```

### 4.3 Test Case 3: Receipt Verification

**Objective**: Verify backend receipt validation

**Steps**:
1. Make a purchase
2. Check backend logs
3. Verify database entry

**Backend Verification**:
```sql
-- Check subscription was created
SELECT * FROM subscriptions 
WHERE user_id = '[user_id]' 
ORDER BY created_at DESC 
LIMIT 1;

-- Check transaction was logged
SELECT * FROM transactions 
WHERE user_id = '[user_id]' 
ORDER BY created_at DESC 
LIMIT 1;
```

**Expected Result**:
- Receipt sent to backend
- Backend verifies with Apple
- Subscription record created
- Transaction logged

### 4.4 Test Case 4: Subscription Renewal

**Objective**: Test auto-renewal (accelerated in sandbox)

**Note**: Sandbox subscriptions renew at accelerated rates:
- 1 month = 5 minutes
- 1 year = 1 hour

**Steps**:
1. Purchase a subscription
2. Wait for renewal period (5 minutes for monthly)
3. Observe renewal notification
4. Verify subscription extends

**Expected Result**:
- Renewal happens automatically
- New receipt generated
- Backend processes renewal
- Expiry date extends

### 4.5 Test Case 5: Subscription Cancellation

**Objective**: Test cancellation flow

**Steps**:
1. Purchase a subscription
2. Go to Settings → [Your Name] → Subscriptions
3. Select Declutter subscription
4. Tap "Cancel Subscription"
5. Confirm cancellation
6. Return to app

**Expected Result**:
- Subscription marked as cancelled
- Access continues until expiry
- After expiry, premium features lock
- UI shows "Subscription Expired"

### 4.6 Test Case 6: Restore Purchases

**Objective**: Test purchase restoration

**Steps**:
1. Purchase subscription on Device A
2. Install app on Device B
3. Sign in with same Apple ID
4. Navigate to Subscription page
5. Tap "Restore Purchases"

**Expected Result**:
- Subscription restored successfully
- Premium features unlock
- Subscription status syncs

### 4.7 Test Case 7: Upgrade/Downgrade

**Objective**: Test subscription tier changes

**Steps**:
1. Purchase Pro Monthly
2. Tap "Upgrade to Max"
3. Complete upgrade purchase
4. Verify new tier

**Expected Result**:
- Prorated pricing calculated
- Upgrade completes immediately
- Max features unlock
- Backend updates tier

### 4.8 Test Case 8: Offline Mode

**Objective**: Test offline subscription access

**Steps**:
1. Purchase subscription
2. Enable Airplane Mode
3. Force quit app
4. Relaunch app
5. Try to access premium features

**Expected Result**:
- Cached subscription used (< 24 hours)
- Premium features accessible
- No network errors

### 4.9 Test Case 9: Expired Cache

**Objective**: Test stale cache handling

**Steps**:
1. Purchase subscription
2. Manually set cache timestamp to 25 hours ago
3. Enable Airplane Mode
4. Try to access premium features

**Expected Result**:
- Cache considered stale
- Premium features locked
- Error message: "Cannot verify subscription. Please connect to internet."

### 4.10 Test Case 10: Error Handling

**Objective**: Test error scenarios

**Test Scenarios**:
- User cancels purchase → No changes
- Network error during purchase → Retry prompt
- Invalid receipt → Error message
- Backend unavailable → Cached subscription used

## 5. Production Deployment

### 5.1 Pre-Deployment Checklist

- [ ] All sandbox tests passed
- [ ] Backend configured for production
- [ ] SSL certificate installed
- [ ] Environment variables set
- [ ] Database schema deployed
- [ ] Apple IAP shared secret configured
- [ ] Subscription products approved in App Store Connect
- [ ] App reviewed and approved

### 5.2 Update App Configuration

1. **Update Backend URL**:
```swift
private let baseURL = "https://api.lightgallery.app/api/v1"
```

2. **Update Build Configuration**:
   - Xcode → Product → Scheme → Edit Scheme
   - Run → Build Configuration → Release

3. **Verify Product IDs** match App Store Connect

### 5.3 Build for App Store

1. **Archive the app**:
   - Xcode → Product → Archive
   - Wait for archive to complete

2. **Validate Archive**:
   - Window → Organizer → Archives
   - Select archive → Validate App
   - Fix any issues

3. **Upload to App Store Connect**:
   - Click "Distribute App"
   - Select "App Store Connect"
   - Upload

### 5.4 Submit for Review

1. Go to App Store Connect
2. Select your app
3. Fill in all required information:
   - App Description
   - Screenshots
   - Privacy Policy URL
   - Support URL
4. Submit for review

### 5.5 Post-Approval Steps

1. **Monitor Initial Purchases**:
```bash
# Watch backend logs
journalctl -u lightgallery-backend -f | grep "subscription"
```

2. **Check Subscription Analytics**:
   - App Store Connect → Analytics → Subscriptions

3. **Monitor Error Rates**:
```sql
-- Check failed transactions
SELECT COUNT(*) as failed_count
FROM transactions
WHERE status = 'failed'
AND created_at > NOW() - INTERVAL 24 HOUR;
```

## 6. Testing Checklist

### Sandbox Testing
- [ ] All products load correctly
- [ ] Purchase flow completes
- [ ] Receipt verification succeeds
- [ ] Subscription syncs to backend
- [ ] Premium features unlock
- [ ] Subscription renewal works
- [ ] Cancellation works correctly
- [ ] Restore purchases works
- [ ] Upgrade/downgrade works
- [ ] Offline mode works (< 24h cache)
- [ ] Expired cache locks features
- [ ] Error messages display correctly

### Production Testing (Post-Launch)
- [ ] Real purchase completes
- [ ] Receipt verification in production
- [ ] Subscription appears in App Store
- [ ] Renewal notifications work
- [ ] Cancellation through App Store works
- [ ] Customer support can view subscriptions

## 7. Troubleshooting

### Products Not Loading

**Symptom**: Subscription products don't appear in app

**Solutions**:
1. Verify product IDs match App Store Connect
2. Check products are "Ready to Submit" status
3. Wait 24 hours after creating products
4. Clear app data and reinstall
5. Check network connectivity

### Purchase Fails

**Symptom**: Purchase sheet appears but fails

**Solutions**:
1. Verify signed in with sandbox account
2. Check sandbox account is valid
3. Verify products are approved
4. Check backend logs for errors
5. Verify SSL certificate is valid

### Receipt Verification Fails

**Symptom**: Purchase completes but subscription doesn't activate

**Solutions**:
1. Check backend logs: `journalctl -u lightgallery-backend -f`
2. Verify shared secret is correct
3. Check backend is using correct Apple URL (sandbox vs production)
4. Verify network connectivity to Apple servers
5. Check receipt data is being sent correctly

### Subscription Not Syncing

**Symptom**: Subscription works on one device but not another

**Solutions**:
1. Tap "Restore Purchases"
2. Check backend subscription status
3. Verify same Apple ID on both devices
4. Check network connectivity
5. Clear app cache and re-sync

## 8. Monitoring and Analytics

### Key Metrics to Track

1. **Conversion Rate**: Free → Paid
2. **Subscription Retention**: Monthly/Yearly
3. **Churn Rate**: Cancellations
4. **Revenue**: MRR (Monthly Recurring Revenue)
5. **Trial Conversions**: If offering trials

### App Store Connect Analytics

- Navigate to: **Analytics** → **Subscriptions**
- Monitor:
  - Active Subscriptions
  - New Subscriptions
  - Renewals
  - Cancellations
  - Revenue

### Backend Analytics

```sql
-- Active subscriptions by tier
SELECT tier, COUNT(*) as count
FROM subscriptions
WHERE status = 'active'
GROUP BY tier;

-- Monthly revenue
SELECT 
    DATE_FORMAT(created_at, '%Y-%m') as month,
    SUM(amount) as revenue
FROM transactions
WHERE status = 'completed'
GROUP BY month
ORDER BY month DESC;

-- Churn rate
SELECT 
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) * 100.0 / COUNT(*) as churn_rate
FROM subscriptions
WHERE created_at > NOW() - INTERVAL 30 DAY;
```

## 9. Support and Resources

### Apple Documentation
- [In-App Purchase Programming Guide](https://developer.apple.com/in-app-purchase/)
- [StoreKit Documentation](https://developer.apple.com/documentation/storekit)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)

### Testing Resources
- [Sandbox Testing Guide](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_with_sandbox)
- [Receipt Validation](https://developer.apple.com/documentation/appstorereceipts/verifyreceipt)

### Support Contacts
- Apple Developer Support: https://developer.apple.com/support/
- App Store Connect Support: https://developer.apple.com/contact/

## 10. Common Issues and Solutions

### Issue: "Cannot connect to iTunes Store"
**Solution**: Sign out and sign back in with sandbox account

### Issue: "This In-App Purchase has already been bought"
**Solution**: Tap "Restore Purchases" or use a different sandbox account

### Issue: Subscription shows as expired immediately
**Solution**: Check system date/time is correct

### Issue: Backend returns 401 Unauthorized
**Solution**: Verify JWT token is valid and not expired

### Issue: Receipt verification returns status 21002
**Solution**: Using wrong environment (sandbox vs production)

---

**Last Updated**: December 2024
**Version**: 1.0
**Maintained By**: Declutter Development Team
