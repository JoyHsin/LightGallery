# WeChat SDK Integration Guide

## Overview
This guide explains how to integrate the WeChat SDK for OAuth authentication in the LightGallery iOS app.

## Prerequisites
- WeChat App ID (obtain from WeChat Open Platform: https://open.weixin.qq.com/)
- WeChat App Secret (for backend token exchange)

## Step 1: Install WeChat SDK

### Option A: CocoaPods
Add to your `Podfile`:
```ruby
pod 'WechatOpenSDK'
```

Then run:
```bash
pod install
```

### Option B: Swift Package Manager
Add package dependency in Xcode:
```
https://github.com/Tencent/wechat-sdk-ios-cocoapods
```

### Option C: Manual Installation
1. Download SDK from: https://developers.weixin.qq.com/doc/oplatform/Mobile_App/Access_Guide/iOS.html
2. Add `libWeChatSDK.a` and header files to your project
3. Link required frameworks:
   - SystemConfiguration.framework
   - CoreTelephony.framework
   - Security.framework
   - CFNetwork.framework
   - libc++.tbd
   - libz.tbd
   - libsqlite3.0.tbd

## Step 2: Configure Info.plist

Add the following to your `Info.plist` or project settings:

### 1. URL Scheme
Add a new URL Type:
- **Identifier**: `weixin`
- **URL Schemes**: `wx{YOUR_WECHAT_APP_ID}` (replace with your actual App ID)
- **Role**: Editor

In XML format:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>weixin</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>wx{YOUR_WECHAT_APP_ID}</string>
        </array>
    </dict>
</array>
```

### 2. LSApplicationQueriesSchemes
Add WeChat to the list of queryable schemes:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>weixin</string>
    <string>weixinULAPI</string>
</array>
```

## Step 3: Register WeChat SDK

### In LightGalleryApp.swift:

```swift
import SwiftUI
// Import WeChat SDK (uncomment when SDK is installed)
// import WechatOpenSDK

@main
struct LightGalleryApp: App {
    
    init() {
        // Register WeChat App ID
        // Uncomment when SDK is installed:
        // WXApi.registerApp("YOUR_WECHAT_APP_ID", universalLink: "https://yourdomain.com/")
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
        // Handle WeChat OAuth callback
        if url.scheme?.hasPrefix("wx") == true {
            // Uncomment when SDK is installed:
            // WXApi.handleOpen(url, delegate: self)
            
            // For now, use our manager directly
            let wechatManager = WeChatOAuthManager()
            _ = wechatManager.handleOpenURL(url)
        }
    }
}
```

## Step 4: Handle OAuth Callbacks

The `WeChatOAuthManager` already includes callback handling. When WeChat app returns to your app:

1. The URL scheme handler receives the callback
2. `handleOpenURL(_:)` extracts the authorization code
3. The code is exchanged for an access token via your backend
4. User information is retrieved and a User object is created

## Step 5: Backend Integration

Your backend should implement the token exchange endpoint:

```
POST /api/v1/auth/oauth/exchange
{
    "provider": "wechat",
    "code": "authorization_code_from_wechat",
    "state": "csrf_state_token"
}

Response:
{
    "accessToken": "your_app_access_token",
    "refreshToken": "your_app_refresh_token",
    "expiresAt": "2024-12-07T12:00:00Z",
    "user": {
        "id": "user_id",
        "displayName": "User Name",
        "email": "user@example.com",
        "authProvider": "wechat"
    }
}
```

## Step 6: Update Configuration

Update `WeChatOAuthManager` initialization with your App ID:

```swift
// In AuthenticationService.swift
private let wechatManager = WeChatOAuthManager(
    appId: "YOUR_WECHAT_APP_ID",
    appSecret: "YOUR_WECHAT_APP_SECRET"  // Only if doing direct API calls
)
```

**Security Note**: Never hardcode App Secret in the client app. Token exchange should happen on your backend server.

## Testing

### Test in Development:
1. Install WeChat app on your test device
2. Ensure your App ID is registered and approved on WeChat Open Platform
3. Test the OAuth flow:
   - Tap "微信登录" button
   - WeChat app opens with authorization prompt
   - User approves
   - App receives callback with authorization code
   - Backend exchanges code for tokens
   - User is logged in

### Sandbox Testing:
WeChat provides a sandbox environment for testing. Configure sandbox App ID in development builds.

## Troubleshooting

### "WeChat app not installed"
- Ensure WeChat is installed on the device
- Check LSApplicationQueriesSchemes is configured correctly

### "Invalid App ID"
- Verify App ID is correct in both code and WeChat Open Platform
- Ensure App ID is approved and active

### "Callback not received"
- Check URL scheme is configured correctly (wx{APP_ID})
- Verify URL scheme handler is implemented
- Check WeChat SDK is properly registered

### "Token exchange failed"
- Verify backend endpoint is accessible
- Check App Secret is correct on backend
- Ensure authorization code hasn't expired (valid for 5 minutes)

## Security Considerations

1. **Never store App Secret in the client app** - always exchange tokens on your backend
2. **Use HTTPS** for all backend API calls
3. **Validate state parameter** to prevent CSRF attacks
4. **Implement token refresh** before tokens expire
5. **Store tokens securely** in Keychain

## References

- WeChat Open Platform: https://open.weixin.qq.com/
- iOS Access Guide: https://developers.weixin.qq.com/doc/oplatform/Mobile_App/Access_Guide/iOS.html
- OAuth 2.0 Documentation: https://developers.weixin.qq.com/doc/oplatform/Mobile_App/WeChat_Login/Development_Guide.html
