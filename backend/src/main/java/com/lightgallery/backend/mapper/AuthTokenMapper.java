package com.lightgallery.backend.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.lightgallery.backend.entity.AuthToken;
import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.time.LocalDateTime;
import java.util.List;

/**
 * AuthTokenMapper
 * MyBatis-Plus mapper for AuthToken entity with custom queries
 */
@Mapper
public interface AuthTokenMapper extends BaseMapper<AuthToken> {

    /**
     * Find auth token by access token
     * 
     * @param accessToken JWT access token
     * @return AuthToken if found, null otherwise
     */
    @Select("SELECT * FROM auth_tokens WHERE access_token = #{accessToken} AND deleted = 0")
    AuthToken findByAccessToken(@Param("accessToken") String accessToken);

    /**
     * Find auth token by refresh token
     * 
     * @param refreshToken JWT refresh token
     * @return AuthToken if found, null otherwise
     */
    @Select("SELECT * FROM auth_tokens WHERE refresh_token = #{refreshToken} AND deleted = 0")
    AuthToken findByRefreshToken(@Param("refreshToken") String refreshToken);

    /**
     * Find all active tokens for a user
     * 
     * @param userId User ID
     * @return List of active auth tokens
     */
    @Select("SELECT * FROM auth_tokens WHERE user_id = #{userId} " +
            "AND expires_at > NOW() AND deleted = 0 ORDER BY created_at DESC")
    List<AuthToken> findActiveTokensByUserId(@Param("userId") Long userId);

    /**
     * Find all tokens for a user (including expired)
     * 
     * @param userId User ID
     * @return List of all auth tokens
     */
    @Select("SELECT * FROM auth_tokens WHERE user_id = #{userId} " +
            "AND deleted = 0 ORDER BY created_at DESC")
    List<AuthToken> findAllTokensByUserId(@Param("userId") Long userId);

    /**
     * Delete all tokens for a user (for logout)
     * 
     * @param userId User ID
     * @return Number of rows affected
     */
    @Delete("UPDATE auth_tokens SET deleted = 1, updated_at = NOW() " +
            "WHERE user_id = #{userId}")
    int deleteAllByUserId(@Param("userId") Long userId);

    /**
     * Delete expired tokens (cleanup job)
     * 
     * @param expiryThreshold Expiry threshold timestamp
     * @return Number of rows affected
     */
    @Delete("UPDATE auth_tokens SET deleted = 1, updated_at = NOW() " +
            "WHERE expires_at < #{expiryThreshold}")
    int deleteExpiredTokens(@Param("expiryThreshold") LocalDateTime expiryThreshold);

    /**
     * Check if access token is valid (exists and not expired)
     * 
     * @param accessToken JWT access token
     * @return true if valid, false otherwise
     */
    @Select("SELECT COUNT(*) > 0 FROM auth_tokens WHERE access_token = #{accessToken} " +
            "AND expires_at > NOW() AND deleted = 0")
    boolean isAccessTokenValid(@Param("accessToken") String accessToken);

    /**
     * Check if refresh token is valid (exists and not expired)
     * 
     * @param refreshToken JWT refresh token
     * @return true if valid, false otherwise
     */
    @Select("SELECT COUNT(*) > 0 FROM auth_tokens WHERE refresh_token = #{refreshToken} " +
            "AND refresh_expires_at > NOW() AND deleted = 0")
    boolean isRefreshTokenValid(@Param("refreshToken") String refreshToken);
}
