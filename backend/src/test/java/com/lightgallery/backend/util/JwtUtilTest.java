package com.declutter.backend.util;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for JwtUtil
 * Tests JWT token generation and validation
 */
class JwtUtilTest {

    private JwtUtil jwtUtil;

    @BeforeEach
    void setUp() {
        jwtUtil = new JwtUtil();
        
        // Set test values using reflection
        ReflectionTestUtils.setField(jwtUtil, "secret", "test-secret-key-for-jwt-token-generation-must-be-long-enough");
        ReflectionTestUtils.setField(jwtUtil, "expiration", 604800000L); // 7 days
        ReflectionTestUtils.setField(jwtUtil, "refreshExpiration", 2592000000L); // 30 days
    }

    @Test
    void testGenerateAccessToken_Success() {
        // Given
        Long userId = 1L;

        // When
        String token = jwtUtil.generateAccessToken(userId);

        // Then
        assertNotNull(token);
        assertFalse(token.isEmpty());
        assertTrue(token.split("\\.").length == 3); // JWT has 3 parts
    }

    @Test
    void testGenerateRefreshToken_Success() {
        // Given
        Long userId = 1L;

        // When
        String token = jwtUtil.generateRefreshToken(userId);

        // Then
        assertNotNull(token);
        assertFalse(token.isEmpty());
        assertTrue(token.split("\\.").length == 3);
    }

    @Test
    void testGetUserIdFromToken_Success() {
        // Given
        Long userId = 123L;
        String token = jwtUtil.generateAccessToken(userId);

        // When
        Long extractedUserId = jwtUtil.getUserIdFromToken(token);

        // Then
        assertEquals(userId, extractedUserId);
    }

    @Test
    void testGetTokenType_AccessToken() {
        // Given
        Long userId = 1L;
        String token = jwtUtil.generateAccessToken(userId);

        // When
        String tokenType = jwtUtil.getTokenType(token);

        // Then
        assertEquals("access", tokenType);
    }

    @Test
    void testGetTokenType_RefreshToken() {
        // Given
        Long userId = 1L;
        String token = jwtUtil.generateRefreshToken(userId);

        // When
        String tokenType = jwtUtil.getTokenType(token);

        // Then
        assertEquals("refresh", tokenType);
    }

    @Test
    void testValidateToken_ValidToken_ReturnsTrue() {
        // Given
        Long userId = 1L;
        String token = jwtUtil.generateAccessToken(userId);

        // When
        boolean isValid = jwtUtil.validateToken(token);

        // Then
        assertTrue(isValid);
    }

    @Test
    void testValidateToken_InvalidToken_ReturnsFalse() {
        // Given
        String invalidToken = "invalid.token.here";

        // When
        boolean isValid = jwtUtil.validateToken(invalidToken);

        // Then
        assertFalse(isValid);
    }

    @Test
    void testValidateToken_ExpiredToken_ReturnsFalse() {
        // Given
        JwtUtil shortLivedJwtUtil = new JwtUtil();
        ReflectionTestUtils.setField(shortLivedJwtUtil, "secret", "test-secret-key-for-jwt-token-generation-must-be-long-enough");
        ReflectionTestUtils.setField(shortLivedJwtUtil, "expiration", -1000L); // Already expired
        ReflectionTestUtils.setField(shortLivedJwtUtil, "refreshExpiration", 2592000000L);

        String expiredToken = shortLivedJwtUtil.generateAccessToken(1L);

        // When
        boolean isValid = jwtUtil.validateToken(expiredToken);

        // Then
        assertFalse(isValid);
    }

    @Test
    void testGetExpirationFromToken_Success() {
        // Given
        Long userId = 1L;
        String token = jwtUtil.generateAccessToken(userId);

        // When
        LocalDateTime expiration = jwtUtil.getExpirationFromToken(token);

        // Then
        assertNotNull(expiration);
        assertTrue(expiration.isAfter(LocalDateTime.now()));
    }

    @Test
    void testAccessTokenExpiration_IsCorrect() {
        // When
        Long expiration = jwtUtil.getAccessTokenExpiration();

        // Then
        assertEquals(604800000L, expiration);
    }

    @Test
    void testRefreshTokenExpiration_IsCorrect() {
        // When
        Long expiration = jwtUtil.getRefreshTokenExpiration();

        // Then
        assertEquals(2592000000L, expiration);
    }
}
