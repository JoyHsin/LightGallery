-- LightGallery Database Schema
-- User Authentication and Subscription System

-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS subscriptions;
DROP TABLE IF EXISTS auth_tokens;
DROP TABLE IF EXISTS users;

-- Users Table
-- Stores user account information from OAuth providers
CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '用户ID',
    display_name VARCHAR(100) NOT NULL COMMENT '用户显示名称',
    email VARCHAR(255) COMMENT '用户邮箱地址',
    avatar_url VARCHAR(500) COMMENT '用户头像URL',
    auth_provider VARCHAR(20) NOT NULL COMMENT 'OAuth提供商: apple, wechat, alipay',
    provider_user_id VARCHAR(255) NOT NULL COMMENT 'OAuth提供商的用户ID',
    last_login_at DATETIME COMMENT '最后登录时间',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后更新时间',
    deleted INT DEFAULT 0 COMMENT '逻辑删除标志 (0: 正常, 1: 已删除)',
    
    -- Indexes
    INDEX idx_email (email),
    INDEX idx_provider_user (auth_provider, provider_user_id),
    INDEX idx_created_at (created_at),
    INDEX idx_deleted (deleted),
    
    -- Unique constraint for provider + provider_user_id
    UNIQUE KEY uk_provider_user (auth_provider, provider_user_id, deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='User accounts';

-- Auth Tokens Table
-- Stores JWT tokens for session management
CREATE TABLE auth_tokens (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '令牌ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    access_token VARCHAR(1000) NOT NULL COMMENT 'JWT访问令牌',
    refresh_token VARCHAR(1000) NOT NULL COMMENT 'JWT刷新令牌',
    token_type VARCHAR(20) NOT NULL DEFAULT 'Bearer' COMMENT '令牌类型',
    expires_at DATETIME NOT NULL COMMENT '访问令牌过期时间',
    refresh_expires_at DATETIME NOT NULL COMMENT '刷新令牌过期时间',
    device_info VARCHAR(500) COMMENT '设备信息',
    ip_address VARCHAR(45) COMMENT 'IP地址',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后更新时间',
    deleted INT DEFAULT 0 COMMENT '逻辑删除标志 (0: 正常, 1: 已删除)',
    
    -- Foreign key
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    
    -- Indexes
    INDEX idx_user_id (user_id),
    INDEX idx_access_token (access_token(255)),
    INDEX idx_refresh_token (refresh_token(255)),
    INDEX idx_expires_at (expires_at),
    INDEX idx_deleted (deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Authentication tokens';

-- Subscriptions Table
-- Stores user subscription information
CREATE TABLE subscriptions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '订阅ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    tier VARCHAR(20) NOT NULL COMMENT '订阅层级: free, pro, max',
    billing_period VARCHAR(20) NOT NULL COMMENT '计费周期: monthly, yearly',
    status VARCHAR(20) NOT NULL COMMENT '状态: active, expired, cancelled, pending',
    payment_method VARCHAR(20) NOT NULL COMMENT '支付方式: apple_iap, wechat_pay, alipay',
    start_date DATETIME NOT NULL COMMENT '订阅开始日期',
    expiry_date DATETIME NOT NULL COMMENT '订阅到期日期',
    auto_renew TINYINT(1) NOT NULL DEFAULT 1 COMMENT '自动续订标志 (0: 关闭, 1: 开启)',
    product_id VARCHAR(100) COMMENT '支付平台的产品ID',
    original_transaction_id VARCHAR(255) COMMENT '原始交易ID用于追踪',
    last_synced_at DATETIME COMMENT '最后与后端同步时间',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后更新时间',
    deleted INT DEFAULT 0 COMMENT '逻辑删除标志 (0: 正常, 1: 已删除)',
    
    -- Foreign key
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    
    -- Indexes
    INDEX idx_user_id (user_id),
    INDEX idx_tier (tier),
    INDEX idx_status (status),
    INDEX idx_expiry_date (expiry_date),
    INDEX idx_payment_method (payment_method),
    INDEX idx_original_transaction_id (original_transaction_id),
    INDEX idx_deleted (deleted),
    
    -- Unique constraint: one active subscription per user
    UNIQUE KEY uk_user_active (user_id, deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='User subscriptions';

-- Transactions Table
-- Audit log for all payment and subscription transactions
CREATE TABLE transactions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '交易ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    subscription_id BIGINT COMMENT '订阅ID',
    transaction_type VARCHAR(50) NOT NULL COMMENT '交易类型: purchase, renewal, upgrade, cancellation, refund',
    payment_method VARCHAR(20) NOT NULL COMMENT '支付方式: apple_iap, wechat_pay, alipay',
    amount DECIMAL(10, 2) COMMENT '交易金额',
    currency VARCHAR(10) DEFAULT 'CNY' COMMENT '货币代码',
    platform_transaction_id VARCHAR(255) NOT NULL COMMENT '支付平台的交易ID',
    receipt_data TEXT COMMENT '收据或验证数据',
    verification_status VARCHAR(20) NOT NULL COMMENT '验证状态: pending, verified, failed',
    verification_message TEXT COMMENT '验证结果消息',
    tier VARCHAR(20) COMMENT '交易时的订阅层级',
    billing_period VARCHAR(20) COMMENT '交易时的计费周期',
    metadata JSON COMMENT '额外的交易元数据',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '交易时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后更新时间',
    deleted INT DEFAULT 0 COMMENT '逻辑删除标志 (0: 正常, 1: 已删除)',
    
    -- Foreign keys
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE SET NULL,
    
    -- Indexes
    INDEX idx_user_id (user_id),
    INDEX idx_subscription_id (subscription_id),
    INDEX idx_transaction_type (transaction_type),
    INDEX idx_payment_method (payment_method),
    INDEX idx_platform_transaction_id (platform_transaction_id),
    INDEX idx_verification_status (verification_status),
    INDEX idx_created_at (created_at),
    INDEX idx_deleted (deleted)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Transaction audit log';

-- Insert default free tier subscription for testing
-- This will be removed in production
INSERT INTO users (display_name, email, auth_provider, provider_user_id, last_login_at) 
VALUES ('Test User', 'test@example.com', 'apple', 'test_user_001', NOW());

INSERT INTO subscriptions (user_id, tier, billing_period, status, payment_method, start_date, expiry_date, auto_renew)
VALUES (1, 'free', 'monthly', 'active', 'apple_iap', NOW(), DATE_ADD(NOW(), INTERVAL 100 YEAR), 0);
