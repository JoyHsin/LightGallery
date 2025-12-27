# Declutter Backend API Documentation

## Overview

The Declutter Backend API provides authentication and subscription management services for the Declutter mobile application. This API supports:

- **Multi-platform OAuth authentication** (Apple, WeChat, Alipay)
- **Tiered subscription management** (Free, Pro, Max)
- **Payment verification** (Apple IAP, WeChat Pay, Alipay)
- **Offline-first architecture** with subscription caching

## Base URL

- **Development**: `http://localhost:8080/api/v1`
- **Production**: `https://api.lightgallery.com/api/v1`

## Interactive Documentation

Once the server is running, you can access the interactive Swagger UI documentation at:

- **Swagger UI**: `http://localhost:8080/swagger-ui.html`
- **OpenAPI JSON**: `http://localhost:8080/v3/api-docs`

## Authentication

Most endpoints require JWT authentication. Include the JWT token in the `Authorization` header:

```
Authorization: Bearer <your_jwt_token>
```

### Obtaining a JWT Token

1. Use the `/auth/oauth/exchange` endpoint with an OAuth authorization code
2. The response will include `accessToken` and `refreshToken`
3. Use the `accessToken` for subsequent API calls
4. When the `accessToken` expires, use `/auth/token/refresh` with the `refreshToken`

## API Endpoints

### Authentication Endpoints

#### 1. Exchange OAuth Token

**Endpoint**: `POST /auth/oauth/exchange`

**Description**: Exchanges an OAuth authorization code from a third-party provider for application JWT tokens.

**Authentication**: None required

**Request Body**:
```json
{
  "provider": "apple",
  "code": "oauth_authorization_code",
  "email": "user@example.com",
  "displayName": "John Doe",
  "avatarUrl": "https://example.com/avatar.jpg",
  "providerUserId": "provider_user_id",
  "deviceInfo": "iOS 17.0",
  "ipAddress": "192.168.1.1"
}
```

**Request Parameters**:
- `provider` (required): OAuth provider - `apple`, `wechat`, or `alipay`
- `code` (required): OAuth authorization code from provider
- `email` (optional): User email from OAuth provider
- `displayName` (optional): User display name from OAuth provider
- `avatarUrl` (optional): User avatar URL from OAuth provider
- `providerUserId` (optional): User ID from OAuth provider
- `deviceInfo` (optional): Device information
- `ipAddress` (optional): Client IP address

**Success Response** (200 OK):
```json
{
  "code": 200,
  "message": "Authentication successful",
  "data": {
    "userId": 12345,
    "displayName": "John Doe",
    "email": "john@example.com",
    "avatarUrl": "https://example.com/avatar.jpg",
    "authProvider": "apple",
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresAt": "2024-12-08T10:00:00",
    "refreshExpiresAt": "2024-12-15T10:00:00"
  }
}
```

**Error Response** (400 Bad Request):
```json
{
  "code": 400,
  "message": "Authentication failed: Invalid authorization code",
  "data": null
}
```

---

#### 2. Refresh Access Token

**Endpoint**: `POST /auth/token/refresh`

**Description**: Refreshes an expired access token using a valid refresh token.

**Authentication**: None required

**Request Body**:
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Success Response** (200 OK):
```json
{
  "code": 200,
  "message": "Token refreshed successfully",
  "data": {
    "userId": 12345,
    "displayName": "John Doe",
    "email": "john@example.com",
    "avatarUrl": "https://example.com/avatar.jpg",
    "authProvider": "apple",
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresAt": "2024-12-08T10:00:00",
    "refreshExpiresAt": "2024-12-15T10:00:00"
  }
}
```

**Error Response** (401 Unauthorized):
```json
{
  "code": 401,
  "message": "Token refresh failed: Refresh token expired",
  "data": null
}
```

---

#### 3. Logout

**Endpoint**: `POST /auth/logout`

**Description**: Logs out the current user and invalidates all authentication tokens.

**Authentication**: Required (Bearer token)

**Request Body**: None

**Success Response** (200 OK):
```json
{
  "code": 200,
  "message": "Logout successful",
  "data": null
}
```

**Error Response** (401 Unauthorized):
```json
{
  "code": 401,
  "message": "User not authenticated",
  "data": null
}
```

---

#### 4. Delete Account

**Endpoint**: `DELETE /auth/account`

**Description**: Permanently deletes the user account and all associated data. This action cannot be undone.

**Authentication**: Required (Bearer token)

**Request Body**: None

**Success Response** (200 OK):
```json
{
  "code": 200,
  "message": "Account deleted successfully",
  "data": null
}
```

**Error Responses**:
- **401 Unauthorized**: User not authenticated
- **500 Internal Server Error**: Account deletion failed

---

### Subscription Endpoints

#### 5. Get Subscription Products

**Endpoint**: `GET /subscription/products`

**Description**: Retrieves all available subscription products including pricing and features.

**Authentication**: None required

**Success Response** (200 OK):
```json
{
  "code": 200,
  "message": "Products retrieved successfully",
  "data": [
    {
      "productId": "com.lightgallery.pro.monthly",
      "tier": "pro",
      "billingPeriod": "monthly",
      "price": 10.00,
      "currency": "CNY",
      "localizedPrice": "¥10/月",
      "description": "Professional tier with all premium features",
      "features": [
        "Smart Clean",
        "Duplicate Detection",
        "Similar Photo Cleanup",
        "Screenshot Cleanup",
        "Photo Enhancer",
        "Format Converter",
        "Live Photo Converter",
        "ID Photo Editor",
        "Privacy Wiper",
        "Screenshot Stitcher"
      ]
    },
    {
      "productId": "com.lightgallery.pro.yearly",
      "tier": "pro",
      "billingPeriod": "yearly",
      "price": 100.00,
      "currency": "CNY",
      "localizedPrice": "¥100/年",
      "description": "Professional tier yearly subscription (save 17%)",
      "features": ["..."]
    },
    {
      "productId": "com.lightgallery.max.monthly",
      "tier": "max",
      "billingPeriod": "monthly",
      "price": 20.00,
      "currency": "CNY",
      "localizedPrice": "¥20/月",
      "description": "Max tier with priority support",
      "features": ["..."]
    },
    {
      "productId": "com.lightgallery.max.yearly",
      "tier": "max",
      "billingPeriod": "yearly",
      "price": 200.00,
      "currency": "CNY",
      "localizedPrice": "¥200/年",
      "description": "Max tier yearly subscription (save 17%)",
      "features": ["..."]
    }
  ]
}
```

---

#### 6. Get Subscription Status

**Endpoint**: `GET /subscription/status`

**Description**: Retrieves the current subscription status for the authenticated user.

**Authentication**: Required (Bearer token)

**Success Response** (200 OK):
```json
{
  "code": 200,
  "message": "Subscription status retrieved",
  "data": {
    "id": 1,
    "userId": 12345,
    "tier": "pro",
    "billingPeriod": "monthly",
    "status": "active",
    "paymentMethod": "apple_iap",
    "startDate": "2024-12-01T00:00:00",
    "expiryDate": "2025-01-01T00:00:00",
    "autoRenew": true,
    "productId": "com.lightgallery.pro.monthly",
    "lastSyncedAt": "2024-12-07T10:00:00"
  }
}
```

**Subscription Status Values**:
- `active`: Subscription is currently active
- `expired`: Subscription has expired
- `cancelled`: Subscription is cancelled but still active until expiry
- `pending`: Payment is pending verification

**Error Response** (401 Unauthorized):
```json
{
  "code": 401,
  "message": "User not authenticated",
  "data": null
}
```

---

#### 7. Verify Payment

**Endpoint**: `POST /subscription/verify`

**Description**: Verifies a payment transaction and updates the user's subscription status.

**Authentication**: Required (Bearer token)

**Request Body**:
```json
{
  "paymentMethod": "apple_iap",
  "productId": "com.lightgallery.pro.monthly",
  "transactionId": "1000000123456789",
  "receiptData": "base64_encoded_receipt_data",
  "originalTransactionId": "1000000123456789",
  "platform": "ios"
}
```

**Request Parameters**:
- `paymentMethod` (required): Payment method - `apple_iap`, `wechat_pay`, or `alipay`
- `productId` (required): Product ID being purchased
- `transactionId` (required): Transaction ID from payment platform
- `receiptData` (optional): Receipt data for Apple IAP (base64 encoded)
- `originalTransactionId` (optional): Original transaction ID for Apple IAP renewals
- `platform` (required): Platform - `ios`, `android`, or `web`

**Success Response** (200 OK):
```json
{
  "code": 200,
  "message": "Payment verified and subscription updated",
  "data": {
    "id": 1,
    "userId": 12345,
    "tier": "pro",
    "billingPeriod": "monthly",
    "status": "active",
    "paymentMethod": "apple_iap",
    "startDate": "2024-12-07T10:00:00",
    "expiryDate": "2025-01-07T10:00:00",
    "autoRenew": true,
    "productId": "com.lightgallery.pro.monthly",
    "lastSyncedAt": "2024-12-07T10:00:00"
  }
}
```

**Error Response** (400 Bad Request):
```json
{
  "code": 400,
  "message": "Payment verification failed: Invalid receipt",
  "data": null
}
```

---

#### 8. Sync Subscription

**Endpoint**: `POST /subscription/sync`

**Description**: Synchronizes the subscription status with the payment platform.

**Authentication**: Required (Bearer token)

**Request Body**:
```json
{
  "platform": "ios",
  "lastKnownStatus": "active",
  "forceRefresh": false
}
```

**Request Parameters**:
- `platform` (required): Platform - `ios`, `android`, or `web`
- `lastKnownStatus` (optional): Last known subscription status on client
- `forceRefresh` (optional): Force refresh from payment platform (default: false)

**Success Response** (200 OK):
```json
{
  "code": 200,
  "message": "Subscription synced successfully",
  "data": {
    "id": 1,
    "userId": 12345,
    "tier": "pro",
    "billingPeriod": "monthly",
    "status": "active",
    "paymentMethod": "apple_iap",
    "startDate": "2024-12-01T00:00:00",
    "expiryDate": "2025-01-01T00:00:00",
    "autoRenew": true,
    "productId": "com.lightgallery.pro.monthly",
    "lastSyncedAt": "2024-12-07T10:00:00"
  }
}
```

**Error Response** (500 Internal Server Error):
```json
{
  "code": 500,
  "message": "Subscription sync failed: Network error",
  "data": null
}
```

---

#### 9. Calculate Upgrade

**Endpoint**: `POST /subscription/upgrade/calculate`

**Description**: Calculates prorated pricing for upgrading to a higher subscription tier.

**Authentication**: Required (Bearer token)

**Query Parameters**:
- `targetTier` (required): Target subscription tier - `pro` or `max`

**Example**: `POST /subscription/upgrade/calculate?targetTier=max`

**Success Response** (200 OK):
```json
{
  "code": 200,
  "message": "Upgrade calculation completed",
  "data": {
    "id": 1,
    "userId": 12345,
    "tier": "max",
    "billingPeriod": "monthly",
    "status": "pending",
    "paymentMethod": "apple_iap",
    "startDate": "2024-12-07T10:00:00",
    "expiryDate": "2025-01-07T10:00:00",
    "autoRenew": true,
    "productId": "com.lightgallery.max.monthly",
    "lastSyncedAt": "2024-12-07T10:00:00"
  }
}
```

**Error Response** (400 Bad Request):
```json
{
  "code": 400,
  "message": "Upgrade calculation failed: Cannot downgrade from max to pro",
  "data": null
}
```

---

#### 10. Cancel Subscription

**Endpoint**: `POST /subscription/cancel`

**Description**: Cancels the user's subscription. Access remains active until the current billing period ends.

**Authentication**: Required (Bearer token)

**Request Body**: None

**Success Response** (200 OK):
```json
{
  "code": 200,
  "message": "Subscription cancelled. Access will continue until 2025-01-07T10:00:00",
  "data": {
    "id": 1,
    "userId": 12345,
    "tier": "pro",
    "billingPeriod": "monthly",
    "status": "cancelled",
    "paymentMethod": "apple_iap",
    "startDate": "2024-12-07T10:00:00",
    "expiryDate": "2025-01-07T10:00:00",
    "autoRenew": false,
    "productId": "com.lightgallery.pro.monthly",
    "lastSyncedAt": "2024-12-07T10:00:00"
  }
}
```

**Error Response** (400 Bad Request):
```json
{
  "code": 400,
  "message": "Subscription cancellation failed: No active subscription",
  "data": null
}
```

**Note**: For iOS users, cancellation must be done through App Store settings. This endpoint marks the subscription as cancelled in the backend.

---

### Health Check Endpoint

#### 11. Health Check

**Endpoint**: `GET /health`

**Description**: Returns the health status of the service.

**Authentication**: None required

**Success Response** (200 OK):
```json
{
  "code": 200,
  "message": "Success",
  "data": {
    "status": "UP",
    "timestamp": "2024-12-07T10:00:00",
    "service": "lightgallery-backend"
  }
}
```

---

## Error Responses

All error responses follow a standard format:

```json
{
  "code": <http_status_code>,
  "message": "<error_message>",
  "data": null
}
```

### Common Error Codes

- **400 Bad Request**: Invalid request parameters or validation failure
- **401 Unauthorized**: Missing or invalid authentication token
- **403 Forbidden**: Insufficient permissions
- **404 Not Found**: Resource not found
- **500 Internal Server Error**: Server-side error

### Detailed Error Response Format

For validation errors and exceptions, the API may return additional error details:

```json
{
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed",
  "path": "/api/v1/auth/oauth/exchange",
  "timestamp": "2024-12-07T10:00:00",
  "errorCode": "VALIDATION_ERROR"
}
```

---

## Data Models

### AuthResponse

```typescript
{
  userId: number;
  displayName: string;
  email: string;
  avatarUrl: string;
  authProvider: "apple" | "wechat" | "alipay";
  accessToken: string;
  refreshToken: string;
  tokenType: "Bearer";
  expiresAt: string; // ISO 8601 datetime
  refreshExpiresAt: string; // ISO 8601 datetime
}
```

### SubscriptionDTO

```typescript
{
  id: number;
  userId: number;
  tier: "free" | "pro" | "max";
  billingPeriod: "monthly" | "yearly";
  status: "active" | "expired" | "cancelled" | "pending";
  paymentMethod: "apple_iap" | "wechat_pay" | "alipay";
  startDate: string; // ISO 8601 datetime
  expiryDate: string; // ISO 8601 datetime
  autoRenew: boolean;
  productId: string;
  lastSyncedAt: string; // ISO 8601 datetime
}
```

### SubscriptionProductDTO

```typescript
{
  productId: string;
  tier: "free" | "pro" | "max";
  billingPeriod: "monthly" | "yearly";
  price: number;
  currency: string;
  localizedPrice: string;
  description: string;
  features: string[];
}
```

---

## Subscription Tiers

### Free Tier
- **Price**: Free
- **Features**: Basic photo gallery functionality
- **Limitations**: No access to premium features

### Pro Tier
- **Monthly**: ¥10/month
- **Yearly**: ¥100/year (save 17%)
- **Features**: All premium features including:
  - Smart Clean
  - Duplicate Detection
  - Similar Photo Cleanup
  - Screenshot Cleanup
  - Photo Enhancer
  - Format Converter
  - Live Photo Converter
  - ID Photo Editor
  - Privacy Wiper
  - Screenshot Stitcher

### Max Tier
- **Monthly**: ¥20/month
- **Yearly**: ¥200/year (save 17%)
- **Features**: All Pro features plus:
  - Priority support
  - Early access to new features
  - Enhanced processing limits

---

## Payment Methods

### Apple In-App Purchase (iOS)
- Used exclusively for iOS platform
- Receipt verification via Apple servers
- Auto-renewal handled by Apple

### WeChat Pay (Android/Web)
- Available for Android and Web platforms
- Transaction verification via WeChat API

### Alipay (Android/Web)
- Available for Android and Web platforms
- Transaction verification via Alipay API

---

## Security

### HTTPS
All API communications must use HTTPS with TLS 1.2 or higher.

### JWT Tokens
- Access tokens expire after 7 days
- Refresh tokens expire after 30 days
- Tokens are signed using HS256 algorithm

### Token Storage
- Store tokens securely on the client (Keychain on iOS, Keystore on Android)
- Never log or expose tokens in client-side code

### Rate Limiting
API endpoints are rate-limited to prevent abuse:
- Authentication endpoints: 10 requests per minute
- Subscription endpoints: 30 requests per minute
- Health check: Unlimited

---

## Best Practices

### Offline Support
1. Cache subscription status locally for up to 24 hours
2. Use cached data when network is unavailable
3. Sync with backend when connectivity is restored
4. Use `/subscription/sync` endpoint for periodic updates

### Error Handling
1. Always check the `code` field in responses
2. Display user-friendly error messages from the `message` field
3. Implement retry logic with exponential backoff for network errors
4. Handle token expiration by refreshing tokens automatically

### Token Management
1. Store access and refresh tokens securely
2. Refresh access token before it expires
3. Clear all tokens on logout
4. Handle 401 errors by attempting token refresh

### Payment Verification
1. Always verify payments server-side before granting access
2. Handle payment verification failures gracefully
3. Provide clear feedback to users during payment processing
4. Log all payment transactions for audit purposes

---

## Testing

### Sandbox Environment
Use the development server for testing:
- Base URL: `http://localhost:8080/api/v1`
- Test OAuth credentials provided separately
- Apple IAP sandbox environment for testing subscriptions

### Example cURL Commands

**Exchange OAuth Token**:
```bash
curl -X POST http://localhost:8080/api/v1/auth/oauth/exchange \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "apple",
    "code": "test_auth_code",
    "email": "test@example.com",
    "displayName": "Test User"
  }'
```

**Get Subscription Status**:
```bash
curl -X GET http://localhost:8080/api/v1/subscription/status \
  -H "Authorization: Bearer <your_access_token>"
```

**Verify Payment**:
```bash
curl -X POST http://localhost:8080/api/v1/subscription/verify \
  -H "Authorization: Bearer <your_access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "paymentMethod": "apple_iap",
    "productId": "com.lightgallery.pro.monthly",
    "transactionId": "1000000123456789",
    "receiptData": "base64_encoded_receipt",
    "platform": "ios"
  }'
```

---

## Support

For API support and questions:
- Email: support@lightgallery.com
- Documentation: https://docs.lightgallery.com
- Status Page: https://status.lightgallery.com

---

## Changelog

### Version 1.0.0 (2024-12-07)
- Initial API release
- Authentication endpoints (OAuth exchange, token refresh, logout, account deletion)
- Subscription endpoints (products, status, verify, sync, upgrade, cancel)
- Health check endpoint
- OpenAPI/Swagger documentation
