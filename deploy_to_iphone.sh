#!/bin/bash

echo "=========================================="
echo "LightGallery - 部署到 iPhone"
echo "=========================================="
echo ""

# 获取设备 ID
DEVICE_ID="00008120-001A20A43600C01E"
DEVICE_NAME="Hsin's IPhone"

echo "目标设备: $DEVICE_NAME"
echo "设备 ID: $DEVICE_ID"
echo ""

# 检查设备是否连接
echo "检查设备连接状态..."
if xcrun xctrace list devices 2>&1 | grep -q "$DEVICE_ID"; then
    echo "✅ 设备已连接"
else
    echo "❌ 设备未连接或不可用"
    echo "请确保："
    echo "  1. iPhone 已通过 USB 连接"
    echo "  2. iPhone 已解锁"
    echo "  3. 在 iPhone 上信任此电脑"
    exit 1
fi

echo ""
echo "开始构建和部署..."
echo ""

# 清理并构建
xcodebuild clean \
    -project LightGallery.xcodeproj \
    -scheme LightGallery \
    -destination "platform=iOS,id=$DEVICE_ID" \
    > /dev/null 2>&1

# 构建并安装到设备
xcodebuild build \
    -project LightGallery.xcodeproj \
    -scheme LightGallery \
    -destination "platform=iOS,id=$DEVICE_ID" \
    -configuration Debug

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ 构建成功！"
    echo "=========================================="
    echo ""
    echo "应用已安装到你的 iPhone 上。"
    echo ""
    echo "如果这是首次运行，请在 iPhone 上："
    echo "1. 打开 设置 > 通用 > VPN与设备管理"
    echo "2. 信任开发者证书"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "❌ 构建失败"
    echo "=========================================="
    echo ""
    echo "请检查上面的错误信息。"
    echo "常见问题："
    echo "  - 设备正忙或正在同步"
    echo "  - 需要在 Xcode 中配置签名"
    echo "  - iOS 版本不兼容（需要 iOS 17.0+）"
    echo ""
    exit 1
fi
