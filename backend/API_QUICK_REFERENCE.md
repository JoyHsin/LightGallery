# LightGallery API Quick Reference

## Base URLs
- **Development**: `http://localhost:8080/api/v1`
- **Production**: `https://api.lightgallery.com/api/v1`
- **Swagger UI**: `http://localhost:8080/swagger-ui.html`

## Authentication

### Get JWT Token
```bash
POST /auth/oauth/exchange
{
  "provider": "apple|wechat|alipay",
  "code": "oauth_code",
  "email": "user@example.com",
  "displayName": "User Name"
}
```

### Refresh Token
```bash
POST /auth/token/refresh
{
  "refreshToken": "your_refresh_token"
}
```

### Logout
```bash
POST /auth/logout
Authorization: Bearer <token>
```

### Delete Account
```bash
DELETE /auth/account
Authorization: Bearer <token>
```

## Subscriptions

### Get Products
```bash
GET /subscription/products
```

### Get Status
```bash
GET /subscription/status
Authorization: Bearer <token>
```

### Verify Payment
```bash
POST /subscription/verify
Authorization: Bearer <token>
{
  "paymentMethod": "apple_iap|wechat_pay|alipay",
  "productId": "com.lightgallery.pro.monthly",
  "transactionId": "transaction_id",
  "receiptData": "base64_receipt",
  "platform": "ios|android|web"
}
```

### Sync Subscription
```bash
POST /subscription/sync
Authorization: Bearer <token>
{
  "platform": "ios|android|web",
  "forceRefresh": false
}
```

### Calculate Upgrade
```bash
POST /subscription/upgrade/calculate?targetTier=max
Authorization: Bearer <token>
```

### Cancel Subscription
```bash
POST /subscription/cancel
Authorization: Bearer <token>
```

## Health Check
```bash
GET /health
```

## Response Format

### Success Response
```json
{
  "code": 200,
  "message": "Success message",
  "data": { ... }
}
```

### Error Response
```json
{
  "code": 400,
  "message": "Error message",
  "data": null
}
```

## Common Status Codes
- **200**: Success
- **400**: Bad Request
- **401**: Unauthorized
- **403**: Forbidden
- **404**: Not Found
- **500**: Internal Server Error

## Subscription Tiers
- **Free**: ¥0 - Basic features
- **Pro**: ¥10/month or ¥100/year - All premium features
- **Max**: ¥20/month or ¥200/year - All features + priority support

## Payment Methods
- **apple_iap**: Apple In-App Purchase (iOS only)
- **wechat_pay**: WeChat Pay (Android/Web)
- **alipay**: Alipay (Android/Web)

## Testing with cURL

### Complete Flow Example
```bash
# 1. Get JWT token
curl -X POST http://localhost:8080/api/v1/auth/oauth/exchange \
  -H "Content-Type: application/json" \
  -d '{"provider":"apple","code":"test_code","email":"test@example.com"}'

# 2. Get subscription status (use token from step 1)
curl -X GET http://localhost:8080/api/v1/subscription/status \
  -H "Authorization: Bearer YOUR_TOKEN"

# 3. Get available products
curl -X GET http://localhost:8080/api/v1/subscription/products

# 4. Verify payment
curl -X POST http://localhost:8080/api/v1/subscription/verify \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "paymentMethod":"apple_iap",
    "productId":"com.lightgallery.pro.monthly",
    "transactionId":"1000000123456789",
    "receiptData":"base64_receipt",
    "platform":"ios"
  }'
```

## Documentation Files
- **API_DOCUMENTATION.md**: Complete API reference
- **SWAGGER_GUIDE.md**: Guide to using Swagger UI
- **API_QUICK_REFERENCE.md**: This file - quick reference

## Support
- Email: support@lightgallery.com
- Swagger UI: http://localhost:8080/swagger-ui.html
