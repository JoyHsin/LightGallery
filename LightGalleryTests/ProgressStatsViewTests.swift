//
//  ProgressStatsViewTests.swift
//  LightGalleryTests
//
//  Created by Kiro on 2025/9/7.
//

import XCTest
import SwiftUI
@testable import LightGallery

final class ProgressStatsViewTests: XCTestCase {
    
    func testProgressPercentageCalculation() {
        // 测试进度百分比计算
        let view = ProgressStatsView(
            currentIndex: 10,
            totalCount: 100,
            deletedCount: 30,
            keptCount: 20,
            currentPhoto: nil
        )
        
        // 已处理50张，总共100张，应该是50%
        XCTAssertEqual(view.progressPercentage, 50.0, accuracy: 0.1)
    }
    
    func testProgressPercentageWithZeroTotal() {
        // 测试总数为0时的进度百分比
        let view = ProgressStatsView(
            currentIndex: 0,
            totalCount: 0,
            deletedCount: 0,
            keptCount: 0,
            currentPhoto: nil
        )
        
        XCTAssertEqual(view.progressPercentage, 0.0)
    }
    
    func testPositionText() {
        // 测试位置文本显示
        let view = ProgressStatsView(
            currentIndex: 14, // 第15张（从0开始计数）
            totalCount: 200,
            deletedCount: 5,
            keptCount: 3,
            currentPhoto: nil
        )
        
        XCTAssertEqual(view.positionText, "15 / 200")
    }
    
    func testPositionTextWithZeroTotal() {
        // 测试总数为0时的位置文本
        let view = ProgressStatsView(
            currentIndex: 0,
            totalCount: 0,
            deletedCount: 0,
            keptCount: 0,
            currentPhoto: nil
        )
        
        XCTAssertEqual(view.positionText, "0 / 0")
    }
    
    func testProcessedText() {
        // 测试已处理数量文本
        let view = ProgressStatsView(
            currentIndex: 10,
            totalCount: 100,
            deletedCount: 25,
            keptCount: 15,
            currentPhoto: nil
        )
        
        XCTAssertEqual(view.processedText, "已处理: 40")
    }
    
    func testDeletedAndKeptText() {
        // 测试删除和保留统计文本
        let view = ProgressStatsView(
            currentIndex: 10,
            totalCount: 100,
            deletedCount: 25,
            keptCount: 15,
            currentPhoto: nil
        )
        
        XCTAssertEqual(view.deletedText, "已删除: 25")
        XCTAssertEqual(view.keptText, "已保留: 15")
    }
    
    func testProgressText() {
        // 测试进度百分比文本格式
        let view = ProgressStatsView(
            currentIndex: 10,
            totalCount: 100,
            deletedCount: 33,
            keptCount: 17,
            currentPhoto: nil
        )
        
        // 50张处理完成，总共100张，应该显示50.0%
        XCTAssertEqual(view.progressText, "50.0%")
    }
    
    func testProgressTextWithDecimal() {
        // 测试带小数的进度百分比文本
        let view = ProgressStatsView(
            currentIndex: 10,
            totalCount: 300,
            deletedCount: 50,
            keptCount: 50,
            currentPhoto: nil
        )
        
        // 100张处理完成，总共300张，应该显示33.3%
        XCTAssertEqual(view.progressText, "33.3%")
    }
}