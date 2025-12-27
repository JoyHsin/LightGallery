//
//  ImageCacheManager.swift
//  LightGallery
//
//  高性能图片缓存管理器 - 内存缓存 + 磁盘缓存
//

import UIKit
import Photos

/// 图片缓存管理器 - 单例模式
class ImageCacheManager {
    static let shared = ImageCacheManager()

    // MARK: - 缓存配置
    private let memoryCache = NSCache<NSString, UIImage>()
    private let thumbnailCache = NSCache<NSString, UIImage>()
    private let imageManager = PHCachingImageManager()

    /// 缩略图尺寸
    let thumbnailSize = CGSize(width: 300, height: 300)
    /// 预览图尺寸
    let previewSize = CGSize(width: 800, height: 800)

    /// 正在加载的请求ID，用于取消重复请求
    private var loadingRequests: [String: PHImageRequestID] = [:]
    private let requestLock = NSLock()

    // MARK: - 初始化
    private init() {
        // 配置内存缓存
        memoryCache.countLimit = 100  // 最多缓存100张大图
        memoryCache.totalCostLimit = 100 * 1024 * 1024  // 100MB

        thumbnailCache.countLimit = 500  // 最多缓存500张缩略图
        thumbnailCache.totalCostLimit = 50 * 1024 * 1024  // 50MB

        // 配置 PHCachingImageManager
        imageManager.allowsCachingHighQualityImages = true

        // 监听内存警告
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - 内存警告处理
    @objc private func handleMemoryWarning() {
        clearMemoryCache()
    }

    /// 清除内存缓存
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
        thumbnailCache.removeAllObjects()
        imageManager.stopCachingImagesForAllAssets()
    }

    // MARK: - 缩略图加载

    /// 加载缩略图（带缓存）
    /// - Parameters:
    ///   - asset: PHAsset
    ///   - completion: 完成回调
    func loadThumbnail(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = "\(asset.localIdentifier)_thumb" as NSString

        // 1. 检查内存缓存
        if let cachedImage = thumbnailCache.object(forKey: cacheKey) {
            completion(cachedImage)
            return
        }

        // 2. 从 Photos 框架加载
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        imageManager.requestImage(
            for: asset,
            targetSize: thumbnailSize,
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, info in
            guard let self = self, let image = image else {
                completion(nil)
                return
            }

            // 检查是否是降级图片（低质量预览）
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false

            // 只缓存最终图片
            if !isDegraded {
                let cost = Int(image.size.width * image.size.height * 4)
                self.thumbnailCache.setObject(image, forKey: cacheKey, cost: cost)
            }

            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    /// 异步加载缩略图
    func loadThumbnailAsync(for asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            loadThumbnail(for: asset) { image in
                continuation.resume(returning: image)
            }
        }
    }

    // MARK: - 高清图加载

    /// 加载高清图（带缓存和渐进式加载）
    /// - Parameters:
    ///   - asset: PHAsset
    ///   - targetSize: 目标尺寸
    ///   - progressHandler: 进度回调（可选）
    ///   - completion: 完成回调，可能被调用多次（先返回低质量，再返回高质量）
    func loadHighQualityImage(
        for asset: PHAsset,
        targetSize: CGSize? = nil,
        progressHandler: ((Double) -> Void)? = nil,
        completion: @escaping (UIImage?, Bool) -> Void
    ) {
        let size = targetSize ?? CGSize(
            width: UIScreen.main.bounds.width * UIScreen.main.scale,
            height: UIScreen.main.bounds.height * UIScreen.main.scale
        )
        let cacheKey = "\(asset.localIdentifier)_\(Int(size.width))x\(Int(size.height))" as NSString

        // 1. 检查内存缓存
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            completion(cachedImage, true)
            return
        }

        // 2. 先返回缩略图作为占位
        let thumbKey = "\(asset.localIdentifier)_thumb" as NSString
        if let thumbImage = thumbnailCache.object(forKey: thumbKey) {
            completion(thumbImage, false)
        }

        // 3. 取消之前的请求（如果有）
        cancelRequest(for: asset.localIdentifier)

        // 4. 加载高清图
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        if let progressHandler = progressHandler {
            options.progressHandler = { progress, _, _, _ in
                DispatchQueue.main.async {
                    progressHandler(progress)
                }
            }
        }

        let requestID = imageManager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFit,
            options: options
        ) { [weak self] image, info in
            guard let self = self else { return }

            // 移除请求记录
            self.removeRequest(for: asset.localIdentifier)

            guard let image = image else {
                DispatchQueue.main.async {
                    completion(nil, true)
                }
                return
            }

            // 缓存高清图
            let cost = Int(image.size.width * image.size.height * 4)
            self.memoryCache.setObject(image, forKey: cacheKey, cost: cost)

            DispatchQueue.main.async {
                completion(image, true)
            }
        }

        // 记录请求ID
        saveRequest(requestID, for: asset.localIdentifier)
    }

    /// 异步加载高清图
    func loadHighQualityImageAsync(for asset: PHAsset, targetSize: CGSize? = nil) async -> UIImage? {
        await withCheckedContinuation { continuation in
            var hasResumed = false
            loadHighQualityImage(for: asset, targetSize: targetSize) { image, isFinal in
                if isFinal && !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: image)
                }
            }
        }
    }

    // MARK: - 预加载

    /// 预加载一组资源的缩略图
    func startCachingThumbnails(for assets: [PHAsset]) {
        imageManager.startCachingImages(
            for: assets,
            targetSize: thumbnailSize,
            contentMode: .aspectFill,
            options: nil
        )
    }

    /// 停止预加载
    func stopCachingThumbnails(for assets: [PHAsset]) {
        imageManager.stopCachingImages(
            for: assets,
            targetSize: thumbnailSize,
            contentMode: .aspectFill,
            options: nil
        )
    }

    /// 预加载相邻图片（用于全屏浏览时）
    func preloadAdjacentImages(currentIndex: Int, assets: [PHAsset], range: Int = 2) {
        let startIndex = max(0, currentIndex - range)
        let endIndex = min(assets.count - 1, currentIndex + range)

        guard startIndex <= endIndex else { return }

        for i in startIndex...endIndex {
            if i != currentIndex {
                let asset = assets[i]
                // 预加载预览尺寸的图片
                loadHighQualityImage(for: asset, targetSize: previewSize) { _, _ in }
            }
        }
    }

    // MARK: - 请求管理

    private func saveRequest(_ requestID: PHImageRequestID, for identifier: String) {
        requestLock.lock()
        loadingRequests[identifier] = requestID
        requestLock.unlock()
    }

    private func removeRequest(for identifier: String) {
        requestLock.lock()
        loadingRequests.removeValue(forKey: identifier)
        requestLock.unlock()
    }

    /// 取消指定资源的加载请求
    func cancelRequest(for identifier: String) {
        requestLock.lock()
        if let requestID = loadingRequests[identifier] {
            imageManager.cancelImageRequest(requestID)
            loadingRequests.removeValue(forKey: identifier)
        }
        requestLock.unlock()
    }

    /// 取消所有加载请求
    func cancelAllRequests() {
        requestLock.lock()
        for (_, requestID) in loadingRequests {
            imageManager.cancelImageRequest(requestID)
        }
        loadingRequests.removeAll()
        requestLock.unlock()
    }

    // MARK: - 缓存状态

    /// 检查缩略图是否已缓存
    func hasCachedThumbnail(for asset: PHAsset) -> Bool {
        let cacheKey = "\(asset.localIdentifier)_thumb" as NSString
        return thumbnailCache.object(forKey: cacheKey) != nil
    }

    /// 检查高清图是否已缓存
    func hasCachedHighQualityImage(for asset: PHAsset, size: CGSize) -> Bool {
        let cacheKey = "\(asset.localIdentifier)_\(Int(size.width))x\(Int(size.height))" as NSString
        return memoryCache.object(forKey: cacheKey) != nil
    }
}

// MARK: - 便捷扩展
extension PHAsset {
    /// 快速获取缩略图
    func thumbnail(completion: @escaping (UIImage?) -> Void) {
        ImageCacheManager.shared.loadThumbnail(for: self, completion: completion)
    }

    /// 快速获取高清图
    func highQualityImage(completion: @escaping (UIImage?) -> Void) {
        ImageCacheManager.shared.loadHighQualityImage(for: self) { image, _ in
            completion(image)
        }
    }
}
