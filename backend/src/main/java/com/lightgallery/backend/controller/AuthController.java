package com.declutter.backend.controller;

import com.declutter.backend.dto.ApiResponse;
import com.declutter.backend.dto.AuthResponse;
import com.declutter.backend.dto.OAuthExchangeRequest;
import com.declutter.backend.dto.RefreshTokenRequest;
import com.declutter.backend.service.AuthService;
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

/**
 * Authentication Controller
 * Handles user authentication, token management, and account operations
 */
@Slf4j
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@Tag(name = "Authentication", description = "User authentication and token management endpoints")
public class AuthController {

    private final AuthService authService;

    /**
     * Exchange OAuth token for app JWT token
     * POST /api/v1/auth/oauth/exchange
     *
     * @param request OAuth exchange request containing provider and code
     * @return AuthResponse with JWT tokens and user information
     */
    @Operation(
            summary = "Exchange OAuth token for JWT",
            description = "Exchanges an OAuth authorization code from a third-party provider (Apple, WeChat, Alipay) " +
                    "for application JWT tokens. Creates a new user account if this is the first login.",
            security = {}
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "Authentication successful",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = AuthResponse.class),
                            examples = @ExampleObject(value = """
                                    {
                                      "code": 200,
                                      "message": "Authentication successful",
                                      "data": {
                                        "userId": 12345,
                                        "displayName": "John Doe",
                                        "email": "john@example.com",
                                        "avatarUrl": "https://example.com/avatar.jpg",
                                        "authProvider": "apple",
                                        "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                                        "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                                        "tokenType": "Bearer",
                                        "expiresAt": "2024-12-08T10:00:00",
                                        "refreshExpiresAt": "2024-12-15T10:00:00"
                                      }
                                    }
                                    """)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "400",
                    description = "Invalid OAuth code or provider",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(value = """
                                    {
                                      "code": 400,
                                      "message": "Authentication failed: Invalid authorization code",
                                      "data": null
                                    }
                                    """)
                    )
            )
    })
    @PostMapping("/oauth/exchange")
    public ResponseEntity<ApiResponse<AuthResponse>> exchangeOAuthToken(
            @Parameter(description = "OAuth exchange request with provider and authorization code", required = true)
            @Valid @RequestBody OAuthExchangeRequest request) {
        log.info("OAuth token exchange request for provider: {}", request.getProvider());
        
        try {
            AuthResponse response = authService.exchangeOAuthToken(request);
            log.info("OAuth token exchange successful for user: {}", response.getUserId());
            return ResponseEntity.ok(ApiResponse.success("Authentication successful", response));
        } catch (Exception e) {
            log.error("OAuth token exchange failed: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(400, "Authentication failed: " + e.getMessage()));
        }
    }

    /**
     * Refresh access token using refresh token
     * POST /api/v1/auth/token/refresh
     *
     * @param request Refresh token request
     * @return AuthResponse with new JWT tokens
     */
    @Operation(
            summary = "Refresh access token",
            description = "Refreshes an expired access token using a valid refresh token. " +
                    "Returns new access and refresh tokens.",
            security = {}
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "Token refreshed successfully",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = AuthResponse.class)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "Invalid or expired refresh token",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(value = """
                                    {
                                      "code": 401,
                                      "message": "Token refresh failed: Refresh token expired",
                                      "data": null
                                    }
                                    """)
                    )
            )
    })
    @PostMapping("/token/refresh")
    public ResponseEntity<ApiResponse<AuthResponse>> refreshToken(
            @Parameter(description = "Refresh token request", required = true)
            @Valid @RequestBody RefreshTokenRequest request) {
        log.info("Token refresh request");
        
        try {
            AuthResponse response = authService.refreshToken(request.getRefreshToken());
            log.info("Token refresh successful for user: {}", response.getUserId());
            return ResponseEntity.ok(ApiResponse.success("Token refreshed successfully", response));
        } catch (Exception e) {
            log.error("Token refresh failed: {}", e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(401, "Token refresh failed: " + e.getMessage()));
        }
    }

    /**
     * Logout user and invalidate tokens
     * POST /api/v1/auth/logout
     *
     * @param authentication Current authenticated user
     * @return Success response
     */
    @Operation(
            summary = "Logout user",
            description = "Logs out the current user and invalidates all authentication tokens. " +
                    "Requires valid JWT token in Authorization header.",
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "Logout successful",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(value = """
                                    {
                                      "code": 200,
                                      "message": "Logout successful",
                                      "data": null
                                    }
                                    """)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "User not authenticated",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(value = """
                                    {
                                      "code": 401,
                                      "message": "User not authenticated",
                                      "data": null
                                    }
                                    """)
                    )
            )
    })
    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(
            @Parameter(hidden = true) Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(401, "User not authenticated"));
        }

        Long userId = Long.parseLong(authentication.getName());
        log.info("Logout request for user: {}", userId);
        
        try {
            authService.logout(userId);
            log.info("Logout successful for user: {}", userId);
            return ResponseEntity.ok(ApiResponse.success("Logout successful", null));
        } catch (Exception e) {
            log.error("Logout failed for user {}: {}", userId, e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(500, "Logout failed: " + e.getMessage()));
        }
    }

    /**
     * Delete user account and all associated data
     * DELETE /api/v1/auth/account
     *
     * @param authentication Current authenticated user
     * @return Success response
     */
    @Operation(
            summary = "Delete user account",
            description = "Permanently deletes the user account and all associated data including subscriptions and transactions. " +
                    "This action cannot be undone. Requires valid JWT token in Authorization header.",
            security = @SecurityRequirement(name = "bearerAuth")
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "Account deleted successfully",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(value = """
                                    {
                                      "code": 200,
                                      "message": "Account deleted successfully",
                                      "data": null
                                    }
                                    """)
                    )
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "401",
                    description = "User not authenticated",
                    content = @Content(mediaType = "application/json")
            ),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "500",
                    description = "Account deletion failed",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(value = """
                                    {
                                      "code": 500,
                                      "message": "Account deletion failed: Database error",
                                      "data": null
                                    }
                                    """)
                    )
            )
    })
    @DeleteMapping("/account")
    public ResponseEntity<ApiResponse<Void>> deleteAccount(
            @Parameter(hidden = true) Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(401, "User not authenticated"));
        }

        Long userId = Long.parseLong(authentication.getName());
        log.info("Account deletion request for user: {}", userId);
        
        try {
            authService.deleteAccount(userId);
            log.info("Account deletion successful for user: {}", userId);
            return ResponseEntity.ok(ApiResponse.success("Account deleted successfully", null));
        } catch (Exception e) {
            log.error("Account deletion failed for user {}: {}", userId, e.getMessage(), e);
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(500, "Account deletion failed: " + e.getMessage()));
        }
    }
}
