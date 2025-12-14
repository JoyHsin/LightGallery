# Alipay Info.plist Configuration

This file documents the required Info.plist configuration for Alipay OAuth integration.

## Required Configuration

### 1. URL Scheme Configuration

Add the following to your Info.plist to handle Alipay OAuth callbacks:

**In Xcode:**
1. Open your project in Xcode
2. Select the LightGallery target
3. Go to the "Info" tab
4. Expand "URL Types"
5. Click "+" to add a new URL Type
6. Set the following values:
   - **Identifier**: `alipay`
   - **URL Schemes**: `ap{YOUR_ALIPAY_APP_ID}` (replace with your actual Alipay App ID)
   - **Role**: Editor

**In Info.plist XML:**
```xml
<key>CFBundleURLTypes</key>
<array>
    <!-- Existing URL types (WeChat, etc.) -->
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

### 2. LSApplicationQueriesSchemes Configuration

Add Alipay to the list of queryable schemes to allow the app to check if Alipay is installed:

**In Xcode:**
1. Open Info.plist
2. Add a new row with key: `LSApplicationQueriesSchemes`
3. Set type to Array
4. Add the following string items:
   - `alipay`
   - `alipayshare`

**In Info.plist XML:**
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <!-- Existing schemes (weixin, weixinULAPI, etc.) -->
    <string>alipay</string>
    <string>alipayshare</string>
</array>
```

## Complete Example

Here's a complete example of what your Info.plist should include for all OAuth providers:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Other Info.plist entries -->
    
    <!-- URL Types for OAuth callbacks -->
    <key>CFBundleURLTypes</key>
    <array>
        <!-- WeChat -->
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
        
        <!-- Alipay -->
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
    
    <!-- Queryable Schemes -->
    <key>LSApplicationQueriesSchemes</key>
    <array>
        <string>weixin</string>
        <string>weixinULAPI</string>
        <string>alipay</string>
        <string>alipayshare</string>
    </array>
    
    <!-- Other Info.plist entries -->
</dict>
</plist>
```

## Verification

After adding the configuration:

1. Build and run the app
2. Check that the URL scheme is registered by running:
   ```bash
   xcrun simctl openurl booted "ap{YOUR_APP_ID}://oauth?code=test"
   ```
3. The app should open and handle the URL

## Notes

- Replace `{YOUR_ALIPAY_APP_ID}` with your actual Alipay App ID from the Alipay Open Platform
- The URL scheme must match exactly what's configured in the Alipay Developer Console
- For production apps, ensure the App ID is stored securely and not hardcoded

## Related Files

- `AlipayOAuthManager.swift` - Handles the OAuth flow and URL callbacks
- `LightGalleryApp.swift` - Registers the URL handler
- `Alipay_Integration_Guide.md` - Complete integration guide
