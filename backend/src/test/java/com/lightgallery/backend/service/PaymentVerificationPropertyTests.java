package com.declutter.backend.service;

import com.declutter.backend.dto.PaymentVerificationRequest;
import com.declutter.backend.dto.SubscriptionDTO;
import com.declutter.backend.entity.Subscription;
import com.declutter.backend.entity.Transaction;
import com.declutter.backend.entity.User;
import com.declutter.backend.mapper.SubscriptionMapper;
import com.declutter.backend.mapper.TransactionMapper;
import com.declutter.backend.mapper.UserMapper;
import net.jqwik.api.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Base64;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Property-Based Tests for Payment Verification
 * 
 * Tests the following properties:
 * - Property 26: Payment Verification Routing
 * - Property 27: Failed Verification Rejection
 * - Property 28: Audit Logging
 * 
 * Validates Requirements: 8.1, 8.2, 8.3, 8.4, 8.5
 */
@ExtendWith(MockitoExtension.class)
class PaymentVerificationPropertyTests {

    @Mock
    private SubscriptionMapper subscriptionMapper;

    @Mock
    private TransactionMapper transactionMapper;

    @Mock
    private UserMapper userMapper;

    @Mock
    private PaymentService paymentService;

    @InjectMocks
    private SubscriptionService subscriptionService;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setId(1L);
        testUser.setAuthProvider("apple");
        testUser.setProviderUserId("apple-user-123");
        testUser.setEmail("test@example.com");
        testUser.setDisplayName("Test User");
        testUser.setCreatedAt(LocalDateTime.now());
        testUser.setUpdatedAt(LocalDateTime.now());
    }

    /**
     * **Feature: user-auth-subscription, Property 26: Payment Verification Routing**
     * **Validates: Requirements 8.1, 8.2, 8.3**
     * 
     * For any subscription update request, the system should verify the payment 
     * using the correct verification API (Apple for IAP, WeChat/Alipay for their respective payments).
     */
    @Property(tries = 100)
    void property26_paymentVerificationRouting(
            @ForAll("paymentMethods") String paymentMethod,
            @ForAll("productIds") String productId,
            @ForAll("transactionIds") String transactionId,
            @ForAll("platforms") String platform) {
        
        // Given: A payment verification request with any payment method
        PaymentVerificationRequest request = PaymentVerificationRequest.builder()
                .paymentMethod(paymentMethod)
                .productId(productId)
                .transactionId(transactionId)
                .receiptData(generateReceiptData(paymentMethod))
                .platform(platform)
                .build();

        // Setup mocks
        when(userMapper.selectById(1L)).thenReturn(testUser);
        when(transactionMapper.selectOne(any())).thenReturn(null);
        when(subscriptionMapper.findActiveByUserId(1L)).thenReturn(null);
        when(subscriptionMapper.insert(any(Subscription.class))).thenAnswer(invocation -> {
            Subscription sub = invocation.getArgument(0);
            sub.setId(1L);
            return 1;
        });
        when(transactionMapper.insert(any(Transaction.class))).thenReturn(1);
        
        // Mock payment verification to succeed
        when(paymentService.verifyPayment(any(PaymentVerificationRequest.class))).thenReturn(true);

        // When: Verifying and updating subscription
        SubscriptionDTO result = subscriptionService.verifyAndUpdateSubscription(1L, request);

        // Then: Payment service should be called with the request
        verify(paymentService, times(1)).verifyPayment(argThat(req -> 
                req.getPaymentMethod().equals(paymentMethod) &&
                req.getTransactionId().equals(transactionId)
        ));

        // And: Subscription should be created/updated
        assertNotNull(result);
        assertEquals("active", result.getStatus());
    }

    /**
     * **Feature: user-auth-subscription, Property 27: Failed Verification Rejection**
     * **Validates: Requirements 8.4**
     * 
     * For any failed payment verification, the system should reject the subscription update 
     * and not modify the user's subscription status.
     */
    @Property(tries = 100)
    void property27_failedVerificationRejection(
            @ForAll("paymentMethods") String paymentMethod,
            @ForAll("productIds") String productId,
            @ForAll("transactionIds") String transactionId,
            @ForAll("platforms") String platform) {
        
        // Given: A payment verification request
        PaymentVerificationRequest request = PaymentVerificationRequest.builder()
                .paymentMethod(paymentMethod)
                .productId(productId)
                .transactionId(transactionId)
                .receiptData(generateReceiptData(paymentMethod))
                .platform(platform)
                .build();

        // Setup mocks
        when(userMapper.selectById(1L)).thenReturn(testUser);
        when(transactionMapper.selectOne(any())).thenReturn(null);
        
        // Mock payment verification to fail
        when(paymentService.verifyPayment(any(PaymentVerificationRequest.class))).thenReturn(false);
        when(transactionMapper.insert(any(Transaction.class))).thenReturn(1);

        // When & Then: Verification should throw exception
        RuntimeException exception = assertThrows(RuntimeException.class, () -> {
            subscriptionService.verifyAndUpdateSubscription(1L, request);
        });

        assertEquals("Payment verification failed", exception.getMessage());

        // And: Subscription should NOT be created or updated
        verify(subscriptionMapper, never()).insert(any(Subscription.class));
        verify(subscriptionMapper, never()).updateById(any(Subscription.class));

        // And: Failed transaction should be recorded
        verify(transactionMapper, times(1)).insert(argThat(txn -> 
                "failed".equals(txn.getVerificationStatus()) &&
                transactionId.equals(txn.getPlatformTransactionId())
        ));
    }

    /**
     * **Feature: user-auth-subscription, Property 28: Audit Logging**
     * **Validates: Requirements 8.5**
     * 
     * For any subscription status update, the system should create an audit log entry 
     * with timestamp and payment details.
     */
    @Property(tries = 100)
    void property28_auditLogging(
            @ForAll("paymentMethods") String paymentMethod,
            @ForAll("productIds") String productId,
            @ForAll("transactionIds") String transactionId,
            @ForAll("platforms") String platform,
            @ForAll boolean verificationSuccess) {
        
        // Given: A payment verification request
        PaymentVerificationRequest request = PaymentVerificationRequest.builder()
                .paymentMethod(paymentMethod)
                .productId(productId)
                .transactionId(transactionId)
                .receiptData(generateReceiptData(paymentMethod))
                .platform(platform)
                .build();

        // Setup mocks
        when(userMapper.selectById(1L)).thenReturn(testUser);
        when(transactionMapper.selectOne(any())).thenReturn(null);
        when(paymentService.verifyPayment(any(PaymentVerificationRequest.class))).thenReturn(verificationSuccess);
        when(transactionMapper.insert(any(Transaction.class))).thenReturn(1);

        if (verificationSuccess) {
            when(subscriptionMapper.findActiveByUserId(1L)).thenReturn(null);
            when(subscriptionMapper.insert(any(Subscription.class))).thenAnswer(invocation -> {
                Subscription sub = invocation.getArgument(0);
                sub.setId(1L);
                return 1;
            });
        }

        // When: Attempting to verify and update subscription
        try {
            subscriptionService.verifyAndUpdateSubscription(1L, request);
        } catch (RuntimeException e) {
            // Expected for failed verification
        }

        // Then: Transaction record should be created with correct status
        String expectedStatus = verificationSuccess ? "verified" : "failed";
        verify(transactionMapper, times(1)).insert(argThat(txn -> {
            boolean statusMatches = expectedStatus.equals(txn.getVerificationStatus());
            boolean transactionIdMatches = transactionId.equals(txn.getPlatformTransactionId());
            boolean paymentMethodMatches = paymentMethod.equals(txn.getPaymentMethod());
            boolean userIdMatches = Long.valueOf(1L).equals(txn.getUserId());
            boolean hasTimestamp = txn.getCreatedAt() != null;
            boolean hasAmount = txn.getAmount() != null && txn.getAmount().compareTo(BigDecimal.ZERO) > 0;
            boolean hasCurrency = "CNY".equals(txn.getCurrency());

            return statusMatches && transactionIdMatches && paymentMethodMatches && 
                   userIdMatches && hasTimestamp && hasAmount && hasCurrency;
        }));
    }

    // Arbitraries (generators) for property-based testing

    @Provide
    Arbitrary<String> paymentMethods() {
        return Arbitraries.of("apple_iap", "wechat_pay", "alipay");
    }

    @Provide
    Arbitrary<String> productIds() {
        return Arbitraries.of(
                "com.declutter.pro.monthly",
                "com.declutter.pro.yearly",
                "com.declutter.max.monthly",
                "com.declutter.max.yearly"
        );
    }

    @Provide
    Arbitrary<String> transactionIds() {
        return Arbitraries.strings()
                .alpha()
                .numeric()
                .ofMinLength(10)
                .ofMaxLength(50)
                .map(s -> "txn-" + s);
    }

    @Provide
    Arbitrary<String> platforms() {
        return Arbitraries.of("ios", "android", "web");
    }

    /**
     * Generate receipt data based on payment method
     */
    private String generateReceiptData(String paymentMethod) {
        if ("apple_iap".equals(paymentMethod)) {
            // Generate base64 encoded receipt data for Apple IAP
            String receiptJson = "{\"receipt\":{\"bundle_id\":\"com.declutter\",\"application_version\":\"1.0\"}}";
            return Base64.getEncoder().encodeToString(receiptJson.getBytes());
        }
        return null;
    }
}
