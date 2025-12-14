package com.lightgallery.backend.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.lightgallery.backend.dto.PaymentVerificationRequest;
import com.lightgallery.backend.dto.SubscriptionDTO;
import com.lightgallery.backend.dto.SubscriptionProductDTO;
import com.lightgallery.backend.dto.SubscriptionSyncRequest;
import com.lightgallery.backend.entity.Subscription;
import com.lightgallery.backend.entity.Transaction;
import com.lightgallery.backend.entity.User;
import com.lightgallery.backend.mapper.SubscriptionMapper;
import com.lightgallery.backend.mapper.TransactionMapper;
import com.lightgallery.backend.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Subscription Service
 * Handles subscription product retrieval, status checks, creation, updates, and sync
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SubscriptionService {

    private final SubscriptionMapper subscriptionMapper;
    private final TransactionMapper transactionMapper;
    private final UserMapper userMapper;
    private final PaymentService paymentService;
    private final AuditLogService auditLogService;

    /**
     * Get available subscription products
     * Returns predefined list of subscription products
     *
     * @return List of subscription products
     */
    public List<SubscriptionProductDTO> getAvailableProducts() {
        log.info("Retrieving available subscription products");
        
        List<SubscriptionProductDTO> products = new ArrayList<>();
        
        // Pro Monthly
        products.add(SubscriptionProductDTO.builder()
                .productId("joyhisn.LightGallery.pro.monthly")
                .tier("pro")
                .billingPeriod("monthly")
                .price(new BigDecimal("10.00"))
                .currency("CNY")
                .localizedPrice("¥10/月")
                .description("专业版月付订阅")
                .features(new String[]{
                    "工具箱所有功能",
                    "智能清理",
                    "重复照片检测",
                    "相似照片清理",
                    "截图清理",
                    "照片增强",
                    "格式转换",
                    "Live Photo 转换",
                    "证件照编辑",
                    "隐私擦除",
                    "长截图拼接"
                })
                .build());
        
        // Pro Yearly
        products.add(SubscriptionProductDTO.builder()
                .productId("joyhisn.LightGallery.pro.yearly")
                .tier("pro")
                .billingPeriod("yearly")
                .price(new BigDecimal("100.00"))
                .currency("CNY")
                .localizedPrice("¥100/年")
                .description("专业版年付订阅（节省20元）")
                .features(new String[]{
                    "工具箱所有功能",
                    "智能清理",
                    "重复照片检测",
                    "相似照片清理",
                    "截图清理",
                    "照片增强",
                    "格式转换",
                    "Live Photo 转换",
                    "证件照编辑",
                    "隐私擦除",
                    "长截图拼接"
                })
                .build());
        
        // Max Monthly
        products.add(SubscriptionProductDTO.builder()
                .productId("joyhisn.LightGallery.max.monthly")
                .tier("max")
                .billingPeriod("monthly")
                .price(new BigDecimal("20.00"))
                .currency("CNY")
                .localizedPrice("¥20/月")
                .description("旗舰版月付订阅")
                .features(new String[]{
                    "专业版所有功能",
                    "优先客服支持",
                    "云端备份（即将推出）",
                    "高级AI功能（即将推出）"
                })
                .build());
        
        // Max Yearly
        products.add(SubscriptionProductDTO.builder()
                .productId("joyhisn.LightGallery.max.yearly")
                .tier("max")
                .billingPeriod("yearly")
                .price(new BigDecimal("200.00"))
                .currency("CNY")
                .localizedPrice("¥200/年")
                .description("旗舰版年付订阅（节省40元）")
                .features(new String[]{
                    "专业版所有功能",
                    "优先客服支持",
                    "云端备份（即将推出）",
                    "高级AI功能（即将推出）"
                })
                .build());
        
        log.info("Retrieved {} subscription products", products.size());
        return products;
    }

    /**
     * Get current subscription for user
     * Returns active subscription or creates a free tier subscription if none exists
     *
     * @param userId User ID
     * @return Current subscription
     */
    public SubscriptionDTO getCurrentSubscription(Long userId) {
        log.info("Fetching current subscription for user: {}", userId);
        
        // Verify user exists
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new RuntimeException("User not found");
        }
        
        // Try to find active subscription
        Subscription subscription = subscriptionMapper.findActiveByUserId(userId);
        
        // If no active subscription, check for any subscription
        if (subscription == null) {
            LambdaQueryWrapper<Subscription> queryWrapper = new LambdaQueryWrapper<>();
            queryWrapper.eq(Subscription::getUserId, userId)
                    .orderByDesc(Subscription::getCreatedAt)
                    .last("LIMIT 1");
            subscription = subscriptionMapper.selectOne(queryWrapper);
        }
        
        // If still no subscription, create a free tier subscription
        if (subscription == null) {
            log.info("No subscription found for user {}, creating free tier", userId);
            subscription = createFreeSubscription(userId);
        }
        
        // Check if subscription is expired and update status
        if ("active".equals(subscription.getStatus()) && 
            subscription.getExpiryDate() != null && 
            subscription.getExpiryDate().isBefore(LocalDateTime.now())) {
            log.info("Subscription {} is expired, updating status", subscription.getId());
            subscription.setStatus("expired");
            subscription.setUpdatedAt(LocalDateTime.now());
            subscriptionMapper.updateById(subscription);
        }
        
        return convertToDTO(subscription);
    }

    /**
     * Verify payment and update subscription
     * Validates payment with payment platform and creates/updates subscription
     *
     * @param userId User ID
     * @param request Payment verification request
     * @return Updated subscription
     */
    @Transactional
    public SubscriptionDTO verifyAndUpdateSubscription(Long userId, PaymentVerificationRequest request) {
        log.info("Verifying payment for user {}: method={}, productId={}", 
                userId, request.getPaymentMethod(), request.getProductId());
        
        // Verify user exists
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new RuntimeException("User not found");
        }
        
        // Check if transaction already exists (prevent duplicate processing)
        LambdaQueryWrapper<Transaction> transactionQuery = new LambdaQueryWrapper<>();
        transactionQuery.eq(Transaction::getPlatformTransactionId, request.getTransactionId());
        Transaction existingTransaction = transactionMapper.selectOne(transactionQuery);
        
        if (existingTransaction != null && "verified".equals(existingTransaction.getVerificationStatus())) {
            log.warn("Transaction {} already processed successfully", request.getTransactionId());
            // Return existing subscription
            Subscription subscription = subscriptionMapper.selectById(existingTransaction.getSubscriptionId());
            if (subscription != null) {
                return convertToDTO(subscription);
            }
        }
        
        // Parse product ID to determine tier and billing period
        String tier = extractTierFromProductId(request.getProductId());
        String billingPeriod = extractBillingPeriodFromProductId(request.getProductId());
        BigDecimal amount = calculateAmount(tier, billingPeriod);
        
        // Verify payment with payment platform using PaymentService
        // Requirements: 4.3, 8.4
        boolean paymentVerified = paymentService.verifyPayment(request);
        
        if (!paymentVerified) {
            // Create failed transaction record for audit
            // Requirement: 8.5
            log.error("Payment verification failed for user {}: transactionId={}", 
                    userId, request.getTransactionId());
            createTransactionRecord(userId, null, request, amount, "failed");
            
            // Log payment verification failure
            // Requirement: 8.5
            auditLogService.logPaymentVerificationFailure(userId, request.getPaymentMethod(), 
                    request.getTransactionId(), "Payment verification failed");
            
            throw new RuntimeException("Payment verification failed");
        }
        
        log.info("Payment verified successfully for user {}: transactionId={}", 
                userId, request.getTransactionId());
        
        // Log successful payment verification
        // Requirement: 8.5
        auditLogService.logPaymentVerification(userId, request.getPaymentMethod(), 
                request.getTransactionId(), amount.doubleValue(), "CNY", true);
        
        // Find or create subscription
        Subscription subscription = findOrCreateSubscription(userId, request);
        
        // Update subscription details
        subscription.setTier(tier);
        subscription.setBillingPeriod(billingPeriod);
        subscription.setStatus("active");
        subscription.setPaymentMethod(request.getPaymentMethod());
        subscription.setProductId(request.getProductId());
        subscription.setAutoRenew(true);
        
        // Set dates
        LocalDateTime now = LocalDateTime.now();
        if (subscription.getStartDate() == null) {
            subscription.setStartDate(now);
        }
        
        // Calculate expiry date based on billing period
        LocalDateTime expiryDate = calculateExpiryDate(now, billingPeriod);
        subscription.setExpiryDate(expiryDate);
        
        // Set original transaction ID for tracking renewals
        if (request.getOriginalTransactionId() != null) {
            subscription.setOriginalTransactionId(request.getOriginalTransactionId());
        } else {
            subscription.setOriginalTransactionId(request.getTransactionId());
        }
        
        subscription.setLastSyncedAt(now);
        subscription.setUpdatedAt(now);
        
        // Save subscription
        if (subscription.getId() == null) {
            subscriptionMapper.insert(subscription);
        } else {
            subscriptionMapper.updateById(subscription);
        }
        
        // Create successful transaction record for audit
        // Requirement: 8.5
        createTransactionRecord(userId, subscription.getId(), request, amount, "success");
        
        // Log subscription update
        // Requirement: 8.5
        auditLogService.logSubscriptionUpdate(userId, subscription.getId(), tier, 
                subscription.getStatus(), request.getPaymentMethod(), request.getTransactionId());
        
        log.info("Subscription updated successfully for user {}: tier={}, expiryDate={}, transactionId={}", 
                userId, tier, expiryDate, request.getTransactionId());
        
        return convertToDTO(subscription);
    }

    /**
     * Sync subscription status with payment platform
     * Refreshes subscription status from payment platform
     *
     * @param userId User ID
     * @param request Sync request
     * @return Synced subscription
     */
    @Transactional
    public SubscriptionDTO syncSubscription(Long userId, SubscriptionSyncRequest request) {
        log.info("Syncing subscription for user {}: platform={}, forceRefresh={}", 
                userId, request.getPlatform(), request.getForceRefresh());
        
        // Get current subscription
        Subscription subscription = subscriptionMapper.findActiveByUserId(userId);
        
        if (subscription == null) {
            // No active subscription, return free tier
            log.info("No active subscription found for user {}, returning free tier", userId);
            subscription = createFreeSubscription(userId);
            return convertToDTO(subscription);
        }
        
        // Check if sync is needed
        boolean needsSync = request.getForceRefresh() != null && request.getForceRefresh();
        if (!needsSync && subscription.getLastSyncedAt() != null) {
            // Check if last sync was within 1 hour
            LocalDateTime oneHourAgo = LocalDateTime.now().minusHours(1);
            needsSync = subscription.getLastSyncedAt().isBefore(oneHourAgo);
        }
        
        if (needsSync) {
            log.info("Syncing subscription {} with payment platform", subscription.getId());
            // In production, this should query the payment platform for latest status
            // For now, just update the last synced timestamp
            subscription.setLastSyncedAt(LocalDateTime.now());
            subscription.setUpdatedAt(LocalDateTime.now());
            subscriptionMapper.updateById(subscription);
        }
        
        // Check if subscription is expired
        if ("active".equals(subscription.getStatus()) && 
            subscription.getExpiryDate() != null && 
            subscription.getExpiryDate().isBefore(LocalDateTime.now())) {
            log.info("Subscription {} is expired during sync, updating status", subscription.getId());
            subscription.setStatus("expired");
            subscription.setUpdatedAt(LocalDateTime.now());
            subscriptionMapper.updateById(subscription);
        }
        
        log.info("Subscription synced for user {}: tier={}, status={}", 
                userId, subscription.getTier(), subscription.getStatus());
        
        return convertToDTO(subscription);
    }

    /**
     * Create a free tier subscription for user
     *
     * @param userId User ID
     * @return Free subscription
     */
    private Subscription createFreeSubscription(Long userId) {
        Subscription subscription = new Subscription();
        subscription.setUserId(userId);
        subscription.setTier("free");
        subscription.setBillingPeriod("monthly");
        subscription.setStatus("active");
        subscription.setPaymentMethod("none");
        subscription.setStartDate(LocalDateTime.now());
        subscription.setExpiryDate(LocalDateTime.now().plusYears(100)); // Free tier never expires
        subscription.setAutoRenew(false);
        subscription.setProductId("com.lightgallery.free");
        subscription.setLastSyncedAt(LocalDateTime.now());
        subscription.setCreatedAt(LocalDateTime.now());
        subscription.setUpdatedAt(LocalDateTime.now());
        
        subscriptionMapper.insert(subscription);
        log.info("Created free subscription for user: {}", userId);
        
        return subscription;
    }

    /**
     * Find or create subscription for user
     *
     * @param userId User ID
     * @param request Payment verification request
     * @return Subscription
     */
    private Subscription findOrCreateSubscription(Long userId, PaymentVerificationRequest request) {
        // Try to find by original transaction ID first (for renewals)
        if (request.getOriginalTransactionId() != null) {
            Subscription subscription = subscriptionMapper.findByOriginalTransactionId(
                    request.getOriginalTransactionId());
            if (subscription != null) {
                return subscription;
            }
        }
        
        // Try to find active subscription
        Subscription subscription = subscriptionMapper.findActiveByUserId(userId);
        if (subscription != null) {
            return subscription;
        }
        
        // Create new subscription
        subscription = new Subscription();
        subscription.setUserId(userId);
        subscription.setCreatedAt(LocalDateTime.now());
        return subscription;
    }

    /**
     * Create transaction record for audit
     *
     * @param userId User ID
     * @param subscriptionId Subscription ID
     * @param request Payment verification request
     * @param amount Transaction amount
     * @param status Transaction status
     */
    private void createTransactionRecord(Long userId, Long subscriptionId, 
                                        PaymentVerificationRequest request, 
                                        BigDecimal amount, String status) {
        Transaction transaction = new Transaction();
        transaction.setUserId(userId);
        transaction.setSubscriptionId(subscriptionId);
        transaction.setPaymentMethod(request.getPaymentMethod());
        transaction.setAmount(amount);
        transaction.setCurrency("CNY");
        transaction.setPlatformTransactionId(request.getTransactionId());
        transaction.setReceiptData(request.getReceiptData());
        transaction.setVerificationStatus(status);
        transaction.setCreatedAt(LocalDateTime.now());
        transaction.setUpdatedAt(LocalDateTime.now());
        
        transactionMapper.insert(transaction);
        log.info("Created transaction record: userId={}, transactionId={}, status={}", 
                userId, request.getTransactionId(), status);
    }

    /**
     * Extract tier from product ID
     *
     * @param productId Product ID
     * @return Tier (pro or max)
     */
    private String extractTierFromProductId(String productId) {
        if (productId.contains(".pro.")) {
            return "pro";
        } else if (productId.contains(".max.")) {
            return "max";
        }
        throw new RuntimeException("Invalid product ID: " + productId);
    }

    /**
     * Extract billing period from product ID
     *
     * @param productId Product ID
     * @return Billing period (monthly or yearly)
     */
    private String extractBillingPeriodFromProductId(String productId) {
        if (productId.endsWith(".monthly")) {
            return "monthly";
        } else if (productId.endsWith(".yearly")) {
            return "yearly";
        }
        throw new RuntimeException("Invalid product ID: " + productId);
    }

    /**
     * Calculate amount based on tier and billing period
     *
     * @param tier Subscription tier
     * @param billingPeriod Billing period
     * @return Amount in CNY
     */
    private BigDecimal calculateAmount(String tier, String billingPeriod) {
        if ("pro".equals(tier)) {
            return "monthly".equals(billingPeriod) ? 
                    new BigDecimal("10.00") : new BigDecimal("100.00");
        } else if ("max".equals(tier)) {
            return "monthly".equals(billingPeriod) ? 
                    new BigDecimal("20.00") : new BigDecimal("200.00");
        }
        return BigDecimal.ZERO;
    }

    /**
     * Calculate expiry date based on billing period
     *
     * @param startDate Start date
     * @param billingPeriod Billing period
     * @return Expiry date
     */
    private LocalDateTime calculateExpiryDate(LocalDateTime startDate, String billingPeriod) {
        if ("monthly".equals(billingPeriod)) {
            return startDate.plusMonths(1);
        } else if ("yearly".equals(billingPeriod)) {
            return startDate.plusYears(1);
        }
        throw new RuntimeException("Invalid billing period: " + billingPeriod);
    }

    /**
     * Calculate prorated pricing for subscription upgrade
     * Requirement: 7.2
     *
     * @param userId User ID
     * @param targetTier Target subscription tier
     * @return Upgrade information with prorated pricing
     */
    public SubscriptionDTO calculateUpgrade(Long userId, String targetTier) {
        log.info("Calculating upgrade for user {}: targetTier={}", userId, targetTier);
        
        // Get current subscription
        Subscription currentSubscription = subscriptionMapper.findActiveByUserId(userId);
        if (currentSubscription == null) {
            throw new RuntimeException("No active subscription found");
        }
        
        // Validate upgrade is to a higher tier
        if (!isUpgrade(currentSubscription.getTier(), targetTier)) {
            throw new RuntimeException("Can only upgrade to a higher tier");
        }
        
        // Calculate prorated amount
        BigDecimal proratedAmount = calculateProratedAmount(
                currentSubscription.getTier(),
                targetTier,
                currentSubscription.getBillingPeriod(),
                currentSubscription.getExpiryDate()
        );
        
        log.info("Prorated upgrade amount for user {}: ¥{}", userId, proratedAmount);
        
        // Return upgrade information
        SubscriptionDTO upgradeInfo = convertToDTO(currentSubscription);
        // Note: In a real implementation, we would add proratedAmount to the DTO
        // For now, we log it and return the current subscription info
        
        return upgradeInfo;
    }
    
    /**
     * Check if target tier is an upgrade from current tier
     *
     * @param currentTier Current subscription tier
     * @param targetTier Target subscription tier
     * @return True if target is higher than current
     */
    private boolean isUpgrade(String currentTier, String targetTier) {
        int currentLevel = getTierLevel(currentTier);
        int targetLevel = getTierLevel(targetTier);
        return targetLevel > currentLevel;
    }
    
    /**
     * Get numeric level for tier comparison
     *
     * @param tier Subscription tier
     * @return Numeric level (0=free, 1=pro, 2=max)
     */
    private int getTierLevel(String tier) {
        switch (tier) {
            case "free": return 0;
            case "pro": return 1;
            case "max": return 2;
            default: return -1;
        }
    }
    
    /**
     * Calculate prorated amount for upgrade
     * Formula: (target price - current price) * (remaining days / total days)
     *
     * @param currentTier Current subscription tier
     * @param targetTier Target subscription tier
     * @param billingPeriod Billing period
     * @param expiryDate Current subscription expiry date
     * @return Prorated amount
     */
    private BigDecimal calculateProratedAmount(String currentTier, String targetTier, 
                                               String billingPeriod, LocalDateTime expiryDate) {
        // Get prices
        BigDecimal currentPrice = getPriceForTier(currentTier, billingPeriod);
        BigDecimal targetPrice = getPriceForTier(targetTier, billingPeriod);
        BigDecimal priceDifference = targetPrice.subtract(currentPrice);
        
        // Calculate remaining days
        LocalDateTime now = LocalDateTime.now();
        long remainingDays = java.time.temporal.ChronoUnit.DAYS.between(now, expiryDate);
        
        // Get total days in period
        int totalDays = getTotalDaysInPeriod(billingPeriod);
        
        // Calculate prorated amount: (price difference) * (remaining days / total days)
        BigDecimal proratedAmount = priceDifference
                .multiply(BigDecimal.valueOf(remainingDays))
                .divide(BigDecimal.valueOf(totalDays), 2, java.math.RoundingMode.HALF_UP);
        
        return proratedAmount.max(BigDecimal.ZERO);
    }
    
    /**
     * Get price for a specific tier and billing period
     *
     * @param tier Subscription tier
     * @param billingPeriod Billing period
     * @return Price in CNY
     */
    private BigDecimal getPriceForTier(String tier, String billingPeriod) {
        if ("free".equals(tier)) {
            return BigDecimal.ZERO;
        } else if ("pro".equals(tier)) {
            return "monthly".equals(billingPeriod) ? 
                    new BigDecimal("10.00") : new BigDecimal("100.00");
        } else if ("max".equals(tier)) {
            return "monthly".equals(billingPeriod) ? 
                    new BigDecimal("20.00") : new BigDecimal("200.00");
        }
        return BigDecimal.ZERO;
    }
    
    /**
     * Get total days in a billing period
     *
     * @param billingPeriod Billing period
     * @return Total days
     */
    private int getTotalDaysInPeriod(String billingPeriod) {
        return "monthly".equals(billingPeriod) ? 30 : 365;
    }

    /**
     * Cancel subscription
     * Updates subscription status to cancelled while maintaining access until expiry
     * Requirements: 7.3, 7.4
     *
     * @param userId User ID
     * @return Updated subscription with cancelled status
     */
    @Transactional
    public SubscriptionDTO cancelSubscription(Long userId) {
        log.info("Cancelling subscription for user {}", userId);
        
        // Get current subscription
        Subscription subscription = subscriptionMapper.findActiveByUserId(userId);
        if (subscription == null) {
            throw new RuntimeException("No active subscription found");
        }
        
        // Update subscription status to cancelled
        subscription.setStatus("cancelled");
        subscription.setAutoRenew(false);
        subscription.setUpdatedAt(LocalDateTime.now());
        
        subscriptionMapper.updateById(subscription);
        
        // Log cancellation
        auditLogService.logSubscriptionCancellation(userId, subscription.getId(), 
                subscription.getTier(), "User requested cancellation");
        
        log.info("Subscription cancelled for user {}: subscriptionId={}, expiryDate={}", 
                userId, subscription.getId(), subscription.getExpiryDate());
        
        return convertToDTO(subscription);
    }

    /**
     * Convert Subscription entity to DTO
     *
     * @param subscription Subscription entity
     * @return Subscription DTO
     */
    private SubscriptionDTO convertToDTO(Subscription subscription) {
        return SubscriptionDTO.builder()
                .id(subscription.getId())
                .userId(subscription.getUserId())
                .tier(subscription.getTier())
                .billingPeriod(subscription.getBillingPeriod())
                .status(subscription.getStatus())
                .paymentMethod(subscription.getPaymentMethod())
                .startDate(subscription.getStartDate())
                .expiryDate(subscription.getExpiryDate())
                .autoRenew(subscription.getAutoRenew())
                .productId(subscription.getProductId())
                .lastSyncedAt(subscription.getLastSyncedAt())
                .build();
    }
}
