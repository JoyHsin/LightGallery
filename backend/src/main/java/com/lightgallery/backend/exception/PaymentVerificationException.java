package com.lightgallery.backend.exception;

/**
 * Payment Verification Exception
 * Thrown when payment verification fails
 * Requirements: 8.4
 */
public class PaymentVerificationException extends RuntimeException {
    
    private final String paymentMethod;
    private final String transactionId;
    private final String errorCode;
    
    public PaymentVerificationException(String message) {
        super(message);
        this.paymentMethod = null;
        this.transactionId = null;
        this.errorCode = "PAYMENT_VERIFICATION_ERROR";
    }
    
    public PaymentVerificationException(String message, String paymentMethod, String transactionId) {
        super(message);
        this.paymentMethod = paymentMethod;
        this.transactionId = transactionId;
        this.errorCode = "PAYMENT_VERIFICATION_ERROR";
    }
    
    public PaymentVerificationException(String message, String paymentMethod, String transactionId, String errorCode) {
        super(message);
        this.paymentMethod = paymentMethod;
        this.transactionId = transactionId;
        this.errorCode = errorCode;
    }
    
    public PaymentVerificationException(String message, Throwable cause) {
        super(message, cause);
        this.paymentMethod = null;
        this.transactionId = null;
        this.errorCode = "PAYMENT_VERIFICATION_ERROR";
    }
    
    public String getPaymentMethod() {
        return paymentMethod;
    }
    
    public String getTransactionId() {
        return transactionId;
    }
    
    public String getErrorCode() {
        return errorCode;
    }
}
