package com.declutter.backend.exception;

/**
 * Subscription Exception
 * Thrown when subscription operations fail
 * Requirements: 4.4
 */
public class SubscriptionException extends RuntimeException {
    
    private final String errorCode;
    
    public SubscriptionException(String message) {
        super(message);
        this.errorCode = "SUBSCRIPTION_ERROR";
    }
    
    public SubscriptionException(String message, String errorCode) {
        super(message);
        this.errorCode = errorCode;
    }
    
    public SubscriptionException(String message, Throwable cause) {
        super(message, cause);
        this.errorCode = "SUBSCRIPTION_ERROR";
    }
    
    public SubscriptionException(String message, String errorCode, Throwable cause) {
        super(message, cause);
        this.errorCode = errorCode;
    }
    
    public String getErrorCode() {
        return errorCode;
    }
}
