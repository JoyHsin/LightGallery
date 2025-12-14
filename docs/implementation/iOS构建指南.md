# LightGallery iOS 构建指南

## 问题诊断

根据错误信息，主要问题是：
1. ✅ **iOS 部署目标已修复** - 从 18.5 调整到 17.0（应用使用了 iOS 17+ 的 API）
2. ✅ **开发团队已配置** - 使用 "RENYI XING (Personal Team)"
3. ✅ **设备已连接** - 检测到 "Hsin's IPhone"
4. ✅ **构建成功** - 应用已成功编译和签名

## 解决步骤

### 1. 在 Xcode 中打开项目

```bash
open LightGallery.xcodeproj
```

### 2. 配置签名

1. 在左侧项目导航器中，点击最顶部的 **LightGallery** 项目图标（蓝色的）
2. 在中间区域，选择 **TARGETS** 下的 **LightGallery**
3. 点击顶部的 **Signing & Capabilities** 标签
4. 确保 **Automatically manage signing** 已勾选 ✅
5. 在 **Team** 下拉菜单中：
   - 如果你有 Apple Developer 账号，选择你的团队
   - 如果没有，点击 **Add Account...** 添加你的 Apple ID
   - 添加后，选择你的 Apple ID（会显示为 "Personal Team"）

### 3. 选择目标设备

1. 在 Xcode 顶部工具栏，点击设备选择器（默认可能显示 "My Mac"）
2. 从下拉菜单中选择 **Hsin's IPhone**
3. 如果设备显示为"忙碌"或"正在准备"，等待几秒钟

### 4. 构建并运行

1. 点击左上角的 **运行按钮** (▶️) 或按 **Cmd + R**
2. 等待构建完成

### 5. 首次运行 - 信任开发者

如果这是第一次在你的 iPhone 上运行此应用，你会看到一个错误提示。需要：

1. 在 iPhone 上打开 **设置**
2. 进入 **通用** > **VPN与设备管理**
3. 找到你的开发者应用（可能显示为你的 Apple ID 邮箱）
4. 点击 **信任 "[你的邮箱]"**
5. 在弹出的对话框中再次点击 **信任**
6. 返回 Xcode，再次点击运行按钮

## 常见问题

### Q: 提示 "Device is busy"
**A:** 设备可能正在同步或准备中。解决方法：
- 等待几分钟
- 在 iPhone 上解锁屏幕
- 断开并重新连接 USB 线
- 在 Xcode 菜单中选择 **Window** > **Devices and Simulators**，检查设备状态

### Q: 提示 "Signing for LightGallery requires a development team"
**A:** 按照上面的步骤 2 配置签名

### Q: 提示 "Could not launch LightGallery"
**A:** 需要在 iPhone 上信任开发者证书（见步骤 5）

### Q: 构建成功但应用闪退
**A:** 检查以下几点：
- 确保 iPhone 运行的 iOS 版本 ≥ 16.0
- 在 iPhone 上打开应用时，检查是否有权限请求弹窗
- 在设置中授予照片库访问权限

## 技术细节

已修复的配置：
- `IPHONEOS_DEPLOYMENT_TARGET`: 18.5 → 17.0（应用使用了 iOS 17+ 的新 API）
- `MACOSX_DEPLOYMENT_TARGET`: 15.5 → 14.0
- `XROS_DEPLOYMENT_TARGET`: 2.5 → 1.0

**重要提示**：你的 iPhone 14 Pro 需要运行 iOS 17.0 或更高版本才能运行此应用。如果你的 iPhone 运行的是较旧版本，请先更新系统。

## 下一步

配置完成后，你可以：
1. 直接在 iPhone 上测试应用
2. 使用 Xcode 的调试功能查看日志
3. 在真机上测试照片库访问和滑动手势

如果遇到其他问题，请查看 Xcode 的错误信息或控制台日志。
