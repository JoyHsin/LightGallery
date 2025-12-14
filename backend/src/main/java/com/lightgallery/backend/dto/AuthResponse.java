package com.lightgallery.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Authentication Response
 * Contains JWT tokens and user information
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {

    /**
     * User ID
     */
    private Long userId;

    /**
     * User display name
     */
    private String displayName;

    /**
     * User email
     */
    private String email;

    /**
     * User avatar URL
     */
    private String avatarUrl;

    /**
     * OAuth provider
     */
    private String authProvider;

    /**
     * JWT access token
     */
    private String accessToken;

    /**
     * JWT refresh token
     */
    private String refreshToken;

    /**
     * Token type (e.g., "Bearer")
     */
    private String tokenType;

    /**
     * Access token expiration time
     */
    private LocalDateTime expiresAt;

    /**
     * Refresh token expiration time
     */
    private LocalDateTime refreshExpiresAt;
}
