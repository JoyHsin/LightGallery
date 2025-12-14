package com.lightgallery.backend;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * LightGallery Backend Application
 * Main entry point for the Spring Boot application
 */
@SpringBootApplication
@MapperScan("com.lightgallery.backend.mapper")
public class BackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(BackendApplication.class, args);
    }
}
