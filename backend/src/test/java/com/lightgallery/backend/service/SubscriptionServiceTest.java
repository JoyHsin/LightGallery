package com.declutter.backend.service;

import com.declutter.backend.dto.PaymentVerificationRequest;
import com.declutter.backend.dto.SubscriptionDTO;
import com.declutter.backend.dto.SubscriptionProductDTO;
import com.declutter.backend.dto.SubscriptionSyncRequest;
import com.declutter.backend.entity.Subscription;
import com.declutter.backend.entity.Transaction;
import com.declutter.backend.entity.User;
import com.declutter.backend.mapper.SubscriptionMapper;
import com.declutter.backend.mapper.TransactionMapper;
import com.declutter.backend.mapper.UserMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.*;

/**
 * Unit tests for SubscriptionService
 * Tests product retrieval, subscription status logic, and subscription updates
 */
@ExtendWith(MockitoExtension.class)
class SubscriptionServiceTest {

    @Mock
    private SubscriptionMapper subscriptionMapper;

    @Mock
    private TransactionMapper transactionMapper;

    @Mock
    private UserMapper userMapper;

    @InjectMocks
    private SubscriptionService subscriptionService;

    private User testUser;
    private Subscription testSubscription;
    private PaymentVerificationRequest paymentRequest;

    @BeforeEach
    void setUp() {
        // Setup test user
        testUser = new User();
        testUser.setId(1L);
        testUser.setAuthProvider("apple");
        testUser.setProviderUserId("apple-user-123");
        testUser.setEmail("test@example.com");
        testUser.setDisplayName("Test User");
        testUser.setCreatedAt(LocalDateTime.now());
        testUser.setUpdatedAt(LocalDateTime.now());

        // Setup test subscription
        testSubscription = new Subscription();
        testSubscription.setId(1L);
        testSubscription.setUserId(1L);
        testSubscription.setTier("pro");
        testSubscription.setBillingPeriod("monthly");
        testSubscription.setStatus("active");
        testSubscription.setPaymentMethod("apple_iap");
        testSubscription.setStartDate(LocalDateTime.now());
        testSubscription.setExpiryDate(LocalDateTime.now().plusMonths(1));
        testSubscription.setAutoRenew(true);
        testSubscription.setProductId("com.declutter.pro.monthly");
        testSubscription.setOriginalTransactionId("txn-123");
        testSubscription.setLastSyncedAt(LocalDateTime.now());
        testSubscription.setCreatedAt(LocalDateTime.now());
        testSubscription.setUpdatedAt(LocalDateTime.now());

        // Setup payment verification request
        paymentRequest = PaymentVerificationRequest.builder()
                .paymentMethod("apple_iap")
                .productId("com.declutter.pro.monthly")
                .transactionId("txn-456")
                .receiptData("base64-encoded-receipt")
                .platform("ios")
                .build();
    }

    @Test
    void testGetAvailableProducts_ReturnsAllProducts() {
        // When
        List<SubscriptionProductDTO> products = subscriptionService.getAvailableProducts();

        // Then
        assertNotNull(products);
        assertEquals(4, products.size());

        // Verify Pro Monthly
        SubscriptionProductDTO proMonthly = products.stream()
                .filter(p -> "com.declutter.pro.monthly".equals(p.getProductId()))
                .findFirst()
                .orElse(null);
        assertNotNull(proMonthly);
        assertEquals("pro", proMonthly.getTier());
        assertEquals("monthly", proMonthly.getBillingPeriod());
        assertEquals(new BigDecimal("10.00"), proMonthly.getPrice());
        assertEquals("CNY", proMonthly.getCurrency());
        assertEquals("¥10/月", proMonthly.getLocalizedPrice());

        // Verify Pro Yearly
        SubscriptionProductDTO proYearly = products.stream()
                .filter(p -> "com.declutter.pro.yearly".equals(p.getProductId()))
                .findFirst()
                .orElse(null);
        assertNotNull(proYearly);
        assertEquals("pro", proYearly.getTier());
        assertEquals("yearly", proYearly.getBillingPeriod());
        assertEquals(new BigDecimal("100.00"), proYearly.getPrice());

        // Verify Max Monthly
        SubscriptionProductDTO maxMonthly = products.stream()
                .filter(p -> "com.declutter.max.monthly".equals(p.getProductId()))
                .findFirst()
                .orElse(null);
        assertNotNull(maxMonthly);
        assertEquals("max", maxMonthly.getTier());
        assertEquals("monthly", maxMonthly.getBillingPeriod());
        assertEquals(new BigDecimal("20.00"), maxMonthly.getPrice());

        // Verify Max Yearly
        SubscriptionProductDTO maxYearly = products.stream()
                .filter(p -> "com.declutter.max.yearly".equals(p.getProductId()))
                .findFirst()
                .orElse(null);
        assertNotNull(maxYearly);
        assertEquals("max", maxYearly.getTier());
        assertEquals("yearly", maxYearly.getBillingPeriod());
        assertEquals(new BigDecimal("200.00"), maxYearly.getPrice());
    }

    @Test
    void testGetCurrentSubscription_ActiveSubscription_ReturnsSubscription() {
        // Given
        when(userMapper.selectById(1L)).thenReturn(testUser);
        when(subscriptionMapper.findActiveByUserId(1L)).thenReturn(testSubscription);

        // When
        SubscriptionDTO result = subscriptionService.getCurrentSubscription(1L);

        // Then
        assertNotNull(result);
        assertEquals(1L, result.getId());
        assertEquals(1L, result.getUserId());
        assertEquals("pro", result.getTier());
        assertEquals("monthly", result.getBillingPeriod());
        assertEquals("active", result.getStatus());
        assertEquals("apple_iap", result.getPaymentMethod());

        verify(userMapper).selectById(1L);
        verify(subscriptionMapper).findActiveByUserId(1L);
    }

    @Test
    void testGetCurrentSubscription_NoSubscription_CreatesFreeSubscription() {
        // Given
        when(userMapper.selectById(1L)).thenReturn(testUser);
        when(subscriptionMapper.findActiveByUserId(1L)).thenReturn(null);
        when(subscriptionMapper.selectOne(any())).thenReturn(null);
        when(subscriptionMapper.insert(any(Subscription.class))).thenAnswer(invocation -> {
            Subscription sub = invocation.getArgument(0);
            sub.setId(2L);
            return 1;
        });

        // When
        SubscriptionDTO result = subscriptionService.getCurrentSubscription(1L);

        // Then
        assertNotNull(result);
        assertEquals("free", result.getTier());
        assertEquals("active", result.getStatus());
        assertEquals("none", result.getPaymentMethod());

        verify(subscriptionMapper).insert(any(Subscription.class));
    }

    @Test
    void testGetCurrentSubscription_ExpiredSubscription_UpdatesStatus() {
        // Given
        testSubscription.setExpiryDate(LocalDateTime.now().minusDays(1)); // Expired
        when(userMapper.selectById(1L)).thenReturn(testUser);
        when(subscriptionMapper.findActiveByUserId(1L)).thenReturn(testSubscription);
        when(subscriptionMapper.updateById(any(Subscription.class))).thenReturn(1);

        // When
        SubscriptionDTO result = subscriptionService.getCurrentSubscription(1L);

        // Then
        assertNotNull(result);
        assertEquals("expired", result.getStatus());

        verify(subscriptionMapper).updateById(any(Subscription.class));
    }

    @Test
    void testGetCurrentSubscription_UserNotFound_ThrowsException() {
        // Given
        when(userMapper.selectById(1L)).thenReturn(null);

        // When & Then
        RuntimeException exception = assertThrows(RuntimeException.class, () -> {
            subscriptionService.getCurrentSubscription(1L);
        });

        assertEquals("User not found", exception.getMessage());
        verify(subscriptionMapper, never()).findActiveByUserId(anyLong());
    }

    @Test
    void testVerifyAndUpdateSubscription_NewSubscription_Success() {
        // Given
        when(userMapper.selectById(1L)).thenReturn(testUser);
        when(transactionMapper.selectOne(any())).thenReturn(null);
        when(subscriptionMapper.findActiveByUserId(1L)).thenReturn(null);
        when(subscriptionMapper.insert(any(Subscription.class))).thenAnswer(invocation -> {
            Subscription sub = invocation.getArgument(0);
            sub.setId(1L);
            return 1;
        });
        when(transactionMapper.insert(any(Transaction.class))).thenReturn(1);

        // When
        SubscriptionDTO result = subscriptionService.verifyAndUpdateSubscription(1L, paymentRequest);

        // Then
        assertNotNull(result);
        assertEquals("pro", result.getTier());
        assertEquals("monthly", result.getBillingPeriod());
        assertEquals("active", result.getStatus());
        assertEquals("apple_iap", result.getPaymentMethod());
        assertNotNull(result.getExpiryDate());

        verify(subscriptionMapper).insert(any(Subscription.class));
        verify(transactionMapper).insert(any(Transaction.class));
    }

    @Test
    void testVerifyAndUpdateSubscription_ExistingSubscription_Updates() {
        // Given
        when(userMapper.selectById(1L)).thenReturn(testUser);
        when(transactionMapper.selectOne(any())).thenReturn(null);
        when(subscriptionMapper.findActiveByUserId(1L)).thenReturn(testSubscription);
        when(subscriptionMapper.updateById(any(Subscription.class))).thenReturn(1);
        when(transactionMapper.insert(any(Transaction.class))).thenReturn(1);

        // When
        SubscriptionDTO result = subscriptionService.verifyAndUpdateSubscription(1L, paymentRequest);

        // Then
        assertNotNull(result);
        assertEquals("pro", result.getTier());
        assertEquals("active", result.getStatus());

        verify(subscriptionMapper).updateById(any(Subscription.class));
        verify(transactionMapper).insert(any(Transaction.class));
    }

    @Test
    void testVerifyAndUpdateSubscription_DuplicateTransaction_ReturnsExisting() {
        // Given
        Transaction existingTransaction = new Transaction();
        existingTransaction.setId(1L);
        existingTransaction.setPlatformTransactionId("txn-456");
        existingTransaction.setVerificationStatus("verified");
        existingTransaction.setSubscriptionId(1L);

        when(userMapper.selectById(1L)).thenReturn(testUser);
        when(transactionMapper.selectOne(any())).thenReturn(existingTransaction);
        when(subscriptionMapper.selectById(1L)).thenReturn(testSubscription);

        // When
        SubscriptionDTO result = subscriptionService.verifyAndUpdateSubscription(1L, paymentRequest);

        // Then
        assertNotNull(result);
        assertEquals(1L, result.getId());

        verify(subscriptionMapper, never()).insert(any());
        verify(subscriptionMapper, never()).updateById(any());
    }

    @Test
    void testVerifyAndUpdateSubscription_YearlySubscription_CalculatesCorrectExpiry() {
        // Given
        paymentRequest.setProductId("com.declutter.pro.yearly");
        when(userMapper.selectById(1L)).thenReturn(testUser);
        when(transactionMapper.selectOne(any())).thenReturn(null);
        when(subscriptionMapper.findActiveByUserId(1L)).thenReturn(null);
        when(subscriptionMapper.insert(any(Subscription.class))).thenAnswer(invocation -> {
            Subscription sub = invocation.getArgument(0);
            sub.setId(1L);
            return 1;
        });
        when(transactionMapper.insert(any(Transaction.class))).thenReturn(1);

        // When
        SubscriptionDTO result = subscriptionService.verifyAndUpdateSubscription(1L, paymentRequest);

        // Then
        assertNotNull(result);
        assertEquals("yearly", result.getBillingPeriod());
        assertNotNull(result.getExpiryDate());
        // Verify expiry is approximately 1 year from now
        assertTrue(result.getExpiryDate().isAfter(LocalDateTime.now().plusMonths(11)));
        assertTrue(result.getExpiryDate().isBefore(LocalDateTime.now().plusMonths(13)));
    }

    @Test
    void testSyncSubscription_ActiveSubscription_UpdatesLastSynced() {
        // Given
        SubscriptionSyncRequest syncRequest = SubscriptionSyncRequest.builder()
                .platform("ios")
                .forceRefresh(true)
                .build();

        testSubscription.setLastSyncedAt(LocalDateTime.now().minusHours(2));
        when(subscriptionMapper.findActiveByUserId(1L)).thenReturn(testSubscription);
        when(subscriptionMapper.updateById(any(Subscription.class))).thenReturn(1);

        // When
        SubscriptionDTO result = subscriptionService.syncSubscription(1L, syncRequest);

        // Then
        assertNotNull(result);
        assertEquals("pro", result.getTier());
        assertEquals("active", result.getStatus());

        verify(subscriptionMapper).updateById(any(Subscription.class));
    }

    @Test
    void testSyncSubscription_NoActiveSubscription_ReturnsFreeSubscription() {
        // Given
        SubscriptionSyncRequest syncRequest = SubscriptionSyncRequest.builder()
                .platform("ios")
                .forceRefresh(false)
                .build();

        when(subscriptionMapper.findActiveByUserId(1L)).thenReturn(null);
        when(subscriptionMapper.insert(any(Subscription.class))).thenAnswer(invocation -> {
            Subscription sub = invocation.getArgument(0);
            sub.setId(2L);
            return 1;
        });

        // When
        SubscriptionDTO result = subscriptionService.syncSubscription(1L, syncRequest);

        // Then
        assertNotNull(result);
        assertEquals("free", result.getTier());
        assertEquals("active", result.getStatus());

        verify(subscriptionMapper).insert(any(Subscription.class));
    }

    @Test
    void testSyncSubscription_ExpiredDuringSync_UpdatesStatus() {
        // Given
        SubscriptionSyncRequest syncRequest = SubscriptionSyncRequest.builder()
                .platform("ios")
                .forceRefresh(true)
                .build();

        testSubscription.setExpiryDate(LocalDateTime.now().minusDays(1)); // Expired
        when(subscriptionMapper.findActiveByUserId(1L)).thenReturn(testSubscription);
        when(subscriptionMapper.updateById(any(Subscription.class))).thenReturn(1);

        // When
        SubscriptionDTO result = subscriptionService.syncSubscription(1L, syncRequest);

        // Then
        assertNotNull(result);
        assertEquals("expired", result.getStatus());

        verify(subscriptionMapper, times(2)).updateById(any(Subscription.class));
    }

    @Test
    void testSyncSubscription_RecentSync_SkipsUpdate() {
        // Given
        SubscriptionSyncRequest syncRequest = SubscriptionSyncRequest.builder()
                .platform("ios")
                .forceRefresh(false)
                .build();

        testSubscription.setLastSyncedAt(LocalDateTime.now().minusMinutes(30)); // Recent sync
        when(subscriptionMapper.findActiveByUserId(1L)).thenReturn(testSubscription);

        // When
        SubscriptionDTO result = subscriptionService.syncSubscription(1L, syncRequest);

        // Then
        assertNotNull(result);
        assertEquals("pro", result.getTier());
        assertEquals("active", result.getStatus());

        verify(subscriptionMapper, never()).updateById(any(Subscription.class));
    }
}
