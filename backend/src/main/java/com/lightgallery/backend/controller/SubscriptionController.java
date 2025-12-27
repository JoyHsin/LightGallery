package com.declutter.backend.controller;

import com.declutter.backend.dto.ApiResponse;
import com.declutter.backend.dto.PaymentVerificationRequest;
import com.declutter.backend.dto.SubscriptionDTO;
import com.declutter.backend.dto.SubscriptionProductDTO;
import com.declutter.backend.dto.SubscriptionSyncRequest;
import com.declutter.backend.service.SubscriptionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Subscription Controller
 * Handles subscription products, status, verification, and sync operations
 */
@Slf4j
@RestController
@RequestMapping("/subscription")
@RequiredArgsConstructor
@Tag(name = "Subscription", description = "Subscription management and payment verification endpoints")
public class SubscriptionController {

    private final SubscriptionService subscriptionService;

    /**
     * Get available subscription products
     * GET /api/v1/subscription/products
     *
     * @return List of available subscription products
     */
    @Operation(
            summary = "Get subscription products",
            description = "Retrieves all available subscription products including Free, Pro, and Max tiers " +
                    "with monthly and yearly billing options. No authentication required.",
            security = {}
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "Products retrieved successfully",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(value = """
                                    {
                                      "code": 200,
                                      "message": "Products retrieved successfully",
                                      "data": [
                                        {
                                          "productId": "com.declutter.pro.monthly",
                                          "tier": "pro",
                                          "billingPeriod": "monthly",
                                          "price": 10.00,
                                          "currency": "CNY",
                                          "localizedPrice": "¥10/月",
                                          "description": "Professional tier with all premium features",
                                          "features": ["Smart Clean", "Duplicate Detection", "Photo Enhancer"]
                                        },
                                        {
                                          "productId": "com.declutter.pro.yearly",
                                          "tier": "pro",
                                          "billingPeriod": "yearly",
                                          "price": 100.00,
                                          "currency": "CNY",
                                          "localizedPrice": "¥100/年",
                                          "description": "Professional tier yearly subscription",
                                          "features": ["Smart Clean", "Duplicate Detection", "Photo Enhancer"]
                                        }
                                      ]
                                    }
                                    """)
                    )
            )
    })
    @GetMapping("/products")
    public ResponseEntity<ApiResponse<List<SubscriptionProductDTO>>> getProducts() {
        log.info("Fetching available subscription products");
        
        try {
            List<SubscriptionProductDTO> products = subscriptionService.getAvailableProducts();
            log.info("Retrieved {} subscription products", products.size());
            return ResponseEntity.ok(ApiResponse.success("Products retrieved successfully", products));
        } catch (Exception e) {
            log.error("Failed to fetch subscription products: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(500, "Failed to fetch products: " + e.getMessage()));
        }
    }

    /**
     * Get current subscription status for authenticated user
     * GET /api/v1/subscription/status
     *
     * @param authentication Current authenticated user
     * @return Current subscription status
     */
    @Operation(
            summary = "Get subscription status",
            description = "Retrieves the current subscription status for the authenticated user including tier, " +
                    "expiry date, and auto-renewal status. Requires valid JWT token.",
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "Subscription status retrieved",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = SubscriptionDTO.class),
                            examples = @ExampleObject(value = """
                                    {
                                      "code": 200,
                                      "message": "Subscription status retrieved",
                                      "data": {
                                        "id": 1,
                                        "userId": 12345,
                                        "tier": "pro",
                                        "billingPeriod": "monthly",
                                        "status": "active",
                                        "paymentMethod": "apple_iap",
                                        "startDate": "2024-12-01T00:00:00",
                                        "expiryDate": "2025-01-01T00:00:00",
                                        "autoRenew": true,
                                        "productId": "com.declutter.pro.monthly",
                                        "lastSyncedAt": "2024-12-07T10:00:00"
                                      }
                                    }
                                    """)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "User not authenticated",
                    content = @Content(mediaType = "application/json")
            )
    })
    @GetMapping("/status")
    public ResponseEntity<ApiResponse<SubscriptionDTO>> getStatus(
            @Parameter(hidden = true) Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(401, "User not authenticated"));
        }

        Long userId = Long.parseLong(authentication.getName());
        log.info("Fetching subscription status for user: {}", userId);
        
        try {
            SubscriptionDTO subscription = subscriptionService.getCurrentSubscription(userId);
            log.info("Retrieved subscription status for user {}: tier={}, status={}", 
                    userId, subscription.getTier(), subscription.getStatus());
            return ResponseEntity.ok(ApiResponse.success("Subscription status retrieved", subscription));
        } catch (Exception e) {
            log.error("Failed to fetch subscription status for user {}: {}", userId, e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(500, "Failed to fetch subscription status: " + e.getMessage()));
        }
    }

    /**
     * Verify payment and update subscription
     * POST /api/v1/subscription/verify
     *
     * @param request Payment verification request
     * @param authentication Current authenticated user
     * @return Updated subscription status
     */
    @Operation(
            summary = "Verify payment and update subscription",
            description = "Verifies a payment transaction with the payment gateway (Apple IAP, WeChat Pay, or Alipay) " +
                    "and updates the user's subscription status. Creates an audit log entry for the transaction. " +
                    "Requires valid JWT token.",
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "Payment verified and subscription updated",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = SubscriptionDTO.class),
                            examples = @ExampleObject(value = """
                                    {
                                      "code": 200,
                                      "message": "Payment verified and subscription updated",
                                      "data": {
                                        "id": 1,
                                        "userId": 12345,
                                        "tier": "pro",
                                        "billingPeriod": "monthly",
                                        "status": "active",
                                        "paymentMethod": "apple_iap",
                                        "startDate": "2024-12-07T10:00:00",
                                        "expiryDate": "2025-01-07T10:00:00",
                                        "autoRenew": true,
                                        "productId": "com.declutter.pro.monthly",
                                        "lastSyncedAt": "2024-12-07T10:00:00"
                                      }
                                    }
                                    """)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "400",
                    description = "Payment verification failed",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(value = """
                                    {
                                      "code": 400,
                                      "message": "Payment verification failed: Invalid receipt",
                                      "data": null
                                    }
                                    """)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "User not authenticated",
                    content = @Content(mediaType = "application/json")
            )
    })
    @PostMapping("/verify")
    public ResponseEntity<ApiResponse<SubscriptionDTO>> verifyPayment(
            @Parameter(description = "Payment verification request with transaction details", required = true)
            @Valid @RequestBody PaymentVerificationRequest request,
            @Parameter(hidden = true) Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(401, "User not authenticated"));
        }

        Long userId = Long.parseLong(authentication.getName());
        log.info("Payment verification request for user {}: method={}, productId={}, transactionId={}", 
                userId, request.getPaymentMethod(), request.getProductId(), request.getTransactionId());
        
        try {
            SubscriptionDTO subscription = subscriptionService.verifyAndUpdateSubscription(userId, request);
            log.info("Payment verified and subscription updated for user {}: tier={}, status={}", 
                    userId, subscription.getTier(), subscription.getStatus());
            return ResponseEntity.ok(ApiResponse.success("Payment verified and subscription updated", subscription));
        } catch (Exception e) {
            log.error("Payment verification failed for user {}: {}", userId, e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(400, "Payment verification failed: " + e.getMessage()));
        }
    }

    /**
     * Sync subscription status with payment platform
     * POST /api/v1/subscription/sync
     *
     * @param request Subscription sync request
     * @param authentication Current authenticated user
     * @return Synced subscription status
     */
    @Operation(
            summary = "Sync subscription status",
            description = "Synchronizes the subscription status with the payment platform. " +
                    "Used for offline-to-online sync and periodic status updates. Requires valid JWT token.",
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "Subscription synced successfully",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = SubscriptionDTO.class)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "User not authenticated",
                    content = @Content(mediaType = "application/json")
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "500",
                    description = "Subscription sync failed",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(value = """
                                    {
                                      "code": 500,
                                      "message": "Subscription sync failed: Network error",
                                      "data": null
                                    }
                                    """)
                    )
            )
    })
    @PostMapping("/sync")
    public ResponseEntity<ApiResponse<SubscriptionDTO>> syncSubscription(
            @Parameter(description = "Subscription sync request", required = true)
            @Valid @RequestBody SubscriptionSyncRequest request,
            @Parameter(hidden = true) Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(401, "User not authenticated"));
        }

        Long userId = Long.parseLong(authentication.getName());
        log.info("Subscription sync request for user {}: platform={}, forceRefresh={}", 
                userId, request.getPlatform(), request.getForceRefresh());
        
        try {
            SubscriptionDTO subscription = subscriptionService.syncSubscription(userId, request);
            log.info("Subscription synced for user {}: tier={}, status={}", 
                    userId, subscription.getTier(), subscription.getStatus());
            return ResponseEntity.ok(ApiResponse.success("Subscription synced successfully", subscription));
        } catch (Exception e) {
            log.error("Subscription sync failed for user {}: {}", userId, e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(500, "Subscription sync failed: " + e.getMessage()));
        }
    }

    /**
     * Calculate prorated pricing for subscription upgrade
     * POST /api/v1/subscription/upgrade/calculate
     *
     * @param targetTier Target subscription tier
     * @param authentication Current authenticated user
     * @return Prorated pricing information
     */
    @Operation(
            summary = "Calculate subscription upgrade",
            description = "Calculates prorated pricing for upgrading from current subscription tier to a higher tier. " +
                    "Takes into account remaining billing period. Requires valid JWT token.",
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "Upgrade calculation completed",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = SubscriptionDTO.class)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "400",
                    description = "Invalid upgrade request",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(value = """
                                    {
                                      "code": 400,
                                      "message": "Upgrade calculation failed: Cannot downgrade from max to pro",
                                      "data": null
                                    }
                                    """)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "User not authenticated",
                    content = @Content(mediaType = "application/json")
            )
    })
    @PostMapping("/upgrade/calculate")
    public ResponseEntity<ApiResponse<SubscriptionDTO>> calculateUpgrade(
            @Parameter(description = "Target subscription tier (pro or max)", required = true)
            @RequestParam String targetTier,
            @Parameter(hidden = true) Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(401, "User not authenticated"));
        }

        Long userId = Long.parseLong(authentication.getName());
        log.info("Calculate upgrade request for user {}: targetTier={}", userId, targetTier);
        
        try {
            SubscriptionDTO upgradeInfo = subscriptionService.calculateUpgrade(userId, targetTier);
            log.info("Upgrade calculation completed for user {}: targetTier={}", userId, targetTier);
            return ResponseEntity.ok(ApiResponse.success("Upgrade calculation completed", upgradeInfo));
        } catch (Exception e) {
            log.error("Upgrade calculation failed for user {}: {}", userId, e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(400, "Upgrade calculation failed: " + e.getMessage()));
        }
    }

    /**
     * Cancel subscription
     * POST /api/v1/subscription/cancel
     * Note: For iOS, this returns guidance to App Store settings
     * Subscription remains active until current billing period ends
     *
     * @param authentication Current authenticated user
     * @return Cancellation guidance and updated subscription status
     */
    @Operation(
            summary = "Cancel subscription",
            description = "Cancels the user's subscription. For iOS users, provides guidance to cancel via App Store settings. " +
                    "Subscription access remains active until the current billing period ends. Requires valid JWT token.",
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "Subscription cancelled",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = SubscriptionDTO.class),
                            examples = @ExampleObject(value = """
                                    {
                                      "code": 200,
                                      "message": "Subscription cancelled. Access will continue until 2025-01-07T10:00:00",
                                      "data": {
                                        "id": 1,
                                        "userId": 12345,
                                        "tier": "pro",
                                        "billingPeriod": "monthly",
                                        "status": "cancelled",
                                        "paymentMethod": "apple_iap",
                                        "startDate": "2024-12-07T10:00:00",
                                        "expiryDate": "2025-01-07T10:00:00",
                                        "autoRenew": false,
                                        "productId": "com.declutter.pro.monthly",
                                        "lastSyncedAt": "2024-12-07T10:00:00"
                                      }
                                    }
                                    """)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "400",
                    description = "Cancellation failed",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(value = """
                                    {
                                      "code": 400,
                                      "message": "Subscription cancellation failed: No active subscription",
                                      "data": null
                                    }
                                    """)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "User not authenticated",
                    content = @Content(mediaType = "application/json")
            )
    })
    @PostMapping("/cancel")
    public ResponseEntity<ApiResponse<SubscriptionDTO>> cancelSubscription(
            @Parameter(hidden = true) Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(401, "User not authenticated"));
        }

        Long userId = Long.parseLong(authentication.getName());
        log.info("Cancel subscription request for user {}", userId);
        
        try {
            SubscriptionDTO subscription = subscriptionService.cancelSubscription(userId);
            log.info("Subscription cancelled for user {}: status={}, expiryDate={}", 
                    userId, subscription.getStatus(), subscription.getExpiryDate());
            return ResponseEntity.ok(ApiResponse.success(
                    "Subscription cancelled. Access will continue until " + subscription.getExpiryDate(), 
                    subscription));
        } catch (Exception e) {
            log.error("Subscription cancellation failed for user {}: {}", userId, e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(400, "Subscription cancellation failed: " + e.getMessage()));
        }
    }
}
