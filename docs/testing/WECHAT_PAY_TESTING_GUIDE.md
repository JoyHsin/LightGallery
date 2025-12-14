# 微信支付订阅测试指南

## 概述

本指南详细说明如何在LightGallery应用中测试真实的微信支付订阅功能。

**重要提示**: 目前应用主要支持Apple IAP，微信支付功能需要额外配置和开发。

---

## 前置条件

### 1. 微信开放平台账号
- [ ] 注册微信开放平台账号: https://open.weixin.qq.com/
- [ ] 创建移动应用
- [ ] 获取AppID和AppSecret
- [ ] 通过应用审核（需要软著等资质）

### 2. 微信商户平台账号
- [ ] 注册微信商户平台: https://pay.weixin.qq.com/
- [ ] 完成企业认证
- [ ] 开通APP支付功能
- [ ] 获取商户号(mch_id)和API密钥

### 3. 开发环境配置
- [ ] 安装微信SDK
- [ ] 配置URL Scheme
- [ ] 设置后端微信支付参数

---

## 第一步：安装和配置微信SDK

### 1.1 安装微信SDK

在项目根目录的`Podfile`中添加：

```ruby
pod 'WechatOpenSDK'
```

然后运行：
```bash
cd /path/to/LightGallery
pod install
```

### 1.2 配置Info.plist

在`LightGallery/Info.plist`中添加：

```xml
<!-- URL Schemes -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>weixin</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>wx你的微信AppID</string>
        </array>
    </dict>
</array>

<!-- 白名单 -->
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>weixin</string>
    <string>weixinULAPI</string>
</array>
```

### 1.3 注册微信SDK

修改`LightGallery/LightGalleryApp.swift`：

```swift
import SwiftUI
import WechatOpenSDK

@main
struct LightGalleryApp: App {
    
    init() {
        // 注册微信SDK
        WXApi.registerApp("你的微信AppID", universalLink: "https://yourdomain.com/")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleOpenURL(url)
                }
        }
    }
    
    private func handleOpenURL(_ url: URL) {
        if url.scheme?.hasPrefix("wx") == true {
            WXApi.handleOpen(url, delegate: nil)
        }
    }
}
```

---

## 第二步：配置后端微信支付

### 2.1 更新后端配置

在`backend/src/main/resources/application.yml`中添加：

```yaml
wechat:
  app-id: ${WECHAT_APP_ID:你的微信AppID}
  app-secret: ${WECHAT_APP_SECRET:你的微信AppSecret}
  mch-id: ${WECHAT_MCH_ID:你的商户号}
  api-key: ${WECHAT_API_KEY:你的API密钥}
  pay-notify-url: ${WECHAT_PAY_NOTIFY_URL:https://yourdomain.com/api/v1/payment/wechat/notify}
  
# 测试环境配置
spring:
  profiles:
    active: dev
    
---
spring:
  profiles: dev
  
wechat:
  sandbox: true  # 开启沙盒模式
```

### 2.2 设置环境变量

创建`.env`文件：

```bash
# 微信开放平台
WECHAT_APP_ID=wx你的AppID
WECHAT_APP_SECRET=你的AppSecret

# 微信商户平台
WECHAT_MCH_ID=你的商户号
WECHAT_API_KEY=你的API密钥
WECHAT_PAY_NOTIFY_URL=https://yourdomain.com/api/v1/payment/wechat/notify
```

---

## 第三步：实现微信支付订阅

### 3.1 创建微信支付服务

创建`LightGallery/Services/WeChatPayManager.swift`：

```swift
import Foundation
import WechatOpenSDK

class WeChatPayManager: NSObject, ObservableObject {
    static let shared = WeChatPayManager()
    
    private var paymentContinuation: CheckedContinuation<Bool, Error>?
    
    override init() {
        super.init()
    }
    
    func initiatePayment(for productId: String) async throws -> Bool {
        // 1. 向后端请求预支付订单
        let prepayOrder = try await requestPrepayOrder(productId: productId)
        
        // 2. 调起微信支付
        return try await withCheckedThrowingContinuation { continuation in
            self.paymentContinuation = continuation
            
            let req = PayReq()
            req.partnerId = prepayOrder.partnerId
            req.prepayId = prepayOrder.prepayId
            req.nonceStr = prepayOrder.nonceStr
            req.timeStamp = prepayOrder.timeStamp
            req.package = prepayOrder.package
            req.sign = prepayOrder.sign
            
            WXApi.send(req) { success in
                if !success {
                    continuation.resume(throwing: WeChatPayError.launchFailed)
                }
            }
        }
    }
    
    private func requestPrepayOrder(productId: String) async throws -> PrepayOrder {
        // 调用后端API创建预支付订单
        let url = URL(string: "https://yourdomain.com/api/v1/payment/wechat/prepay")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["productId": productId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(PrepayOrderResponse.self, from: data)
        
        return response.data
    }
}

// MARK: - WXApiDelegate
extension WeChatPayManager: WXApiDelegate {
    func onResp(_ resp: BaseResp) {
        if let payResp = resp as? PayResp {
            switch payResp.errCode {
            case WXSuccess.rawValue:
                paymentContinuation?.resume(returning: true)
            case WXErrCodeUserCancel.rawValue:
                paymentContinuation?.resume(throwing: WeChatPayError.userCancelled)
            default:
                paymentContinuation?.resume(throwing: WeChatPayError.paymentFailed(payResp.errStr))
            }
            paymentContinuation = nil
        }
    }
}

// MARK: - Models
struct PrepayOrder: Codable {
    let partnerId: String
    let prepayId: String
    let nonceStr: String
    let timeStamp: UInt32
    let package: String
    let sign: String
}

struct PrepayOrderResponse: Codable {
    let code: Int
    let message: String
    let data: PrepayOrder
}

enum WeChatPayError: Error {
    case launchFailed
    case userCancelled
    case paymentFailed(String?)
}
```

### 3.2 更新订阅视图

修改`LightGallery/Views/Subscription/SubscriptionView.swift`，添加微信支付选项：

```swift
// 在支付方式选择部分添加
VStack(spacing: 12) {
    Text("选择支付方式")
        .font(.headline)
    
    // Apple Pay
    Button(action: {
        Task {
            await purchaseWithApplePay(product)
        }
    }) {
        HStack {
            Image(systemName: "apple.logo")
            Text("Apple Pay")
            Spacer()
        }
        .padding()
        .background(Color.black)
        .foregroundColor(.white)
        .cornerRadius(12)
    }
    
    // 微信支付
    Button(action: {
        Task {
            await purchaseWithWeChatPay(product)
        }
    }) {
        HStack {
            Image("wechat_pay_icon") // 需要添加微信支付图标
            Text("微信支付")
            Spacer()
        }
        .padding()
        .background(Color.green)
        .foregroundColor(.white)
        .cornerRadius(12)
    }
}

// 添加微信支付方法
private func purchaseWithWeChatPay(_ product: SubscriptionProduct) async {
    do {
        let success = try await WeChatPayManager.shared.initiatePayment(for: product.productId)
        if success {
            // 支付成功，更新订阅状态
            await viewModel.checkSubscriptionStatus()
        }
    } catch {
        errorMessage = "微信支付失败: \(error.localizedDescription)"
    }
}
```

---

## 第四步：后端微信支付实现

### 4.1 创建微信支付控制器

创建`backend/src/main/java/com/lightgallery/backend/controller/WeChatPayController.java`：

```java
@RestController
@RequestMapping("/api/v1/payment/wechat")
@Slf4j
public class WeChatPayController {
    
    @Autowired
    private WeChatPayService weChatPayService;
    
    @PostMapping("/prepay")
    public ApiResponse<PrepayOrderDTO> createPrepayOrder(
            @RequestBody @Valid PrepayOrderRequest request,
            Authentication authentication) {
        
        String userId = authentication.getName();
        PrepayOrderDTO prepayOrder = weChatPayService.createPrepayOrder(userId, request);
        
        return ApiResponse.success("预支付订单创建成功", prepayOrder);
    }
    
    @PostMapping("/notify")
    public String handlePaymentNotify(@RequestBody String notifyData) {
        try {
            weChatPayService.handlePaymentNotify(notifyData);
            return "<xml><return_code><![CDATA[SUCCESS]]></return_code></xml>";
        } catch (Exception e) {
            log.error("处理微信支付回调失败", e);
            return "<xml><return_code><![CDATA[FAIL]]></return_code></xml>";
        }
    }
}
```

### 4.2 创建微信支付服务

创建`backend/src/main/java/com/lightgallery/backend/service/WeChatPayService.java`：

```java
@Service
@Slf4j
public class WeChatPayService {
    
    @Value("${wechat.app-id}")
    private String appId;
    
    @Value("${wechat.mch-id}")
    private String mchId;
    
    @Value("${wechat.api-key}")
    private String apiKey;
    
    @Value("${wechat.pay-notify-url}")
    private String notifyUrl;
    
    @Autowired
    private SubscriptionService subscriptionService;
    
    public PrepayOrderDTO createPrepayOrder(String userId, PrepayOrderRequest request) {
        // 1. 获取产品信息
        SubscriptionProduct product = getProductById(request.getProductId());
        
        // 2. 创建预支付订单参数
        Map<String, String> params = new HashMap<>();
        params.put("appid", appId);
        params.put("mch_id", mchId);
        params.put("nonce_str", generateNonceStr());
        params.put("body", "LightGallery " + product.getDescription());
        params.put("out_trade_no", generateTradeNo(userId));
        params.put("total_fee", String.valueOf(product.getPrice() * 100)); // 分为单位
        params.put("spbill_create_ip", "127.0.0.1");
        params.put("notify_url", notifyUrl);
        params.put("trade_type", "APP");
        
        // 3. 生成签名
        String sign = generateSign(params);
        params.put("sign", sign);
        
        // 4. 调用微信统一下单API
        String prepayId = callWeChatUnifiedOrder(params);
        
        // 5. 生成APP调起支付参数
        return buildAppPayParams(prepayId);
    }
    
    public void handlePaymentNotify(String notifyData) {
        // 1. 解析通知数据
        Map<String, String> notifyParams = parseNotifyData(notifyData);
        
        // 2. 验证签名
        if (!verifyNotifySign(notifyParams)) {
            throw new RuntimeException("签名验证失败");
        }
        
        // 3. 检查支付结果
        if ("SUCCESS".equals(notifyParams.get("result_code"))) {
            String outTradeNo = notifyParams.get("out_trade_no");
            String transactionId = notifyParams.get("transaction_id");
            
            // 4. 更新订阅状态
            updateSubscriptionFromPayment(outTradeNo, transactionId);
        }
    }
    
    private String callWeChatUnifiedOrder(Map<String, String> params) {
        // 调用微信统一下单API
        // 这里需要实现HTTP请求到微信API
        // 返回prepay_id
        return "prepay_id_from_wechat";
    }
    
    private PrepayOrderDTO buildAppPayParams(String prepayId) {
        String timeStamp = String.valueOf(System.currentTimeMillis() / 1000);
        String nonceStr = generateNonceStr();
        String packageValue = "Sign=WXPay";
        
        Map<String, String> payParams = new HashMap<>();
        payParams.put("appid", appId);
        payParams.put("partnerid", mchId);
        payParams.put("prepayid", prepayId);
        payParams.put("package", packageValue);
        payParams.put("noncestr", nonceStr);
        payParams.put("timestamp", timeStamp);
        
        String sign = generateSign(payParams);
        
        return PrepayOrderDTO.builder()
                .partnerId(mchId)
                .prepayId(prepayId)
                .nonceStr(nonceStr)
                .timeStamp(Long.parseLong(timeStamp))
                .packageValue(packageValue)
                .sign(sign)
                .build();
    }
}
```

---

## 第五步：测试流程

### 5.1 沙盒环境测试

微信支付提供沙盒环境用于测试：

1. **获取沙盒参数**
   ```bash
   curl -X POST "https://api.mch.weixin.qq.com/sandboxnew/pay/getsignkey" \
   -d "mch_id=你的商户号&nonce_str=随机字符串&sign=签名"
   ```

2. **配置沙盒环境**
   ```yaml
   wechat:
     sandbox: true
     sandbox-mch-id: 沙盒商户号
     sandbox-api-key: 沙盒API密钥
   ```

### 5.2 真实环境测试

1. **准备测试账号**
   - 使用真实微信账号
   - 确保微信钱包有余额或绑定银行卡

2. **配置生产环境**
   ```yaml
   wechat:
     sandbox: false
     app-id: 正式AppID
     mch-id: 正式商户号
     api-key: 正式API密钥
   ```

3. **测试步骤**
   ```
   1. 启动应用
   2. 进入订阅页面
   3. 选择订阅套餐
   4. 选择微信支付
   5. 确认支付信息
   6. 调起微信支付
   7. 在微信中完成支付
   8. 返回应用验证订阅状态
   ```

### 5.3 测试检查清单

- [ ] 微信SDK正确集成
- [ ] URL Scheme配置正确
- [ ] 后端API正常响应
- [ ] 预支付订单创建成功
- [ ] 微信支付界面正常调起
- [ ] 支付流程完整
- [ ] 支付回调处理正确
- [ ] 订阅状态更新正确
- [ ] 功能解锁正常

---

## 第六步：调试和问题排查

### 6.1 常见问题

1. **微信未安装**
   ```swift
   if !WXApi.isWXAppInstalled() {
       // 提示用户安装微信
       showAlert("请先安装微信客户端")
       return
   }
   ```

2. **签名错误**
   ```java
   // 检查参数排序和编码
   String signString = params.entrySet().stream()
       .filter(entry -> !"sign".equals(entry.getKey()))
       .sorted(Map.Entry.comparingByKey())
       .map(entry -> entry.getKey() + "=" + entry.getValue())
       .collect(Collectors.joining("&"));
   ```

3. **回调验证失败**
   ```java
   // 验证回调签名
   String receivedSign = notifyParams.get("sign");
   String calculatedSign = generateSign(notifyParams);
   if (!receivedSign.equals(calculatedSign)) {
       throw new RuntimeException("回调签名验证失败");
   }
   ```

### 6.2 日志调试

在后端添加详细日志：

```java
@Slf4j
public class WeChatPayService {
    
    public PrepayOrderDTO createPrepayOrder(String userId, PrepayOrderRequest request) {
        log.info("创建微信预支付订单: userId={}, productId={}", userId, request.getProductId());
        
        // ... 业务逻辑
        
        log.info("预支付订单创建成功: prepayId={}", prepayId);
        return result;
    }
    
    public void handlePaymentNotify(String notifyData) {
        log.info("收到微信支付回调: {}", notifyData);
        
        // ... 处理逻辑
        
        log.info("支付回调处理完成: tradeNo={}", outTradeNo);
    }
}
```

### 6.3 测试工具

1. **Postman测试后端API**
   ```json
   POST /api/v1/payment/wechat/prepay
   {
     "productId": "com.lightgallery.pro.monthly"
   }
   ```

2. **微信支付接口调试工具**
   - 使用微信官方提供的接口调试工具
   - 验证签名算法正确性

---

## 第七步：上线前检查

### 7.1 安全检查
- [ ] API密钥安全存储
- [ ] 签名算法正确实现
- [ ] 回调URL使用HTTPS
- [ ] 参数验证完整

### 7.2 功能检查
- [ ] 所有订阅套餐可正常购买
- [ ] 支付成功后功能正常解锁
- [ ] 订阅状态同步正确
- [ ] 错误处理完善

### 7.3 合规检查
- [ ] 微信开放平台应用审核通过
- [ ] 商户平台资质完整
- [ ] 支付功能符合相关法规

---

## 总结

要测试真实的微信支付订阅，你需要：

1. **完成微信开放平台和商户平台的注册认证**
2. **集成微信SDK到iOS应用**
3. **实现后端微信支付API**
4. **配置正确的回调处理**
5. **进行完整的端到端测试**

**注意**: 微信支付的集成相对复杂，需要企业资质和较长的审核周期。建议先完善Apple IAP功能，再逐步添加微信支付支持。

如果你需要快速测试订阅功能，建议优先使用Apple IAP，它的集成更简单，测试环境更完善。