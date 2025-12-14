package com.lightgallery.backend.config;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

import java.io.IOException;

/**
 * HTTPS Enforcement Configuration
 * Enforces HTTPS for all requests in production
 * Requirement: 10.2
 */
@Slf4j
@Configuration
public class HttpsEnforcementConfig {

    @Value("${server.ssl.enabled:false}")
    private boolean sslEnabled;

    /**
     * HTTPS enforcement filter for production
     * Redirects HTTP requests to HTTPS
     * Requirement: 10.2
     */
    @Bean
    @Profile("prod")
    public Filter httpsEnforcementFilter() {
        return new Filter() {
            @Override
            public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
                    throws IOException, ServletException {
                
                HttpServletRequest httpRequest = (HttpServletRequest) request;
                HttpServletResponse httpResponse = (HttpServletResponse) response;
                
                // Check if request is secure (HTTPS)
                if (!httpRequest.isSecure() && sslEnabled) {
                    String redirectUrl = "https://" + httpRequest.getServerName() + 
                                       httpRequest.getRequestURI();
                    
                    if (httpRequest.getQueryString() != null) {
                        redirectUrl += "?" + httpRequest.getQueryString();
                    }
                    
                    log.warn("Redirecting insecure request to HTTPS: {}", redirectUrl);
                    httpResponse.sendRedirect(redirectUrl);
                    return;
                }
                
                // Add security headers
                httpResponse.setHeader("Strict-Transport-Security", "max-age=31536000; includeSubDomains");
                httpResponse.setHeader("X-Content-Type-Options", "nosniff");
                httpResponse.setHeader("X-Frame-Options", "DENY");
                httpResponse.setHeader("X-XSS-Protection", "1; mode=block");
                
                chain.doFilter(request, response);
            }
        };
    }

    /**
     * TLS version enforcement
     * Ensures only TLS 1.2+ is used
     * Requirement: 10.2
     */
    @Bean
    @Profile("prod")
    public Filter tlsVersionFilter() {
        return new Filter() {
            @Override
            public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
                    throws IOException, ServletException {
                
                HttpServletRequest httpRequest = (HttpServletRequest) request;
                HttpServletResponse httpResponse = (HttpServletResponse) response;
                
                // Check TLS version if available
                String protocol = (String) httpRequest.getAttribute("jakarta.servlet.request.ssl_session_protocol");
                
                if (protocol != null && !isTlsVersionAcceptable(protocol)) {
                    log.error("Rejecting request with unsupported TLS version: {}", protocol);
                    httpResponse.sendError(HttpServletResponse.SC_FORBIDDEN, 
                            "TLS 1.2 or higher is required");
                    return;
                }
                
                chain.doFilter(request, response);
            }
            
            private boolean isTlsVersionAcceptable(String protocol) {
                // Accept TLS 1.2 and TLS 1.3
                return protocol.equals("TLSv1.2") || protocol.equals("TLSv1.3");
            }
        };
    }
}
