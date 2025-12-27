package com.declutter.backend.service;

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
 * WeChat OAuth Service
 * Validates WeChat OAuth tokens
 */
@Slf4j
@Service
public class WeChatOAuthService {

    @Value("${oauth.wechat.app-id}")
    private String appId;

    @Value("${oauth.wechat.app-secret}")
    private String appSecret;

    private final RestTemplate restTemplate = new RestTemplate();

    /**
     * Validate WeChat OAuth token
     * Exchanges authorization code for access token and validates user info
     *
     * @param code Authorization code from WeChat
     * @param providerUserId Expected user ID from WeChat
     * @return true if token is valid, false otherwise
     */
    public boolean validateToken(String code, String providerUserId) {
        log.info("Validating WeChat OAuth token");

        try {
            // Exchange code for access token
            String url = String.format(
                    "https://api.weixin.qq.com/sns/oauth2/access_token?appid=%s&secret=%s&code=%s&grant_type=authorization_code",
                    appId, appSecret, code
            );

            ResponseEntity<Map> response = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    null,
                    Map.class
            );

            Map<String, Object> body = response.getBody();
            if (body == null || body.containsKey("errcode")) {
                log.error("WeChat OAuth token exchange failed: {}", body);
                return false;
            }

            // Verify user ID matches
            String openid = (String) body.get("openid");
            if (providerUserId != null && !providerUserId.equals(openid)) {
                log.error("WeChat user ID mismatch. Expected: {}, Got: {}", providerUserId, openid);
                return false;
            }

            log.info("WeChat OAuth token validated successfully");
            return true;

        } catch (Exception e) {
            log.error("WeChat OAuth validation error: {}", e.getMessage(), e);
            return false;
        }
    }

    /**
     * Get WeChat user info
     *
     * @param accessToken WeChat access token
     * @param openid WeChat user openid
     * @return User info map
     */
    public Map<String, Object> getUserInfo(String accessToken, String openid) {
        try {
            String url = String.format(
                    "https://api.weixin.qq.com/sns/userinfo?access_token=%s&openid=%s&lang=zh_CN",
                    accessToken, openid
            );

            ResponseEntity<Map> response = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    null,
                    Map.class
            );

            return response.getBody();

        } catch (Exception e) {
            log.error("Failed to get WeChat user info: {}", e.getMessage(), e);
            return null;
        }
    }
}
