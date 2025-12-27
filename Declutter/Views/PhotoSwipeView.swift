//
//  PhotoSwipeView.swift
//  Declutter
//
//  Created by Kiro on 2025/9/7.
//

import SwiftUI
import Photos
import PhotosUI



/// 自定义AsyncImage用于加载PHAsset
struct PhotoAsyncImage<Content: View, Placeholder: View>: View {
    let phAsset: PHAsset
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var image: PlatformImage?
    @State private var isLoading = true
    
    init(
        phAsset: PHAsset,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.phAsset = phAsset
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                #if canImport(UIKit)
                content(Image(uiImage: image))
                #elseif canImport(AppKit)
                content(Image(nsImage: image))
                #endif
            } else if isLoading {
                placeholder()
            } else {
                // 加载失败的占位符
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
        }
        .task {
            await loadImage()
        }
        .onChange(of: phAsset.localIdentifier) {
            Task {
                await loadImage()
            }
        }
    }
    
    private func loadImage() async {
        isLoading = true
        image = nil
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: phAsset,
                targetSize: CGSize(width: 1024, height: 1024), // 适中的分辨率
                contentMode: .aspectFit,
                options: options
            ) { result, _ in
                DispatchQueue.main.async {
                    self.image = result
                    self.isLoading = false
                    continuation.resume()
                }
            }
        }
    }
}

/// 主要的照片浏览界面，支持滑动手势和动画反馈
struct PhotoSwipeView: View {
    @EnvironmentObject private var viewModel: PhotoViewModel
    @State private var dragOffset: CGSize = .zero
    @State private var swipeDirection: SwipeDirection? = nil
    @State private var isSwipeInProgress: Bool = false
    @State private var swipeActionType: SwipeAction = .none
    @State private var animationScale: CGFloat = 1.0
    @State private var backgroundOpacity: Double = 1.0
    @State private var indicatorOpacity: Double = 0.0
    @State private var rotationAngle: Double = 0.0
    @AppStorage("skipDeleteConfirmation") private var skipDeleteConfirmation: Bool = false
    @State private var showDeleteConfirmationDialog: Bool = false
    @State private var showAlbumSelection: Bool = false

    
    // 手势阈值常量
    private let swipeThreshold: CGFloat = 100.0  // 触发滑动操作的最小距离
    private let velocityThreshold: CGFloat = 300.0  // 触发快速滑动的速度阈值
    
    // 动画常量
    private let maxRotationAngle: Double = 15.0  // 最大旋转角度
    private let animationDuration: Double = 0.25  // 主动画持续时间
    private let quickAnimationDuration: Double = 0.15  // 快速动画持续时间
    
    let photoService: PhotoServiceProtocol
    let onFinishWithoutDeletion: () -> Void
    let onFinishAfterDeletion: () -> Void
    
    init(photoService: PhotoServiceProtocol, onFinishWithoutDeletion: @escaping () -> Void, onFinishAfterDeletion: @escaping () -> Void) {
        self.photoService = photoService
        self.onFinishWithoutDeletion = onFinishWithoutDeletion
        self.onFinishAfterDeletion = onFinishAfterDeletion
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                loadingView
            } else if !viewModel.hasPermission {
                permissionView
            } else if viewModel.photos.isEmpty {
                emptyStateView
            } else {
                photoContentView
            }
        }
        .confirmationDialog(
            "确认删除这张照片吗？",
            isPresented: $showDeleteConfirmationDialog,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                performSwipeAction(direction: .left)
            }
            Button("删除并不再询问", role: .destructive) {
                skipDeleteConfirmation = true
                performSwipeAction(direction: .left)
            }
            Button("取消", role: .cancel) {
                resetSwipeState()
            }
        } message: {
            Text("此操作会将照片移至“最近删除”，可在30天内恢复。")
        }
        .alert("操作失败", isPresented: .constant(viewModel.errorMessage != nil)) {
            if viewModel.showRetryOption {
                Button("重试") {
                    viewModel.retryLastOperation()
                }
                .keyboardShortcut(.defaultAction)
                
                Button("取消") {
                    viewModel.clearError()
                }
            } else {
                Button("确定") {
                    viewModel.clearError()
                }
                .keyboardShortcut(.defaultAction)
                
                if !viewModel.hasPermission {
                    Button("前往设置") {
                        openAppSettings()
                        viewModel.clearError()
                    }
                }
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .onKeyPress(.leftArrow) {
            navigateToPrevious()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            navigateToNext()
            return .handled
        }
        .focusable()
        .sheet(isPresented: $showAlbumSelection) {
            AlbumSelectionView { album in
                guard let asset = viewModel.currentPhoto?.phAsset else { return }
                Task {
                    do {
                        try await photoService.addAssetToAlbum(asset: asset, album: album)
                        // 归档成功后，自动执行“保留”操作（右滑）
                        await MainActor.run {
                            performSwipeAction(direction: .right)
                        }
                    } catch {
                        print("Failed to add to album: \(error)")
                    }
                }
            }
        }

    }
    
    // MARK: - View Components
    
    private var permissionView: some View {
        VStack(spacing: 24) {
            // 权限图标
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.orange)
                .symbolEffect(.bounce, value: !viewModel.hasPermission)
            
            VStack(spacing: 12) {
                Text("需要访问照片库")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Declutter需要访问您的照片库来帮助您整理照片")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // 权限说明
            VStack(spacing: 16) {
                permissionFeatureRow(
                    icon: "eye.slash.fill",
                    title: "隐私保护",
                    description: "我们不会上传或分享您的照片"
                )
                
                permissionFeatureRow(
                    icon: "trash.fill",
                    title: "安全删除",
                    description: "删除的照片会移动到\"最近删除\"，可以恢复"
                )
                
                permissionFeatureRow(
                    icon: "lock.fill",
                    title: "本地处理",
                    description: "所有操作都在您的设备上进行"
                )
            }
            .padding(.horizontal)
            
            // 操作按钮
            VStack(spacing: 12) {
                Button("重新请求权限") {
                    Task {
                        await viewModel.loadPhotos()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("前往设置") {
                    openAppSettings()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.1), Color.clear]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    /// 权限功能说明行
    private func permissionFeatureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    /// 打开应用设置
    private func openAppSettings() {
        #if canImport(UIKit)
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
        #elseif canImport(AppKit)
        // macOS 设置打开方式
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos")!)
        #endif
    }
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
            
            VStack(spacing: 8) {
                Text("加载照片中...")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("正在从照片库获取照片信息")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.clear]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo")
                .font(.system(size: 80))
                .foregroundColor(.gray)
                .symbolEffect(.pulse, value: viewModel.photos.isEmpty)
            
            VStack(spacing: 12) {
                Text("没有找到照片")
                    .font(.title2)
                    .fontWeight(.medium)
                
                if viewModel.currentFilter.isActive {
                    Text("在选定的时间范围内没有找到照片")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("清除筛选条件") {
                        Task {
                            await viewModel.clearFilter()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Text("照片库中没有可显示的照片")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("重新加载") {
                        Task {
                            await viewModel.loadPhotos()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var photoContentView: some View {
        // 主要照片显示区域（全屏）
        photoDisplayArea
    }
    
    private var photoDisplayArea: some View {
        ZStack {
            // 动态背景颜色
            backgroundColorForSwipe
                .opacity(backgroundOpacity)
                .animation(.easeInOut(duration: quickAnimationDuration), value: backgroundOpacity)
            
            if let currentPhoto = viewModel.currentPhoto {
                PhotoAsyncImage(phAsset: currentPhoto.phAsset) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipped()
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
                .scaleEffect(animationScale)
                .offset(x: dragOffset.width, y: dragOffset.height * 0.1) // 轻微的垂直偏移
                .rotationEffect(.degrees(rotationAngle))
                .opacity(calculatePhotoOpacity())
                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: animationScale)
                .animation(.easeOut(duration: animationDuration), value: dragOffset)
                .animation(.easeOut(duration: animationDuration), value: rotationAngle)
            } else {
                // 无照片时的占位符
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("无照片")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            
            // 增强的滑动指示器
            enhancedSwipeIndicatorOverlay
            
            // 动作确认覆盖层
            swipeActionOverlay
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    handleDragChanged(value)
                }
                .onEnded { value in
                    handleDragEnded(value)
                }
                .exclusively(before:
                    // 添加点击手势用于基础导航
                    TapGesture(count: 2)
                        .onEnded {
                            // 双击切换到下一张照片
                            navigateToNext()
                        }
                        .exclusively(before:
                            TapGesture()
                                .onEnded {
                                    // 单击显示/隐藏信息栏（后续任务实现）
                                }
                        )
                )
        )
        .overlay(
            // 导航按钮覆盖层
            navigationOverlay,
            alignment: .center
        )
        .overlay(
            // 底部操作按钮（结束处理 / 立即删除）
            bottomControls,
            alignment: .bottomTrailing
        )
    }
    
    private var navigationOverlay: some View {
        HStack {
            // 左侧导航区域
            Button(action: navigateToPrevious) {
                Color.clear
                    .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(0.01) // 几乎透明但可点击
            
            Spacer()
            
            // 右侧导航区域
            Button(action: navigateToNext) {
                Color.clear
                    .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(0.01) // 几乎透明但可点击
        }
    }
    

    
    private var enhancedSwipeIndicatorOverlay: some View {
        HStack {
            // 左侧删除指示器
            if dragOffset.width < -30 {
                VStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 35, weight: .bold))
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(Color.red)
                                .frame(width: 60, height: 60)
                        )
                        .scaleEffect(calculateIndicatorScale(for: .left))
                    
                    Text("删除")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .opacity(calculateIndicatorOpacity(for: .left))
                .scaleEffect(calculateIndicatorScale(for: .left))
                .animation(.easeOut(duration: quickAnimationDuration), value: dragOffset.width)
            }
            
            Spacer()
            
            // 右侧保留指示器
            if dragOffset.width > 30 {
                VStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 35, weight: .bold))
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(Color.green)
                                .frame(width: 60, height: 60)
                        )
                        .scaleEffect(calculateIndicatorScale(for: .right))
                    
                    Text("保留")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .opacity(calculateIndicatorOpacity(for: .right))
                .scaleEffect(calculateIndicatorScale(for: .right))
                .animation(.easeOut(duration: quickAnimationDuration), value: dragOffset.width)
            }
        }
        .padding(.horizontal, 40)
    }
    
    private var swipeActionOverlay: some View {
        Group {
            if isSwipeInProgress && swipeActionType != .none {
                ZStack {
                    // 半透明背景
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                    
                    // 动作确认图标
                    VStack(spacing: 20) {
                        Image(systemName: swipeActionType == .delete ? "trash.fill" : "heart.fill")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundColor(swipeActionType == .delete ? .red : .green)
                            .scaleEffect(animationScale)
                        
                        Text(swipeActionType == .delete ? "已删除" : "已保留")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .scaleEffect(animationScale)
                    .opacity(indicatorOpacity)
                }
                .animation(.easeOut(duration: animationDuration), value: animationScale)
                .animation(.easeOut(duration: animationDuration), value: indicatorOpacity)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var backgroundColorForPlatform: Color {
        #if canImport(UIKit)
        return Color(.systemBackground)
        #elseif canImport(AppKit)
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    private var backgroundColorForSwipe: Color {
        if abs(dragOffset.width) > 50 {
            return dragOffset.width < 0 ? Color.red.opacity(0.2) : Color.green.opacity(0.2)
        }
        return Color.black
    }
    
    // MARK: - Animation Calculation Methods
    
    private func calculatePhotoOpacity() -> Double {
        let maxOffset: CGFloat = 400
        let currentOffset = abs(dragOffset.width)
        return max(0.3, 1.0 - (currentOffset / maxOffset))
    }
    
    private func calculateIndicatorOpacity(for direction: SwipeDirection) -> Double {
        let offset = direction == .left ? abs(dragOffset.width) : dragOffset.width
        let threshold: CGFloat = 30
        let maxOpacity: Double = 1.0
        
        guard offset > threshold else { return 0 }
        
        let progress = min((offset - threshold) / (swipeThreshold - threshold), 1.0)
        return Double(progress) * maxOpacity
    }
    
    private func calculateIndicatorScale(for direction: SwipeDirection) -> CGFloat {
        let offset = direction == .left ? abs(dragOffset.width) : dragOffset.width
        let threshold: CGFloat = 30
        let minScale: CGFloat = 0.8
        let maxScale: CGFloat = 1.2
        
        guard offset > threshold else { return minScale }
        
        let progress = min((offset - threshold) / (swipeThreshold - threshold), 1.0)
        return minScale + (maxScale - minScale) * progress
    }
    
    // MARK: - Gesture Handling Methods
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        // 防止在滑动操作进行中时处理新的拖拽
        guard !isSwipeInProgress else { return }
        
        // 处理水平和轻微垂直方向的拖拽
        dragOffset = CGSize(
            width: value.translation.width,
            height: value.translation.height * 0.1 // 轻微的垂直移动
        )
        
        // 计算旋转角度
        let rotationProgress = min(abs(value.translation.width) / 200, 1.0)
        rotationAngle = (value.translation.width > 0 ? 1 : -1) * rotationProgress * maxRotationAngle
        
        // 计算缩放效果
        let scaleProgress = min(abs(value.translation.width) / 300, 1.0)
        animationScale = 1.0 - (scaleProgress * 0.1) // 轻微缩小
        
        // 更新背景透明度
        let opacityProgress = min(abs(value.translation.width) / 200, 1.0)
        backgroundOpacity = 1.0 - (opacityProgress * 0.3)
        
        // 确定滑动方向
        if abs(value.translation.width) > 20 {
            swipeDirection = value.translation.width > 0 ? .right : .left
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        // 防止在滑动操作进行中时处理新的拖拽结束
        guard !isSwipeInProgress else { return }
        
        let horizontalDistance = abs(value.translation.width)
        let velocity = abs(value.velocity.width)
        
        // 判断是否触发滑动操作
        let shouldTriggerSwipe = horizontalDistance > swipeThreshold || velocity > velocityThreshold
        
        if shouldTriggerSwipe {
            let direction = determineSwipeDirection(translation: value.translation.width)
            if direction == .left && !skipDeleteConfirmation {
                // 显示删除确认对话框并重置滑动位置
                showDeleteConfirmationDialog = true
                resetSwipeState()
            } else {
                performSwipeAction(direction: direction)
            }
        } else {
            // 未达到阈值，恢复原位
            resetSwipeState()
        }
    }
    
    private func determineSwipeDirection(translation: CGFloat) -> SwipeDirection {
        return translation > 0 ? .right : .left
    }
    
    private func performSwipeAction(direction: SwipeDirection) {
        isSwipeInProgress = true
        swipeActionType = direction == .left ? .delete : .keep
        
        // 第一阶段：滑出动画
        withAnimation(.easeOut(duration: quickAnimationDuration)) {
            switch direction {
            case .left:
                dragOffset.width = -1000 // 足够大的负值以滑出屏幕
                rotationAngle = -maxRotationAngle * 2
            case .right:
                dragOffset.width = 1000  // 足够大的正值以滑出屏幕
                rotationAngle = maxRotationAngle * 2
            }
            animationScale = 0.8
            backgroundOpacity = 0.5
        }
        
        // 第二阶段：显示动作确认
        DispatchQueue.main.asyncAfter(deadline: .now() + quickAnimationDuration) {
            withAnimation(.easeOut(duration: quickAnimationDuration)) {
                indicatorOpacity = 1.0
                animationScale = 1.2
            }
            
            // 第三阶段：执行实际操作
            DispatchQueue.main.asyncAfter(deadline: .now() + quickAnimationDuration) {
                Task {
                    switch direction {
                    case .left:
                        await viewModel.swipeLeft()
                    case .right:
                        viewModel.swipeRight()
                    }
                    
                    // 第四阶段：淡出确认并切换到下一张
                    withAnimation(.easeOut(duration: quickAnimationDuration)) {
                        indicatorOpacity = 0.0
                        animationScale = 1.0
                    }
                    
                    // 最终阶段：重置状态并显示下一张照片
                    DispatchQueue.main.asyncAfter(deadline: .now() + quickAnimationDuration) {
                        resetSwipeStateAndShowNext()
                    }
                }
            }
        }
    }
    
    private func resetSwipeState() {
        withAnimation(.easeInOut(duration: quickAnimationDuration)) {
            dragOffset = .zero
            rotationAngle = 0
            animationScale = 1.0
            backgroundOpacity = 1.0
        }
        swipeDirection = nil
        swipeActionType = .none
        indicatorOpacity = 0.0
        isSwipeInProgress = false
    }
    
    // MARK: - Bottom Controls
    @State private var showCommitConfirm: Bool = false
    private var bottomControls: some View {
        HStack(spacing: 10) {
            if !viewModel.pendingDeletion.isEmpty {
                Button {
                    showCommitConfirm = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                        Text("立即删除(\(viewModel.pendingDeletion.count))")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            
            

            
            Button {
                showAlbumSelection = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder.badge.plus")
                    Text("归档")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
            }
            
            Button {
                onFinishWithoutDeletion()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle")
                    Text("结束处理")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
            }
        }
        .padding(.trailing, 16)
        .padding(.bottom, 20)
        .confirmationDialog(
            "确认删除所有待删除的照片吗？",
            isPresented: $showCommitConfirm,
            titleVisibility: .visible
        ) {
            Button("删除所有(\(viewModel.pendingDeletion.count))", role: .destructive) {
                Task {
                    await viewModel.commitPendingDeletion()
                    await MainActor.run { onFinishAfterDeletion() }
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("将提交一次系统删除确认，完成后进入统计页。")
        }
    }
    
    private func resetSwipeStateAndShowNext() {
        // 从右侧滑入新照片的动画
        dragOffset = CGSize(width: 800, height: 0) // 从右侧开始
        rotationAngle = 0
        animationScale = 1.0
        backgroundOpacity = 1.0
        swipeActionType = .none
        indicatorOpacity = 0.0
        
        withAnimation(.easeOut(duration: animationDuration)) {
            dragOffset = .zero
        }
        
        swipeDirection = nil
        isSwipeInProgress = false
    }
    
    // MARK: - Navigation Methods
    
    private func navigateToNext() {
        guard viewModel.currentIndex < viewModel.totalCount - 1 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.currentIndex += 1
        }
    }
    
    private func navigateToPrevious() {
        guard viewModel.currentIndex > 0 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.currentIndex -= 1
        }
    }
}