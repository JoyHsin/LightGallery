package com.declutter.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Subscription DTO
 * Represents user subscription status
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SubscriptionDTO {

    /**
     * Subscription ID
     */
    private Long id;

    /**
     * User ID
     */
    private Long userId;

    /**
     * Subscription tier: free, pro, max
     */
    private String tier;

    /**
     * Billing period: monthly, yearly
     */
    private String billingPeriod;

    /**
     * Status: active, expired, cancelled, pending
     */
    private String status;

    /**
     * Payment method: apple_iap, wechat_pay, alipay
     */
    private String paymentMethod;

    /**
     * Subscription start date
     */
    private LocalDateTime startDate;

    /**
     * Subscription expiry date
     */
    private LocalDateTime expiryDate;

    /**
     * Auto-renewal flag
     */
    private Boolean autoRenew;

    /**
     * Product ID from payment platform
     */
    private String productId;

    /**
     * Last sync timestamp
     */
    private LocalDateTime lastSyncedAt;
}
