package com.declutter.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Subscription Product DTO
 * Represents available subscription products
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SubscriptionProductDTO {

    /**
     * Product ID (e.g., "com.declutter.pro.monthly")
     */
    private String productId;

    /**
     * Subscription tier: free, pro, max
     */
    private String tier;

    /**
     * Billing period: monthly, yearly
     */
    private String billingPeriod;

    /**
     * Price in CNY
     */
    private BigDecimal price;

    /**
     * Currency code (default: CNY)
     */
    private String currency;

    /**
     * Localized price string (e.g., "¥10/月")
     */
    private String localizedPrice;

    /**
     * Product description
     */
    private String description;

    /**
     * Features included in this tier
     */
    private String[] features;
}
