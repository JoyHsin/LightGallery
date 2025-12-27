//
//  PhotoDetailView.swift
//  LightGallery
//
//  全屏图片查看器 - 支持缩放、左右滑动切换
//

import SwiftUI
import Photos

struct PhotoDetailView: View {
    let assets: [PHAsset]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss

    @State private var showControls = true
    @State private var showDeleteConfirm = false
    @State private var currentScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            // 背景
            Color.black.ignoresSafeArea()

            // 图片轮播
            TabView(selection: $selectedIndex) {
                ForEach(Array(assets.enumerated()), id: \.element.localIdentifier) { index, asset in
                    ZoomablePhotoView(asset: asset)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showControls.toggle()
                }
            }

            // 顶部导航栏
            if showControls {
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }

                        Spacer()

                        Text("\(selectedIndex + 1) / \(assets.count)")
                            .font(.headline)
                            .foregroundColor(.white)

                        Spacer()

                        // 占位，保持标题居中
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Spacer()

                    // 底部工具栏
                    HStack(spacing: 60) {
                        Button {
                            sharePhoto()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title2)
                                Text("分享")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                        }

                        Button {
                            showDeleteConfirm = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.title2)
                                Text("删除")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0.6), Color.black.opacity(0)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
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
    }

    private func sharePhoto() {
        guard selectedIndex < assets.count else { return }
        let asset = assets[selectedIndex]

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            guard let image = image else { return }

            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(
                    activityItems: [image],
                    applicationActivities: nil
                )

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(activityVC, animated: true)
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

// MARK: - 可缩放的图片视图
struct ZoomablePhotoView: View {
    let asset: PHAsset

    @State private var image: UIImage?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .gesture(
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
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                if scale > 1 {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
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
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .onAppear {
            loadHighQualityImage()
        }
    }

    private func loadHighQualityImage() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        let targetSize = CGSize(
            width: UIScreen.main.bounds.width * UIScreen.main.scale,
            height: UIScreen.main.bounds.height * UIScreen.main.scale
        )

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { result, info in
            if let result = result {
                DispatchQueue.main.async {
                    self.image = result
                }
            }
        }
    }
}

#Preview {
    PhotoDetailView(assets: [], selectedIndex: .constant(0))
}
