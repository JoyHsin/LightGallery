//
//  SmartCleanSummaryView.swift
//  LightGallery
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI

struct SmartCleanSummaryView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var viewModel = SmartCleanViewModel()
    @StateObject private var featureAccessManager = FeatureAccessManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showPaywall = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Scanning library...".localized)
                } else if viewModel.categories.isEmpty {
                    ContentUnavailableView(
                        "All Clean!".localized,
                        systemImage: "checkmark.circle.fill",
                        description: Text("No items found to clean.".localized)
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Total Size Card
                            VStack(spacing: 8) {
                                Text("Total Size to Clean".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(viewModel.totalSizeToClean)
                                    .font(.system(size: 42, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(20)
                            
                            // Categories List
                            VStack(spacing: 16) {
                                ForEach(viewModel.categories) { category in
                                    SmartCleanCategoryRow(category: category, viewModel: viewModel)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Smart Clean".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.rescan()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .onAppear {
                // Check access before scanning
                if featureAccessManager.canAccessFeature(.smartClean) {
                    viewModel.scan()
                } else {
                    showPaywall = true
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(feature: .smartClean)
            }
        }
    }
}

struct SmartCleanCategoryRow: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let category: SmartCleanCategory
    @ObservedObject var viewModel: SmartCleanViewModel
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationLink(destination: SmartCleanDetailView(category: category, viewModel: viewModel)) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(category.type.color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: category.type.iconName)
                        .font(.title3)
                        .foregroundColor(category.type.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.type.rawValue.localized)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("\(category.assets.count) items • \(category.formattedSize)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(10)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle()) // Prevent triggering NavigationLink
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
        .alert("Delete All".localized + " \(category.type.rawValue.localized)?", isPresented: $showDeleteConfirmation) {
            Button("Delete".localized, role: .destructive) {
                viewModel.deleteCategory(category)
            }
            Button("Cancel".localized, role: .cancel) {}
        } message: {
            Text("Are you sure?".localized)
        }
    }
}
