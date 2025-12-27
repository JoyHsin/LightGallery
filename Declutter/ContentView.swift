//
//  ContentView.swift
//  Declutter
//
//  Created by Joy Hsin on 2025/9/7.
//

import SwiftUI
import Photos

/// 主界面视图，集成所有功能组件
struct ContentView: View {
    @StateObject private var photoViewModel: PhotoViewModel
    @State private var showWelcomeScreen = true
    @State private var showCompletionView = false
    @State private var showProgressStats = false
    @State private var showFilterView = false
    @State private var permissionStatus: PHAuthorizationStatus = .notDetermined
    @State private var showBatchDeletionConfirm: Bool = false
    @State private var showSimilarPhotos: Bool = false
    @State private var showScreenshotCleanup: Bool = false
    
    private let photoService = PhotoService()
    
    init() {
        let service = PhotoService()
        self._photoViewModel = StateObject(wrappedValue: PhotoViewModel(photoService: service))
    }
    
    var body: some View {
        ZStack {
            // 主要内容区域
            if showWelcomeScreen {
                welcomeView
            } else if showCompletionView {
                completionView
            } else {
                mainPhotoView
            }
            
            // 进度统计覆盖层（可选显示）
            if showProgressStats && !showWelcomeScreen && !showCompletionView {
                progressStatsOverlay
            }
        }
        .onAppear {
            checkInitialPermissionStatus()
        }
        .onChange(of: photoViewModel.isCompleted) { _, isCompleted in
            if isCompleted && !showWelcomeScreen {
                if photoViewModel.pendingDeletion.isEmpty {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showCompletionView = true
                    }
                } else {
                    showBatchDeletionConfirm = true
                }
            }
        }
        .confirmationDialog(
            "是否删除待删除列表中的照片？",
            isPresented: $showBatchDeletionConfirm,
            titleVisibility: .visible
        ) {
            Button("删除所有(\(photoViewModel.pendingDeletion.count))", role: .destructive) {
                Task {
                    await photoViewModel.commitPendingDeletion()
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showCompletionView = true
                        }
                    }
                }
            }
            Button("不删除，直接完成", role: .cancel) {
                // 放弃批量删除，将队列计为“保留”并进入完成页
                photoViewModel.cancelPendingDeletionAndMarkKept()
                withAnimation(.easeInOut(duration: 0.5)) {
                    showCompletionView = true
                }
            }
        } message: {
            Text("您有 \(photoViewModel.pendingDeletion.count) 张照片在待删除列表。\n选择“删除所有”将提交一次性系统确认；选择“不删除”将保留这些照片。")
        }
        .sheet(isPresented: $showFilterView) {
            FilterView(
                isPresented: $showFilterView,
                onFilterApplied: { startDate, endDate in
                    Task {
                        await photoViewModel.applyDateFilter(startDate, endDate)
                    }
                },
                onFilterCleared: {
                    Task {
                        await photoViewModel.clearFilter()
                    }
                }
            )
        }
        .sheet(isPresented: $showSimilarPhotos) {
            SimilarPhotosCleanupView()
        }
        .sheet(isPresented: $showScreenshotCleanup) {
            ScreenshotCleanupView()
        }
    }
    
    // MARK: - View Components
    
    /// 欢迎界面
    private var welcomeView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 应用图标和标题
            VStack(spacing: 16) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .symbolEffect(.bounce, value: showWelcomeScreen)
                
                Text("Declutter")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("照片整理助手")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 功能介绍
            VStack(spacing: 12) {
                featureRow(icon: "hand.draw", title: "滑动操作", description: "左滑删除，右滑保留")
                featureRow(icon: "clock", title: "时间排序", description: "按拍摄时间顺序浏览")
                featureRow(icon: "chart.bar", title: "进度统计", description: "实时查看清理进度")
                featureRow(icon: "line.3.horizontal.decrease", title: "智能筛选", description: "按时间段筛选照片")
                
                Button(action: {
                    showSimilarPhotos = true
                }) {
                    HStack {
                        Image(systemName: "square.on.square.badge.person.crop")
                            .foregroundColor(.purple)
                        VStack(alignment: .leading) {
                            Text("相似照片清理")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Text("自动识别并清理重复照片")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                
                Button(action: {
                    showScreenshotCleanup = true
                }) {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text("截图清理")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Text("快速查找并删除截图")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // 开始按钮
            VStack(spacing: 12) {
                Button(action: requestPermissionAndStart) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("开始整理照片")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                if photoViewModel.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(0.8)
                        
                        Text("正在加载照片...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let errorMessage = photoViewModel.errorMessage {
                    VStack(spacing: 8) {
                        Text("⚠️ \(errorMessage)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        
                        if photoViewModel.showRetryOption {
                            Button("重试") {
                                photoViewModel.retryLastOperation()
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.clear]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    /// 功能介绍行
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    /// 主要照片浏览界面
    private var mainPhotoView: some View {
        ZStack {
            // 照片浏览组件
            PhotoSwipeView(
                photoService: photoService,
                onFinishWithoutDeletion: {
                    photoViewModel.cancelPendingDeletionAndMarkKept()
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showCompletionView = true
                        showProgressStats = false
                    }
                },
                onFinishAfterDeletion: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showCompletionView = true
                        showProgressStats = false
                    }
                }
            )
                .environmentObject(photoViewModel)
            
            // 顶部工具栏
            VStack {
                topToolbar
                Spacer()
            }
        }
    }
    
    /// 顶部工具栏
    private var topToolbar: some View {
        HStack {
            // 返回按钮
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showWelcomeScreen = true
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(Color.primary.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // 筛选状态和进度信息
            VStack(spacing: 2) {
                HStack(spacing: 8) {
                    Text("第 \(photoViewModel.currentIndex + 1) 张")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("共 \(photoViewModel.totalCount) 张")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if photoViewModel.currentFilter.isActive {
                    Text("已筛选")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.1))
            .cornerRadius(16)
            
            Spacer()
            
            // 工具按钮组
            HStack(spacing: 8) {
                // 筛选按钮
                Button(action: {
                    showFilterView = true
                }) {
                    Image(systemName: photoViewModel.currentFilter.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundColor(photoViewModel.currentFilter.isActive ? .blue : .primary)
                        .padding(8)
                        .background(Color.primary.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // 统计信息切换按钮
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showProgressStats.toggle()
                    }
                }) {
                    Image(systemName: showProgressStats ? "chart.bar.fill" : "chart.bar")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color.primary.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    /// 进度统计覆盖层
    private var progressStatsOverlay: some View {
        VStack {
            Spacer()
            
            ProgressStatsView(
                currentIndex: photoViewModel.currentIndex,
                totalCount: photoViewModel.totalCount,
                deletedCount: photoViewModel.deletedCount,
                keptCount: photoViewModel.keptCount,
                currentPhoto: photoViewModel.currentPhoto
            )
            .padding(.horizontal)
            .padding(.bottom, 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .background(
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showProgressStats = false
                    }
                }
        )
    }
    
    /// 完成界面
    private var completionView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 完成图标和标题
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .symbolEffect(.bounce, value: showCompletionView)
                
                Text("清理完成！")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("恭喜您完成了照片整理")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // 统计摘要
            VStack(spacing: 16) {
                summaryCard(
                    icon: "photo",
                    title: "总共处理",
                    value: "\(photoViewModel.totalCount) 张照片",
                    color: .blue
                )
                
                HStack(spacing: 16) {
                    summaryCard(
                        icon: "trash",
                        title: "已删除",
                        value: "\(photoViewModel.deletedCount) 张",
                        color: .red
                    )
                    
                    summaryCard(
                        icon: "heart",
                        title: "已保留",
                        value: "\(photoViewModel.keptCount) 张",
                        color: .green
                    )
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // 操作按钮
            VStack(spacing: 12) {
                Button(action: restartCleaning) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("重新开始")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                Button(action: returnToWelcome) {
                    Text("返回首页")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.1), Color.clear]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    /// 统计摘要卡片
    private func summaryCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Private Methods
    
    private func checkInitialPermissionStatus() {
        permissionStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if permissionStatus == .authorized || permissionStatus == .limited {
            // 如果已有权限，直接进入主界面
            withAnimation(.easeInOut(duration: 0.5)) {
                showWelcomeScreen = false
            }
        }
    }
    
    private func requestPermissionAndStart() {
        Task {
            await photoViewModel.loadPhotos()
            
            await MainActor.run {
                if photoViewModel.hasPermission && photoViewModel.totalCount > 0 {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showWelcomeScreen = false
                        showCompletionView = false
                    }
                }
            }
        }
    }
    
    private func restartCleaning() {
        Task {
            // 重置统计数据
            await photoViewModel.clearFilter()
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showCompletionView = false
                    showProgressStats = false
                }
            }
        }
    }
    
    private func returnToWelcome() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showWelcomeScreen = true
            showCompletionView = false
            showProgressStats = false
        }
    }
}

#Preview {
    ContentView()
}
