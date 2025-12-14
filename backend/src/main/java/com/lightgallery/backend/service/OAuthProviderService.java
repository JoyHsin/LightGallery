package com.lightgallery.backend.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * OAuth Provider Service
 * Validates OAuth tokens from different providers (WeChat, Alipay, Apple)
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class OAuthProviderService {

    private final WeChatOAuthService weChatOAuthService;
    private final AlipayOAuthService alipayOAuthService;
    private final AppleOAuthService appleOAuthService;

    /**
     * Validate OAuth token with the appropriate provider
     *
     * @param provider OAuth provider (wechat, alipay, apple)
     * @param code Authorization code or token
     * @param providerUserId User ID from provider
     * @return true if token is valid, false otherwise
     */
    public boolean validateOAuthToken(String provider, String code, String providerUserId) {
        log.info("Validating OAuth token for provider: {}", provider);

        try {
            switch (provider.toLowerCase()) {
                case "wechat":
                    return weChatOAuthService.validateToken(code, providerUserId);
                case "alipay":
                    return alipayOAuthService.validateToken(code, providerUserId);
                case "apple":
                    return appleOAuthService.validateToken(code, providerUserId);
                default:
                    log.error("Unknown OAuth provider: {}", provider);
                    return false;
            }
        } catch (Exception e) {
            log.error("OAuth token validation failed for provider {}: {}", provider, e.getMessage(), e);
            return false;
        }
    }
}
