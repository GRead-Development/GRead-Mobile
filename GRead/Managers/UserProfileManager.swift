import Foundation
import SwiftUI
import Combine

class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()

    // Cache profiles by userId
    @Published var cachedProfiles: [Int: CachedUserProfile] = [:]

    private init() {
        // Load cached data from UserDefaults on initialization
        loadFromCache()
    }

    /// Load profile data for a user (only if not already loaded)
    func loadProfileIfNeeded(userId: Int) async -> CachedUserProfile? {
        // Check if we have a cached profile
        if let cached = cachedProfiles[userId] {
            print("📋 Profile for user \(userId) already cached")
            return cached
        }

        return await loadProfile(userId: userId)
    }

    /// Force reload profile data for a user
    func loadProfile(userId: Int) async -> CachedUserProfile? {
        print("🔄 Loading profile for user \(userId)")

        var cachedProfile = CachedUserProfile(userId: userId)

        // Load basic user info (required)
        do {
            let user: User = try await APIManager.shared.request(
                endpoint: "/members/\(userId)",
                authenticated: false
            )
            cachedProfile.user = user
        } catch {
            print("❌ Failed to load basic user info for \(userId): \(error)")
            return nil
        }

        // Try to load full profile (optional)
        do {
            let profile = try await APIManager.shared.getUserProfile(userId: userId)
            cachedProfile.userProfile = profile
        } catch {
            print("⚠️ Failed to load full profile for \(userId): \(error)")
        }

        // Try to load xprofile fields (optional)
        do {
            let fields = try await APIManager.shared.getUserXProfileFields(userId: userId)
            cachedProfile.xprofileFields = fields.filter { $0.id != 0 }
        } catch {
            print("⚠️ Failed to load xprofile fields for \(userId): \(error)")
        }

        // Try to load stats (optional)
        do {
            let stats = try await APIManager.shared.getUserStats(userId: userId)
            cachedProfile.userStats = stats
        } catch {
            print("⚠️ Failed to load stats for \(userId): \(error)")
        }

        // Try to load friends (optional)
        do {
            let friendsResponse = try await APIManager.shared.getFriends(userId: userId)
            cachedProfile.friends = friendsResponse.friends
        } catch {
            print("⚠️ Failed to load friends for \(userId): \(error)")
        }

        await MainActor.run {
            cachedProfile.lastLoadTime = Date()
            cachedProfiles[userId] = cachedProfile
            saveToCache()
        }

        print("✅ Successfully loaded and cached profile for user \(userId)")
        return cachedProfile
    }

    /// Clear all cached profiles (useful for logout)
    func clearCache() {
        cachedProfiles.removeAll()
        UserDefaults.standard.removeObject(forKey: "cachedUserProfiles")
        print("🗑️ Cleared all cached user profiles")
    }

    // MARK: - Persistence

    private func saveToCache() {
        if let encoded = try? JSONEncoder().encode(cachedProfiles) {
            UserDefaults.standard.set(encoded, forKey: "cachedUserProfiles")
        }
    }

    private func loadFromCache() {
        if let data = UserDefaults.standard.data(forKey: "cachedUserProfiles"),
           let decoded = try? JSONDecoder().decode([Int: CachedUserProfile].self, from: data) {
            cachedProfiles = decoded
            print("📋 Loaded \(decoded.count) cached user profiles from disk")
        }
    }
}

// MARK: - Cached User Profile Model

struct CachedUserProfile: Codable {
    let userId: Int
    var user: User?
    var userProfile: UserProfile?
    var xprofileFields: [XProfileField] = []
    var userStats: UserStats?
    var friends: [User] = []
    var lastLoadTime: Date?
}
