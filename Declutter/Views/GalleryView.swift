//
//  GalleryView.swift
//  Declutter
//
//  类似 iOS 原生相册的图片浏览体验
//

import SwiftUI
import Photos

struct GalleryView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var allAssets: [PHAsset] = []
    @State private var photosByDate: [(String, [PHAsset])] = []
    @State private var isLoading = true
    @State private var isSelecting = false
    @State private var selectedIds: Set<String> = []
    @State private var showPhotoDetail = false
    @State private var selectedPhotoIndex = 0
    @State private var showDeleteConfirm = false
    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if isLoading {
                        ProgressView("加载照片中...")
                    } else if authorizationStatus == .denied || authorizationStatus == .restricted {
                        noPermissionView
                    } else if photosByDate.isEmpty {
                        ContentUnavailableView(
                            "没有照片",
                            systemImage: "photo.on.rectangle.angled",
                            description: Text("您的相册是空的")
                        )
                    } else {
                        photoGridView
                    }
                }

                // 底部工具栏（选择模式下显示）
                if isSelecting && !selectedIds.isEmpty {
                    VStack {
                        Spacer()
                        bottomToolbar
                    }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("相册")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSelecting ? "完成" : "选择") {
                        withAnimation {
                            isSelecting.toggle()
                            if !isSelecting {
                                selectedIds.removeAll()
                            }
                        }
                    }
                }

                if isSelecting {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(selectedIds.count == allAssets.count ? "取消全选" : "全选") {
                            withAnimation {
                                if selectedIds.count == allAssets.count {
                                    selectedIds.removeAll()
                                } else {
                                    selectedIds = Set(allAssets.map { $0.localIdentifier })
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                checkPermissionAndLoad()
            }
            .fullScreenCover(isPresented: $showPhotoDetail) {
                PhotoDetailView(assets: allAssets, selectedIndex: $selectedPhotoIndex)
                    .onDisappear {
                        // 刷新照片列表（可能有删除操作）
                        loadPhotos()
                    }
            }
            .confirmationDialog(
                "确定要删除 \(selectedIds.count) 张照片吗？",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("删除 \(selectedIds.count) 张照片", role: .destructive) {
                    deleteSelectedPhotos()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("此操作无法撤销")
            }
        }
    }

    // MARK: - 照片网格视图
    private var photoGridView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(photosByDate, id: \.0) { dateString, assets in
                    Section {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(assets, id: \.localIdentifier) { asset in
                                PhotoThumbnailView(
                                    asset: asset,
                                    isSelected: selectedIds.contains(asset.localIdentifier),
                                    isSelecting: isSelecting
                                ) {
                                    handlePhotoTap(asset)
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text(dateString)
                                .font(.headline)
                                .fontWeight(.semibold)

                            Spacer()

                            if isSelecting {
                                let sectionIds = Set(assets.map { $0.localIdentifier })
                                let allSelected = sectionIds.isSubset(of: selectedIds)

                                Button(allSelected ? "取消" : "选择") {
                                    withAnimation {
                                        if allSelected {
                                            selectedIds.subtract(sectionIds)
                                        } else {
                                            selectedIds.formUnion(sectionIds)
                                        }
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            }
            .padding(.bottom, isSelecting ? 80 : 20)
        }
    }

    // MARK: - 底部工具栏
    private var bottomToolbar: some View {
        HStack {
            Spacer()

            Button {
                shareSelectedPhotos()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                    Text("分享")
                        .font(.caption)
                }
            }

            Spacer()

            Button {
                showDeleteConfirm = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.title2)
                    Text("删除")
                        .font(.caption)
                }
                .foregroundColor(.red)
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - 无权限视图
    private var noPermissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("无法访问相册")
                .font(.title2)
                .fontWeight(.semibold)

            Text("请在设置中允许 Declutter 访问您的照片")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("打开设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - 方法
    private func handlePhotoTap(_ asset: PHAsset) {
        if isSelecting {
            toggleSelection(asset.localIdentifier)
        } else {
            // 找到在 allAssets 中的索引
            if let index = allAssets.firstIndex(where: { $0.localIdentifier == asset.localIdentifier }) {
                selectedPhotoIndex = index
                showPhotoDetail = true
            }
        }
    }

    private func toggleSelection(_ id: String) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            if selectedIds.contains(id) {
                selectedIds.remove(id)
            } else {
                selectedIds.insert(id)
            }
        }
    }

    private func checkPermissionAndLoad() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        authorizationStatus = status

        switch status {
        case .authorized, .limited:
            loadPhotos()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    authorizationStatus = newStatus
                    if newStatus == .authorized || newStatus == .limited {
                        loadPhotos()
                    } else {
                        isLoading = false
                    }
                }
            }
        default:
            isLoading = false
        }
    }

    private func loadPhotos() {
        Task {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            let result = PHAsset.fetchAssets(with: .image, options: options)
            var assets: [PHAsset] = []
            var grouped: [String: [PHAsset]] = [:]

            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = Locale(identifier: localizationManager.language == .simplifiedChinese || localizationManager.language == .traditionalChinese ? "zh_CN" : "en_US")

            result.enumerateObjects { asset, _, _ in
                assets.append(asset)
                let dateKey = formatter.string(from: asset.creationDate ?? Date())
                grouped[dateKey, default: []].append(asset)
            }

            // Sort by date (most recent first)
            let sorted = grouped.sorted { lhs, rhs in
                let lhsDate = lhs.value.first?.creationDate ?? Date.distantPast
                let rhsDate = rhs.value.first?.creationDate ?? Date.distantPast
                return lhsDate > rhsDate
            }

            await MainActor.run {
                allAssets = assets
                photosByDate = sorted
                isLoading = false
            }
        }
    }

    private func deleteSelectedPhotos() {
        let assetsToDelete = allAssets.filter { selectedIds.contains($0.localIdentifier) }

        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSArray)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                if success {
                    selectedIds.removeAll()
                    isSelecting = false
                    loadPhotos()
                }
            }
        }
    }

    private func shareSelectedPhotos() {
        let assetsToShare = allAssets.filter { selectedIds.contains($0.localIdentifier) }
        var images: [UIImage] = []

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = true

        for asset in assetsToShare {
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                if let image = image {
                    images.append(image)
                }
            }
        }

        guard !images.isEmpty else { return }

        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(
                activityItems: images,
                applicationActivities: nil
            )

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
    }
}

// MARK: - Photo Thumbnail
struct PhotoThumbnailView: View {
    let asset: PHAsset
    let isSelected: Bool
    let isSelecting: Bool
    let onTap: () -> Void

    @State private var image: UIImage?
    @State private var isLoaded = false

    private let cacheManager = ImageCacheManager.shared

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                        .opacity(isLoaded ? 1 : 0.5)
                        .animation(.easeIn(duration: 0.2), value: isLoaded)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                }

                // 视频标识
                if asset.mediaType == .video {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.caption2)
                            Text(formatDuration(asset.duration))
                                .font(.caption2)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(4)
                        .padding(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // 选择指示器
                if isSelecting {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.3), radius: 2)

                        if isSelected {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 24, height: 24)
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(6)
                }

                // 选中时的遮罩
                if isSelected {
                    Rectangle()
                        .fill(Color.blue.opacity(0.2))
                }
            }
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            loadImage()
        }
        .onDisappear {
            // 取消加载请求（如果还在加载中）
            if !isLoaded {
                cacheManager.cancelRequest(for: asset.localIdentifier)
            }
        }
    }

    private func loadImage() {
        // 使用缓存管理器加载缩略图
        cacheManager.loadThumbnail(for: asset) { loadedImage in
            if let loadedImage = loadedImage {
                self.image = loadedImage
                self.isLoaded = true
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    GalleryView()
}
