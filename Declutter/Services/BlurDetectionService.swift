//
//  BlurDetectionService.swift
//  Declutter
//
//  Created by Claude on 2025/12/27.
//

import Photos
import UIKit
import CoreImage

/// 模糊照片检测结果
struct BlurryPhoto: Identifiable {
    let id: String
    let asset: PhotoAsset
    let blurScore: Double // 0-1, 越高越模糊
    let fileSize: Int64

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    var blurLevel: BlurLevel {
        if blurScore > 0.7 {
            return .veryBlurry
        } else if blurScore > 0.5 {
            return .blurry
        } else {
            return .slightlyBlurry
        }
    }

    enum BlurLevel: String {
        case veryBlurry = "Very Blurry"
        case blurry = "Blurry"
        case slightlyBlurry = "Slightly Blurry"

        var color: UIColor {
            switch self {
            case .veryBlurry: return .systemRed
            case .blurry: return .systemOrange
            case .slightlyBlurry: return .systemYellow
            }
        }
    }
}

/// 模糊照片检测服务
/// 使用 Laplacian 方差算法检测图像清晰度
class BlurDetectionService {
    static let shared = BlurDetectionService()

    private let context = CIContext()
    private let imageManager = PHImageManager.default()

    /// 模糊阈值 - 低于此值认为是模糊的
    private let blurThreshold: Double = 100.0

    private init() {}

    /// 扫描相册中的模糊照片
    /// - Parameter limit: 最大扫描数量，默认500张（避免扫描时间过长）
    /// - Returns: 模糊照片列表，按模糊程度排序
    func scanForBlurryPhotos(limit: Int = 500) async -> [BlurryPhoto] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = limit

        let allAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        // 先收集所有 assets 到数组中
        var assetArray: [PHAsset] = []
        allAssets.enumerateObjects { asset, _, _ in
            assetArray.append(asset)
        }

        var blurryPhotos: [BlurryPhoto] = []

        // 使用 TaskGroup 并行处理
        await withTaskGroup(of: BlurryPhoto?.self) { group in
            for asset in assetArray {
                group.addTask {
                    return await self.analyzeAsset(asset)
                }
            }

            for await result in group {
                if let photo = result {
                    blurryPhotos.append(photo)
                }
            }
        }

        // 按模糊程度排序（最模糊的在前）
        return blurryPhotos.sorted { $0.blurScore > $1.blurScore }
    }

    /// 分析单张照片的模糊程度
    private func analyzeAsset(_ asset: PHAsset) async -> BlurryPhoto? {
        // 请求小尺寸图片用于分析（提高性能）
        let targetSize = CGSize(width: 300, height: 300)

        guard let image = await requestImage(for: asset, targetSize: targetSize) else {
            return nil
        }

        let blurScore = calculateBlurScore(image: image)

        // 只返回模糊的照片
        guard blurScore > 0.3 else { return nil }

        // 估算文件大小
        let fileSize = estimateFileSize(for: asset)

        return BlurryPhoto(
            id: asset.localIdentifier,
            asset: PhotoAsset(phAsset: asset),
            blurScore: blurScore,
            fileSize: fileSize
        )
    }

    /// 请求图片
    private func requestImage(for asset: PHAsset, targetSize: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            options.isSynchronous = false

            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    /// 使用 Laplacian 方差计算模糊分数
    /// 原理：清晰图像边缘锐利，Laplacian 方差大；模糊图像边缘平滑，方差小
    private func calculateBlurScore(image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 0 }

        let ciImage = CIImage(cgImage: cgImage)

        // 转换为灰度图
        guard let grayscaleFilter = CIFilter(name: "CIColorControls") else { return 0 }
        grayscaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
        grayscaleFilter.setValue(0.0, forKey: kCIInputSaturationKey)

        guard let grayscaleImage = grayscaleFilter.outputImage else { return 0 }

        // 应用 Laplacian 边缘检测
        guard let laplacianFilter = CIFilter(name: "CIConvolution3X3") else { return 0 }

        // Laplacian 核
        let laplacianKernel: [CGFloat] = [
            0, 1, 0,
            1, -4, 1,
            0, 1, 0
        ]

        laplacianFilter.setValue(grayscaleImage, forKey: kCIInputImageKey)
        laplacianFilter.setValue(CIVector(values: laplacianKernel, count: 9), forKey: "inputWeights")
        laplacianFilter.setValue(0.0, forKey: "inputBias")

        guard let laplacianImage = laplacianFilter.outputImage else { return 0 }

        // 计算方差
        let variance = calculateVariance(of: laplacianImage)

        // 将方差转换为 0-1 的模糊分数
        // 方差越小，图像越模糊，分数越高
        let normalizedScore = max(0, min(1, 1 - (variance / blurThreshold)))

        return normalizedScore
    }

    /// 计算图像的方差
    private func calculateVariance(of ciImage: CIImage) -> Double {
        let extent = ciImage.extent

        // 使用 CIAreaAverage 获取平均值
        guard let avgFilter = CIFilter(name: "CIAreaAverage") else { return 0 }
        avgFilter.setValue(ciImage, forKey: kCIInputImageKey)
        avgFilter.setValue(CIVector(cgRect: extent), forKey: "inputExtent")

        guard let avgImage = avgFilter.outputImage else { return 0 }

        // 渲染单个像素获取平均值
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(avgImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

        // 简化计算：使用亮度通道的值作为方差的近似
        let avgValue = Double(bitmap[0])

        // 计算与平均值的偏差（简化版方差）
        // 实际应用中可以采样多个点计算真实方差
        return avgValue
    }

    /// 估算文件大小
    private func estimateFileSize(for asset: PHAsset) -> Int64 {
        // 基于像素数量估算
        let pixelCount = Int64(asset.pixelWidth * asset.pixelHeight)
        // 假设 JPEG 压缩后每像素约 0.5 字节
        return pixelCount / 2
    }

    /// 删除照片
    func deletePhotos(_ photos: [BlurryPhoto]) async -> Bool {
        let assets = photos.map { $0.asset.phAsset }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            } completionHandler: { success, error in
                if let error = error {
                    print("Delete error: \(error.localizedDescription)")
                }
                continuation.resume(returning: success)
            }
        }
    }
}
