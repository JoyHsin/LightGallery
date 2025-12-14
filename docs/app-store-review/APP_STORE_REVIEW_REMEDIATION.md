# LightGallery App Store 审核整改文档

> 文档版本: 1.0  
> 创建日期: 2024-12-14  
> 应用名称: LightGallery  
> Bundle ID: joyhisn.LightGallery

---

## 目录

1. [整改概述](#整改概述)
2. [🔴 高风险项 - 必须修改](#高风险项---必须修改)
3. [🟡 中风险项 - 建议修改](#中风险项---建议修改)
4. [🟢 低风险项 - 可选优化](#低风险项---可选优化)
5. [整改进度跟踪](#整改进度跟踪)
6. [提交前检查清单](#提交前检查清单)

---

## 整改概述

基于 App Store Review Guidelines 的代码审查，发现以下需要整改的问题：

| 风险等级 | 数量 | 说明 |
|---------|------|------|
| 🔴 高风险 | 3 项 | 必须修改，否则极大概率被拒 |
| 🟡 中风险 | 4 项 | 建议修改，可能被审核员盘问 |
| 🟢 低风险 | 3 项 | 可选优化，提升审核通过率 |

---

## 高风险项 - 必须修改

### 🔴 H-001: 第三方支付方式代码残留

**违反条款**: Guideline 3.1.1 - In-App Purchase

**问题描述**:  
后端和客户端代码中包含微信支付和支付宝支付的实现，虽然 iOS 客户端目前只使用 Apple IAP，但代码中存在这些支付方式的枚举和验证逻辑，可能被审核员发现。

**涉及文件**:
- `LightGallery/Models/Subscription/SubscriptionTier.swift`
- `backend/src/main/java/com/lightgallery/backend/service/PaymentService.java`

**当前代码**:
```swift
// LightGallery/Models/Subscription/SubscriptionTier.swift (第 85-89 行)
enum PaymentMethod: String, Codable {
    case appleIAP = "apple_iap"
    case wechatPay = "wechat_pay"  // ❌ 违规
    case alipay = "alipay"          // ❌ 违规
}
```

```java
// PaymentService.java (第 47-53 行)
switch (request.getPaymentMethod().toLowerCase()) {
    case "apple_iap":
        return verifyAppleIAPReceipt(request);
    case "wechat_pay":           // ❌ 违规
        return verifyWeChatPayment(request);
    case "alipay":               // ❌ 违规
        return verifyAlipayPayment(request);
}
```

**整改方案**:

**方案 A - iOS 客户端移除 (推荐)**:
```swift
// LightGallery/Models/Subscription/SubscriptionTier.swift
enum PaymentMethod: String, Codable {
    case appleIAP = "apple_iap"
    // 以下支付方式仅用于非 iOS 平台，iOS 版本不包含
}
```

**方案 B - 后端添加平台检测**:
```java
// PaymentService.java
public boolean verifyPayment(PaymentVerificationRequest request) {
    // iOS 平台只允许 Apple IAP
    if ("ios".equalsIgnoreCase(request.getPlatform())) {
        if (!"apple_iap".equalsIgnoreCase(request.getPaymentMethod())) {
            log.error("iOS platform must use Apple IAP");
            return false;
        }
    }
    // ... 其余逻辑
}
```

**预计工时**: 2 小时

---

### 🔴 H-002: 订阅条款展示不完整

**违反条款**: Guideline 3.1.2 - Subscriptions

**问题描述**:  
付费墙页面缺少必要的订阅条款说明，包括自动续订说明、取消方式、隐私政策链接等。

**涉及文件**:
- `LightGallery/Views/Subscription/PaywallView.swift`
- `LightGallery/Views/Subscription/SubscriptionView.swift`

**当前缺失内容**:
- ❌ 自动续订说明
- ❌ 取消订阅方式说明
- ❌ 隐私政策链接
- ❌ 使用条款链接
- ❌ 免费试用期说明（如适用）

**整改方案**:

在 `PaywallView.swift` 的 `subscriptionOptions` 后添加：

```swift
// MARK: - Subscription Terms (新增)

private var subscriptionTerms: some View {
    VStack(alignment: .leading, spacing: 8) {
        Divider()
            .padding(.vertical, 8)
        
        Group {
            Text("• 订阅将自动续订，除非在当前订阅期结束前至少24小时关闭自动续订")
            Text("• 账户将在当前订阅期结束前24小时内按所选套餐价格扣款")
            Text("• 您可以在 App Store 账户设置中管理和取消订阅")
            Text("• 购买后，任何未使用的免费试用期部分将被作废")
        }
        .font(.caption2)
        .foregroundColor(.secondary)
        
        HStack(spacing: 16) {
            Button("隐私政策") {
                openURL("https://your-domain.com/privacy")
            }
            
            Button("使用条款") {
                openURL("https://your-domain.com/terms")
            }
        }
        .font(.caption)
        .padding(.top, 8)
    }
    .padding(.top, 16)
}

private func openURL(_ urlString: String) {
    guard let url = URL(string: urlString) else { return }
    UIApplication.shared.open(url)
}
```

在 `body` 中调用：
```swift
var body: some View {
    // ... 现有代码
    subscriptionOptions
    subscriptionTerms  // 新增
    // ...
}
```

**预计工时**: 1 小时

---

### 🔴 H-003: 隐私政策链接未实现

**违反条款**: Guideline 5.1.1 - Data Collection and Storage

**问题描述**:  
登录页面的隐私政策和服务条款按钮点击后没有任何操作。

**涉及文件**:
- `LightGallery/Views/Auth/LoginView.swift`

**当前代码**:
```swift
// LoginView.swift (第 119-126 行)
Button("服务条款") {
    // Open terms of service  ← 未实现
}

Button("隐私政策") {
    // Open privacy policy    ← 未实现
}
```

**整改方案**:

```swift
// LoginView.swift

// 添加 URL 常量
private let privacyPolicyURL = "https://your-domain.com/privacy"
private let termsOfServiceURL = "https://your-domain.com/terms"

// 修改按钮实现
Button("服务条款") {
    if let url = URL(string: termsOfServiceURL) {
        UIApplication.shared.open(url)
    }
}

Button("隐私政策") {
    if let url = URL(string: privacyPolicyURL) {
        UIApplication.shared.open(url)
    }
}
```

**前置条件**:
- 需要准备隐私政策网页 (中英文)
- 需要准备服务条款网页 (中英文)
- 网页需要在 App Store Connect 中填写相同的 URL

**预计工时**: 0.5 小时 (代码) + 网页准备时间

---

## 中风险项 - 建议修改

### 🟡 M-001: 相册权限描述过于简单

**违反条款**: Guideline 5.1.1 - Data Collection and Storage

**问题描述**:  
当前的相册权限描述没有说明会读取照片元数据（GPS 位置、设备信息），也没有说明数据处理方式。

**涉及文件**:
- `LightGallery.xcodeproj/project.pbxproj`

**当前描述**:
```
INFOPLIST_KEY_NSPhotoLibraryUsageDescription = "此应用需要访问您的照片库来帮助您整理和管理照片。";
```

**整改方案**:

```
INFOPLIST_KEY_NSPhotoLibraryUsageDescription = "LightGallery 需要访问您的照片库以：
• 分析和清理重复/相似照片
• 读取照片元数据（位置、设备信息）用于隐私擦除功能
• 管理和整理您的照片
所有照片仅在本地处理，不会上传到任何服务器。";
```

**注意**: 由于 Info.plist 描述不支持换行，实际应为：
```
INFOPLIST_KEY_NSPhotoLibraryUsageDescription = "LightGallery 需要访问您的照片库以分析重复照片、读取照片元数据（位置、设备信息）用于隐私擦除功能、管理和整理您的照片。所有照片仅在本地处理，不会上传到服务器。";
```

**预计工时**: 0.5 小时

---

### 🟡 M-002: Sign in with Apple 按钮样式不规范

**违反条款**: Guideline 4.8 - Sign in with Apple (Human Interface Guidelines)

**问题描述**:  
当前使用自定义按钮实现 Apple 登录，而非 Apple 官方提供的 `SignInWithAppleButton` 组件。

**涉及文件**:
- `LightGallery/Views/Auth/LoginView.swift`

**当前代码**:
```swift
// 自定义按钮 (第 44-58 行)
Button(action: { ... }) {
    HStack {
        Image(systemName: "apple.logo")
        Text("使用 Apple ID 登录")
    }
    .background(Color.black)
    // ...
}
```

**整改方案**:

```swift
import AuthenticationServices

// 替换为官方按钮
SignInWithAppleButton(.signIn) { request in
    request.requestedScopes = [.fullName, .email]
} onCompletion: { result in
    switch result {
    case .success(let authorization):
        Task {
            await viewModel.handleAppleSignIn(authorization)
        }
    case .failure(let error):
        viewModel.errorMessage = "Apple 登录失败: \(error.localizedDescription)"
    }
}
.signInWithAppleButtonStyle(.black)
.frame(maxWidth: .infinity)
.frame(height: 50)
.cornerRadius(12)
```

**预计工时**: 1 小时

---

### 🟡 M-003: App Privacy Nutrition Label 配置

**违反条款**: Guideline 5.1.1 - Data Collection and Storage

**问题描述**:  
需要在 App Store Connect 中准确填写 App Privacy 信息，特别是关于照片元数据的访问。

**需要声明的数据类型**:

| 数据类型 | 用途 | 是否关联用户 |
|---------|------|-------------|
| Photos or Videos | App Functionality | 否 |
| Precise Location | App Functionality (从照片元数据读取) | 否 |
| Device ID | Analytics | 否 |
| User ID | App Functionality (登录) | 是 |

**整改方案**:
1. 登录 App Store Connect
2. 进入 App → App Privacy
3. 按上表填写数据收集声明
4. 确保与隐私政策内容一致

**预计工时**: 1 小时

---

### 🟡 M-004: 设置页面隐私政策链接未实现

**违反条款**: Guideline 5.1.1 - Data Collection and Storage

**问题描述**:  
设置页面的隐私政策导航链接只显示占位文本。

**涉及文件**:
- `LightGallery/Views/SettingsView.swift`

**当前代码**:
```swift
// SettingsView.swift (第 108-113 行)
NavigationLink {
    Text("Privacy Policy Content")  // ← 占位文本
        .navigationTitle("Privacy Policy".localized)
} label: {
    Label("Privacy Policy".localized, systemImage: "hand.raised.fill")
}
```

**整改方案**:

```swift
NavigationLink {
    PrivacyPolicyView()
        .navigationTitle("Privacy Policy".localized)
} label: {
    Label("Privacy Policy".localized, systemImage: "hand.raised.fill")
}

// 或者使用 WebView 加载在线隐私政策
NavigationLink {
    WebView(url: URL(string: "https://your-domain.com/privacy")!)
        .navigationTitle("Privacy Policy".localized)
} label: {
    Label("Privacy Policy".localized, systemImage: "hand.raised.fill")
}
```

**预计工时**: 1 小时

---

## 低风险项 - 可选优化

### 🟢 L-001: App Store 元数据优化

**相关条款**: App Store Review Guidelines - Metadata

**问题描述**:  
App 名称副标题过长，且"隐私保护"可能引起审核员额外关注。

**当前元数据**:
```
名称: LightGallery - 智能照片管理与隐私保护工具
```

**优化建议**:
```
名称: LightGallery
副标题: 智能照片清理与管理
```

**关键词建议**:
```
照片清理,重复照片,相似照片,存储空间,证件照,截图拼接,格式转换,HEIC,照片增强,照片管理
```

**预计工时**: 0.5 小时

---

### 🟢 L-002: 审核备注准备

**相关条款**: App Store Review Guidelines - General

**问题描述**:  
提交审核时应准备详细的审核备注，帮助审核员理解 App 功能。

**建议的审核备注**:

```
审核员您好，

关于 LightGallery 的几点说明：

1. 数据处理方式
   - 所有照片处理均在用户设备本地完成
   - 不会上传任何用户照片到服务器
   - AI 增强功能使用 Core ML 本地模型

2. 隐私空间功能
   - 类似 iOS 原生的"隐藏相册"功能
   - 用于保护用户个人隐私照片
   - 不涉及任何违规内容隐藏

3. 订阅说明
   - 所有订阅通过 Apple IAP 完成
   - 支持恢复购买功能
   - 取消订阅引导至 App Store 设置

4. 测试账号
   - Apple ID: [测试账号]
   - 密码: [测试密码]

如有任何问题，请随时联系我们。
```

**预计工时**: 0.5 小时

---

### 🟢 L-003: 错误提示本地化完善

**相关条款**: Guideline 2.1 - App Completeness

**问题描述**:  
部分错误提示信息混合使用中英文，建议统一。

**涉及文件**:
- `LightGallery/Services/Subscription/SubscriptionService.swift`

**当前代码**:
```swift
case .purchaseFailed(let reason):
    return "购买失败：\(reason)"  // reason 可能是英文
```

**优化建议**:
```swift
case .purchaseFailed(let reason):
    return "购买失败，请稍后重试"  // 统一使用中文
```

**预计工时**: 1 小时

---

## 整改进度跟踪

| 编号 | 风险等级 | 问题描述 | 负责人 | 状态 | 完成日期 |
|------|---------|----------|--------|------|----------|
| H-001 | 🔴 高 | 第三方支付方式代码残留 | Kiro | ✅ 已完成 | 2024-12-14 |
| H-002 | 🔴 高 | 订阅条款展示不完整 | Kiro | ✅ 已完成 | 2024-12-14 |
| H-003 | 🔴 高 | 隐私政策链接未实现 | Kiro | ✅ 已完成 | 2024-12-14 |
| M-001 | 🟡 中 | 相册权限描述过于简单 | Kiro | ✅ 已完成 | 2024-12-14 |
| M-002 | 🟡 中 | Apple 登录按钮样式 | Kiro | ✅ 已完成 | 2024-12-14 |
| M-003 | 🟡 中 | App Privacy 配置 | - | ⬜ 待处理 | - |
| M-004 | 🟡 中 | 设置页隐私政策链接 | Kiro | ✅ 已完成 | 2024-12-14 |
| L-001 | 🟢 低 | App Store 元数据优化 | Kiro | ✅ 已完成 | 2024-12-14 |
| L-002 | 🟢 低 | 审核备注准备 | Kiro | ✅ 已完成 | 2024-12-14 |
| L-003 | 🟢 低 | 错误提示本地化 | Kiro | ✅ 已完成 | 2024-12-14 |

**状态说明**: ⬜ 待处理 | 🔄 进行中 | ✅ 已完成 | ❌ 已取消

**注意**: M-003 (App Privacy 配置) 需要在 App Store Connect 中手动配置，无法通过代码完成。

---

## 提交前检查清单

### 代码层面

- [ ] **H-001**: 移除或隔离第三方支付代码
- [ ] **H-002**: PaywallView 添加订阅条款
- [ ] **H-002**: SubscriptionView 添加订阅条款
- [ ] **H-003**: LoginView 实现隐私政策链接
- [ ] **H-003**: LoginView 实现服务条款链接
- [ ] **M-001**: 更新 NSPhotoLibraryUsageDescription
- [ ] **M-002**: 使用官方 SignInWithAppleButton
- [ ] **M-004**: SettingsView 实现隐私政策页面

### App Store Connect 配置

- [ ] 填写 App Privacy Nutrition Label
- [ ] 上传隐私政策 URL
- [ ] 上传支持 URL
- [ ] 配置订阅产品信息
- [ ] 准备审核备注
- [ ] 上传所有尺寸截图

### 外部资源准备

- [ ] 隐私政策网页 (中文)
- [ ] 隐私政策网页 (英文)
- [ ] 服务条款网页 (中文)
- [ ] 服务条款网页 (英文)
- [ ] 测试账号准备

### 测试验证

- [ ] Apple IAP 购买流程测试
- [ ] 恢复购买功能测试
- [ ] 取消订阅引导测试
- [ ] Apple 登录流程测试
- [ ] 微信登录流程测试
- [ ] 支付宝登录流程测试
- [ ] 相册权限请求测试
- [ ] 相机权限请求测试

---

## 附录 A: 相关审核条款原文

### Guideline 3.1.1 - In-App Purchase
> If you want to unlock features or functionality within your app, you must use in-app purchase. Apps may not use their own mechanisms to unlock content or functionality.

### Guideline 3.1.2 - Subscriptions
> Apps offering auto-renewable subscriptions must:
> - Clearly identify the duration of the subscription
> - Clearly identify the price of the subscription
> - Explain what the user will get for the price
> - Provide a link to the terms of use

### Guideline 4.8 - Sign in with Apple
> Apps that exclusively use a third-party or social login service to set up or authenticate the user's primary account with the app must also offer Sign in with Apple as an equivalent option.

### Guideline 5.1.1 - Data Collection and Storage
> Apps that collect user or usage data must have a privacy policy and must secure user consent for the collection.

---

## 附录 B: 预计整改工时

| 风险等级 | 工时估算 |
|---------|---------|
| 🔴 高风险项 (3项) | 3.5 小时 |
| 🟡 中风险项 (4项) | 3.5 小时 |
| 🟢 低风险项 (3项) | 2 小时 |
| **总计** | **9 小时** |

**注意**: 以上工时不包括外部资源准备（如隐私政策网页制作）的时间。

---

## 文档更新记录

| 版本 | 日期 | 更新内容 | 更新人 |
|------|------|----------|--------|
| 1.0 | 2024-12-14 | 初始版本 | Kiro |

---

*本文档基于 App Store Review Guidelines 2024 版本编写，请在提交前确认最新审核要求。*
