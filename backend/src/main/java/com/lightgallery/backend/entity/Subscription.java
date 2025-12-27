package com.declutter.backend.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * Subscription Entity
 * Stores user subscription information
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("subscriptions")
public class Subscription extends BaseEntity {

    /**
     * Subscription ID (Primary Key)
     */
    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * User ID (Foreign Key)
     */
    @TableField("user_id")
    private Long userId;

    /**
     * Subscription tier: free, pro, max
     */
    @TableField("tier")
    private String tier;

    /**
     * Billing period: monthly, yearly
     */
    @TableField("billing_period")
    private String billingPeriod;

    /**
     * Status: active, expired, cancelled, pending
     */
    @TableField("status")
    private String status;

    /**
     * Payment method: apple_iap, wechat_pay, alipay
     */
    @TableField("payment_method")
    private String paymentMethod;

    /**
     * Subscription start date
     */
    @TableField("start_date")
    private LocalDateTime startDate;

    /**
     * Subscription expiry date
     */
    @TableField("expiry_date")
    private LocalDateTime expiryDate;

    /**
     * Auto-renewal flag (false: disabled, true: enabled)
     */
    @TableField("auto_renew")
    private Boolean autoRenew;

    /**
     * Product ID from payment platform
     */
    @TableField("product_id")
    private String productId;

    /**
     * Original transaction ID for tracking
     */
    @TableField("original_transaction_id")
    private String originalTransactionId;

    /**
     * Last sync timestamp with backend
     */
    @TableField("last_synced_at")
    private LocalDateTime lastSyncedAt;
}
