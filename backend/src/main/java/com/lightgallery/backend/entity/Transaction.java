package com.lightgallery.backend.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;

/**
 * Transaction Entity
 * Audit log for all payment and subscription transactions
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("transactions")
public class Transaction extends BaseEntity {

    /**
     * Transaction ID (Primary Key)
     */
    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * User ID (Foreign Key)
     */
    @TableField("user_id")
    private Long userId;

    /**
     * Subscription ID (Foreign Key, nullable)
     */
    @TableField("subscription_id")
    private Long subscriptionId;

    /**
     * Transaction type: purchase, renewal, upgrade, cancellation, refund
     */
    @TableField("transaction_type")
    private String transactionType;

    /**
     * Payment method: apple_iap, wechat_pay, alipay
     */
    @TableField("payment_method")
    private String paymentMethod;

    /**
     * Transaction amount
     */
    @TableField("amount")
    private BigDecimal amount;

    /**
     * Currency code (e.g., CNY, USD)
     */
    @TableField("currency")
    private String currency;

    /**
     * Transaction ID from payment platform
     */
    @TableField("platform_transaction_id")
    private String platformTransactionId;

    /**
     * Receipt or verification data
     */
    @TableField("receipt_data")
    private String receiptData;

    /**
     * Verification status: pending, verified, failed
     */
    @TableField("verification_status")
    private String verificationStatus;

    /**
     * Verification result message
     */
    @TableField("verification_message")
    private String verificationMessage;

    /**
     * Subscription tier at time of transaction
     */
    @TableField("tier")
    private String tier;

    /**
     * Billing period at time of transaction
     */
    @TableField("billing_period")
    private String billingPeriod;

    /**
     * Additional transaction metadata (JSON)
     */
    @TableField("metadata")
    private String metadata;
}
