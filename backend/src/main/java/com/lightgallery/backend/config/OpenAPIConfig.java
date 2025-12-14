package com.lightgallery.backend.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

/**
 * OpenAPI Configuration
 * Configures Swagger/OpenAPI documentation for the LightGallery Backend API
 */
@Configuration
public class OpenAPIConfig {

    @Value("${server.port:8080}")
    private String serverPort;

    @Bean
    public OpenAPI lightGalleryOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("LightGallery Backend API")
                        .description("Backend service for LightGallery authentication and subscription management. " +
                                "This API provides endpoints for user authentication via OAuth providers (Apple, WeChat, Alipay), " +
                                "subscription management with multiple tiers (Free, Pro, Max), and payment verification.")
                        .version("1.0.0")
                        .contact(new Contact()
                                .name("LightGallery Team")
                                .email("support@lightgallery.com"))
                        .license(new License()
                                .name("Proprietary")
                                .url("https://lightgallery.com/license")))
                .servers(List.of(
                        new Server()
                                .url("http://localhost:" + serverPort + "/api/v1")
                                .description("Local Development Server"),
                        new Server()
                                .url("https://api.lightgallery.com/api/v1")
                                .description("Production Server")))
                .components(new Components()
                        .addSecuritySchemes("bearerAuth", new SecurityScheme()
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("JWT authentication token. Obtain via /auth/oauth/exchange or /auth/token/refresh")))
                .addSecurityItem(new SecurityRequirement().addList("bearerAuth"));
    }
}
