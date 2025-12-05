//
//  FilterViewTests.swift
//  LightGalleryTests
//
//  Created by Kiro on 2025/9/7.
//

import XCTest
import SwiftUI
@testable import LightGallery

final class FilterViewTests: XCTestCase {
    
    func testFilterViewInitialization() {
        // Given
        let isPresented = Binding.constant(true)
        var appliedDates: (Date, Date)?
        var filterCleared = false
        
        // When
        let filterView = FilterView(
            isPresented: isPresented,
            onFilterApplied: { startDate, endDate in
                appliedDates = (startDate, endDate)
            },
            onFilterCleared: {
                filterCleared = true
            }
        )
        
        // Then
        XCTAssertNotNil(filterView)
    }
    
    func testFilterDateRangeCalculation() {
        // Given
        let calendar = Calendar.current
        let year = 2024
        let month = 3
        
        // When
        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = month
        startComponents.day = 1
        startComponents.hour = 0
        startComponents.minute = 0
        startComponents.second = 0
        
        guard let startDate = calendar.date(from: startComponents) else {
            XCTFail("Failed to create start date")
            return
        }
        
        guard let endDate = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: startDate) else {
            XCTFail("Failed to create end date")
            return
        }
        
        // Then
        let startDateComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
        let endDateComponents = calendar.dateComponents([.year, .month, .day], from: endDate)
        
        XCTAssertEqual(startDateComponents.year, year)
        XCTAssertEqual(startDateComponents.month, month)
        XCTAssertEqual(startDateComponents.day, 1)
        
        XCTAssertEqual(endDateComponents.year, year)
        XCTAssertEqual(endDateComponents.month, month)
        XCTAssertEqual(endDateComponents.day, 31) // March has 31 days
    }
    
    func testMonthNameLocalization() {
        // Given
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        
        // When & Then
        XCTAssertEqual(formatter.monthSymbols[0], "一月")
        XCTAssertEqual(formatter.monthSymbols[2], "三月")
        XCTAssertEqual(formatter.monthSymbols[11], "十二月")
    }
    
    func testAvailableYearsRange() {
        // Given
        let currentYear = Calendar.current.component(.year, from: Date())
        
        // When
        let availableYears = Array((currentYear - 9)...currentYear).reversed()
        
        // Then
        XCTAssertEqual(availableYears.count, 10)
        XCTAssertEqual(availableYears.first, currentYear)
        XCTAssertEqual(availableYears.last, currentYear - 9)
    }
}