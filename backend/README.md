# Declutter Backend Service

Backend service for Declutter authentication and subscription management system.

## Technology Stack

- **Java 17**
- **Spring Boot 3.2.0**
- **MySQL 8.0+**
- **MyBatis-Plus 3.5.5**
- **Spring Security**
- **JWT (JSON Web Tokens)**

## Project Structure

```
backend/
├── src/
│   ├── main/
│   │   ├── java/com/lightgallery/backend/
│   │   │   ├── controller/     # REST API controllers
│   │   │   ├── service/        # Business logic services
│   │   │   ├── mapper/         # MyBatis-Plus mappers
│   │   │   ├── entity/         # Database entities
│   │   │   ├── dto/            # Data Transfer Objects
│   │   │   ├── config/         # Configuration classes
│   │   │   └── BackendApplication.java
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-dev.yml
│   │       └── application-prod.yml
│   └── test/
│       └── java/com/lightgallery/backend/
├── pom.xml
└── README.md
```

## Prerequisites

- Java 17 or higher
- Maven 3.6+
- MySQL 8.0+

## Database Setup

1. Create MySQL database:
```sql
CREATE DATABASE lightgallery CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

2. Configure database connection in `application.yml` or use environment variables:
```bash
export DB_USERNAME=your_username
export DB_PASSWORD=your_password
```

## Configuration

### Environment Variables

- `DB_USERNAME`: Database username (default: root)
- `DB_PASSWORD`: Database password (default: password)
- `DB_HOST`: Database host (production only, default: localhost)
- `DB_PORT`: Database port (production only, default: 3306)
- `DB_NAME`: Database name (production only, default: lightgallery)
- `JWT_SECRET`: JWT signing secret (required in production)
- `WECHAT_APP_ID`: WeChat OAuth App ID
- `WECHAT_APP_SECRET`: WeChat OAuth App Secret
- `ALIPAY_APP_ID`: Alipay OAuth App ID
- `ALIPAY_PRIVATE_KEY`: Alipay private key
- `ALIPAY_PUBLIC_KEY`: Alipay public key
- `APPLE_CLIENT_ID`: Apple Sign In client ID
- `APPLE_TEAM_ID`: Apple Team ID
- `APPLE_KEY_ID`: Apple Key ID
- `APPLE_PRIVATE_KEY`: Apple private key

### Profiles

- `dev`: Development profile (default)
- `prod`: Production profile

## Running the Application

### Development Mode

```bash
mvn spring-boot:run
```

Or with specific profile:
```bash
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

### Production Mode

```bash
mvn clean package
java -jar target/backend-1.0.0.jar --spring.profiles.active=prod
```

## Building

```bash
mvn clean package
```

The executable JAR will be created in `target/backend-1.0.0.jar`

## Testing

Run all tests:
```bash
mvn test
```

Run specific test class:
```bash
mvn test -Dtest=ClassName
```

## API Documentation

Once the application is running, the API will be available at:
- Development: `http://localhost:8080/api/v1`
- Production: `https://your-domain.com/api/v1`

### Health Check

```bash
curl http://localhost:8080/api/v1/health
```

## Security

- All authentication tokens are stored securely using JWT
- HTTPS is enforced in production (TLS 1.2+)
- CORS is configured for mobile clients
- Passwords and sensitive data are never logged

## License

Proprietary - Declutter
