package com.declutter.backend.service;

import com.declutter.backend.dto.AuthResponse;
import com.declutter.backend.dto.OAuthExchangeRequest;
import com.declutter.backend.entity.AuthToken;
import com.declutter.backend.entity.User;
import com.declutter.backend.mapper.AuthTokenMapper;
import com.declutter.backend.mapper.UserMapper;
import com.declutter.backend.util.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.*;

/**
 * Unit tests for AuthService
 * Tests OAuth token exchange, JWT generation, and token refresh logic
 */
@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserMapper userMapper;

    @Mock
    private AuthTokenMapper authTokenMapper;

    @Mock
    private JwtUtil jwtUtil;

    @Mock
    private OAuthProviderService oauthProviderService;

    @InjectMocks
    private AuthService authService;

    private OAuthExchangeRequest oauthRequest;
    private User testUser;
    private AuthToken testAuthToken;

    @BeforeEach
    void setUp() {
        // Setup test OAuth request
        oauthRequest = new OAuthExchangeRequest();
        oauthRequest.setProvider("apple");
        oauthRequest.setCode("test-auth-code");
        oauthRequest.setProviderUserId("apple-user-123");
        oauthRequest.setEmail("test@example.com");
        oauthRequest.setDisplayName("Test User");
        oauthRequest.setAvatarUrl("https://example.com/avatar.jpg");
        oauthRequest.setDeviceInfo("iPhone 14");
        oauthRequest.setIpAddress("192.168.1.1");

        // Setup test user
        testUser = new User();
        testUser.setId(1L);
        testUser.setAuthProvider("apple");
        testUser.setProviderUserId("apple-user-123");
        testUser.setEmail("test@example.com");
        testUser.setDisplayName("Test User");
        testUser.setAvatarUrl("https://example.com/avatar.jpg");
        testUser.setCreatedAt(LocalDateTime.now());
        testUser.setUpdatedAt(LocalDateTime.now());

        // Setup test auth token
        testAuthToken = new AuthToken();
        testAuthToken.setId(1L);
        testAuthToken.setUserId(1L);
        testAuthToken.setAccessToken("test-access-token");
        testAuthToken.setRefreshToken("test-refresh-token");
        testAuthToken.setTokenType("Bearer");
        testAuthToken.setExpiresAt(LocalDateTime.now().plusDays(7));
        testAuthToken.setRefreshExpiresAt(LocalDateTime.now().plusDays(30));
    }

    @Test
    void testExchangeOAuthToken_NewUser_Success() {
        // Given
        when(oauthProviderService.validateOAuthToken(anyString(), anyString(), anyString()))
                .thenReturn(true);
        when(userMapper.selectOne(any())).thenReturn(null);
        when(userMapper.insert(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            user.setId(1L);
            return 1;
        });
        when(jwtUtil.generateAccessToken(anyLong())).thenReturn("new-access-token");
        when(jwtUtil.generateRefreshToken(anyLong())).thenReturn("new-refresh-token");
        when(jwtUtil.getAccessTokenExpiration()).thenReturn(604800000L);
        when(jwtUtil.getRefreshTokenExpiration()).thenReturn(2592000000L);
        when(authTokenMapper.insert(any(AuthToken.class))).thenReturn(1);

        // When
        AuthResponse response = authService.exchangeOAuthToken(oauthRequest);

        // Then
        assertNotNull(response);
        assertEquals("Test User", response.getDisplayName());
        assertEquals("test@example.com", response.getEmail());
        assertEquals("apple", response.getAuthProvider());
        assertEquals("new-access-token", response.getAccessToken());
        assertEquals("new-refresh-token", response.getRefreshToken());
        assertEquals("Bearer", response.getTokenType());

        verify(oauthProviderService).validateOAuthToken("apple", "test-auth-code", "apple-user-123");
        verify(userMapper).insert(any(User.class));
        verify(authTokenMapper).insert(any(AuthToken.class));
    }

    @Test
    void testExchangeOAuthToken_ExistingUser_Success() {
        // Given
        when(oauthProviderService.validateOAuthToken(anyString(), anyString(), anyString()))
                .thenReturn(true);
        when(userMapper.selectOne(any())).thenReturn(testUser);
        when(userMapper.updateById(any(User.class))).thenReturn(1);
        when(jwtUtil.generateAccessToken(anyLong())).thenReturn("new-access-token");
        when(jwtUtil.generateRefreshToken(anyLong())).thenReturn("new-refresh-token");
        when(jwtUtil.getAccessTokenExpiration()).thenReturn(604800000L);
        when(jwtUtil.getRefreshTokenExpiration()).thenReturn(2592000000L);
        when(authTokenMapper.insert(any(AuthToken.class))).thenReturn(1);

        // When
        AuthResponse response = authService.exchangeOAuthToken(oauthRequest);

        // Then
        assertNotNull(response);
        assertEquals(1L, response.getUserId());
        assertEquals("Test User", response.getDisplayName());
        assertEquals("new-access-token", response.getAccessToken());

        verify(userMapper).updateById(any(User.class));
        verify(authTokenMapper).insert(any(AuthToken.class));
    }

    @Test
    void testExchangeOAuthToken_InvalidToken_ThrowsException() {
        // Given
        when(oauthProviderService.validateOAuthToken(anyString(), anyString(), anyString()))
                .thenReturn(false);

        // When & Then
        RuntimeException exception = assertThrows(RuntimeException.class, () -> {
            authService.exchangeOAuthToken(oauthRequest);
        });

        assertEquals("Invalid OAuth token", exception.getMessage());
        verify(userMapper, never()).insert(any());
        verify(authTokenMapper, never()).insert(any());
    }

    @Test
    void testRefreshToken_ValidToken_Success() {
        // Given
        String refreshToken = "valid-refresh-token";
        when(jwtUtil.validateToken(refreshToken)).thenReturn(true);
        when(jwtUtil.getTokenType(refreshToken)).thenReturn("refresh");
        when(jwtUtil.getUserIdFromToken(refreshToken)).thenReturn(1L);
        when(authTokenMapper.selectOne(any())).thenReturn(testAuthToken);
        when(userMapper.selectById(1L)).thenReturn(testUser);
        when(jwtUtil.generateAccessToken(1L)).thenReturn("new-access-token");
        when(jwtUtil.generateRefreshToken(1L)).thenReturn("new-refresh-token");
        when(jwtUtil.getAccessTokenExpiration()).thenReturn(604800000L);
        when(jwtUtil.getRefreshTokenExpiration()).thenReturn(2592000000L);
        when(authTokenMapper.updateById(any(AuthToken.class))).thenReturn(1);

        // When
        AuthResponse response = authService.refreshToken(refreshToken);

        // Then
        assertNotNull(response);
        assertEquals(1L, response.getUserId());
        assertEquals("new-access-token", response.getAccessToken());
        assertEquals("new-refresh-token", response.getRefreshToken());

        verify(jwtUtil).validateToken(refreshToken);
        verify(authTokenMapper).updateById(any(AuthToken.class));
    }

    @Test
    void testRefreshToken_InvalidToken_ThrowsException() {
        // Given
        String refreshToken = "invalid-refresh-token";
        when(jwtUtil.validateToken(refreshToken)).thenReturn(false);

        // When & Then
        RuntimeException exception = assertThrows(RuntimeException.class, () -> {
            authService.refreshToken(refreshToken);
        });

        assertEquals("Invalid or expired refresh token", exception.getMessage());
        verify(authTokenMapper, never()).updateById(any());
    }

    @Test
    void testRefreshToken_WrongTokenType_ThrowsException() {
        // Given
        String accessToken = "access-token-not-refresh";
        when(jwtUtil.validateToken(accessToken)).thenReturn(true);
        when(jwtUtil.getTokenType(accessToken)).thenReturn("access");

        // When & Then
        RuntimeException exception = assertThrows(RuntimeException.class, () -> {
            authService.refreshToken(accessToken);
        });

        assertEquals("Invalid token type", exception.getMessage());
    }

    @Test
    void testLogout_Success() {
        // Given
        Long userId = 1L;
        when(authTokenMapper.delete(any())).thenReturn(1);

        // When
        authService.logout(userId);

        // Then
        verify(authTokenMapper).delete(any());
    }

    @Test
    void testDeleteAccount_Success() {
        // Given
        Long userId = 1L;
        when(authTokenMapper.delete(any())).thenReturn(1);
        when(userMapper.deleteById(userId)).thenReturn(1);

        // When
        authService.deleteAccount(userId);

        // Then
        verify(authTokenMapper).delete(any());
        verify(userMapper).deleteById(userId);
    }
}
