package com.declutter.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * Refresh Token Request
 * Used to refresh an expired access token
 */
@Data
public class RefreshTokenRequest {

    /**
     * Refresh token
     */
    @NotBlank(message = "Refresh token is required")
    private String refreshToken;
}
