package com.declutter.backend.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Audit Log Service
 * Records subscription updates and payment verifications with sanitized data
 * Requirements: 8.5, 10.5
 */
@Slf4j
@Service
public class AuditLogService {

    /**
     * Log subscription update
     * Requirements: 8.5
     * 
     * @param userId User ID
     * @param subscriptionId Subscription ID
     * @param tier Subscription tier
     * @param status Subscription status
     * @param paymentMethod Payment method
     * @param transactionId Transaction ID (sanitized)
     */
    public void logSubscriptionUpdate(Long userId, Long subscriptionId, String tier, 
                                     String status, String paymentMethod, String transactionId) {
        Map<String, Object> auditData = new HashMap<>();
        auditData.put("timestamp", LocalDateTime.now());
        auditData.put("eventType", "SUBSCRIPTION_UPDATE");
        auditData.put("userId", userId);
        auditData.put("subscriptionId", subscriptionId);
        auditData.put("tier", tier);
        auditData.put("status", status);
        auditData.put("paymentMethod", paymentMethod);
        auditData.put("transactionId", sanitizeTransactionId(transactionId));
        
        log.info("AUDIT: Subscription update - userId={}, subscriptionId={}, tier={}, status={}, paymentMethod={}, transactionId={}", 
                userId, subscriptionId, tier, status, paymentMethod, sanitizeTransactionId(transactionId));
    }

    /**
     * Log payment verification
     * Requirements: 8.5
     * 
     * @param userId User ID
     * @param paymentMethod Payment method
     * @param transactionId Transaction ID (sanitized)
     * @param amount Payment amount
     * @param currency Currency
     * @param verificationResult Verification result (success/failure)
     */
    public void logPaymentVerification(Long userId, String paymentMethod, String transactionId, 
                                      Double amount, String currency, boolean verificationResult) {
        Map<String, Object> auditData = new HashMap<>();
        auditData.put("timestamp", LocalDateTime.now());
        auditData.put("eventType", "PAYMENT_VERIFICATION");
        auditData.put("userId", userId);
        auditData.put("paymentMethod", paymentMethod);
        auditData.put("transactionId", sanitizeTransactionId(transactionId));
        auditData.put("amount", amount);
        auditData.put("currency", currency);
        auditData.put("verificationResult", verificationResult ? "SUCCESS" : "FAILURE");
        
        log.info("AUDIT: Payment verification - userId={}, paymentMethod={}, transactionId={}, amount={}, currency={}, result={}", 
                userId, paymentMethod, sanitizeTransactionId(transactionId), amount, currency, 
                verificationResult ? "SUCCESS" : "FAILURE");
    }

    /**
     * Log payment verification failure
     * Requirements: 8.5
     * 
     * @param userId User ID
     * @param paymentMethod Payment method
     * @param transactionId Transaction ID (sanitized)
     * @param errorReason Error reason (sanitized)
     */
    public void logPaymentVerificationFailure(Long userId, String paymentMethod, 
                                             String transactionId, String errorReason) {
        Map<String, Object> auditData = new HashMap<>();
        auditData.put("timestamp", LocalDateTime.now());
        auditData.put("eventType", "PAYMENT_VERIFICATION_FAILURE");
        auditData.put("userId", userId);
        auditData.put("paymentMethod", paymentMethod);
        auditData.put("transactionId", sanitizeTransactionId(transactionId));
        auditData.put("errorReason", sanitizeErrorMessage(errorReason));
        
        log.warn("AUDIT: Payment verification failure - userId={}, paymentMethod={}, transactionId={}, errorReason={}", 
                userId, paymentMethod, sanitizeTransactionId(transactionId), sanitizeErrorMessage(errorReason));
    }

    /**
     * Log subscription cancellation
     * Requirements: 8.5
     * 
     * @param userId User ID
     * @param subscriptionId Subscription ID
     * @param tier Subscription tier
     * @param reason Cancellation reason
     */
    public void logSubscriptionCancellation(Long userId, Long subscriptionId, String tier, String reason) {
        Map<String, Object> auditData = new HashMap<>();
        auditData.put("timestamp", LocalDateTime.now());
        auditData.put("eventType", "SUBSCRIPTION_CANCELLATION");
        auditData.put("userId", userId);
        auditData.put("subscriptionId", subscriptionId);
        auditData.put("tier", tier);
        auditData.put("reason", sanitizeErrorMessage(reason));
        
        log.info("AUDIT: Subscription cancellation - userId={}, subscriptionId={}, tier={}, reason={}", 
                userId, subscriptionId, tier, sanitizeErrorMessage(reason));
    }

    /**
     * Log subscription renewal
     * Requirements: 8.5
     * 
     * @param userId User ID
     * @param subscriptionId Subscription ID
     * @param tier Subscription tier
     * @param transactionId Transaction ID (sanitized)
     */
    public void logSubscriptionRenewal(Long userId, Long subscriptionId, String tier, String transactionId) {
        Map<String, Object> auditData = new HashMap<>();
        auditData.put("timestamp", LocalDateTime.now());
        auditData.put("eventType", "SUBSCRIPTION_RENEWAL");
        auditData.put("userId", userId);
        auditData.put("subscriptionId", subscriptionId);
        auditData.put("tier", tier);
        auditData.put("transactionId", sanitizeTransactionId(transactionId));
        
        log.info("AUDIT: Subscription renewal - userId={}, subscriptionId={}, tier={}, transactionId={}", 
                userId, subscriptionId, tier, sanitizeTransactionId(transactionId));
    }

    /**
     * Sanitize transaction ID to mask sensitive information
     * Requirements: 10.5
     * 
     * Shows only first 4 and last 4 characters, masks the middle
     * Example: "1234567890abcdef" -> "1234****cdef"
     */
    private String sanitizeTransactionId(String transactionId) {
        if (transactionId == null || transactionId.isEmpty()) {
            return "N/A";
        }
        
        if (transactionId.length() <= 8) {
            // For short IDs, mask everything except first 2 chars
            return transactionId.substring(0, Math.min(2, transactionId.length())) + "****";
        }
        
        // For longer IDs, show first 4 and last 4, mask the middle
        String prefix = transactionId.substring(0, 4);
        String suffix = transactionId.substring(transactionId.length() - 4);
        return prefix + "****" + suffix;
    }

    /**
     * Sanitize error messages to remove sensitive information
     * Requirements: 10.5
     * 
     * Removes potential tokens, passwords, credit card numbers, etc.
     */
    private String sanitizeErrorMessage(String message) {
        if (message == null || message.isEmpty()) {
            return "N/A";
        }
        
        // Remove potential tokens (long alphanumeric strings)
        String sanitized = message.replaceAll("\\b[A-Za-z0-9]{32,}\\b", "[TOKEN_REDACTED]");
        
        // Remove potential credit card numbers (sequences of 13-19 digits)
        sanitized = sanitized.replaceAll("\\b\\d{13,19}\\b", "[CARD_REDACTED]");
        
        // Remove potential passwords (after "password=" or "pwd=")
        sanitized = sanitized.replaceAll("(?i)(password|pwd)=[^&\\s]+", "$1=[REDACTED]");
        
        // Remove potential API keys (after "key=" or "apikey=")
        sanitized = sanitized.replaceAll("(?i)(key|apikey|api_key)=[^&\\s]+", "$1=[REDACTED]");
        
        // Limit message length to prevent log flooding
        if (sanitized.length() > 500) {
            sanitized = sanitized.substring(0, 497) + "...";
        }
        
        return sanitized;
    }

    /**
     * Log authentication event
     * Requirements: 10.5
     * 
     * @param userId User ID
     * @param provider OAuth provider
     * @param success Authentication success/failure
     */
    public void logAuthenticationEvent(Long userId, String provider, boolean success) {
        Map<String, Object> auditData = new HashMap<>();
        auditData.put("timestamp", LocalDateTime.now());
        auditData.put("eventType", "AUTHENTICATION");
        auditData.put("userId", userId);
        auditData.put("provider", provider);
        auditData.put("result", success ? "SUCCESS" : "FAILURE");
        
        log.info("AUDIT: Authentication - userId={}, provider={}, result={}", 
                userId, provider, success ? "SUCCESS" : "FAILURE");
    }

    /**
     * Log account deletion
     * Requirements: 10.5
     * 
     * @param userId User ID
     * @param reason Deletion reason
     */
    public void logAccountDeletion(Long userId, String reason) {
        Map<String, Object> auditData = new HashMap<>();
        auditData.put("timestamp", LocalDateTime.now());
        auditData.put("eventType", "ACCOUNT_DELETION");
        auditData.put("userId", userId);
        auditData.put("reason", sanitizeErrorMessage(reason));
        
        log.info("AUDIT: Account deletion - userId={}, reason={}", 
                userId, sanitizeErrorMessage(reason));
    }
}
