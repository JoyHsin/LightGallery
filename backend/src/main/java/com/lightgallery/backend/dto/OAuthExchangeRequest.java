package com.declutter.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * OAuth Token Exchange Request
 * Used to exchange OAuth provider token for app JWT token
 */
@Data
public class OAuthExchangeRequest {

    /**
     * OAuth provider: apple, wechat, alipay
     */
    @NotBlank(message = "Provider is required")
    private String provider;

    /**
     * OAuth authorization code or token from provider
     */
    @NotBlank(message = "Code is required")
    private String code;

    /**
     * User email (optional, from OAuth provider)
     */
    private String email;

    /**
     * User display name (optional, from OAuth provider)
     */
    private String displayName;

    /**
     * User avatar URL (optional, from OAuth provider)
     */
    private String avatarUrl;

    /**
     * Provider user ID
     */
    private String providerUserId;

    /**
     * Device information
     */
    private String deviceInfo;

    /**
     * IP address
     */
    private String ipAddress;
}
