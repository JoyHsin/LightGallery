//
//  FilterView.swift
//  Declutter
//
//  Created by Kiro on 2025/9/7.
//

import SwiftUI

/// 时间筛选功能的界面组件
struct FilterView: View {
    @Binding var isPresented: Bool
    let onFilterApplied: (Date, Date) -> Void
    let onFilterCleared: () -> Void
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    
    // 可选择的年份范围（最近10年）
    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 9)...currentYear).reversed()
    }
    
    // 月份选项
    private var availableMonths: [Int] {
        Array(1...12)
    }
    
    // 月份名称
    private func monthName(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.monthSymbols[month - 1]
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("选择时间范围")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    // 年份选择
                    VStack(alignment: .leading, spacing: 8) {
                        Text("年份")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("年份", selection: $selectedYear) {
                            ForEach(availableYears, id: \.self) { year in
                                Text("\(year)年").tag(year)
                            }
                        }
                        #if os(iOS)
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 120)
                        #else
                        .pickerStyle(MenuPickerStyle())
                        #endif
                    }
                    
                    // 月份选择
                    VStack(alignment: .leading, spacing: 8) {
                        Text("月份")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("月份", selection: $selectedMonth) {
                            ForEach(availableMonths, id: \.self) { month in
                                Text(monthName(for: month)).tag(month)
                            }
                        }
                        #if os(iOS)
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 120)
                        #else
                        .pickerStyle(MenuPickerStyle())
                        #endif
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 操作按钮
                VStack(spacing: 12) {
                    Button(action: applyFilter) {
                        Text("应用筛选")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button(action: clearFilter) {
                        Text("清除筛选")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
            #endif
        }
    }
    
    // MARK: - Private Methods
    
    private func applyFilter() {
        let calendar = Calendar.current
        
        // 创建选定月份的开始日期
        var startComponents = DateComponents()
        startComponents.year = selectedYear
        startComponents.month = selectedMonth
        startComponents.day = 1
        startComponents.hour = 0
        startComponents.minute = 0
        startComponents.second = 0
        
        guard let startDate = calendar.date(from: startComponents) else { return }
        
        // 创建选定月份的结束日期
        guard let endDate = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: startDate) else { return }
        
        onFilterApplied(startDate, endDate)
        isPresented = false
    }
    
    private func clearFilter() {
        onFilterCleared()
        isPresented = false
    }
}

// MARK: - Preview

struct FilterView_Previews: PreviewProvider {
    static var previews: some View {
        FilterView(
            isPresented: .constant(true),
            onFilterApplied: { _, _ in },
            onFilterCleared: { }
        )
    }
}