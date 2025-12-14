package com.lightgallery.backend.service;

import com.lightgallery.backend.dto.AuthResponse;
import com.lightgallery.backend.dto.OAuthExchangeRequest;
import com.lightgallery.backend.entity.AuthToken;
import com.lightgallery.backend.entity.User;
import com.lightgallery.backend.mapper.AuthTokenMapper;
import com.lightgallery.backend.mapper.UserMapper;
import com.lightgallery.backend.util.JwtUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * Authentication Service
 * Handles OAuth token exchange, JWT generation, token refresh, and account management
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserMapper userMapper;
    private final AuthTokenMapper authTokenMapper;
    private final JwtUtil jwtUtil;
    private final OAuthProviderService oauthProviderService;
    private final AuditLogService auditLogService;

    /**
     * Exchange OAuth token for app JWT token
     * Validates OAuth token with provider, creates or updates user, generates JWT tokens
     *
     * @param request OAuth exchange request
     * @return AuthResponse with JWT tokens and user info
     */
    @Transactional
    public AuthResponse exchangeOAuthToken(OAuthExchangeRequest request) {
        log.info("Exchanging OAuth token for provider: {}", request.getProvider());

        // Validate OAuth token with provider
        boolean isValid = oauthProviderService.validateOAuthToken(
                request.getProvider(),
                request.getCode(),
                request.getProviderUserId()
        );

        if (!isValid) {
            // Log failed authentication
            auditLogService.logAuthenticationEvent(null, request.getProvider(), false);
            throw new RuntimeException("Invalid OAuth token");
        }

        // Find or create user
        User user = findOrCreateUser(request);
        
        // Log successful authentication
        auditLogService.logAuthenticationEvent(user.getId(), request.getProvider(), true);

        // Update last login time
        user.setLastLoginAt(LocalDateTime.now());
        userMapper.updateById(user);

        // Generate JWT tokens
        String accessToken = jwtUtil.generateAccessToken(user.getId());
        String refreshToken = jwtUtil.generateRefreshToken(user.getId());

        // Calculate expiration times
        LocalDateTime accessTokenExpiry = LocalDateTime.now()
                .plusSeconds(jwtUtil.getAccessTokenExpiration() / 1000);
        LocalDateTime refreshTokenExpiry = LocalDateTime.now()
                .plusSeconds(jwtUtil.getRefreshTokenExpiration() / 1000);

        // Save tokens to database
        saveAuthToken(user.getId(), accessToken, refreshToken, 
                accessTokenExpiry, refreshTokenExpiry, request);

        // Build response
        return AuthResponse.builder()
                .userId(user.getId())
                .displayName(user.getDisplayName())
                .email(user.getEmail())
                .avatarUrl(user.getAvatarUrl())
                .authProvider(user.getAuthProvider())
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresAt(accessTokenExpiry)
                .refreshExpiresAt(refreshTokenExpiry)
                .build();
    }

    /**
     * Refresh access token using refresh token
     *
     * @param refreshToken Refresh token
     * @return AuthResponse with new JWT tokens
     */
    @Transactional
    public AuthResponse refreshToken(String refreshToken) {
        log.info("Refreshing access token");

        // Validate refresh token
        if (!jwtUtil.validateToken(refreshToken)) {
            throw new RuntimeException("Invalid or expired refresh token");
        }

        // Check token type
        String tokenType = jwtUtil.getTokenType(refreshToken);
        if (!"refresh".equals(tokenType)) {
            throw new RuntimeException("Invalid token type");
        }

        // Get user ID from token
        Long userId = jwtUtil.getUserIdFromToken(refreshToken);

        // Verify token exists in database
        LambdaQueryWrapper<AuthToken> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(AuthToken::getUserId, userId)
                .eq(AuthToken::getRefreshToken, refreshToken)
                .gt(AuthToken::getRefreshExpiresAt, LocalDateTime.now());

        AuthToken authToken = authTokenMapper.selectOne(queryWrapper);
        if (authToken == null) {
            throw new RuntimeException("Refresh token not found or expired");
        }

        // Get user
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new RuntimeException("User not found");
        }

        // Generate new tokens
        String newAccessToken = jwtUtil.generateAccessToken(userId);
        String newRefreshToken = jwtUtil.generateRefreshToken(userId);

        // Calculate expiration times
        LocalDateTime accessTokenExpiry = LocalDateTime.now()
                .plusSeconds(jwtUtil.getAccessTokenExpiration() / 1000);
        LocalDateTime refreshTokenExpiry = LocalDateTime.now()
                .plusSeconds(jwtUtil.getRefreshTokenExpiration() / 1000);

        // Update tokens in database
        authToken.setAccessToken(newAccessToken);
        authToken.setRefreshToken(newRefreshToken);
        authToken.setExpiresAt(accessTokenExpiry);
        authToken.setRefreshExpiresAt(refreshTokenExpiry);
        authToken.setUpdatedAt(LocalDateTime.now());
        authTokenMapper.updateById(authToken);

        // Build response
        return AuthResponse.builder()
                .userId(user.getId())
                .displayName(user.getDisplayName())
                .email(user.getEmail())
                .avatarUrl(user.getAvatarUrl())
                .authProvider(user.getAuthProvider())
                .accessToken(newAccessToken)
                .refreshToken(newRefreshToken)
                .tokenType("Bearer")
                .expiresAt(accessTokenExpiry)
                .refreshExpiresAt(refreshTokenExpiry)
                .build();
    }

    /**
     * Logout user and invalidate tokens
     *
     * @param userId User ID
     */
    @Transactional
    public void logout(Long userId) {
        log.info("Logging out user: {}", userId);

        // Delete all auth tokens for user
        LambdaQueryWrapper<AuthToken> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(AuthToken::getUserId, userId);
        authTokenMapper.delete(queryWrapper);

        log.info("User {} logged out successfully", userId);
    }

    /**
     * Delete user account and all associated data
     *
     * @param userId User ID
     */
    @Transactional
    public void deleteAccount(Long userId) {
        log.info("Deleting account for user: {}", userId);

        // Delete all auth tokens
        LambdaQueryWrapper<AuthToken> tokenQueryWrapper = new LambdaQueryWrapper<>();
        tokenQueryWrapper.eq(AuthToken::getUserId, userId);
        authTokenMapper.delete(tokenQueryWrapper);

        // Soft delete user (using MyBatis-Plus logic delete)
        userMapper.deleteById(userId);
        
        // Log account deletion
        auditLogService.logAccountDeletion(userId, "User requested account deletion");

        log.info("Account deleted successfully for user: {}", userId);
    }

    /**
     * Find or create user based on OAuth provider information
     *
     * @param request OAuth exchange request
     * @return User entity
     */
    private User findOrCreateUser(OAuthExchangeRequest request) {
        // Try to find existing user by provider and provider user ID
        LambdaQueryWrapper<User> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(User::getAuthProvider, request.getProvider())
                .eq(User::getProviderUserId, request.getProviderUserId());

        User user = userMapper.selectOne(queryWrapper);

        if (user == null) {
            // Create new user
            user = new User();
            user.setAuthProvider(request.getProvider());
            user.setProviderUserId(request.getProviderUserId());
            user.setDisplayName(request.getDisplayName());
            user.setEmail(request.getEmail());
            user.setAvatarUrl(request.getAvatarUrl());
            user.setLastLoginAt(LocalDateTime.now());
            user.setCreatedAt(LocalDateTime.now());
            user.setUpdatedAt(LocalDateTime.now());

            userMapper.insert(user);
            log.info("Created new user: {}", user.getId());
        } else {
            // Update existing user information if provided
            boolean updated = false;
            if (request.getDisplayName() != null && !request.getDisplayName().equals(user.getDisplayName())) {
                user.setDisplayName(request.getDisplayName());
                updated = true;
            }
            if (request.getEmail() != null && !request.getEmail().equals(user.getEmail())) {
                user.setEmail(request.getEmail());
                updated = true;
            }
            if (request.getAvatarUrl() != null && !request.getAvatarUrl().equals(user.getAvatarUrl())) {
                user.setAvatarUrl(request.getAvatarUrl());
                updated = true;
            }

            if (updated) {
                user.setUpdatedAt(LocalDateTime.now());
                userMapper.updateById(user);
                log.info("Updated user information: {}", user.getId());
            }
        }

        return user;
    }

    /**
     * Save auth token to database
     *
     * @param userId User ID
     * @param accessToken Access token
     * @param refreshToken Refresh token
     * @param accessTokenExpiry Access token expiration
     * @param refreshTokenExpiry Refresh token expiration
     * @param request OAuth exchange request
     */
    private void saveAuthToken(Long userId, String accessToken, String refreshToken,
                               LocalDateTime accessTokenExpiry, LocalDateTime refreshTokenExpiry,
                               OAuthExchangeRequest request) {
        // Delete old tokens for this user
        LambdaQueryWrapper<AuthToken> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(AuthToken::getUserId, userId);
        authTokenMapper.delete(queryWrapper);

        // Create new auth token
        AuthToken authToken = new AuthToken();
        authToken.setUserId(userId);
        authToken.setAccessToken(accessToken);
        authToken.setRefreshToken(refreshToken);
        authToken.setTokenType("Bearer");
        authToken.setExpiresAt(accessTokenExpiry);
        authToken.setRefreshExpiresAt(refreshTokenExpiry);
        authToken.setDeviceInfo(request.getDeviceInfo());
        authToken.setIpAddress(request.getIpAddress());
        authToken.setCreatedAt(LocalDateTime.now());
        authToken.setUpdatedAt(LocalDateTime.now());

        authTokenMapper.insert(authToken);
        log.info("Saved auth token for user: {}", userId);
    }
}
