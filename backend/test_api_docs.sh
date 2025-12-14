#!/bin/bash

# API Documentation Test Script
# This script verifies that the API documentation is accessible

echo "=========================================="
echo "LightGallery API Documentation Test"
echo "=========================================="
echo ""

# Check if server is running
echo "1. Checking if backend server is running..."
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ Server is running"
else
    echo "❌ Server is not running"
    echo "   Please start the server with: mvn spring-boot:run"
    exit 1
fi

echo ""

# Check Swagger UI
echo "2. Checking Swagger UI..."
if curl -s http://localhost:8080/swagger-ui.html > /dev/null 2>&1; then
    echo "✅ Swagger UI is accessible"
    echo "   URL: http://localhost:8080/swagger-ui.html"
else
    echo "❌ Swagger UI is not accessible"
    exit 1
fi

echo ""

# Check OpenAPI JSON
echo "3. Checking OpenAPI JSON..."
if curl -s http://localhost:8080/v3/api-docs > /dev/null 2>&1; then
    echo "✅ OpenAPI JSON is accessible"
    echo "   URL: http://localhost:8080/v3/api-docs"
else
    echo "❌ OpenAPI JSON is not accessible"
    exit 1
fi

echo ""

# Check OpenAPI YAML
echo "4. Checking OpenAPI YAML..."
if curl -s http://localhost:8080/v3/api-docs.yaml > /dev/null 2>&1; then
    echo "✅ OpenAPI YAML is accessible"
    echo "   URL: http://localhost:8080/v3/api-docs.yaml"
else
    echo "❌ OpenAPI YAML is not accessible"
    exit 1
fi

echo ""

# Test health endpoint
echo "5. Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s http://localhost:8080/api/v1/health)
if echo "$HEALTH_RESPONSE" | grep -q "UP"; then
    echo "✅ Health endpoint is working"
    echo "   Response: $HEALTH_RESPONSE"
else
    echo "❌ Health endpoint is not working properly"
    exit 1
fi

echo ""

# Check documentation files
echo "6. Checking documentation files..."
FILES=(
    "API_DOCUMENTATION.md"
    "SWAGGER_GUIDE.md"
    "API_QUICK_REFERENCE.md"
    "API_DOCUMENTATION_SUMMARY.md"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file is missing"
        exit 1
    fi
done

echo ""
echo "=========================================="
echo "✅ All API documentation tests passed!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Open Swagger UI: http://localhost:8080/swagger-ui.html"
echo "2. Read API_DOCUMENTATION.md for complete reference"
echo "3. Read SWAGGER_GUIDE.md for usage instructions"
echo "4. Read API_QUICK_REFERENCE.md for quick lookup"
echo ""
