package com.lightgallery.backend.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.lightgallery.backend.entity.Subscription;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import java.time.LocalDateTime;
import java.util.List;

/**
 * SubscriptionMapper
 * MyBatis-Plus mapper for Subscription entity with custom queries
 */
@Mapper
public interface SubscriptionMapper extends BaseMapper<Subscription> {

    /**
     * Find active subscription for a user
     * 
     * @param userId User ID
     * @return Active subscription if found, null otherwise
     */
    @Select("SELECT * FROM subscriptions WHERE user_id = #{userId} " +
            "AND status = 'active' AND deleted = 0 LIMIT 1")
    Subscription findActiveByUserId(@Param("userId") Long userId);

    /**
     * Find subscription by user ID and status
     * 
     * @param userId User ID
     * @param status Subscription status
     * @return Subscription if found, null otherwise
     */
    @Select("SELECT * FROM subscriptions WHERE user_id = #{userId} " +
            "AND status = #{status} AND deleted = 0 ORDER BY created_at DESC LIMIT 1")
    Subscription findByUserIdAndStatus(@Param("userId") Long userId,
                                      @Param("status") String status);

    /**
     * Find all subscriptions for a user
     * 
     * @param userId User ID
     * @return List of subscriptions
     */
    @Select("SELECT * FROM subscriptions WHERE user_id = #{userId} " +
            "AND deleted = 0 ORDER BY created_at DESC")
    List<Subscription> findAllByUserId(@Param("userId") Long userId);

    /**
     * Find subscription by original transaction ID
     * 
     * @param originalTransactionId Original transaction ID from payment platform
     * @return Subscription if found, null otherwise
     */
    @Select("SELECT * FROM subscriptions WHERE original_transaction_id = #{originalTransactionId} " +
            "AND deleted = 0 LIMIT 1")
    Subscription findByOriginalTransactionId(@Param("originalTransactionId") String originalTransactionId);

    /**
     * Update subscription status
     * 
     * @param subscriptionId Subscription ID
     * @param status New status
     * @return Number of rows affected
     */
    @Update("UPDATE subscriptions SET status = #{status}, updated_at = NOW() " +
            "WHERE id = #{subscriptionId} AND deleted = 0")
    int updateStatus(@Param("subscriptionId") Long subscriptionId,
                    @Param("status") String status);

    /**
     * Update subscription expiry date
     * 
     * @param subscriptionId Subscription ID
     * @param expiryDate New expiry date
     * @return Number of rows affected
     */
    @Update("UPDATE subscriptions SET expiry_date = #{expiryDate}, updated_at = NOW() " +
            "WHERE id = #{subscriptionId} AND deleted = 0")
    int updateExpiryDate(@Param("subscriptionId") Long subscriptionId,
                        @Param("expiryDate") LocalDateTime expiryDate);

    /**
     * Update subscription tier (for upgrades/downgrades)
     * 
     * @param subscriptionId Subscription ID
     * @param tier New tier
     * @return Number of rows affected
     */
    @Update("UPDATE subscriptions SET tier = #{tier}, updated_at = NOW() " +
            "WHERE id = #{subscriptionId} AND deleted = 0")
    int updateTier(@Param("subscriptionId") Long subscriptionId,
                  @Param("tier") String tier);

    /**
     * Update last synced timestamp
     * 
     * @param subscriptionId Subscription ID
     * @param lastSyncedAt Last synced timestamp
     * @return Number of rows affected
     */
    @Update("UPDATE subscriptions SET last_synced_at = #{lastSyncedAt}, updated_at = NOW() " +
            "WHERE id = #{subscriptionId} AND deleted = 0")
    int updateLastSyncedAt(@Param("subscriptionId") Long subscriptionId,
                          @Param("lastSyncedAt") LocalDateTime lastSyncedAt);

    /**
     * Find expired subscriptions that need status update
     * 
     * @return List of expired subscriptions
     */
    @Select("SELECT * FROM subscriptions WHERE status = 'active' " +
            "AND expiry_date < NOW() AND deleted = 0")
    List<Subscription> findExpiredActiveSubscriptions();

    /**
     * Check if user has active subscription
     * 
     * @param userId User ID
     * @return true if user has active subscription, false otherwise
     */
    @Select("SELECT COUNT(*) > 0 FROM subscriptions WHERE user_id = #{userId} " +
            "AND status = 'active' AND expiry_date > NOW() AND deleted = 0")
    boolean hasActiveSubscription(@Param("userId") Long userId);

    /**
     * Get subscription tier for user
     * 
     * @param userId User ID
     * @return Subscription tier (free, pro, max) or null if no active subscription
     */
    @Select("SELECT tier FROM subscriptions WHERE user_id = #{userId} " +
            "AND status = 'active' AND expiry_date > NOW() AND deleted = 0 LIMIT 1")
    String getUserTier(@Param("userId") Long userId);

    /**
     * Count subscriptions by tier
     * 
     * @param tier Subscription tier
     * @return Count of active subscriptions for the tier
     */
    @Select("SELECT COUNT(*) FROM subscriptions WHERE tier = #{tier} " +
            "AND status = 'active' AND deleted = 0")
    long countByTier(@Param("tier") String tier);
}
