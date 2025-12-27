# Design Document

## Overview

Declutter是一个专注于照片清理的iOS应用，采用SwiftUI框架构建。应用的核心设计理念是提供极简、高效的照片浏览和删除体验。通过直观的滑动手势和实时反馈，用户可以快速决定保留或删除照片，从而高效地管理相册空间。

应用采用MVVM架构模式，确保代码的可维护性和可测试性。所有照片操作都通过iOS Photos框架进行，确保与系统相册的完全兼容性。

## Architecture

### 整体架构
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   SwiftUI Views │    │   ViewModels    │    │    Services     │
│                 │    │                 │    │                 │
│ • PhotoSwipeView│◄──►│ • PhotoViewModel│◄──►│ • PhotoService  │
│ • ProgressView  │    │ • ProgressVM    │    │ • FilterService │
│ • FilterView    │    │ • FilterVM      │    │ • StatsService  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                               ┌─────────────────┐
                                               │  iOS Frameworks │
                                               │                 │
                                               │ • Photos        │
                                               │ • PhotosUI      │
                                               │ • SwiftUI       │
                                               └─────────────────┘
```

### 核心组件层次
1. **Presentation Layer (SwiftUI Views)** - 用户界面和交互
2. **Business Logic Layer (ViewModels)** - 业务逻辑和状态管理
3. **Data Access Layer (Services)** - 数据访问和照片操作
4. **System Integration Layer** - iOS框架集成

## Components and Interfaces

### 1. PhotoService
负责与iOS Photos框架的集成和照片数据管理。

```swift
protocol PhotoServiceProtocol {
    func requestPhotoLibraryAccess() async -> Bool
    func fetchAllPhotos() async -> [PhotoAsset]
    func fetchPhotosInDateRange(_ startDate: Date, _ endDate: Date) async -> [PhotoAsset]
    func movePhotoToTrash(_ asset: PhotoAsset) async throws
    func getPhotoCreationDate(_ asset: PhotoAsset) -> Date?
}
```

**核心功能：**
- 权限管理和照片库访问
- 按时间顺序获取照片资源
- 时间范围筛选
- 照片删除操作（移动到最近删除）

### 2. PhotoAsset Model
照片资源的数据模型，封装PHAsset和相关元数据。

```swift
struct PhotoAsset: Identifiable, Equatable {
    let id: String
    let phAsset: PHAsset
    let creationDate: Date
    let localIdentifier: String
    
    var formattedDate: String { /* 格式化显示日期 */ }
    var formattedTime: String { /* 格式化显示时间 */ }
}
```

### 3. PhotoViewModel
主要的业务逻辑控制器，管理照片浏览状态和用户操作。

```swift
@MainActor
class PhotoViewModel: ObservableObject {
    @Published var photos: [PhotoAsset] = []
    @Published var currentIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var hasPermission: Bool = false
    @Published var deletedCount: Int = 0
    @Published var keptCount: Int = 0
    
    func loadPhotos()
    func swipeLeft() // 删除当前照片
    func swipeRight() // 保留当前照片
    func applyDateFilter(_ startDate: Date, _ endDate: Date)
    func clearFilter()
}
```

### 4. PhotoSwipeView
主要的照片浏览界面，支持滑动手势和动画反馈。

```swift
struct PhotoSwipeView: View {
    @StateObject private var viewModel = PhotoViewModel()
    @State private var dragOffset: CGSize = .zero
    @State private var swipeDirection: SwipeDirection? = nil
    
    var body: some View {
        // 照片显示 + 手势处理 + 动画效果
    }
}
```

**关键特性：**
- 全屏照片显示
- 左右滑动手势识别
- 流畅的动画过渡
- 实时视觉反馈

### 5. ProgressStatsView
显示清理进度和统计信息的组件。

```swift
struct ProgressStatsView: View {
    let currentIndex: Int
    let totalCount: Int
    let deletedCount: Int
    let keptCount: Int
    let currentPhoto: PhotoAsset?
    
    var progressPercentage: Double { /* 计算进度百分比 */ }
}
```

### 6. FilterView
时间筛选功能的界面组件。

```swift
struct FilterView: View {
    @Binding var isPresented: Bool
    let onFilterApplied: (Date, Date) -> Void
    let onFilterCleared: () -> Void
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
}
```

## Data Models

### PhotoAsset
```swift
struct PhotoAsset: Identifiable, Equatable {
    let id: String
    let phAsset: PHAsset
    let creationDate: Date
    let localIdentifier: String
    
    // 计算属性
    var formattedDate: String
    var formattedTime: String
    var year: Int
    var month: Int
}
```

### SwipeAction
```swift
enum SwipeAction {
    case delete
    case keep
    case none
}

enum SwipeDirection {
    case left
    case right
}
```

### FilterCriteria
```swift
struct FilterCriteria {
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    
    static let none = FilterCriteria(
        startDate: Date.distantPast,
        endDate: Date.distantFuture,
        isActive: false
    )
}
```

### AppState
```swift
struct AppState {
    var photos: [PhotoAsset] = []
    var currentIndex: Int = 0
    var deletedPhotos: Set<String> = []
    var keptPhotos: Set<String> = []
    var filter: FilterCriteria = .none
    var hasPhotoPermission: Bool = false
}
```

## Error Handling

### 错误类型定义
```swift
enum PhotoError: LocalizedError {
    case permissionDenied
    case photoLibraryUnavailable
    case deletionFailed(String)
    case loadingFailed(String)
    case filteringFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "需要访问照片库的权限才能使用此功能"
        case .photoLibraryUnavailable:
            return "照片库当前不可用"
        case .deletionFailed(let reason):
            return "删除照片失败：\(reason)"
        case .loadingFailed(let reason):
            return "加载照片失败：\(reason)"
        case .filteringFailed(let reason):
            return "筛选照片失败：\(reason)"
        }
    }
}
```

### 错误处理策略
1. **权限错误** - 显示权限请求对话框，引导用户到设置页面
2. **网络/系统错误** - 显示重试选项和错误信息
3. **操作失败** - 提供撤销选项和详细错误描述
4. **数据加载错误** - 显示加载状态和重新加载按钮

### 用户体验保障
- 所有异步操作都有加载状态指示
- 错误信息使用用户友好的中文描述
- 提供明确的恢复操作路径
- 关键操作失败时保持应用状态稳定

## Testing Strategy

### 单元测试
1. **PhotoService测试**
   - 权限请求流程
   - 照片获取和筛选逻辑
   - 删除操作的正确性

2. **ViewModel测试**
   - 状态管理逻辑
   - 用户操作响应
   - 数据绑定正确性

3. **Model测试**
   - 数据模型的属性计算
   - 相等性比较
   - 序列化/反序列化

### 集成测试
1. **照片库集成**
   - 真实照片数据的加载
   - 删除操作的系统集成
   - 权限流程的端到端测试

2. **UI集成测试**
   - 手势识别准确性
   - 动画流畅性
   - 状态同步正确性

### UI测试
1. **核心用户流程**
   - 应用启动和权限授权
   - 照片浏览和滑动操作
   - 筛选功能使用
   - 进度统计显示

2. **边界情况测试**
   - 空相册处理
   - 网络断开情况
   - 内存不足场景
   - 权限被撤销的处理

### 性能测试
1. **内存使用**
   - 大量照片加载时的内存管理
   - 图片缓存策略效果
   - 内存泄漏检测

2. **响应性能**
   - 滑动手势响应时间
   - 照片切换流畅度
   - 大相册加载性能

### 测试数据准备
- 创建包含不同时间段照片的测试相册
- 准备各种分辨率和格式的测试图片
- 模拟不同权限状态的测试场景