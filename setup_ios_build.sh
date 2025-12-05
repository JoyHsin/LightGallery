#!/bin/bash

echo "=========================================="
echo "LightGallery iOS 构建配置助手"
echo "=========================================="
echo ""

# 检查是否连接了 iOS 设备
echo "正在检查连接的 iOS 设备..."
devices=$(xcrun xctrace list devices 2>&1 | grep "iPhone" | grep -v "Simulator")

if [ -z "$devices" ]; then
    echo "❌ 未检测到连接的 iPhone 设备"
    echo "请确保："
    echo "  1. iPhone 已通过 USB 连接到 Mac"
    echo "  2. iPhone 已解锁"
    echo "  3. 在 iPhone 上信任此电脑"
    exit 1
else
    echo "✅ 检测到以下 iOS 设备："
    echo "$devices"
fi

echo ""
echo "=========================================="
echo "配置步骤："
echo "=========================================="
echo ""
echo "1. 在 Xcode 中打开项目："
echo "   open LightGallery.xcodeproj"
echo ""
echo "2. 在左侧项目导航器中选择 'LightGallery' 项目"
echo ""
echo "3. 选择 'LightGallery' target"
echo ""
echo "4. 点击 'Signing & Capabilities' 标签"
echo ""
echo "5. 在 'Team' 下拉菜单中："
echo "   - 如果你有 Apple Developer 账号，选择你的团队"
echo "   - 如果没有，选择你的 Apple ID（会自动创建个人团队）"
echo ""
echo "6. 确保 'Automatically manage signing' 已勾选"
echo ""
echo "7. 在顶部工具栏选择你的 iPhone 作为目标设备"
echo ""
echo "8. 点击运行按钮 (▶️) 或按 Cmd+R"
echo ""
echo "=========================================="
echo "首次在设备上运行应用："
echo "=========================================="
echo ""
echo "如果这是第一次在你的 iPhone 上运行此应用，你需要："
echo ""
echo "1. 在 iPhone 上打开 '设置'"
echo "2. 进入 '通用' > 'VPN与设备管理'"
echo "3. 找到你的开发者应用"
echo "4. 点击 '信任'"
echo ""
echo "=========================================="

# 尝试打开 Xcode
echo ""
read -p "是否现在打开 Xcode？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open LightGallery.xcodeproj
    echo "✅ 已打开 Xcode"
fi

echo ""
echo "配置完成后，你可以直接在 Xcode 中构建和运行应用。"
