# Swagger/OpenAPI Documentation Guide

## Overview

The LightGallery Backend API includes interactive Swagger/OpenAPI documentation that allows you to explore and test all API endpoints directly from your browser.

## Accessing Swagger UI

### 1. Start the Backend Server

First, ensure the backend server is running:

```bash
cd backend
mvn spring-boot:run
```

Or if you've already built the project:

```bash
java -jar target/backend-1.0.0.jar
```

### 2. Open Swagger UI

Once the server is running, open your browser and navigate to:

**Swagger UI**: http://localhost:8080/swagger-ui.html

Alternative URL (redirects to the same page):
- http://localhost:8080/swagger-ui/index.html

### 3. Access OpenAPI JSON

The raw OpenAPI specification in JSON format is available at:

**OpenAPI JSON**: http://localhost:8080/v3/api-docs

**OpenAPI YAML**: http://localhost:8080/v3/api-docs.yaml

## Using Swagger UI

### Exploring Endpoints

1. **Browse by Tags**: Endpoints are organized into three main categories:
   - **Authentication**: User authentication and token management
   - **Subscription**: Subscription management and payment verification
   - **Health**: Service health check

2. **View Endpoint Details**: Click on any endpoint to see:
   - HTTP method and path
   - Description and summary
   - Request parameters and body schema
   - Response codes and examples
   - Authentication requirements

### Testing Endpoints

#### Testing Public Endpoints (No Authentication)

1. Click on an endpoint (e.g., `POST /auth/oauth/exchange`)
2. Click the "Try it out" button
3. Fill in the request parameters or body
4. Click "Execute"
5. View the response below

**Example: Get Subscription Products**
```
GET /subscription/products
```
No authentication required - just click "Try it out" and "Execute"

#### Testing Protected Endpoints (Requires Authentication)

Protected endpoints require a JWT token. Here's how to authenticate:

1. **Obtain a JWT Token**:
   - First, use the `POST /auth/oauth/exchange` endpoint to get a token
   - Copy the `accessToken` from the response

2. **Authorize in Swagger UI**:
   - Click the "Authorize" button at the top right (🔓 icon)
   - In the "bearerAuth" field, enter: `Bearer <your_access_token>`
   - Click "Authorize"
   - Click "Close"

3. **Test Protected Endpoints**:
   - Now you can test any protected endpoint (e.g., `GET /subscription/status`)
   - The Authorization header will be automatically included

**Example: Get Subscription Status**
```
GET /subscription/status
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Understanding Responses

Each endpoint shows:
- **Response Code**: HTTP status code (200, 400, 401, etc.)
- **Response Body**: JSON response with example data
- **Response Headers**: HTTP headers returned by the server

## API Endpoint Groups

### Authentication Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/auth/oauth/exchange` | Exchange OAuth token for JWT | No |
| POST | `/auth/token/refresh` | Refresh expired access token | No |
| POST | `/auth/logout` | Logout and invalidate tokens | Yes |
| DELETE | `/auth/account` | Delete user account | Yes |

### Subscription Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/subscription/products` | Get available subscription products | No |
| GET | `/subscription/status` | Get current subscription status | Yes |
| POST | `/subscription/verify` | Verify payment and update subscription | Yes |
| POST | `/subscription/sync` | Sync subscription with payment platform | Yes |
| POST | `/subscription/upgrade/calculate` | Calculate upgrade pricing | Yes |
| POST | `/subscription/cancel` | Cancel subscription | Yes |

### Health Check Endpoint

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/health` | Service health check | No |

## Common Testing Scenarios

### Scenario 1: Complete Authentication Flow

1. **Exchange OAuth Token**:
   ```
   POST /auth/oauth/exchange
   Body: {
     "provider": "apple",
     "code": "test_auth_code",
     "email": "test@example.com",
     "displayName": "Test User"
   }
   ```
   Copy the `accessToken` from the response.

2. **Authorize in Swagger**:
   - Click "Authorize" button
   - Enter: `Bearer <accessToken>`
   - Click "Authorize"

3. **Get Subscription Status**:
   ```
   GET /subscription/status
   ```
   Should return the user's current subscription.

4. **Logout**:
   ```
   POST /auth/logout
   ```
   Invalidates all tokens.

### Scenario 2: Subscription Purchase Flow

1. **Authenticate** (see Scenario 1)

2. **Get Available Products**:
   ```
   GET /subscription/products
   ```
   View all available subscription tiers and pricing.

3. **Verify Payment**:
   ```
   POST /subscription/verify
   Body: {
     "paymentMethod": "apple_iap",
     "productId": "com.lightgallery.pro.monthly",
     "transactionId": "1000000123456789",
     "receiptData": "base64_encoded_receipt",
     "platform": "ios"
   }
   ```
   Verifies payment and activates subscription.

4. **Check Updated Status**:
   ```
   GET /subscription/status
   ```
   Should show the newly activated subscription.

### Scenario 3: Token Refresh

1. **Wait for Token to Expire** (or use an expired token)

2. **Refresh Token**:
   ```
   POST /auth/token/refresh
   Body: {
     "refreshToken": "<your_refresh_token>"
   }
   ```
   Returns new access and refresh tokens.

3. **Update Authorization**:
   - Click "Authorize" button
   - Enter new token: `Bearer <new_accessToken>`
   - Click "Authorize"

## Customizing Swagger UI

### Changing Server URL

By default, Swagger UI uses `http://localhost:8080/api/v1`. To test against a different server:

1. In Swagger UI, look for the "Servers" dropdown at the top
2. Select "Production Server" to test against production
3. Or enter a custom server URL

### Saving Requests

Swagger UI doesn't save requests by default. To save your test data:
- Use browser bookmarks for specific endpoint URLs
- Export the OpenAPI spec and import into Postman
- Use the "Download" button to save the OpenAPI JSON

## Troubleshooting

### Issue: "Failed to fetch" Error

**Solution**: Ensure the backend server is running on port 8080.

```bash
# Check if server is running
curl http://localhost:8080/health

# If not running, start it
cd backend
mvn spring-boot:run
```

### Issue: 401 Unauthorized on Protected Endpoints

**Solution**: Make sure you've authorized with a valid JWT token:
1. Get a token from `/auth/oauth/exchange`
2. Click "Authorize" button in Swagger UI
3. Enter: `Bearer <your_token>`
4. Click "Authorize"

### Issue: CORS Errors

**Solution**: CORS is configured to allow requests from `http://localhost:3000` and `http://localhost:8080`. If testing from a different origin, update the CORS configuration in `CorsConfig.java`.

### Issue: Swagger UI Not Loading

**Solution**: 
1. Check that SpringDoc dependency is in `pom.xml`
2. Rebuild the project: `mvn clean install`
3. Restart the server
4. Clear browser cache and try again

## Exporting API Documentation

### Export as JSON

```bash
curl http://localhost:8080/v3/api-docs > openapi.json
```

### Export as YAML

```bash
curl http://localhost:8080/v3/api-docs.yaml > openapi.yaml
```

### Import into Postman

1. Open Postman
2. Click "Import"
3. Select "Link" tab
4. Enter: `http://localhost:8080/v3/api-docs`
5. Click "Continue" and "Import"

### Import into Insomnia

1. Open Insomnia
2. Click "Create" → "Import From" → "URL"
3. Enter: `http://localhost:8080/v3/api-docs`
4. Click "Fetch and Import"

## Additional Resources

- **Full API Documentation**: See `API_DOCUMENTATION.md` for detailed endpoint descriptions
- **OpenAPI Specification**: https://swagger.io/specification/
- **SpringDoc Documentation**: https://springdoc.org/

## Production Deployment

When deploying to production:

1. **Update Server URLs** in `OpenAPIConfig.java`:
   ```java
   new Server()
       .url("https://api.lightgallery.com/api/v1")
       .description("Production Server")
   ```

2. **Secure Swagger UI** (optional):
   - Add authentication to Swagger UI endpoints
   - Or disable Swagger UI in production by setting:
     ```yaml
     springdoc:
       swagger-ui:
         enabled: false
     ```

3. **Keep OpenAPI JSON Available**:
   - The `/v3/api-docs` endpoint should remain accessible for API clients
   - Consider adding API key authentication for this endpoint

## Support

For questions or issues with the API documentation:
- Check `API_DOCUMENTATION.md` for detailed endpoint information
- Review the OpenAPI specification at `/v3/api-docs`
- Contact: support@lightgallery.com
