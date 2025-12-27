package com.declutter.backend.exception;

import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.Map;

/**
 * Global Exception Handler
 * Handles all exceptions thrown by controllers and returns appropriate HTTP responses
 * Requirements: 1.5, 4.4, 8.4
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    /**
     * Handle authentication exceptions
     * Requirements: 1.5
     */
    @ExceptionHandler(com.declutter.backend.exception.AuthenticationException.class)
    public ResponseEntity<ErrorResponse> handleAuthenticationException(
            com.declutter.backend.exception.AuthenticationException ex,
            HttpServletRequest request) {
        
        log.error("Authentication error: provider={}, errorCode={}, message={}", 
                ex.getProvider(), ex.getErrorCode(), ex.getMessage());
        
        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.UNAUTHORIZED.value(),
                "Authentication Failed",
                ex.getMessage(),
                request.getRequestURI(),
                ex.getErrorCode()
        );
        
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
    }

    /**
     * Handle Spring Security authentication exceptions
     * Requirements: 1.5
     */
    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ErrorResponse> handleSpringAuthenticationException(
            AuthenticationException ex,
            HttpServletRequest request) {
        
        log.error("Spring Security authentication error: {}", ex.getMessage());
        
        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.UNAUTHORIZED.value(),
                "Authentication Failed",
                "Invalid credentials or authentication token",
                request.getRequestURI(),
                "AUTH_ERROR"
        );
        
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
    }

    /**
     * Handle bad credentials exception
     * Requirements: 1.5
     */
    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<ErrorResponse> handleBadCredentialsException(
            BadCredentialsException ex,
            HttpServletRequest request) {
        
        log.error("Bad credentials: {}", ex.getMessage());
        
        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.UNAUTHORIZED.value(),
                "Bad Credentials",
                "Invalid username or password",
                request.getRequestURI(),
                "BAD_CREDENTIALS"
        );
        
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
    }

    /**
     * Handle access denied exception
     * Requirements: 1.5
     */
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErrorResponse> handleAccessDeniedException(
            AccessDeniedException ex,
            HttpServletRequest request) {
        
        log.error("Access denied: {}", ex.getMessage());
        
        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.FORBIDDEN.value(),
                "Access Denied",
                "You do not have permission to access this resource",
                request.getRequestURI(),
                "ACCESS_DENIED"
        );
        
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse);
    }

    /**
     * Handle subscription exceptions
     * Requirements: 4.4
     */
    @ExceptionHandler(SubscriptionException.class)
    public ResponseEntity<ErrorResponse> handleSubscriptionException(
            SubscriptionException ex,
            HttpServletRequest request) {
        
        log.error("Subscription error: errorCode={}, message={}", 
                ex.getErrorCode(), ex.getMessage());
        
        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.BAD_REQUEST.value(),
                "Subscription Error",
                ex.getMessage(),
                request.getRequestURI(),
                ex.getErrorCode()
        );
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }

    /**
     * Handle payment verification exceptions
     * Requirements: 8.4
     */
    @ExceptionHandler(PaymentVerificationException.class)
    public ResponseEntity<ErrorResponse> handlePaymentVerificationException(
            PaymentVerificationException ex,
            HttpServletRequest request) {
        
        log.error("Payment verification error: method={}, transactionId={}, errorCode={}, message={}", 
                ex.getPaymentMethod(), ex.getTransactionId(), ex.getErrorCode(), ex.getMessage());
        
        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.BAD_REQUEST.value(),
                "Payment Verification Failed",
                ex.getMessage(),
                request.getRequestURI(),
                ex.getErrorCode()
        );
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }

    /**
     * Handle validation exceptions
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationException(
            MethodArgumentNotValidException ex,
            HttpServletRequest request) {
        
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach((error) -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });
        
        log.error("Validation error: {}", errors);
        
        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.BAD_REQUEST.value(),
                "Validation Failed",
                "Invalid request parameters: " + errors.toString(),
                request.getRequestURI(),
                "VALIDATION_ERROR"
        );
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }

    /**
     * Handle illegal argument exceptions
     */
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ErrorResponse> handleIllegalArgumentException(
            IllegalArgumentException ex,
            HttpServletRequest request) {
        
        log.error("Illegal argument: {}", ex.getMessage());
        
        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.BAD_REQUEST.value(),
                "Invalid Argument",
                ex.getMessage(),
                request.getRequestURI(),
                "INVALID_ARGUMENT"
        );
        
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }

    /**
     * Handle all other exceptions
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGenericException(
            Exception ex,
            HttpServletRequest request) {
        
        log.error("Unexpected error: {}", ex.getMessage(), ex);
        
        ErrorResponse errorResponse = new ErrorResponse(
                HttpStatus.INTERNAL_SERVER_ERROR.value(),
                "Internal Server Error",
                "An unexpected error occurred. Please try again later.",
                request.getRequestURI(),
                "INTERNAL_ERROR"
        );
        
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
    }
}
