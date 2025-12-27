package com.declutter.backend.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.declutter.backend.entity.Transaction;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import java.time.LocalDateTime;
import java.util.List;

/**
 * TransactionMapper
 * MyBatis-Plus mapper for Transaction entity (audit log)
 */
@Mapper
public interface TransactionMapper extends BaseMapper<Transaction> {

    /**
     * Find transaction by platform transaction ID
     * 
     * @param platformTransactionId Transaction ID from payment platform
     * @return Transaction if found, null otherwise
     */
    @Select("SELECT * FROM transactions WHERE platform_transaction_id = #{platformTransactionId} " +
            "AND deleted = 0 LIMIT 1")
    Transaction findByPlatformTransactionId(@Param("platformTransactionId") String platformTransactionId);

    /**
     * Find all transactions for a user
     * 
     * @param userId User ID
     * @return List of transactions ordered by creation date (newest first)
     */
    @Select("SELECT * FROM transactions WHERE user_id = #{userId} " +
            "AND deleted = 0 ORDER BY created_at DESC")
    List<Transaction> findAllByUserId(@Param("userId") Long userId);

    /**
     * Find transactions for a subscription
     * 
     * @param subscriptionId Subscription ID
     * @return List of transactions ordered by creation date (newest first)
     */
    @Select("SELECT * FROM transactions WHERE subscription_id = #{subscriptionId} " +
            "AND deleted = 0 ORDER BY created_at DESC")
    List<Transaction> findAllBySubscriptionId(@Param("subscriptionId") Long subscriptionId);

    /**
     * Find transactions by verification status
     * 
     * @param verificationStatus Verification status (pending, verified, failed)
     * @return List of transactions
     */
    @Select("SELECT * FROM transactions WHERE verification_status = #{verificationStatus} " +
            "AND deleted = 0 ORDER BY created_at DESC")
    List<Transaction> findByVerificationStatus(@Param("verificationStatus") String verificationStatus);

    /**
     * Find transactions by type and user
     * 
     * @param userId User ID
     * @param transactionType Transaction type
     * @return List of transactions
     */
    @Select("SELECT * FROM transactions WHERE user_id = #{userId} " +
            "AND transaction_type = #{transactionType} AND deleted = 0 ORDER BY created_at DESC")
    List<Transaction> findByUserIdAndType(@Param("userId") Long userId,
                                         @Param("transactionType") String transactionType);

    /**
     * Find transactions within date range
     * 
     * @param userId User ID
     * @param startDate Start date
     * @param endDate End date
     * @return List of transactions
     */
    @Select("SELECT * FROM transactions WHERE user_id = #{userId} " +
            "AND created_at BETWEEN #{startDate} AND #{endDate} " +
            "AND deleted = 0 ORDER BY created_at DESC")
    List<Transaction> findByUserIdAndDateRange(@Param("userId") Long userId,
                                              @Param("startDate") LocalDateTime startDate,
                                              @Param("endDate") LocalDateTime endDate);

    /**
     * Update verification status
     * 
     * @param transactionId Transaction ID
     * @param verificationStatus New verification status
     * @param verificationMessage Verification message
     * @return Number of rows affected
     */
    @Update("UPDATE transactions SET verification_status = #{verificationStatus}, " +
            "verification_message = #{verificationMessage}, updated_at = NOW() " +
            "WHERE id = #{transactionId} AND deleted = 0")
    int updateVerificationStatus(@Param("transactionId") Long transactionId,
                                 @Param("verificationStatus") String verificationStatus,
                                 @Param("verificationMessage") String verificationMessage);

    /**
     * Check if transaction exists by platform transaction ID
     * 
     * @param platformTransactionId Transaction ID from payment platform
     * @return true if exists, false otherwise
     */
    @Select("SELECT COUNT(*) > 0 FROM transactions " +
            "WHERE platform_transaction_id = #{platformTransactionId} AND deleted = 0")
    boolean existsByPlatformTransactionId(@Param("platformTransactionId") String platformTransactionId);

    /**
     * Count transactions by payment method
     * 
     * @param paymentMethod Payment method
     * @return Count of transactions
     */
    @Select("SELECT COUNT(*) FROM transactions WHERE payment_method = #{paymentMethod} " +
            "AND deleted = 0")
    long countByPaymentMethod(@Param("paymentMethod") String paymentMethod);

    /**
     * Count verified transactions for a user
     * 
     * @param userId User ID
     * @return Count of verified transactions
     */
    @Select("SELECT COUNT(*) FROM transactions WHERE user_id = #{userId} " +
            "AND verification_status = 'verified' AND deleted = 0")
    long countVerifiedByUserId(@Param("userId") Long userId);

    /**
     * Find pending verification transactions (for retry jobs)
     * 
     * @param olderThan Timestamp threshold
     * @return List of pending transactions
     */
    @Select("SELECT * FROM transactions WHERE verification_status = 'pending' " +
            "AND created_at < #{olderThan} AND deleted = 0 ORDER BY created_at ASC")
    List<Transaction> findPendingVerificationOlderThan(@Param("olderThan") LocalDateTime olderThan);
}
