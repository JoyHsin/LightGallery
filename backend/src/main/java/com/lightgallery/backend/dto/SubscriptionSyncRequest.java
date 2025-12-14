package com.lightgallery.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Subscription Sync Request
 * Used to sync subscription status from client
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SubscriptionSyncRequest {

    /**
     * Platform: ios, android, web
     */
    @NotBlank(message = "Platform is required")
    private String platform;

    /**
     * Last known subscription status on client
     */
    private String lastKnownStatus;

    /**
     * Force refresh from payment platform
     */
    private Boolean forceRefresh;
}
