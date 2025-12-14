package com.lightgallery.backend.service;

import net.jqwik.api.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Method;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Property-Based Tests for Log Sanitization
 * 
 * **Feature: user-auth-subscription, Property 38: Log Sanitization**
 * 
 * Tests that audit logs do not contain sensitive information such as:
 * - Full transaction IDs (should be masked)
 * - Passwords
 * - API keys
 * - Credit card numbers
 * - Long tokens
 * 
 * Validates Requirements: 10.5
 */
class LogSanitizationPropertyTests {

    private AuditLogService auditLogService;

    @BeforeEach
    void setUp() {
        auditLogService = new AuditLogService();
    }

    /**
     * **Feature: user-auth-subscription, Property 38: Log Sanitization**
     * 
     * Property: For any transaction ID, the sanitized version should mask sensitive parts
     * Validates: Requirements 10.5
     */
    @Property(tries = 100)
    void transactionIdShouldBeMasked(@ForAll("transactionIds") String transactionId) throws Exception {
        // Use reflection to access private sanitizeTransactionId method
        Method sanitizeMethod = AuditLogService.class.getDeclaredMethod("sanitizeTransactionId", String.class);
        sanitizeMethod.setAccessible(true);
        
        String sanitized = (String) sanitizeMethod.invoke(auditLogService, transactionId);
        
        // Verify sanitization occurred
        assertNotNull(sanitized, "Sanitized transaction ID should not be null");
        
        if (transactionId != null && !transactionId.isEmpty()) {
            // For IDs longer than 8 characters, verify masking
            if (transactionId.length() > 8) {
                assertTrue(sanitized.contains("****"), 
                        "Long transaction IDs should contain masking: " + sanitized);
                
                // Verify original ID is not fully exposed
                assertNotEquals(transactionId, sanitized, 
                        "Transaction ID should be masked, not exposed in full");
                
                // Verify first 4 and last 4 characters are preserved
                assertTrue(sanitized.startsWith(transactionId.substring(0, 4)),
                        "First 4 characters should be preserved");
                assertTrue(sanitized.endsWith(transactionId.substring(transactionId.length() - 4)),
                        "Last 4 characters should be preserved");
            }
        }
    }

    /**
     * **Feature: user-auth-subscription, Property 38: Log Sanitization**
     * 
     * Property: For any error message containing passwords, the password should be redacted
     * Validates: Requirements 10.5
     */
    @Property(tries = 100)
    void passwordsShouldBeRedacted(@ForAll("errorMessagesWithPasswords") String errorMessage) throws Exception {
        // Use reflection to access private sanitizeErrorMessage method
        Method sanitizeMethod = AuditLogService.class.getDeclaredMethod("sanitizeErrorMessage", String.class);
        sanitizeMethod.setAccessible(true);
        
        String sanitized = (String) sanitizeMethod.invoke(auditLogService, errorMessage);
        
        // Verify password is redacted
        assertNotNull(sanitized, "Sanitized message should not be null");
        
        if (errorMessage != null && !errorMessage.isEmpty()) {
            // Check that actual password values are not present
            assertFalse(sanitized.matches(".*password=(?!\\[REDACTED\\])[^&\\s]+.*"),
                    "Password values should be redacted: " + sanitized);
            assertFalse(sanitized.matches(".*pwd=(?!\\[REDACTED\\])[^&\\s]+.*"),
                    "Password values should be redacted: " + sanitized);
        }
    }

    /**
     * **Feature: user-auth-subscription, Property 38: Log Sanitization**
     * 
     * Property: For any error message containing API keys, the key should be redacted
     * Validates: Requirements 10.5
     */
    @Property(tries = 100)
    void apiKeysShouldBeRedacted(@ForAll("errorMessagesWithApiKeys") String errorMessage) throws Exception {
        // Use reflection to access private sanitizeErrorMessage method
        Method sanitizeMethod = AuditLogService.class.getDeclaredMethod("sanitizeErrorMessage", String.class);
        sanitizeMethod.setAccessible(true);
        
        String sanitized = (String) sanitizeMethod.invoke(auditLogService, errorMessage);
        
        // Verify API key is redacted
        assertNotNull(sanitized, "Sanitized message should not be null");
        
        if (errorMessage != null && !errorMessage.isEmpty()) {
            // Check that actual API key values are not present
            assertFalse(sanitized.matches(".*(?i)(key|apikey|api_key)=(?!\\[REDACTED\\])[^&\\s]+.*"),
                    "API key values should be redacted: " + sanitized);
        }
    }

    /**
     * **Feature: user-auth-subscription, Property 38: Log Sanitization**
     * 
     * Property: For any error message containing credit card numbers, they should be redacted
     * Validates: Requirements 10.5
     */
    @Property(tries = 100)
    void creditCardNumbersShouldBeRedacted(@ForAll("errorMessagesWithCreditCards") String errorMessage) throws Exception {
        // Use reflection to access private sanitizeErrorMessage method
        Method sanitizeMethod = AuditLogService.class.getDeclaredMethod("sanitizeErrorMessage", String.class);
        sanitizeMethod.setAccessible(true);
        
        String sanitized = (String) sanitizeMethod.invoke(auditLogService, errorMessage);
        
        // Verify credit card number is redacted
        assertNotNull(sanitized, "Sanitized message should not be null");
        
        if (errorMessage != null && !errorMessage.isEmpty()) {
            // Check that credit card patterns are not present (13-19 consecutive digits)
            assertFalse(sanitized.matches(".*\\b\\d{13,19}\\b.*"),
                    "Credit card numbers should be redacted: " + sanitized);
        }
    }

    /**
     * **Feature: user-auth-subscription, Property 38: Log Sanitization**
     * 
     * Property: For any error message containing long tokens, they should be redacted
     * Validates: Requirements 10.5
     */
    @Property(tries = 100)
    void longTokensShouldBeRedacted(@ForAll("errorMessagesWithTokens") String errorMessage) throws Exception {
        // Use reflection to access private sanitizeErrorMessage method
        Method sanitizeMethod = AuditLogService.class.getDeclaredMethod("sanitizeErrorMessage", String.class);
        sanitizeMethod.setAccessible(true);
        
        String sanitized = (String) sanitizeMethod.invoke(auditLogService, errorMessage);
        
        // Verify long tokens are redacted
        assertNotNull(sanitized, "Sanitized message should not be null");
        
        if (errorMessage != null && !errorMessage.isEmpty()) {
            // Check that long alphanumeric strings (32+ chars) are not present
            assertFalse(sanitized.matches(".*\\b[A-Za-z0-9]{32,}\\b.*"),
                    "Long tokens should be redacted: " + sanitized);
        }
    }

    /**
     * **Feature: user-auth-subscription, Property 38: Log Sanitization**
     * 
     * Property: For any error message, the sanitized version should not exceed 500 characters
     * Validates: Requirements 10.5
     */
    @Property(tries = 100)
    void errorMessagesShouldBeTruncated(@ForAll("longErrorMessages") String errorMessage) throws Exception {
        // Use reflection to access private sanitizeErrorMessage method
        Method sanitizeMethod = AuditLogService.class.getDeclaredMethod("sanitizeErrorMessage", String.class);
        sanitizeMethod.setAccessible(true);
        
        String sanitized = (String) sanitizeMethod.invoke(auditLogService, errorMessage);
        
        // Verify message length is limited
        assertNotNull(sanitized, "Sanitized message should not be null");
        assertTrue(sanitized.length() <= 500, 
                "Sanitized message should not exceed 500 characters, got: " + sanitized.length());
    }

    // ========== Generators ==========

    @Provide
    Arbitrary<String> transactionIds() {
        return Arbitraries.oneOf(
                // Short IDs
                Arbitraries.strings().alpha().ofMinLength(4).ofMaxLength(8),
                // Medium IDs
                Arbitraries.strings().withChars("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").ofMinLength(9).ofMaxLength(20),
                // Long IDs (typical transaction IDs)
                Arbitraries.strings().withChars("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").ofMinLength(21).ofMaxLength(64),
                // Null and empty
                Arbitraries.just(null),
                Arbitraries.just("")
        );
    }

    @Provide
    Arbitrary<String> errorMessagesWithPasswords() {
        return Arbitraries.oneOf(
                // password= format
                Arbitraries.strings().alpha().ofMinLength(8).ofMaxLength(20)
                        .map(pwd -> "Authentication failed: password=" + pwd),
                // pwd= format
                Arbitraries.strings().alpha().ofMinLength(8).ofMaxLength(20)
                        .map(pwd -> "Login error: pwd=" + pwd + "&user=test"),
                // PASSWORD= format (case insensitive)
                Arbitraries.strings().alpha().ofMinLength(8).ofMaxLength(20)
                        .map(pwd -> "Error: PASSWORD=" + pwd),
                // Multiple passwords
                Arbitraries.strings().alpha().ofMinLength(8).ofMaxLength(20)
                        .map(pwd -> "password=" + pwd + " and pwd=" + pwd + "123"),
                // Null and empty
                Arbitraries.just(null),
                Arbitraries.just("")
        );
    }

    @Provide
    Arbitrary<String> errorMessagesWithApiKeys() {
        return Arbitraries.oneOf(
                // key= format
                Arbitraries.strings().withChars("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").ofMinLength(20).ofMaxLength(40)
                        .map(key -> "API error: key=" + key),
                // apikey= format
                Arbitraries.strings().withChars("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").ofMinLength(20).ofMaxLength(40)
                        .map(key -> "Authentication failed: apikey=" + key),
                // api_key= format
                Arbitraries.strings().withChars("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").ofMinLength(20).ofMaxLength(40)
                        .map(key -> "Error: api_key=" + key + "&user=test"),
                // APIKEY= format (case insensitive)
                Arbitraries.strings().withChars("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").ofMinLength(20).ofMaxLength(40)
                        .map(key -> "Failed: APIKEY=" + key),
                // Null and empty
                Arbitraries.just(null),
                Arbitraries.just("")
        );
    }

    @Provide
    Arbitrary<String> errorMessagesWithCreditCards() {
        return Arbitraries.oneOf(
                // 16-digit card (most common)
                Arbitraries.strings().numeric().ofLength(16)
                        .map(card -> "Payment failed for card: " + card),
                // 15-digit card (Amex)
                Arbitraries.strings().numeric().ofLength(15)
                        .map(card -> "Transaction error: " + card),
                // 13-digit card
                Arbitraries.strings().numeric().ofLength(13)
                        .map(card -> "Card " + card + " declined"),
                // 19-digit card
                Arbitraries.strings().numeric().ofLength(19)
                        .map(card -> "Invalid card number: " + card),
                // Multiple cards
                Arbitraries.strings().numeric().ofLength(16)
                        .map(card -> "Cards: " + card + " and " + card.substring(0, 15) + "0"),
                // Null and empty
                Arbitraries.just(null),
                Arbitraries.just("")
        );
    }

    @Provide
    Arbitrary<String> errorMessagesWithTokens() {
        return Arbitraries.oneOf(
                // 32-character token (minimum for redaction)
                Arbitraries.strings().withChars("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").ofLength(32)
                        .map(token -> "Token validation failed: " + token),
                // 64-character token (common JWT size)
                Arbitraries.strings().withChars("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").ofLength(64)
                        .map(token -> "Invalid token: " + token),
                // 128-character token
                Arbitraries.strings().withChars("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").ofLength(128)
                        .map(token -> "Auth error with token " + token),
                // Multiple tokens
                Arbitraries.strings().withChars("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").ofLength(40)
                        .map(token -> "Tokens: " + token + " and " + token + "abc"),
                // Null and empty
                Arbitraries.just(null),
                Arbitraries.just("")
        );
    }

    @Provide
    Arbitrary<String> longErrorMessages() {
        return Arbitraries.oneOf(
                // Exactly 500 characters
                Arbitraries.strings().alpha().ofLength(500),
                // 501 characters (should be truncated)
                Arbitraries.strings().alpha().ofLength(501),
                // Very long (1000 characters)
                Arbitraries.strings().alpha().ofLength(1000),
                // Extremely long (5000 characters)
                Arbitraries.strings().alpha().ofLength(5000),
                // Short messages (should not be truncated)
                Arbitraries.strings().alpha().ofMinLength(10).ofMaxLength(100),
                // Null and empty
                Arbitraries.just(null),
                Arbitraries.just("")
        );
    }

    // ========== Unit Tests for Edge Cases ==========

    @Test
    void nullTransactionIdShouldReturnNA() throws Exception {
        Method sanitizeMethod = AuditLogService.class.getDeclaredMethod("sanitizeTransactionId", String.class);
        sanitizeMethod.setAccessible(true);
        
        String sanitized = (String) sanitizeMethod.invoke(auditLogService, (String) null);
        assertEquals("N/A", sanitized, "Null transaction ID should return N/A");
    }

    @Test
    void emptyTransactionIdShouldReturnNA() throws Exception {
        Method sanitizeMethod = AuditLogService.class.getDeclaredMethod("sanitizeTransactionId", String.class);
        sanitizeMethod.setAccessible(true);
        
        String sanitized = (String) sanitizeMethod.invoke(auditLogService, "");
        assertEquals("N/A", sanitized, "Empty transaction ID should return N/A");
    }

    @Test
    void nullErrorMessageShouldReturnNA() throws Exception {
        Method sanitizeMethod = AuditLogService.class.getDeclaredMethod("sanitizeErrorMessage", String.class);
        sanitizeMethod.setAccessible(true);
        
        String sanitized = (String) sanitizeMethod.invoke(auditLogService, (String) null);
        assertEquals("N/A", sanitized, "Null error message should return N/A");
    }

    @Test
    void emptyErrorMessageShouldReturnNA() throws Exception {
        Method sanitizeMethod = AuditLogService.class.getDeclaredMethod("sanitizeErrorMessage", String.class);
        sanitizeMethod.setAccessible(true);
        
        String sanitized = (String) sanitizeMethod.invoke(auditLogService, "");
        assertEquals("N/A", sanitized, "Empty error message should return N/A");
    }
}
