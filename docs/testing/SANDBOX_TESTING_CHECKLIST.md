# Declutter Sandbox Testing Checklist

## Overview

This checklist ensures comprehensive testing of Apple In-App Purchases in the sandbox environment before production deployment.

**Testing Date**: _______________  
**Tester Name**: _______________  
**iOS Version**: _______________  
**Device Model**: _______________  
**App Version**: _______________  

---

## Pre-Testing Setup

### Sandbox Account Setup
- [ ] Created sandbox test accounts in App Store Connect
- [ ] Signed out of production App Store on test device
- [ ] Verified sandbox account credentials work

### App Configuration
- [ ] Backend is running and accessible
- [ ] Backend configured for sandbox environment
- [ ] App configured to use sandbox backend URL
- [ ] StoreKit configuration file created (optional)

### Backend Verification
- [ ] Database is set up and accessible
- [ ] Backend health endpoint responds: `curl http://localhost:8080/api/v1/health`
- [ ] Backend logs are accessible: `journalctl -u lightgallery-backend -f`

---

## Test Suite 1: Product Loading

### Test 1.1: Load All Products
**Objective**: Verify all subscription products load correctly

**Steps**:
1. Launch Declutter app
2. Navigate to Subscription page
3. Wait for products to load

**Expected Results**:
- [ ] All 4 products display
- [ ] Pro Monthly shows ¥10/月
- [ ] Pro Yearly shows ¥100/年
- [ ] Max Monthly shows ¥20/月
- [ ] Max Yearly shows ¥200/年
- [ ] Product names in Chinese
- [ ] Product descriptions visible
- [ ] No loading errors

**Actual Results**:
```
_____________________________________________
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

### Test 1.2: Product Details
**Objective**: Verify product information is correct

**Steps**:
1. Tap on each product
2. Review displayed information

**Expected Results**:
- [ ] Correct pricing for each tier
- [ ] Billing period displayed (月付/年付)
- [ ] Feature list shows correctly
- [ ] Localized text in Chinese

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

## Test Suite 2: Purchase Flow

### Test 2.1: Pro Monthly Purchase
**Objective**: Complete a Pro Monthly subscription purchase

**Steps**:
1. Tap "Pro Monthly" subscription
2. Tap "Subscribe" button
3. Sign in with sandbox account when prompted
4. Confirm purchase with Face ID/Touch ID
5. Wait for purchase to complete

**Expected Results**:
- [ ] Purchase sheet appears
- [ ] Sandbox account prompt appears
- [ ] Price shows ¥10
- [ ] Purchase completes successfully
- [ ] Success message displays
- [ ] Subscription status updates to "Pro"
- [ ] Premium features unlock

**Backend Verification**:
```bash
# Check logs
journalctl -u lightgallery-backend -f | grep "receipt verification"

# Expected:
# INFO: Verifying Apple IAP receipt
# INFO: Receipt verification successful
# INFO: Subscription activated: tier=pro, period=monthly
```

**Backend Logs**:
```
_____________________________________________
_____________________________________________
```

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

### Test 2.2: Pro Yearly Purchase
**Objective**: Complete a Pro Yearly subscription purchase

**Steps**:
1. Tap "Pro Yearly" subscription
2. Complete purchase flow

**Expected Results**:
- [ ] Purchase completes
- [ ] Price shows ¥100
- [ ] Subscription status updates
- [ ] Expiry date set to 1 year from now

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

### Test 2.3: Max Monthly Purchase
**Objective**: Complete a Max Monthly subscription purchase

**Steps**:
1. Tap "Max Monthly" subscription
2. Complete purchase flow

**Expected Results**:
- [ ] Purchase completes
- [ ] Price shows ¥20
- [ ] Subscription status updates to "Max"
- [ ] All premium features unlock

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

### Test 2.4: Max Yearly Purchase
**Objective**: Complete a Max Yearly subscription purchase

**Steps**:
1. Tap "Max Yearly" subscription
2. Complete purchase flow

**Expected Results**:
- [ ] Purchase completes
- [ ] Price shows ¥200
- [ ] Subscription status updates
- [ ] Expiry date set to 1 year from now

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

## Test Suite 3: Receipt Verification

### Test 3.1: Backend Receipt Verification
**Objective**: Verify backend processes receipts correctly

**Steps**:
1. Make any purchase
2. Check backend logs
3. Query database

**Expected Results**:
- [ ] Receipt sent to backend
- [ ] Backend verifies with Apple sandbox
- [ ] Subscription record created in database
- [ ] Transaction logged

**Backend Logs**:
```
_____________________________________________
_____________________________________________
```

**Database Query**:
```sql
SELECT * FROM subscriptions WHERE user_id = '[user_id]' ORDER BY created_at DESC LIMIT 1;
SELECT * FROM transactions WHERE user_id = '[user_id]' ORDER BY created_at DESC LIMIT 1;
```

**Database Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

## Test Suite 4: Subscription Management

### Test 4.1: View Active Subscription
**Objective**: Verify subscription details display correctly

**Steps**:
1. After purchasing, navigate to Subscription page
2. Review subscription details

**Expected Results**:
- [ ] Current tier highlighted
- [ ] Expiry date displayed
- [ ] Renewal status shown
- [ ] Payment method displayed

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

### Test 4.2: Subscription Renewal
**Objective**: Test auto-renewal (accelerated in sandbox)

**Note**: Sandbox renewal times:
- 1 month subscription = 5 minutes
- 1 year subscription = 1 hour

**Steps**:
1. Purchase a monthly subscription
2. Wait 5 minutes
3. Observe renewal

**Expected Results**:
- [ ] Renewal happens automatically
- [ ] New receipt generated
- [ ] Backend processes renewal
- [ ] Expiry date extends
- [ ] No interruption to service

**Time Started**: _______________  
**Renewal Observed**: _______________  

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

### Test 4.3: Subscription Cancellation
**Objective**: Test cancellation flow

**Steps**:
1. Purchase a subscription
2. Go to Settings → [Your Name] → Subscriptions
3. Select Declutter
4. Tap "Cancel Subscription"
5. Confirm cancellation
6. Return to app

**Expected Results**:
- [ ] Subscription marked as cancelled
- [ ] Access continues until expiry
- [ ] UI shows "Expires on [date]"
- [ ] After expiry, premium features lock

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

### Test 4.4: Restore Purchases
**Objective**: Test purchase restoration

**Steps**:
1. Purchase subscription on Device A
2. Install app on Device B (or delete and reinstall)
3. Sign in with same Apple ID
4. Navigate to Subscription page
5. Tap "Restore Purchases"

**Expected Results**:
- [ ] Restoration starts
- [ ] Subscription restored successfully
- [ ] Premium features unlock
- [ ] Subscription status syncs
- [ ] Success message displays

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

## Test Suite 5: Upgrade/Downgrade

### Test 5.1: Upgrade Pro to Max
**Objective**: Test subscription upgrade

**Steps**:
1. Purchase Pro Monthly
2. Navigate to Subscription page
3. Tap "Upgrade to Max"
4. Complete upgrade purchase

**Expected Results**:
- [ ] Prorated pricing calculated
- [ ] Upgrade completes immediately
- [ ] Subscription tier changes to Max
- [ ] Max features unlock
- [ ] Backend updates tier

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

### Test 5.2: Downgrade Max to Pro
**Objective**: Test subscription downgrade

**Steps**:
1. Purchase Max Monthly
2. Navigate to Subscription page
3. Tap "Downgrade to Pro"
4. Complete downgrade

**Expected Results**:
- [ ] Downgrade scheduled for end of period
- [ ] Max access continues until expiry
- [ ] UI shows "Downgrades to Pro on [date]"
- [ ] After expiry, tier changes to Pro

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

### Test 5.3: Crossgrade Monthly to Yearly
**Objective**: Test billing period change

**Steps**:
1. Purchase Pro Monthly
2. Tap "Switch to Yearly"
3. Complete purchase

**Expected Results**:
- [ ] Crossgrade completes
- [ ] Billing period changes to yearly
- [ ] Prorated credit applied
- [ ] Expiry date set to 1 year

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

## Test Suite 6: Feature Access Control

### Test 6.1: Free Tier Access
**Objective**: Verify free tier restrictions

**Steps**:
1. Without any subscription, try to access premium features
2. Try each premium feature

**Expected Results**:
- [ ] Smart Clean shows paywall
- [ ] Photo Enhancer shows paywall
- [ ] Format Converter shows paywall
- [ ] All toolbox features show paywall
- [ ] Paywall displays correct messaging
- [ ] "Upgrade" button works

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

### Test 6.2: Pro Tier Access
**Objective**: Verify Pro tier access

**Steps**:
1. Purchase Pro subscription
2. Try to access all premium features

**Expected Results**:
- [ ] All premium features accessible
- [ ] No paywalls shown
- [ ] Features work correctly
- [ ] UI shows "Pro" badge

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

### Test 6.3: Max Tier Access
**Objective**: Verify Max tier access

**Steps**:
1. Purchase Max subscription
2. Try to access all premium features

**Expected Results**:
- [ ] All premium features accessible
- [ ] Max-exclusive features accessible
- [ ] UI shows "Max" badge
- [ ] Priority support available

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

## Test Suite 7: Offline Mode

### Test 7.1: Offline Access (Fresh Cache)
**Objective**: Test offline subscription access with valid cache

**Steps**:
1. Purchase subscription
2. Verify subscription synced
3. Enable Airplane Mode
4. Force quit app
5. Relaunch app
6. Try to access premium features

**Expected Results**:
- [ ] Cached subscription used
- [ ] Premium features accessible
- [ ] No network errors
- [ ] UI shows "Offline Mode"

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

### Test 7.2: Offline Access (Stale Cache)
**Objective**: Test offline behavior with expired cache

**Note**: This test requires manually setting cache timestamp or waiting 24+ hours

**Steps**:
1. Purchase subscription
2. Wait 24+ hours or manually expire cache
3. Enable Airplane Mode
4. Try to access premium features

**Expected Results**:
- [ ] Cache considered stale
- [ ] Premium features locked
- [ ] Error message: "Cannot verify subscription"
- [ ] Prompt to connect to internet

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

### Test 7.3: Network Recovery
**Objective**: Test sync after network restoration

**Steps**:
1. Start in offline mode
2. Disable Airplane Mode
3. Wait for sync

**Expected Results**:
- [ ] App detects network
- [ ] Subscription syncs automatically
- [ ] Premium features unlock
- [ ] Cache updates

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

## Test Suite 8: Error Handling

### Test 8.1: User Cancels Purchase
**Objective**: Test cancellation handling

**Steps**:
1. Start purchase flow
2. Cancel when prompted for payment

**Expected Results**:
- [ ] Purchase cancelled gracefully
- [ ] No error message
- [ ] Subscription status unchanged
- [ ] Can retry purchase

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

### Test 8.2: Network Error During Purchase
**Objective**: Test network error handling

**Steps**:
1. Start purchase flow
2. Enable Airplane Mode during purchase
3. Complete purchase attempt

**Expected Results**:
- [ ] Error message displays
- [ ] Retry option available
- [ ] Subscription status unchanged
- [ ] No partial state

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

### Test 8.3: Backend Unavailable
**Objective**: Test backend failure handling

**Steps**:
1. Stop backend service
2. Make a purchase
3. Observe behavior

**Expected Results**:
- [ ] Purchase completes with Apple
- [ ] Receipt queued for verification
- [ ] User notified of delay
- [ ] Retry happens when backend available

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

### Test 8.4: Invalid Receipt
**Objective**: Test invalid receipt handling

**Note**: This requires backend modification to simulate

**Expected Results**:
- [ ] Backend rejects invalid receipt
- [ ] User notified of error
- [ ] Subscription not activated
- [ ] Support contact info provided

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

## Test Suite 9: UI/UX Testing

### Test 9.1: Subscription Page Layout
**Objective**: Verify UI displays correctly

**Expected Results**:
- [ ] All elements visible
- [ ] Text readable
- [ ] Buttons accessible
- [ ] Proper spacing
- [ ] Correct colors
- [ ] Icons display

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

### Test 9.2: Paywall Display
**Objective**: Verify paywall appears correctly

**Expected Results**:
- [ ] Paywall appears when accessing premium features
- [ ] Feature benefits listed
- [ ] Pricing clear
- [ ] "Upgrade" button prominent
- [ ] "Maybe Later" option available

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

### Test 9.3: Loading States
**Objective**: Verify loading indicators

**Expected Results**:
- [ ] Loading indicator during product fetch
- [ ] Loading indicator during purchase
- [ ] Loading indicator during verification
- [ ] No frozen UI

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

## Test Suite 10: Localization

### Test 10.1: Chinese Localization
**Objective**: Verify Chinese text displays correctly

**Expected Results**:
- [ ] All subscription text in Chinese
- [ ] Pricing in CNY (¥)
- [ ] Error messages in Chinese
- [ ] Proper character encoding

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

### Test 10.2: English Fallback
**Objective**: Verify English fallback works

**Steps**:
1. Change device language to English
2. Relaunch app

**Expected Results**:
- [ ] UI switches to English
- [ ] All text readable
- [ ] No missing translations

**Actual Results**:
```
_____________________________________________
_____________________________________________
```

**Status**: ⬜ Pass  ⬜ Fail  ⬜ Blocked

---

## Summary

### Test Results
- **Total Tests**: 40
- **Passed**: _____
- **Failed**: _____
- **Blocked**: _____
- **Pass Rate**: _____%

### Critical Issues
```
_____________________________________________
_____________________________________________
_____________________________________________
```

### Non-Critical Issues
```
_____________________________________________
_____________________________________________
_____________________________________________
```

### Recommendations
```
_____________________________________________
_____________________________________________
_____________________________________________
```

### Sign-Off

**Tester Signature**: _______________  
**Date**: _______________  

**Ready for Production**: ⬜ Yes  ⬜ No  

**Notes**:
```
_____________________________________________
_____________________________________________
_____________________________________________
```

---

**Document Version**: 1.0  
**Last Updated**: December 2024
