//
//  PhotoDetailView.swift
//  LightGallery
//
//  全屏图片查看器 - 支持缩放、左右滑动切换、渐进式加载、预加载
//

import SwiftUI
import Photos

struct PhotoDetailView: View {
    let assets: [PHAsset]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss

    @State private var showControls = true
    @State private var showDeleteConfirm = false

    private let cacheManager = ImageCacheManager.shared

    var body: some View {
        ZStack {
            // 背景
            Color.black.ignoresSafeArea()

            // 图片轮播
            TabView(selection: $selectedIndex) {
                ForEach(Array(assets.enumerated()), id: \.element.localIdentifier) { index, asset in
                    ZoomablePhotoView(asset: asset, onSingleTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showControls.toggle()
                        }
                    })
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .onChange(of: selectedIndex) { _, newIndex in
                // 预加载相邻图片
                cacheManager.preloadAdjacentImages(currentIndex: newIndex, assets: assets, range: 2)
            }

            // 控制层（顶部导航栏 + 底部工具栏）
            if showControls {
                VStack {
                    // 顶部导航栏
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }

                        Spacer()

                        Text("\(selectedIndex + 1) / \(assets.count)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(20)

                        Spacer()

                        // 占位，保持标题居中
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Spacer()

                    // 底部工具栏
                    HStack(spacing: 0) {
                        Spacer()

                        Button {
                            sharePhoto()
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 22))
                                Text("分享")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .frame(width: 80, height: 60)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()

                        Button {
                            showDeleteConfirm = true
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "trash")
                                    .font(.system(size: 22))
                                Text("删除")
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                            .frame(width: 80, height: 60)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .background(
                        Color.black.opacity(0.6)
                            .ignoresSafeArea()
                    )
                }
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: !showControls)
        .confirmationDialog("确定要删除这张照片吗？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                deleteCurrentPhoto()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作无法撤销")
        }
        .onAppear {
            // 初始预加载
            cacheManager.preloadAdjacentImages(currentIndex: selectedIndex, assets: assets, range: 2)
        }
        .onDisappear {
            // 清理不需要的缓存
            cacheManager.cancelAllRequests()
        }
    }

    private func sharePhoto() {
        guard selectedIndex < assets.count else { return }
        let asset = assets[selectedIndex]

        // 显示加载提示
        cacheManager.loadHighQualityImage(for: asset) { image, isFinal in
            guard isFinal, let image = image else { return }

            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(
                    activityItems: [image],
                    applicationActivities: nil
                )

                // 获取最顶层的 ViewController
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    var topVC = rootVC
                    while let presented = topVC.presentedViewController {
                        topVC = presented
                    }

                    // iPad 需要设置 popover
                    if let popover = activityVC.popoverPresentationController {
                        popover.sourceView = window
                        popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.maxY - 100, width: 0, height: 0)
                    }

                    topVC.present(activityVC, animated: true)
                }
            }
        }
    }

    private func deleteCurrentPhoto() {
        guard selectedIndex < assets.count else { return }
        let asset = assets[selectedIndex]

        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                if success {
                    // 如果删除后没有图片了，关闭视图
                    if assets.count <= 1 {
                        dismiss()
                    } else if selectedIndex >= assets.count - 1 {
                        // 如果删除的是最后一张，往前移
                        selectedIndex = max(0, selectedIndex - 1)
                    }
                }
            }
        }
    }
}

// MARK: - 可缩放的图片视图（带渐进式加载）
struct ZoomablePhotoView: View {
    let asset: PHAsset
    var onSingleTap: (() -> Void)?

    @State private var thumbnailImage: UIImage?
    @State private var highQualityImage: UIImage?
    @State private var isLoadingHighQuality = false
    @State private var loadProgress: Double = 0

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let cacheManager = ImageCacheManager.shared

    /// 当前显示的图片（优先高清图）
    private var displayImage: UIImage? {
        highQualityImage ?? thumbnailImage
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = displayImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .gesture(magnificationGesture)
                        .gesture(scale > 1 ? dragGesture : nil)  // 只在放大时启用拖动
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                if scale > 1 {
                                    scale = 1
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2
                                }
                            }
                        }
                        .onTapGesture(count: 1) {
                            onSingleTap?()
                        }
                        // 高清图加载完成时的淡入效果
                        .opacity(highQualityImage != nil ? 1 : 0.8)
                        .animation(.easeIn(duration: 0.3), value: highQualityImage != nil)
                } else {
                    // 加载中占位
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)

                        if isLoadingHighQuality && loadProgress > 0 {
                            Text("\(Int(loadProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onTapGesture {
                        onSingleTap?()
                    }
                }

                // 加载高清图进度指示器（仅在有缩略图但还在加载高清图时显示）
                if thumbnailImage != nil && highQualityImage == nil && isLoadingHighQuality {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(8)
                                .padding()
                        }
                    }
                    .allowsHitTesting(false)  // 不拦截触摸事件
                }
            }
        }
        .onAppear {
            loadImages()
        }
        .onDisappear {
            // 重置缩放状态
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }

    // MARK: - 手势

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale = min(max(scale * delta, 1), 4)
            }
            .onEnded { _ in
                lastScale = 1.0
                if scale < 1 {
                    withAnimation(.spring()) {
                        scale = 1
                        offset = .zero
                    }
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    // MARK: - 图片加载

    private func loadImages() {
        // 1. 先加载缩略图（快速显示）
        cacheManager.loadThumbnail(for: asset) { image in
            if let image = image {
                self.thumbnailImage = image
            }
        }

        // 2. 加载高清图（渐进式）
        isLoadingHighQuality = true
        cacheManager.loadHighQualityImage(
            for: asset,
            progressHandler: { progress in
                self.loadProgress = progress
            }
        ) { image, isFinal in
            if let image = image {
                if isFinal {
                    self.highQualityImage = image
                    self.isLoadingHighQuality = false
                }
            } else if isFinal {
                self.isLoadingHighQuality = false
            }
        }
    }
}

#Preview {
    PhotoDetailView(assets: [], selectedIndex: .constant(0))
}
