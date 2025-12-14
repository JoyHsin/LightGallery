# Alipay OAuth Integration Guide

This guide explains how to integrate Alipay OAuth authentication into the LightGallery iOS app.

## Prerequisites

1. Register your app on the Alipay Open Platform: https://open.alipay.com/
2. Obtain your App ID (APPID) from the Alipay Developer Console
3. Configure your app's bundle identifier and redirect URL in the Alipay console

## Installation

### Option 1: CocoaPods

Add to your `Podfile`:

```ruby
pod 'AlipaySDK-iOS'
```

Then run:
```bash
pod install
```

### Option 2: Manual Installation

1. Download the Alipay SDK from: https://opendocs.alipay.com/open/54/00y8k9
2. Add `AlipaySDK.framework` to your Xcode project
3. Add required system frameworks:
   - SystemConfiguration.framework
   - CoreTelephony.framework
   - QuartzCore.framework
   - CoreText.framework
   - CoreGraphics.framework
   - UIKit.framework
   - Foundation.framework
   - CFNetwork.framework
   - CoreMotion.framework
   - libc++.tbd
   - libz.tbd

## Configuration

### 1. Configure Info.plist

Add the following to your `Info.plist`:

#### URL Scheme for Alipay Callback

In XML format:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>alipay</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>ap{YOUR_ALIPAY_APP_ID}</string>
        </array>
    </dict>
</array>
```

Or in Xcode's Info tab:
- URL Types → Add new URL Type
- Identifier: `alipay`
- URL Schemes: `ap{YOUR_ALIPAY_APP_ID}` (replace with your actual App ID)

#### LSApplicationQueriesSchemes

Add Alipay to the list of queryable schemes:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>alipay</string>
    <string>alipayshare</string>
</array>
```

### 2. Register Alipay App ID

In your `LightGalleryApp.swift` or `AppDelegate.swift`, register the Alipay App ID:

```swift
import AlipaySDK

@main
struct LightGalleryApp: App {
    init() {
        // Register Alipay App ID
        // Note: Actual registration is handled in AlipayOAuthManager
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
        // Handle Alipay OAuth callback
        if url.scheme?.hasPrefix("ap") == true {
            let alipayManager = AlipayOAuthManager()
            _ = alipayManager.handleOpenURL(url)
        }
    }
}
```

### 3. Handle URL Callbacks

The app needs to handle URL callbacks from the Alipay app. This is done using the `.onOpenURL` modifier in SwiftUI or `application(_:open:options:)` in UIKit.

## Usage

### Basic OAuth Flow

```swift
let alipayManager = AlipayOAuthManager(appId: "YOUR_ALIPAY_APP_ID")

do {
    // Initiate Alipay OAuth
    let credential = try await alipayManager.initiateSignIn()
    
    // Exchange authorization code for access token
    let userInfo = try await alipayManager.exchangeCodeForToken(code: credential.code)
    
    print("User ID: \(userInfo.userId)")
    print("Nickname: \(userInfo.nickname)")
    
} catch {
    print("Alipay OAuth failed: \(error)")
}
```

### Integration with AuthenticationService

The `AuthenticationService` already includes Alipay support:

```swift
let authService = AuthenticationService.shared

do {
    let user = try await authService.signInWithAlipay()
    print("Signed in as: \(user.displayName)")
} catch {
    print("Sign in failed: \(error)")
}
```

## OAuth Flow Diagram

```
┌─────────────┐                                    ┌─────────────┐
│             │  1. initiateSignIn()               │             │
│  Your App   │───────────────────────────────────>│ Alipay App  │
│             │                                    │             │
│             │  2. User authorizes                │             │
│             │<───────────────────────────────────│             │
└─────────────┘                                    └─────────────┘
       │                                                  │
       │ 3. Callback with auth code                      │
       │<─────────────────────────────────────────────────┘
       │
       │ 4. exchangeCodeForToken(code)
       │
       v
┌─────────────┐                                    ┌─────────────┐
│             │  5. Exchange code for token        │             │
│  Your App   │───────────────────────────────────>│   Backend   │
│             │                                    │   Server    │
│             │  6. Return access token & user info│             │
│             │<───────────────────────────────────│             │
└─────────────┘                                    └─────────────┘
```

## Security Considerations

1. **Never hardcode App Secret**: Store sensitive credentials in environment variables or secure configuration
2. **Use HTTPS**: All API calls to your backend should use HTTPS
3. **Validate State Parameter**: Implement CSRF protection using the state parameter
4. **Token Storage**: Store access tokens securely in Keychain (handled by `SecureStorage`)
5. **Backend Validation**: Always validate OAuth tokens on your backend server

## Testing

### Sandbox Environment

Alipay provides a sandbox environment for testing:
- Sandbox URL: https://openapi.alipaydev.com/gateway.do
- Use sandbox accounts from the Alipay Developer Console

### Test Accounts

Create test accounts in the Alipay Developer Console for testing the OAuth flow.

## Troubleshooting

### Common Issues

1. **"Alipay app not installed"**
   - The SDK will fall back to web-based OAuth if the Alipay app is not installed
   - Ensure your URL scheme is correctly configured

2. **"Invalid App ID"**
   - Verify your App ID in the Alipay Developer Console
   - Ensure the App ID matches in both the code and Info.plist

3. **"Callback not received"**
   - Check that your URL scheme is correctly configured
   - Verify the `handleOpenURL` method is being called
   - Check that the URL scheme matches: `ap{YOUR_APP_ID}`

4. **"Authorization failed"**
   - Verify your app's bundle identifier is registered in Alipay console
   - Check that your redirect URL is correctly configured
   - Ensure you're using the correct environment (sandbox vs production)

## API Reference

### AlipayOAuthManager

- `initiateSignIn() async throws -> AlipayCredential`
  - Initiates the Alipay OAuth flow
  - Returns authorization code and state

- `exchangeCodeForToken(code: String) async throws -> AlipayUserInfo`
  - Exchanges authorization code for access token
  - Returns user information and tokens

- `handleOpenURL(_ url: URL) -> Bool`
  - Handles OAuth callback from Alipay app
  - Returns true if URL was handled

## Resources

- Alipay Open Platform: https://open.alipay.com/
- Alipay OAuth Documentation: https://opendocs.alipay.com/open/218/105325
- iOS SDK Documentation: https://opendocs.alipay.com/open/54/00y8k9
- Developer Console: https://open.alipay.com/dev/workspace

## Support

For issues with Alipay SDK integration:
- Alipay Developer Forum: https://forum.alipay.com/
- Technical Support: Contact through Alipay Developer Console
