package com.declutter.backend.controller;

import com.declutter.backend.dto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Health Check Controller
 * Provides health check endpoint for monitoring
 */
@RestController
@RequestMapping("/health")
@Tag(name = "Health", description = "Service health check endpoint")
public class HealthController {

    @Operation(
            summary = "Health check",
            description = "Returns the health status of the service. Used for monitoring and load balancer health checks.",
            security = {}
    )
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(
                    responseCode = "200",
                    description = "Service is healthy",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(value = """
                                    {
                                      "code": 200,
                                      "message": "Success",
                                      "data": {
                                        "status": "UP",
                                        "timestamp": "2024-12-07T10:00:00",
                                        "service": "declutter-backend"
                                      }
                                    }
                                    """)
                    )
            )
    })
    @GetMapping
    public ApiResponse<Map<String, Object>> health() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "UP");
        health.put("timestamp", LocalDateTime.now());
        health.put("service", "declutter-backend");
        
        return ApiResponse.success(health);
    }
}
