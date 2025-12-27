# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

LightGallery 是一个 iOS 照片管理应用，包含前端 (Swift/SwiftUI) 和后端 (Java/Spring Boot) 两部分。应用提供照片清理、格式转换、证件照制作等功能，并集成了用户认证和订阅系统。

**技术栈**:
- **iOS**: Swift, SwiftUI, iOS 17.0+, StoreKit 2 (Apple IAP)
- **后端**: Java 17, Spring Boot 3.1.5, MySQL 8.0+, MyBatis-Plus 3.5.5
- **认证**: JWT, Apple Sign In, WeChat OAuth, Alipay OAuth

## 常用命令

### iOS 开发

**构建和运行**:
```bash
# 在 Xcode 中打开项目
open LightGallery.xcodeproj

# 命令行构建（需要先配置签名）
xcodebuild build \
  -project LightGallery.xcodeproj \
  -scheme LightGallery \
  -destination "platform=iOS Simulator,name=iPhone 15 Pro"

# 部署到真机（需要修改脚本中的设备 ID）
./deploy_to_iphone.sh
```

**测试**:
```bash
# 运行所有测试
xcodebuild test \
  -project LightGallery.xcodeproj \
  -scheme LightGallery \
  -destination "platform=iOS Simulator,name=iPhone 15 Pro"

# 运行单个测试类
xcodebuild test \
  -project LightGallery.xcodeproj \
  -scheme LightGallery \
  -destination "platform=iOS Simulator,name=iPhone 15 Pro" \
  -only-testing:LightGalleryTests/TestClassName
```

### 后端开发

**运行后端服务**:
```bash
cd backend

# 开发模式
mvn spring-boot:run

# 指定配置文件
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 生产模式
mvn clean package
java -jar target/backend-1.0.0.jar --spring.profiles.active=prod
```

**测试**:
```bash
cd backend

# 运行所有测试
mvn test

# 运行单个测试类
mvn test -Dtest=ClassName

# 运行单个测试方法
mvn test -Dtest=ClassName#methodName
```

**数据库设置**:
```bash
# 创建数据库
mysql -u root -p
CREATE DATABASE lightgallery CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# 配置环境变量
export DB_USERNAME=your_username
export DB_PASSWORD=your_password
```

## 架构设计

### iOS 应用架构 (MVVM)

**核心层次结构**:
```
LightGallery/
├── Models/              # 数据模型
│   ├── Auth/           # 认证相关模型 (User, OAuthCredential, AuthResponse)
│   └── Subscription/   # 订阅相关模型 (Subscription, SubscriptionTier, PremiumFeature)
├── Views/              # SwiftUI 视图
│   ├── Auth/           # 登录、注册视图
│   ├── Subscription/   # 订阅管理视图
│   └── [功能视图]      # HomeView, ToolsView, ProfileView 等
├── ViewModels/         # 视图模型
│   ├── Auth/           # LoginViewModel, ProfileViewModel
│   └── Subscription/   # SubscriptionViewModel
├── Services/           # 业务逻辑服务
│   ├── Auth/           # 认证服务
│   └── Subscription/   # 订阅服务
└── Constants/          # 常量配置
```

**关键设计模式**:

1. **服务层抽象**: 所有服务都定义了 Protocol，便于测试和模拟
   - `AuthenticationServiceProtocol` → `AuthenticationService` / `MockAuthenticationService`
   - `SubscriptionServiceProtocol` → `SubscriptionService`
   - `PhotoServiceProtocol` → `PhotoService`

2. **环境对象传递**: 使用 `@EnvironmentObject` 在视图树中共享状态
   - `LocalizationManager`: 多语言管理
   - `SubscriptionViewModel`: 订阅状态
   - `LoginPromptManager`: 登录提示管理

3. **功能访问控制**: `FeatureAccessManager` 统一管理基于订阅的功能访问
   - 检查用户登录状态
   - 验证订阅层级和过期状态
   - 处理取消订阅的访问权限（保留至到期）

### 后端架构 (Spring Boot)

**分层结构**:
```
backend/src/main/java/com/lightgallery/backend/
├── controller/         # REST API 控制器
│   ├── AuthController.java
│   ├── SubscriptionController.java
│   └── UserController.java
├── service/           # 业务逻辑服务
│   ├── AuthService.java
│   ├── SubscriptionService.java
│   └── PaymentService.java
├── mapper/            # MyBatis-Plus 数据访问层
│   ├── UserMapper.java
│   └── SubscriptionMapper.java
├── entity/            # 数据库实体
│   ├── User.java
│   └── Subscription.java
├── dto/               # 数据传输对象
│   ├── request/
│   └── response/
└── config/            # 配置类
    ├── SecurityConfig.java
    └── JwtConfig.java
```

**API 端点结构**:
- `/api/v1/auth/*` - 认证相关 (OAuth 交换、令牌验证、登出)
- `/api/v1/users/*` - 用户管理 (个人资料、偏好设置)
- `/api/v1/subscriptions/*` - 订阅管理 (产品列表、购买验证、状态查询)

### 认证流程

**OAuth 集成流程**:
1. iOS 客户端通过第三方 SDK 获取 OAuth 凭证 (authCode/idToken)
2. 客户端调用 `BackendAPIClient.exchangeOAuthToken()` 将凭证发送到后端
3. 后端验证 OAuth 凭证并创建/更新用户记录
4. 后端返回 JWT token 和用户信息
5. 客户端使用 `SecureStorage` 将 token 存储在 Keychain
6. 后续 API 请求在 Authorization header 中携带 JWT token

**支持的认证方式**:
- Apple Sign In (生产环境主要方式)
- WeChat OAuth (需要 WeChat SDK，当前为模拟实现)
- Alipay OAuth (需要 Alipay SDK，当前为模拟实现)

### 订阅系统

**订阅层级** (定义在 `SubscriptionTier.swift`):
- `free`: 免费版，基础功能
- `basic`: 基础订阅，部分高级功能
- `premium`: 高级订阅，所有功能

**Apple IAP 集成**:
- 使用 StoreKit 2 框架
- Product IDs: `com.lightgallery.basic.monthly`, `com.lightgallery.premium.monthly`
- 收据验证通过后端 API 完成
- 支持离线缓存和网络恢复时同步

**功能访问控制**:
- `FeatureAccessManager.canAccessFeature()` 检查功能访问权限
- 基于用户登录状态、订阅层级和过期状态
- 取消的订阅保留访问权限直到到期日

## 重要注意事项

### App Store 审核合规性

**必须遵守的规则** (详见 `docs/app-store-review/APP_STORE_REVIEW_REMEDIATION.md`):

1. **仅使用 Apple IAP**: iOS 版本不得包含其他支付方式的代码或引用
   - `PaymentMethod` 枚举应只包含 `appleIAP`
   - 后端需要验证 iOS 平台只能使用 Apple IAP

2. **订阅条款展示**: 订阅页面必须清晰展示
   - 订阅价格和计费周期
   - 自动续订说明
   - 取消订阅方式
   - 隐私政策和服务条款链接

3. **Apple Sign In 配置**:
   - 已在 `LightGallery.entitlements` 中配置
   - Bundle ID: `joyhisn.LightGallery`
   - 需要在 Apple Developer Portal 配置 Sign in with Apple capability

### 环境配置

**iOS 环境切换** (在 `BackendAPIClient.swift`):
```swift
// 修改初始化时的环境
init(environment: Environment = .development)  // 开发环境
init(environment: Environment = .production)   // 生产环境
```

**后端环境配置**:
- `application-dev.yml`: 开发环境 (localhost:8080)
- `application-prod.yml`: 生产环境 (需要配置环境变量)

**必需的环境变量** (生产环境):
```bash
DB_USERNAME, DB_PASSWORD, DB_HOST, DB_PORT, DB_NAME
JWT_SECRET
APPLE_CLIENT_ID, APPLE_TEAM_ID, APPLE_KEY_ID, APPLE_PRIVATE_KEY
```

### 本地化支持

应用支持多语言，通过 `LocalizationManager` 管理:
- 支持的语言: 简体中文 (zh-Hans), 英文 (en)
- 本地化文件位置: `LightGallery/Resources/Localizations/`
- 使用方式: `LocalizationManager.shared.localizedString(for: key)`

### 测试指南

**IAP 测试** (详见 `docs/testing/APPLE_IAP_TESTING_GUIDE.md`):
1. 在 App Store Connect 创建沙盒测试账号
2. 在 iOS 设备上登录沙盒账号 (设置 > App Store > 沙盒账户)
3. 运行应用并测试购买流程
4. 验证收据通过后端 API 验证

**认证测试**:
- 开发环境使用 `MockAuthenticationService` 进行模拟登录
- 生产环境需要配置真实的 OAuth 凭证

## 文档资源

- `docs/app-store-review/` - App Store 审核相关文档
- `docs/testing/` - 测试指南 (IAP, 微信支付, 沙盒测试)
- `docs/deployment/` - 部署指南
- `docs/implementation/` - 实现说明 (iOS 构建, 相机权限)
- `backend/README.md` - 后端详细文档

## 开发工作流

### 添加新功能

1. **定义功能访问级别**: 在 `PremiumFeature` 枚举中添加新功能
2. **实现功能逻辑**: 在 Services 层实现业务逻辑
3. **创建视图**: 在 Views 中创建 SwiftUI 视图
4. **添加访问控制**: 使用 `FeatureAccessManager.canAccessFeature()` 检查权限
5. **更新导航**: 在 `MainTabView` 或相关视图中添加导航入口

### 修改订阅层级

1. **更新模型**: 修改 `SubscriptionTier.swift` 中的层级定义
2. **更新功能映射**: 在 `PremiumFeature` 中更新 `requiredTier` 属性
3. **更新后端**: 同步修改后端的订阅层级定义
4. **更新 App Store Connect**: 配置对应的 IAP 产品

### 调试技巧

**查看日志**:
- iOS: 在 Xcode Console 中查看，关键服务都有详细日志输出
- 后端: 日志输出到控制台，使用 `application.yml` 配置日志级别

**常见问题**:
- **IAP 无法加载产品**: 检查 Product IDs 是否与 App Store Connect 一致
- **认证失败**: 检查后端 API 地址和网络连接
- **订阅状态不同步**: 检查 `SubscriptionCache` 和网络监控状态
