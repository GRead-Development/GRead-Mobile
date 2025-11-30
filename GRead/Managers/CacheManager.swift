import Foundation
import SwiftUI
import Combine

class CacheManager: ObservableObject {
    static let shared = CacheManager()

    @Published var cacheSize: Int64 = 0
    @Published var maxCacheSize: Int64 = 100 * 1024 * 1024 // 100 MB default

    private let maxCacheSizeKey = "maxCacheSize"

    private init() {
        // Load max cache size from UserDefaults
        if let savedMaxSize = UserDefaults.standard.object(forKey: maxCacheSizeKey) as? Int64 {
            maxCacheSize = savedMaxSize
        }
        calculateCacheSize()
    }

    /// Calculate total cache size from UserDefaults
    func calculateCacheSize() {
        Logger.debug("Calculating cache size...")

        var totalSize: Int64 = 0

        // Only calculate size for specific known cache keys
        let cacheKeys = [
            "cachedLibrary",
            "cachedDashboard",
            "cachedProfile",
            "cachedUserProfiles",
            "jwtToken"
        ]

        for key in cacheKeys {
            if let data = UserDefaults.standard.data(forKey: key) {
                totalSize += Int64(data.count)
            } else if let string = UserDefaults.standard.string(forKey: key) {
                totalSize += Int64(string.utf8.count)
            } else if let object = UserDefaults.standard.object(forKey: key) {
                // Try to get an estimate by converting to property list
                if let plistData = try? PropertyListSerialization.data(fromPropertyList: object, format: .binary, options: 0) {
                    totalSize += Int64(plistData.count)
                }
            }
        }

        DispatchQueue.main.async {
            self.cacheSize = totalSize
            Logger.debug("Total cache size: \(self.formatBytes(totalSize))")
        }
    }

    /// Clear all caches
    func clearAllCaches() {
        Logger.debug("Clearing all caches...")

        LibraryManager.shared.clearCache()
        DashboardManager.shared.clearCache()
        ProfileManager.shared.clearCache()
        UserProfileManager.shared.clearCache()

        // Recalculate cache size
        calculateCacheSize()

        Logger.debug("All caches cleared")
    }

    /// Clear specific cache
    func clearCache(type: CacheType) {
        Logger.debug("Clearing \(type.rawValue) cache...")

        switch type {
        case .library:
            LibraryManager.shared.clearCache()
        case .dashboard:
            DashboardManager.shared.clearCache()
        case .profile:
            ProfileManager.shared.clearCache()
        case .userProfiles:
            UserProfileManager.shared.clearCache()
        }

        calculateCacheSize()
    }

    /// Set maximum cache size
    func setMaxCacheSize(_ size: Int64) {
        maxCacheSize = size
        UserDefaults.standard.set(size, forKey: maxCacheSizeKey)
        Logger.debug("Max cache size set to: \(formatBytes(size))")

        // If current cache exceeds new limit, clear it
        if cacheSize > maxCacheSize {
            Logger.warning("Cache size exceeds new limit, clearing...")
            clearAllCaches()
        }
    }

    /// Format bytes to human-readable string
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    /// Get cache size for specific type
    func getCacheSize(type: CacheType) -> Int64 {
        var size: Int64 = 0

        let key: String
        switch type {
        case .library:
            key = "cachedLibrary"
        case .dashboard:
            key = "cachedDashboard"
        case .profile:
            key = "cachedProfile"
        case .userProfiles:
            key = "cachedUserProfiles"
        }

        if let data = UserDefaults.standard.data(forKey: key) {
            size = Int64(data.count)
        } else if let object = UserDefaults.standard.object(forKey: key) {
            // Try to get an estimate by converting to property list
            if let plistData = try? PropertyListSerialization.data(fromPropertyList: object, format: .binary, options: 0) {
                size = Int64(plistData.count)
            }
        }

        return size
    }

    /// Check if cache is approaching limit
    var isApproachingLimit: Bool {
        return Double(cacheSize) / Double(maxCacheSize) > 0.8
    }

    /// Get cache usage percentage
    var usagePercentage: Double {
        guard maxCacheSize > 0 else { return 0 }
        return min(Double(cacheSize) / Double(maxCacheSize), 1.0)
    }
}

enum CacheType: String, CaseIterable {
    case library = "Library"
    case dashboard = "Dashboard"
    case profile = "Profile"
    case userProfiles = "User Profiles"
}
