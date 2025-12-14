# Database Schema Quick Reference

## Tables Overview

### 1. users
User accounts from OAuth providers (Apple, WeChat, Alipay)

**Key Fields:** id, display_name, email, auth_provider, provider_user_id

**Indexes:** email, provider+provider_user_id

### 2. auth_tokens
JWT tokens for session management

**Key Fields:** id, user_id, access_token, refresh_token, expires_at

**Indexes:** user_id, access_token, refresh_token, expires_at

### 3. subscriptions
User subscription information (Free, Pro, Max)

**Key Fields:** id, user_id, tier, status, expiry_date

**Indexes:** user_id, tier, status, expiry_date

**Constraint:** One active subscription per user

### 4. transactions
Audit log for all payment transactions

**Key Fields:** id, user_id, subscription_id, platform_transaction_id, verification_status

**Indexes:** user_id, subscription_id, platform_transaction_id, verification_status

## Quick Setup

```bash
# 1. Set environment variables
export DB_USERNAME=root
export DB_PASSWORD=your_password

# 2. Run setup script
cd backend
./setup_database.sh

# 3. Verify
mysql -u root -p lightgallery -e "SHOW TABLES;"
```

## Entity Classes

- `User.java` - User entity
- `AuthToken.java` - Auth token entity
- `Subscription.java` - Subscription entity
- `Transaction.java` - Transaction entity

All extend `BaseEntity` (createdAt, updatedAt, deleted)

## Mapper Interfaces

- `UserMapper.java` - User queries
- `AuthTokenMapper.java` - Token queries
- `SubscriptionMapper.java` - Subscription queries
- `TransactionMapper.java` - Transaction queries

All extend `BaseMapper<T>` with custom queries

## Common Queries

### Find User by OAuth Provider
```java
userMapper.findByProviderAndProviderId("apple", "user123");
```

### Get Active Subscription
```java
subscriptionMapper.findActiveByUserId(userId);
```

### Validate Access Token
```java
authTokenMapper.isAccessTokenValid(token);
```

### Log Transaction
```java
Transaction tx = new Transaction();
tx.setUserId(userId);
tx.setTransactionType("purchase");
// ... set other fields
transactionMapper.insert(tx);
```

## Database Configuration

Edit `application.yml`:
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/lightgallery
    username: ${DB_USERNAME:root}
    password: ${DB_PASSWORD:password}
```

## Notes

- All tables use logical delete (deleted = 0/1)
- UTF-8MB4 character encoding
- Timestamps in Asia/Shanghai timezone
- Foreign keys with CASCADE/SET NULL
- Comprehensive indexes for performance

For detailed documentation, see `DATABASE_IMPLEMENTATION.md`
