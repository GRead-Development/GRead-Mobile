import Foundation
import SwiftUI
import Combine

class DashboardManager: ObservableObject {
    static let shared = DashboardManager()

    @Published var stats: UserStats?
    @Published var recentActivity: [Activity] = []
    @Published var achievements: [Achievement] = []
    @Published var isLoading = false
    @Published var lastLoadTime: Date?

    private var hasLoadedOnce = false

    private init() {
        // Load cached data from UserDefaults on initialization
        loadFromCache()
    }

    /// Load dashboard data from server (only if not already loaded)
    func loadDashboardIfNeeded(userId: Int) async {
        guard !hasLoadedOnce else {
            print("📊 Dashboard already cached, skipping reload")
            return
        }

        await loadDashboard(userId: userId)
    }

    /// Force reload dashboard data from server
    func loadDashboard(userId: Int) async {
        guard !isLoading else { return }

        await MainActor.run {
            isLoading = true
        }

        async let statsTask = loadStats(userId: userId)
        async let activityTask = loadRecentActivity()
        async let achievementsTask = loadAchievements(userId: userId)

        _ = await [statsTask, activityTask, achievementsTask]

        await MainActor.run {
            lastLoadTime = Date()
            hasLoadedOnce = true
            isLoading = false

            // Save to cache
            saveToCache()
        }
    }

    private func loadStats(userId: Int) async {
        do {
            let loadedStats = try await APIManager.shared.getUserStats(userId: userId)
            await MainActor.run {
                stats = loadedStats
            }
        } catch is CancellationError {
            return
        } catch {
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }
            print("Failed to load stats: \(error)")
        }
    }

    private func loadRecentActivity() async {
        do {
            let response: ActivityResponse = try await APIManager.shared.request(
                endpoint: "/activity?per_page=5&page=1",
                authenticated: false
            )
            await MainActor.run {
                recentActivity = response.activities
            }
        } catch is CancellationError {
            return
        } catch {
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }
            print("Failed to load activity: \(error)")
        }
    }

    private func loadAchievements(userId: Int) async {
        do {
            let response = try await APIManager.shared.getUserAchievements(userId: userId, filter: "unlocked")
            await MainActor.run {
                achievements = response.achievements.sorted(by: { $0.dateUnlocked ?? "" > $1.dateUnlocked ?? "" })
            }
        } catch is CancellationError {
            return
        } catch {
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }
            print("Failed to load achievements: \(error)")
        }
    }

    /// Clear cache (useful for logout or manual refresh)
    func clearCache() {
        stats = nil
        recentActivity = []
        achievements = []
        hasLoadedOnce = false
        lastLoadTime = nil

        // Remove from UserDefaults
        UserDefaults.standard.removeObject(forKey: "cachedDashboardStats")
        UserDefaults.standard.removeObject(forKey: "cachedDashboardActivity")
        UserDefaults.standard.removeObject(forKey: "cachedDashboardAchievements")
        UserDefaults.standard.removeObject(forKey: "cachedDashboardLoadTime")
    }

    // MARK: - Persistence

    private func saveToCache() {
        if let stats = stats, let encoded = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(encoded, forKey: "cachedDashboardStats")
        }

        if let encoded = try? JSONEncoder().encode(recentActivity) {
            UserDefaults.standard.set(encoded, forKey: "cachedDashboardActivity")
        }

        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: "cachedDashboardAchievements")
        }

        if let lastLoadTime = lastLoadTime {
            UserDefaults.standard.set(lastLoadTime, forKey: "cachedDashboardLoadTime")
        }
    }

    private func loadFromCache() {
        if let data = UserDefaults.standard.data(forKey: "cachedDashboardStats"),
           let decoded = try? JSONDecoder().decode(UserStats.self, from: data) {
            stats = decoded
            hasLoadedOnce = true
            print("📊 Loaded stats from cache")
        }

        if let data = UserDefaults.standard.data(forKey: "cachedDashboardActivity"),
           let decoded = try? JSONDecoder().decode([Activity].self, from: data) {
            recentActivity = decoded
            print("📊 Loaded \(decoded.count) activities from cache")
        }

        if let data = UserDefaults.standard.data(forKey: "cachedDashboardAchievements"),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded
            print("📊 Loaded \(decoded.count) achievements from cache")
        }

        if let cachedTime = UserDefaults.standard.object(forKey: "cachedDashboardLoadTime") as? Date {
            lastLoadTime = cachedTime
        }
    }
}
