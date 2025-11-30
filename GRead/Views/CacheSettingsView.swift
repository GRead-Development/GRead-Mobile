import SwiftUI

struct CacheSettingsView: View {
    @ObservedObject var cacheManager = CacheManager.shared
    @Environment(\.themeColors) var themeColors
    @State private var showClearAllAlert = false
    @State private var showCacheSizePicker = false
    @State private var selectedCacheSize: Int64 = 100 * 1024 * 1024

    let cacheSizeOptions: [(String, Int64)] = [
        ("25 MB", 25 * 1024 * 1024),
        ("50 MB", 50 * 1024 * 1024),
        ("100 MB", 100 * 1024 * 1024),
        ("200 MB", 200 * 1024 * 1024),
        ("500 MB", 500 * 1024 * 1024),
        ("1 GB", 1024 * 1024 * 1024),
        ("No Limit", Int64.max)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Cache Usage Overview
                VStack(spacing: 16) {
                    Text("Cache Usage")
                        .font(.headline)
                        .foregroundColor(themeColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 12) {
                        // Usage bar
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(cacheManager.formatBytes(cacheManager.cacheSize))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(cacheManager.usagePercentage > 0.8 ? themeColors.error : themeColors.primary)

                                Spacer()

                                Text("of \(cacheManager.maxCacheSize == Int64.max ? "unlimited" : cacheManager.formatBytes(cacheManager.maxCacheSize))")
                                    .font(.subheadline)
                                    .foregroundColor(themeColors.textSecondary)
                            }

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(themeColors.border.opacity(0.3))
                                        .frame(height: 12)

                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(cacheManager.usagePercentage > 0.8 ? themeColors.error : themeColors.primary)
                                        .frame(width: geometry.size.width * cacheManager.usagePercentage, height: 12)
                                        .animation(.easeInOut, value: cacheManager.usagePercentage)
                                }
                            }
                            .frame(height: 12)

                            if cacheManager.isApproachingLimit {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(themeColors.warning)
                                    Text("Cache is approaching the limit")
                                        .font(.caption)
                                        .foregroundColor(themeColors.warning)
                                }
                            }
                        }
                        .padding()
                        .background(themeColors.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeColors.border, lineWidth: 1)
                        )
                    }
                }
                .padding()

                // Cache Size Limit
                VStack(spacing: 16) {
                    Text("Cache Size Limit")
                        .font(.headline)
                        .foregroundColor(themeColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: { showCacheSizePicker = true }) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(themeColors.primary)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Maximum Cache Size")
                                    .foregroundColor(themeColors.textPrimary)
                                Text(cacheManager.maxCacheSize == Int64.max ? "No Limit" : cacheManager.formatBytes(cacheManager.maxCacheSize))
                                    .font(.caption)
                                    .foregroundColor(themeColors.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(themeColors.textSecondary)
                        }
                        .padding()
                        .background(themeColors.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeColors.border, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)

                // Individual Cache Breakdown
                VStack(spacing: 16) {
                    Text("Cache Breakdown")
                        .font(.headline)
                        .foregroundColor(themeColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(CacheType.allCases, id: \.self) { cacheType in
                        CacheItemRow(
                            cacheType: cacheType,
                            size: cacheManager.getCacheSize(type: cacheType),
                            onClear: {
                                cacheManager.clearCache(type: cacheType)
                            }
                        )
                    }
                }
                .padding(.horizontal)

                // Clear All Cache
                VStack(spacing: 16) {
                    Text("Danger Zone")
                        .font(.headline)
                        .foregroundColor(themeColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: {
                        showClearAllAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(themeColors.error)
                                .frame(width: 30)

                            Text("Clear All Caches")
                                .fontWeight(.semibold)
                                .foregroundColor(themeColors.error)

                            Spacer()
                        }
                        .padding()
                        .background(themeColors.error.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeColors.error, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .background(themeColors.background)
        .navigationTitle("Cache Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Clear All Caches?", isPresented: $showClearAllAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                cacheManager.clearAllCaches()
            }
        } message: {
            Text("This will clear all cached data including library, dashboard, and profile information. You'll need to reload this data when you next use the app.")
        }
        .sheet(isPresented: $showCacheSizePicker) {
            CacheSizePickerSheet(
                selectedSize: $selectedCacheSize,
                currentSize: cacheManager.maxCacheSize,
                options: cacheSizeOptions,
                onSave: { newSize in
                    cacheManager.setMaxCacheSize(newSize)
                }
            )
            .presentationDetents([.medium])
        }
        .onAppear {
            cacheManager.calculateCacheSize()
            selectedCacheSize = cacheManager.maxCacheSize
        }
    }
}

struct CacheItemRow: View {
    let cacheType: CacheType
    let size: Int64
    let onClear: () -> Void

    @Environment(\.themeColors) var themeColors
    @State private var showClearAlert = false

    var body: some View {
        HStack {
            Image(systemName: iconForCacheType(cacheType))
                .foregroundColor(themeColors.primary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(cacheType.rawValue)
                    .foregroundColor(themeColors.textPrimary)
                Text(CacheManager.shared.formatBytes(size))
                    .font(.caption)
                    .foregroundColor(themeColors.textSecondary)
            }

            Spacer()

            Button(action: { showClearAlert = true }) {
                Text("Clear")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeColors.error)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(themeColors.error.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(themeColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeColors.border, lineWidth: 1)
        )
        .alert("Clear \(cacheType.rawValue) Cache?", isPresented: $showClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                onClear()
            }
        } message: {
            Text("This will clear the cached \(cacheType.rawValue.lowercased()) data.")
        }
    }

    private func iconForCacheType(_ type: CacheType) -> String {
        switch type {
        case .library:
            return "books.vertical.fill"
        case .dashboard:
            return "chart.bar.fill"
        case .profile:
            return "person.fill"
        case .userProfiles:
            return "person.2.fill"
        }
    }
}

struct CacheSizePickerSheet: View {
    @Binding var selectedSize: Int64
    let currentSize: Int64
    let options: [(String, Int64)]
    let onSave: (Int64) -> Void

    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColors) var themeColors

    var body: some View {
        NavigationView {
            List {
                ForEach(options, id: \.1) { option in
                    Button(action: {
                        selectedSize = option.1
                    }) {
                        HStack {
                            Text(option.0)
                                .foregroundColor(themeColors.textPrimary)

                            Spacer()

                            if selectedSize == option.1 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(themeColors.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Cache Size")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(selectedSize)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
