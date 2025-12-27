# Backend Project Structure

## Overview

This document describes the structure and organization of the Declutter backend service.

## Directory Structure

```
backend/
├── src/
│   ├── main/
│   │   ├── java/com/lightgallery/backend/
│   │   │   ├── controller/          # REST API Controllers
│   │   │   │   └── HealthController.java
│   │   │   │
│   │   │   ├── service/             # Business Logic Services
│   │   │   │   └── (To be implemented)
│   │   │   │
│   │   │   ├── mapper/              # MyBatis-Plus Mappers
│   │   │   │   └── (To be implemented)
│   │   │   │
│   │   │   ├── entity/              # Database Entities
│   │   │   │   └── BaseEntity.java
│   │   │   │
│   │   │   ├── dto/                 # Data Transfer Objects
│   │   │   │   └── ApiResponse.java
│   │   │   │
│   │   │   ├── config/              # Configuration Classes
│   │   │   │   ├── CorsConfig.java
│   │   │   │   └── MyBatisPlusConfig.java
│   │   │   │
│   │   │   └── BackendApplication.java  # Main Application Class
│   │   │
│   │   └── resources/
│   │       ├── application.yml           # Main configuration
│   │       ├── application-dev.yml       # Development profile
│   │       ├── application-prod.yml      # Production profile
│   │       └── mapper/                   # MyBatis XML mappers (optional)
│   │
│   └── test/
│       ├── java/com/lightgallery/backend/
│       │   └── BackendApplicationTests.java
│       └── resources/
│           └── application-test.yml      # Test configuration
│
├── pom.xml                    # Maven project configuration
├── README.md                  # Project documentation
├── PROJECT_STRUCTURE.md       # This file
├── setup.sh                   # Setup script
└── .gitignore                 # Git ignore rules
```

## Package Descriptions

### controller/
REST API controllers that handle HTTP requests and responses. Controllers should:
- Be annotated with `@RestController`
- Use `@RequestMapping` for base paths
- Return `ApiResponse<T>` for consistent response format
- Delegate business logic to services
- Handle request validation

**Example:**
```java
@RestController
@RequestMapping("/auth")
public class AuthController {
    // Authentication endpoints
}
```

### service/
Business logic services that implement core functionality. Services should:
- Be annotated with `@Service`
- Contain business logic and validation
- Call mappers for database operations
- Handle transactions with `@Transactional`
- Throw appropriate exceptions

**Example:**
```java
@Service
public class AuthService {
    // Authentication business logic
}
```

### mapper/
MyBatis-Plus mappers for database operations. Mappers should:
- Extend `BaseMapper<T>`
- Be interfaces (no implementation needed)
- Use annotations or XML for custom queries
- Be scanned by `@MapperScan` in main application

**Example:**
```java
@Mapper
public interface UserMapper extends BaseMapper<User> {
    // Custom queries if needed
}
```

### entity/
Database entity classes that map to tables. Entities should:
- Extend `BaseEntity` for common fields
- Use `@TableName` to specify table name
- Use `@TableId` for primary key
- Use `@TableField` for column mapping
- Include Lombok annotations (`@Data`, etc.)

**Example:**
```java
@Data
@TableName("users")
public class User extends BaseEntity {
    @TableId(type = IdType.AUTO)
    private Long id;
    // Other fields
}
```

### dto/
Data Transfer Objects for API requests and responses. DTOs should:
- Be simple POJOs with getters/setters
- Use validation annotations (`@NotNull`, `@Valid`, etc.)
- Not contain business logic
- Be used for API contracts

**Example:**
```java
@Data
public class LoginRequest {
    @NotBlank
    private String provider;
    @NotBlank
    private String authCode;
}
```

### config/
Configuration classes for Spring Boot. Configurations should:
- Be annotated with `@Configuration`
- Define beans with `@Bean`
- Configure framework features
- Load properties with `@Value` or `@ConfigurationProperties`

## Configuration Files

### application.yml
Main configuration file with:
- Database connection settings
- MyBatis-Plus configuration
- Server settings
- JWT configuration
- OAuth provider settings
- CORS configuration

### application-dev.yml
Development-specific overrides:
- Local database connection
- Debug logging
- Disabled SSL

### application-prod.yml
Production-specific overrides:
- Production database connection
- Minimal logging
- Enabled SSL
- Environment variable placeholders

### application-test.yml
Test-specific configuration:
- Test database
- In-memory database option
- Disabled security for testing

## Dependencies

### Core Dependencies
- **Spring Boot Starter Web**: REST API support
- **Spring Boot Starter Security**: Authentication and authorization
- **Spring Boot Starter Validation**: Request validation
- **MySQL Connector**: MySQL database driver
- **MyBatis-Plus**: Enhanced MyBatis with CRUD operations
- **JWT (jjwt)**: JSON Web Token support
- **Lombok**: Reduce boilerplate code

### Test Dependencies
- **Spring Boot Starter Test**: Testing framework
- **Spring Security Test**: Security testing utilities

## Naming Conventions

### Classes
- Controllers: `*Controller` (e.g., `AuthController`)
- Services: `*Service` (e.g., `AuthService`)
- Mappers: `*Mapper` (e.g., `UserMapper`)
- Entities: Singular noun (e.g., `User`, `Subscription`)
- DTOs: `*Request`, `*Response`, `*DTO` (e.g., `LoginRequest`)

### Methods
- Controllers: HTTP verb + resource (e.g., `getUser`, `createSubscription`)
- Services: Business action (e.g., `authenticateUser`, `validateSubscription`)
- Mappers: CRUD operations (inherited from `BaseMapper`)

### Database
- Tables: Plural snake_case (e.g., `users`, `subscriptions`)
- Columns: snake_case (e.g., `user_id`, `created_at`)

## Best Practices

1. **Separation of Concerns**: Keep controllers thin, services focused, and mappers simple
2. **Error Handling**: Use global exception handlers for consistent error responses
3. **Validation**: Validate at controller level with annotations
4. **Transactions**: Use `@Transactional` on service methods that modify data
5. **Logging**: Use SLF4J logger, avoid logging sensitive data
6. **Security**: Never log passwords, tokens, or payment information
7. **Testing**: Write unit tests for services, integration tests for controllers

## Next Steps

The following components need to be implemented:

1. **Authentication Module** (Task 20)
   - AuthController
   - AuthService
   - OAuth provider integrations

2. **Subscription Module** (Task 21)
   - SubscriptionController
   - SubscriptionService
   - Product management

3. **Payment Module** (Task 22)
   - PaymentService
   - Receipt verification
   - Payment gateway integrations

4. **Database Schema** (Task 19)
   - User entity and mapper
   - Subscription entity and mapper
   - Transaction entity and mapper
   - AuthToken entity and mapper

5. **Security Configuration** (Task 23)
   - JWT authentication filter
   - Security filter chain
   - HTTPS configuration

6. **Error Handling** (Task 24)
   - Global exception handler
   - Audit logging
   - Log sanitization
