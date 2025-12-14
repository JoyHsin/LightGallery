package com.lightgallery.backend.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

/**
 * Alipay OAuth Service
 * Validates Alipay OAuth tokens
 */
@Slf4j
@Service
public class AlipayOAuthService {

    @Value("${oauth.alipay.app-id}")
    private String appId;

    @Value("${oauth.alipay.private-key}")
    private String privateKey;

    @Value("${oauth.alipay.public-key}")
    private String publicKey;

    private final RestTemplate restTemplate = new RestTemplate();

    /**
     * Validate Alipay OAuth token
     * Exchanges authorization code for access token and validates user info
     *
     * @param code Authorization code from Alipay
     * @param providerUserId Expected user ID from Alipay
     * @return true if token is valid, false otherwise
     */
    public boolean validateToken(String code, String providerUserId) {
        log.info("Validating Alipay OAuth token");

        try {
            // In production, you would use Alipay SDK to properly sign and verify requests
            // This is a simplified version for demonstration
            
            // Exchange code for access token
            String url = String.format(
                    "https://openapi.alipay.com/gateway.do?app_id=%s&method=alipay.system.oauth.token&grant_type=authorization_code&code=%s",
                    appId, code
            );

            // Note: In production, you need to:
            // 1. Sign the request with your private key
            // 2. Verify the response signature with Alipay's public key
            // 3. Use the official Alipay SDK for proper implementation

            ResponseEntity<Map> response = restTemplate.exchange(
                    url,
                    HttpMethod.POST,
                    null,
                    Map.class
            );

            Map<String, Object> body = response.getBody();
            if (body == null) {
                log.error("Alipay OAuth token exchange failed: empty response");
                return false;
            }

            // Check for errors
            Map<String, Object> responseData = (Map<String, Object>) body.get("alipay_system_oauth_token_response");
            if (responseData == null || responseData.containsKey("code") && !"10000".equals(responseData.get("code"))) {
                log.error("Alipay OAuth token exchange failed: {}", responseData);
                return false;
            }

            // Verify user ID matches
            String userId = (String) responseData.get("user_id");
            if (providerUserId != null && !providerUserId.equals(userId)) {
                log.error("Alipay user ID mismatch. Expected: {}, Got: {}", providerUserId, userId);
                return false;
            }

            log.info("Alipay OAuth token validated successfully");
            return true;

        } catch (Exception e) {
            log.error("Alipay OAuth validation error: {}", e.getMessage(), e);
            return false;
        }
    }

    /**
     * Get Alipay user info
     *
     * @param accessToken Alipay access token
     * @return User info map
     */
    public Map<String, Object> getUserInfo(String accessToken) {
        try {
            String url = String.format(
                    "https://openapi.alipay.com/gateway.do?app_id=%s&method=alipay.user.info.share&access_token=%s",
                    appId, accessToken
            );

            // Note: In production, you need to sign this request properly
            ResponseEntity<Map> response = restTemplate.exchange(
                    url,
                    HttpMethod.POST,
                    null,
                    Map.class
            );

            return response.getBody();

        } catch (Exception e) {
            log.error("Failed to get Alipay user info: {}", e.getMessage(), e);
            return null;
        }
    }
}
