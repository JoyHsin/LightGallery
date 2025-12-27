package com.declutter.backend.exception;

/**
 * Authentication Exception
 * Thrown when authentication operations fail
 * Requirements: 1.5
 */
public class AuthenticationException extends RuntimeException {
    
    private final String provider;
    private final String errorCode;
    
    public AuthenticationException(String message) {
        super(message);
        this.provider = null;
        this.errorCode = "AUTH_ERROR";
    }
    
    public AuthenticationException(String message, String provider) {
        super(message);
        this.provider = provider;
        this.errorCode = "AUTH_ERROR";
    }
    
    public AuthenticationException(String message, String provider, String errorCode) {
        super(message);
        this.provider = provider;
        this.errorCode = errorCode;
    }
    
    public AuthenticationException(String message, Throwable cause) {
        super(message, cause);
        this.provider = null;
        this.errorCode = "AUTH_ERROR";
    }
    
    public String getProvider() {
        return provider;
    }
    
    public String getErrorCode() {
        return errorCode;
    }
}
