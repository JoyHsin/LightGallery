//
//  HomeView.swift
//  LightGallery
//
//  Created by Antigravity on 2025/12/05.
//

import SwiftUI
import Photos

struct HomeView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showSmartClean = false
    @State private var showScreenshots = false
    @State private var showDuplicates = false
    @State private var showBlurry = false
    
    @State private var screenshotCount: Int = 0
    @State private var photoLibrarySize: String = "--"
    @State private var weeklyGrowth: String = "--"
    
    @State private var usedStorage: String = "--"
    @State private var totalStorage: String = "--"
    @State private var usedPercent: Double = 0.0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Storage Card
                    StorageCardView(
                        savedStorage: photoLibrarySize,
                        usedStorage: usedStorage,
                        totalStorage: totalStorage,
                        usedPercent: usedPercent
                    )
                    
                    // Quick Actions Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        // Smart Clean
                        QuickActionCard(
                            title: "Smart Clean".localized,
                            subtitle: "Review items".localized,
                            iconName: "wand.and.stars",
                            iconBackground: .blue,
                            isHighlighted: true
                        ) {
                            showSmartClean = true
                        }
                        
                        // Screenshots
                        QuickActionCard(
                            title: "Screenshots".localized,
                            subtitle: "\(screenshotCount) " + "items".localized, // Simplified for now
                            iconName: "crop",
                            iconBackground: .orange
                        ) {
                            showScreenshots = true
                        }
                        
                        // Duplicates
                        QuickActionCard(
                            title: "Duplicates".localized,
                            subtitle: "Find copies".localized,
                            iconName: "doc.on.doc.fill",
                            iconBackground: .red
                        ) {
                            showDuplicates = true
                        }
                        
                        // Blurry
                        QuickActionCard(
                            title: "Blurry".localized,
                            subtitle: "Out of focus".localized,
                            iconName: "camera.metering.unknown",
                            iconBackground: .purple
                        ) {
                            showBlurry = true
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Summary".localized)
            .onAppear {
                // Load stats asynchronously without blocking UI
                Task {
                    await loadStats()
                }
            }
            .sheet(isPresented: $showScreenshots) {
                ScreenshotCleanupView()
            }
            .sheet(isPresented: $showBlurry) {
                BlurryPhotosView()
            }
            .sheet(isPresented: $showDuplicates) {
                DuplicatesView()
            }
            .sheet(isPresented: $showSmartClean) {
                SmartCleanSummaryView()
            }
        }
    }
    
    private func loadStats() async {
        // 1. Load screenshot count
        let screenshotOptions = PHFetchOptions()
        screenshotOptions.predicate = NSPredicate(format: "mediaSubtype == %d", PHAssetMediaSubtype.photoScreenshot.rawValue)
        let screenshots = PHAsset.fetchAssets(with: .image, options: screenshotOptions)
        
        // 2. Calculate Storage Stats
        var totalPhotoSize: Int64 = 0
        var thisWeekSize: Int64 = 0
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        
        // Fetch all assets to calculate size (Estimate)
        let allAssets = PHAsset.fetchAssets(with: .image, options: nil)
        
        allAssets.enumerateObjects { asset, _, _ in
            let estimatedSize: Int64 = 2 * 1024 * 1024 // 2MB default
            totalPhotoSize += estimatedSize
            
            if let date = asset.creationDate, date >= startOfWeek {
                thisWeekSize += estimatedSize
            }
        }
        
        // 3. System Storage
        var usedDisk: Int64 = 0
        var totalDisk: Int64 = 0
        
        let fileURL = URL(fileURLWithPath: NSHomeDirectory())
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])
            if let capacity = values.volumeTotalCapacity,
               let available = values.volumeAvailableCapacityForImportantUsage {
                let capacity64 = Int64(capacity)
                totalDisk = capacity64
                usedDisk = capacity64 - available
            }
        } catch {
            print("Error retrieving storage info: \(error)")
        }
        
        // Update UI
        await MainActor.run {
            self.screenshotCount = screenshots.count
            
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useGB, .useMB]
            formatter.countStyle = .file
            
            self.usedStorage = formatter.string(fromByteCount: usedDisk)
            self.totalStorage = formatter.string(fromByteCount: totalDisk)
            self.usedPercent = totalDisk > 0 ? Double(usedDisk) / Double(totalDisk) : 0
            
            self.photoLibrarySize = formatter.string(fromByteCount: totalPhotoSize)
            self.weeklyGrowth = formatter.string(fromByteCount: thisWeekSize)
        }
    }
}

// MARK: - Storage Card
struct StorageCardView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let savedStorage: String
    let usedStorage: String
    let totalStorage: String
    let usedPercent: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PHOTOS SIZE".localized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text(savedStorage) // We will pass photo size here
                        .font(.system(size: 32, weight: .bold))
                }
                Spacer()
                VStack(alignment: .trailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                        Text("New".localized)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    Text("this week".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue)
                        .frame(width: geo.size.width * usedPercent)
                }
            }
            .frame(height: 10)
            
            HStack {
                Text("Used".localized + ": \(usedStorage)")
                Spacer()
                Text("Total".localized + ": \(totalStorage)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let title: String
    let subtitle: String
    let iconName: String
    let iconBackground: Color
    var isHighlighted: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(isHighlighted ? Color.white.opacity(0.2) : iconBackground.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: iconName)
                            .font(.system(size: 18))
                            .foregroundColor(isHighlighted ? .white : iconBackground)
                    }
                    Spacer()
                    if isHighlighted {
                        Text("Recommended".localized)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(subtitle)
                        .font(.subheadline)
                        .opacity(0.8)
                }
            }
            .padding()
            .frame(height: 140)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isHighlighted
                    ? LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(colors: [Color(uiColor: .secondarySystemGroupedBackground)], startPoint: .top, endPoint: .bottom)
            )
            .foregroundColor(isHighlighted ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    HomeView()
}
