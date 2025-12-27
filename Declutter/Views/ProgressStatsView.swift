//
//  ProgressStatsView.swift
//  Declutter
//
//  Created by Kiro on 2025/9/7.
//

import SwiftUI
import Photos

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// 显示清理进度和统计信息的组件
struct ProgressStatsView: View {
    let currentIndex: Int
    let totalCount: Int
    let deletedCount: Int
    let keptCount: Int
    let currentPhoto: PhotoAsset?
    
    /// 计算进度百分比
    var progressPercentage: Double {
        guard totalCount > 0 else { return 0 }
        let processedCount = deletedCount + keptCount
        return Double(processedCount) / Double(totalCount) * 100
    }
    
    /// 当前位置显示文本（从1开始计数）
    var positionText: String {
        guard totalCount > 0 else { return "0 / 0" }
        return "\(currentIndex + 1) / \(totalCount)"
    }
    
    /// 已处理数量显示文本
    var processedText: String {
        let processedCount = deletedCount + keptCount
        return "已处理: \(processedCount)"
    }
    
    /// 删除统计显示文本
    var deletedText: String {
        return "已删除: \(deletedCount)"
    }
    
    /// 保留统计显示文本
    var keptText: String {
        return "已保留: \(keptCount)"
    }
    
    /// 进度百分比显示文本
    var progressText: String {
        return String(format: "%.1f%%", progressPercentage)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 当前位置和总数
            HStack {
                Text("照片")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(positionText)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            // 进度条
            VStack(spacing: 4) {
                HStack {
                    Text("进度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(progressText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                ProgressView(value: progressPercentage, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }
            
            // 统计信息
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(processedText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Text(deletedText)
                            .font(.caption2)
                            .foregroundColor(.red)
                        
                        Text(keptText)
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
            }
            
            // 当前照片时间信息
            if let photo = currentPhoto {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("拍摄时间")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(photo.formattedDate)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(photo.formattedTime)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private var backgroundColor: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #elseif canImport(AppKit)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.white
        #endif
    }
}

// MARK: - Preview

struct ProgressStatsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 预览：有当前照片的情况
            ProgressStatsView(
                currentIndex: 14,
                totalCount: 200,
                deletedCount: 8,
                keptCount: 6,
                currentPhoto: PhotoAsset.mockPhoto()
            )
            
            // 预览：无当前照片的情况
            ProgressStatsView(
                currentIndex: 0,
                totalCount: 0,
                deletedCount: 0,
                keptCount: 0,
                currentPhoto: nil
            )
            
            // 预览：进度较高的情况
            ProgressStatsView(
                currentIndex: 180,
                totalCount: 200,
                deletedCount: 95,
                keptCount: 85,
                currentPhoto: PhotoAsset.mockPhoto()
            )
        }
        .padding()
        .background(previewBackgroundColor)
        .previewLayout(.sizeThatFits)
    }
    
    static var previewBackgroundColor: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemGray6)
        #elseif canImport(AppKit)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }
}

// MARK: - Mock Data Extension

extension PhotoAsset {
    static func mockPhoto() -> PhotoAsset {
        // 创建一个模拟的PhotoAsset用于预览
        return PhotoAsset(
            id: "mock-photo-id",
            creationDate: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
            localIdentifier: "mock-photo-id"
        )
    }
}