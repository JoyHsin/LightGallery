# Database Implementation Summary

## Task 19: 实现数据库架构

**Status:** ✅ COMPLETED

## Overview

This document describes the implementation of the database schema for the LightGallery authentication and subscription system. The implementation includes MySQL database tables, MyBatis-Plus entities, and mapper interfaces with custom queries.

## What Was Implemented

### 19.1 MySQL Database Schema ✅

Created comprehensive database schema with four main tables:

#### 1. **users** Table
Stores user account information from OAuth providers.

**Columns:**
- `id` (BIGINT, PRIMARY KEY, AUTO_INCREMENT) - User ID
- `display_name` (VARCHAR(100)) - User display name
- `email` (VARCHAR(255)) - User email address
- `avatar_url` (VARCHAR(500)) - User avatar URL
- `auth_provider` (VARCHAR(20)) - OAuth provider (apple, wechat, alipay)
- `provider_user_id` (VARCHAR(255)) - User ID from OAuth provider
- `last_login_at` (DATETIME) - Last login timestamp
- `created_at` (DATETIME) - Creation timestamp
- `updated_at` (DATETIME) - Last update timestamp
- `deleted` (INT) - Logical delete flag

**Indexes:**
- `idx_email` - Email lookup
- `idx_provider_user` - Provider and provider user ID lookup
- `idx_created_at` - Creation date queries
- `idx_deleted` - Logical delete queries
- `uk_provider_user` - UNIQUE constraint on (auth_provider, provider_user_id, deleted)

#### 2. **auth_tokens** Table
Stores JWT tokens for session management.

**Columns:**
- `id` (BIGINT, PRIMARY KEY, AUTO_INCREMENT) - Token ID
- `user_id` (BIGINT, FOREIGN KEY) - User ID
- `access_token` (VARCHAR(1000)) - JWT access token
- `refresh_token` (VARCHAR(1000)) - JWT refresh token
- `token_type` (VARCHAR(20)) - Token type (Bearer)
- `expires_at` (DATETIME) - Access token expiration
- `refresh_expires_at` (DATETIME) - Refresh token expiration
- `device_info` (VARCHAR(500)) - Device information
- `ip_address` (VARCHAR(45)) - IP address
- `created_at` (DATETIME) - Creation timestamp
- `updated_at` (DATETIME) - Last update timestamp
- `deleted` (INT) - Logical delete flag

**Indexes:**
- `idx_user_id` - User lookup
- `idx_access_token` - Access token lookup
- `idx_refresh_token` - Refresh token lookup
- `idx_expires_at` - Expiration queries
- `idx_deleted` - Logical delete queries

**Foreign Keys:**
- `user_id` → `users(id)` ON DELETE CASCADE

#### 3. **subscriptions** Table
Stores user subscription information.

**Columns:**
- `id` (BIGINT, PRIMARY KEY, AUTO_INCREMENT) - Subscription ID
- `user_id` (BIGINT, FOREIGN KEY) - User ID
- `tier` (VARCHAR(20)) - Subscription tier (free, pro, max)
- `billing_period` (VARCHAR(20)) - Billing period (monthly, yearly)
- `status` (VARCHAR(20)) - Status (active, expired, cancelled, pending)
- `payment_method` (VARCHAR(20)) - Payment method (apple_iap, wechat_pay, alipay)
- `start_date` (DATETIME) - Subscription start date
- `expiry_date` (DATETIME) - Subscription expiry date
- `auto_renew` (TINYINT(1)) - Auto-renewal flag
- `product_id` (VARCHAR(100)) - Product ID from payment platform
- `original_transaction_id` (VARCHAR(255)) - Original transaction ID
- `last_synced_at` (DATETIME) - Last sync timestamp
- `created_at` (DATETIME) - Creation timestamp
- `updated_at` (DATETIME) - Last update timestamp
- `deleted` (INT) - Logical delete flag

**Indexes:**
- `idx_user_id` - User lookup
- `idx_tier` - Tier queries
- `idx_status` - Status queries
- `idx_expiry_date` - Expiration queries
- `idx_payment_method` - Payment method queries
- `idx_original_transaction_id` - Transaction tracking
- `idx_deleted` - Logical delete queries
- `uk_user_active` - UNIQUE constraint on (user_id, deleted) - one active subscription per user

**Foreign Keys:**
- `user_id` → `users(id)` ON DELETE CASCADE

#### 4. **transactions** Table
Audit log for all payment and subscription transactions.

**Columns:**
- `id` (BIGINT, PRIMARY KEY, AUTO_INCREMENT) - Transaction ID
- `user_id` (BIGINT, FOREIGN KEY) - User ID
- `subscription_id` (BIGINT, FOREIGN KEY) - Subscription ID
- `transaction_type` (VARCHAR(50)) - Transaction type (purchase, renewal, upgrade, cancellation, refund)
- `payment_method` (VARCHAR(20)) - Payment method
- `amount` (DECIMAL(10, 2)) - Transaction amount
- `currency` (VARCHAR(10)) - Currency code (CNY, USD)
- `platform_transaction_id` (VARCHAR(255)) - Transaction ID from payment platform
- `receipt_data` (TEXT) - Receipt or verification data
- `verification_status` (VARCHAR(20)) - Verification status (pending, verified, failed)
- `verification_message` (TEXT) - Verification result message
- `tier` (VARCHAR(20)) - Subscription tier at time of transaction
- `billing_period` (VARCHAR(20)) - Billing period at time of transaction
- `metadata` (JSON) - Additional transaction metadata
- `created_at` (DATETIME) - Transaction timestamp
- `updated_at` (DATETIME) - Last update timestamp
- `deleted` (INT) - Logical delete flag

**Indexes:**
- `idx_user_id` - User lookup
- `idx_subscription_id` - Subscription lookup
- `idx_transaction_type` - Transaction type queries
- `idx_payment_method` - Payment method queries
- `idx_platform_transaction_id` - Platform transaction lookup
- `idx_verification_status` - Verification status queries
- `idx_created_at` - Date queries
- `idx_deleted` - Logical delete queries

**Foreign Keys:**
- `user_id` → `users(id)` ON DELETE CASCADE
- `subscription_id` → `subscriptions(id)` ON DELETE SET NULL

### 19.2 MyBatis-Plus Entities ✅

Created four entity classes that map to database tables:

#### 1. **User.java**
```java
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("users")
public class User extends BaseEntity
```

**Fields:**
- All database columns mapped with `@TableField` annotations
- Extends `BaseEntity` for common fields (createdAt, updatedAt, deleted)
- Uses Lombok `@Data` for getters/setters
- Primary key with `@TableId(type = IdType.AUTO)`

#### 2. **AuthToken.java**
```java
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("auth_tokens")
public class AuthToken extends BaseEntity
```

**Fields:**
- JWT access and refresh tokens
- Expiration timestamps
- Device and IP information
- User ID foreign key

#### 3. **Subscription.java**
```java
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("subscriptions")
public class Subscription extends BaseEntity
```

**Fields:**
- Subscription tier and billing period
- Status and payment method
- Start and expiry dates
- Auto-renewal flag
- Product and transaction IDs
- Last sync timestamp

#### 4. **Transaction.java**
```java
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("transactions")
public class Transaction extends BaseEntity
```

**Fields:**
- Transaction type and payment method
- Amount and currency
- Platform transaction ID
- Receipt data
- Verification status and message
- Tier and billing period at time of transaction
- Metadata (JSON)

### 19.3 MyBatis-Plus Mappers ✅

Created four mapper interfaces with custom queries:

#### 1. **UserMapper.java**
Extends `BaseMapper<User>` with custom queries:

- `findByProviderAndProviderId()` - Find user by OAuth provider and provider user ID
- `findByEmail()` - Find user by email
- `updateLastLoginAt()` - Update last login timestamp
- `existsByProviderAndProviderId()` - Check if user exists
- `softDeleteById()` - Soft delete user

#### 2. **AuthTokenMapper.java**
Extends `BaseMapper<AuthToken>` with custom queries:

- `findByAccessToken()` - Find token by access token
- `findByRefreshToken()` - Find token by refresh token
- `findActiveTokensByUserId()` - Find all active tokens for user
- `findAllTokensByUserId()` - Find all tokens for user
- `deleteAllByUserId()` - Delete all tokens for user (logout)
- `deleteExpiredTokens()` - Cleanup expired tokens
- `isAccessTokenValid()` - Check if access token is valid
- `isRefreshTokenValid()` - Check if refresh token is valid

#### 3. **SubscriptionMapper.java**
Extends `BaseMapper<Subscription>` with custom queries:

- `findActiveByUserId()` - Find active subscription for user
- `findByUserIdAndStatus()` - Find subscription by user and status
- `findAllByUserId()` - Find all subscriptions for user
- `findByOriginalTransactionId()` - Find subscription by transaction ID
- `updateStatus()` - Update subscription status
- `updateExpiryDate()` - Update expiry date
- `updateTier()` - Update subscription tier
- `updateLastSyncedAt()` - Update last sync timestamp
- `findExpiredActiveSubscriptions()` - Find expired subscriptions
- `hasActiveSubscription()` - Check if user has active subscription
- `getUserTier()` - Get user's subscription tier
- `countByTier()` - Count subscriptions by tier

#### 4. **TransactionMapper.java**
Extends `BaseMapper<Transaction>` with custom queries:

- `findByPlatformTransactionId()` - Find transaction by platform ID
- `findAllByUserId()` - Find all transactions for user
- `findAllBySubscriptionId()` - Find transactions for subscription
- `findByVerificationStatus()` - Find transactions by verification status
- `findByUserIdAndType()` - Find transactions by user and type
- `findByUserIdAndDateRange()` - Find transactions in date range
- `updateVerificationStatus()` - Update verification status
- `existsByPlatformTransactionId()` - Check if transaction exists
- `countByPaymentMethod()` - Count transactions by payment method
- `countVerifiedByUserId()` - Count verified transactions for user
- `findPendingVerificationOlderThan()` - Find pending verifications for retry

## Database Setup

### Setup Script
Created `setup_database.sh` script that:
- Checks for MySQL installation
- Tests database connection
- Creates database if it doesn't exist
- Runs schema.sql to create tables
- Verifies table creation
- Shows table statistics

### Usage
```bash
cd backend
export DB_USERNAME=root
export DB_PASSWORD=your_password
./setup_database.sh
```

## Requirements Satisfied

✅ **Requirement 8.5**: Database schema implementation
- Created users table with indexes
- Created subscriptions table with foreign keys
- Created transactions table for audit logs
- Created auth_tokens table for session management

✅ **Requirement 10.4**: Data management
- Implemented logical delete for all tables
- Created audit log (transactions table)
- Proper foreign key relationships
- Indexes for performance

✅ **Requirement 8.1**: Backend service implementation
- MyBatis-Plus entities created
- Mapper interfaces with custom queries
- Proper annotations and configurations

## Technical Decisions

### Why Logical Delete?
- Preserves audit trail
- Allows data recovery
- Maintains referential integrity
- Configured in MyBatis-Plus with `@TableLogic`

### Why Separate auth_tokens Table?
- Supports multiple active sessions per user
- Allows device-specific token management
- Enables token revocation
- Tracks device and IP information

### Why JSON Metadata in Transactions?
- Flexible storage for platform-specific data
- Supports different payment platforms
- Allows future extensibility
- MySQL 5.7+ has native JSON support

### Index Strategy
- Primary keys on all tables
- Foreign key indexes for joins
- Composite indexes for common queries
- Unique constraints for data integrity

## File Structure

```
backend/
├── src/main/
│   ├── java/com/lightgallery/backend/
│   │   ├── entity/
│   │   │   ├── BaseEntity.java (existing)
│   │   │   ├── User.java ✅
│   │   │   ├── AuthToken.java ✅
│   │   │   ├── Subscription.java ✅
│   │   │   └── Transaction.java ✅
│   │   └── mapper/
│   │       ├── UserMapper.java ✅
│   │       ├── AuthTokenMapper.java ✅
│   │       ├── SubscriptionMapper.java ✅
│   │       └── TransactionMapper.java ✅
│   └── resources/
│       └── schema.sql ✅
├── setup_database.sh ✅
└── DATABASE_IMPLEMENTATION.md ✅ (this file)
```

## Testing the Implementation

### 1. Create Database
```bash
cd backend
./setup_database.sh
```

### 2. Verify Tables
```sql
USE lightgallery;
SHOW TABLES;
DESCRIBE users;
DESCRIBE auth_tokens;
DESCRIBE subscriptions;
DESCRIBE transactions;
```

### 3. Test Entities (requires Maven)
```bash
mvn test
```

### 4. Verify Mappers
The mappers will be tested in the next tasks when we implement the services.

## Next Steps

With the database schema and entities in place, the next tasks are:

1. **Task 20**: Implement authentication endpoints
   - AuthController
   - AuthService
   - OAuth provider integrations
   - Use UserMapper and AuthTokenMapper

2. **Task 21**: Implement subscription endpoints
   - SubscriptionController
   - SubscriptionService
   - Use SubscriptionMapper

3. **Task 22**: Implement payment verification
   - PaymentService
   - Receipt verification
   - Use TransactionMapper for audit logging

## Notes

- All tables use `utf8mb4` character set for full Unicode support (including emojis)
- Timestamps use `DATETIME` type with Asia/Shanghai timezone
- Logical delete is implemented with `deleted` column (0: active, 1: deleted)
- Foreign keys use `ON DELETE CASCADE` for users, `ON DELETE SET NULL` for subscriptions
- All mappers use `@Mapper` annotation for Spring Boot auto-detection
- Custom queries use MyBatis annotations (`@Select`, `@Update`, `@Delete`)

## Conclusion

Task 19 has been successfully completed with:
- ✅ MySQL database schema with 4 tables
- ✅ Comprehensive indexes and foreign keys
- ✅ 4 MyBatis-Plus entity classes
- ✅ 4 MyBatis-Plus mapper interfaces with custom queries
- ✅ Database setup script
- ✅ Complete documentation

The database layer is now ready for service implementation in the next tasks.
