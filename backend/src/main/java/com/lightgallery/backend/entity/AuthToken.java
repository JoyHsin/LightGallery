package com.lightgallery.backend.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * AuthToken Entity
 * Stores JWT tokens for session management
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("auth_tokens")
public class AuthToken extends BaseEntity {

    /**
     * Token ID (Primary Key)
     */
    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * User ID (Foreign Key)
     */
    @TableField("user_id")
    private Long userId;

    /**
     * JWT access token
     */
    @TableField("access_token")
    private String accessToken;

    /**
     * JWT refresh token
     */
    @TableField("refresh_token")
    private String refreshToken;

    /**
     * Token type (e.g., "Bearer")
     */
    @TableField("token_type")
    private String tokenType;

    /**
     * Access token expiration time
     */
    @TableField("expires_at")
    private LocalDateTime expiresAt;

    /**
     * Refresh token expiration time
     */
    @TableField("refresh_expires_at")
    private LocalDateTime refreshExpiresAt;

    /**
     * Device information
     */
    @TableField("device_info")
    private String deviceInfo;

    /**
     * IP address
     */
    @TableField("ip_address")
    private String ipAddress;
}
