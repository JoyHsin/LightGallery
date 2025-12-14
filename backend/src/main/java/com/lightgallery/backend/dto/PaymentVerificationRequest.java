package com.lightgallery.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Payment Verification Request
 * Used to verify payment and update subscription
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PaymentVerificationRequest {

    /**
     * Payment method: apple_iap, wechat_pay, alipay
     */
    @NotBlank(message = "Payment method is required")
    private String paymentMethod;

    /**
     * Product ID being purchased
     */
    @NotBlank(message = "Product ID is required")
    private String productId;

    /**
     * Transaction ID from payment platform
     */
    @NotBlank(message = "Transaction ID is required")
    private String transactionId;

    /**
     * Receipt data (for Apple IAP, base64 encoded)
     */
    private String receiptData;

    /**
     * Original transaction ID (for Apple IAP renewals)
     */
    private String originalTransactionId;

    /**
     * Platform: ios, android, web
     */
    @NotBlank(message = "Platform is required")
    private String platform;
}
