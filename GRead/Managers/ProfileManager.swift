import Foundation
import SwiftUI
import Combine

class ProfileManager: ObservableObject {
    static let shared = ProfileManager()

    @Published var userProfile: UserProfile?
    @Published var xprofileFields: [XProfileField] = []
    @Published var isLoading = false
    @Published var lastLoadTime: Date?

    private var hasLoadedOnce = false

    private init() {
        // Load cached data from UserDefaults on initialization
        loadFromCache()
    }

    /// Load profile data from server (only if not already loaded)
    func loadProfileIfNeeded() async {
        guard !hasLoadedOnce else {
            print("📋 Profile already cached, skipping reload")
            return
        }

        await loadProfile()
    }

    /// Force reload profile data from server
    func loadProfile() async {
        guard !isLoading else {
            print("📋 Profile already loading, skipping duplicate request")
            return
        }

        await MainActor.run {
            isLoading = true
        }

        // Load full profile
        do {
            let profile = try await APIManager.shared.getMyProfile()
            await MainActor.run {
                userProfile = profile
                print("✅ Successfully loaded profile for \(profile.displayName)")
            }
        } catch is CancellationError {
            await MainActor.run {
                isLoading = false
            }
            return
        } catch {
            if let urlError = error as? URLError, urlError.code == .cancelled {
                await MainActor.run {
                    isLoading = false
                }
                return
            }
            print("❌ Failed to load profile: \(error)")
        }

        // Load xprofile fields (optional - don't fail if endpoint doesn't exist)
        do {
            let fields = try await APIManager.shared.getXProfileFields()
            await MainActor.run {
                xprofileFields = fields.sorted { $0.order ?? 0 < $1.order ?? 0 }
                print("✅ Successfully loaded \(fields.count) xprofile fields")
            }
        } catch is CancellationError {
            await MainActor.run {
                isLoading = false
            }
            return
        } catch {
            if let urlError = error as? URLError, urlError.code == .cancelled {
                await MainActor.run {
                    isLoading = false
                }
                return
            }
            // XProfile fields are optional - just log warning and continue
            print("⚠️ XProfile fields not available: \(error)")
        }

        await MainActor.run {
            lastLoadTime = Date()
            hasLoadedOnce = true
            isLoading = false

            // Save to cache
            saveToCache()
        }
    }

    /// Update profile data
    func updateProfile(displayName: String? = nil, bio: String? = nil, website: String? = nil, location: String? = nil) async throws {
        let updatedProfile = try await APIManager.shared.updateMyProfile(
            displayName: displayName,
            bio: bio,
            website: website,
            location: location
        )

        await MainActor.run {
            userProfile = updatedProfile
            saveToCache()
        }
    }

    /// Clear cache (useful for logout)
    func clearCache() {
        userProfile = nil
        xprofileFields = []
        hasLoadedOnce = false
        lastLoadTime = nil

        // Remove from UserDefaults
        UserDefaults.standard.removeObject(forKey: "cachedUserProfile")
        UserDefaults.standard.removeObject(forKey: "cachedXProfileFields")
        UserDefaults.standard.removeObject(forKey: "cachedProfileLoadTime")
    }

    // MARK: - Persistence

    private func saveToCache() {
        if let profile = userProfile, let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "cachedUserProfile")
        }

        if let encoded = try? JSONEncoder().encode(xprofileFields) {
            UserDefaults.standard.set(encoded, forKey: "cachedXProfileFields")
        }

        if let lastLoadTime = lastLoadTime {
            UserDefaults.standard.set(lastLoadTime, forKey: "cachedProfileLoadTime")
        }
    }

    private func loadFromCache() {
        if let data = UserDefaults.standard.data(forKey: "cachedUserProfile"),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = decoded
            // Don't set hasLoadedOnce here - cache data should not prevent fresh server loads
            print("📋 Loaded profile from cache for \(decoded.displayName)")
        }

        if let data = UserDefaults.standard.data(forKey: "cachedXProfileFields"),
           let decoded = try? JSONDecoder().decode([XProfileField].self, from: data) {
            xprofileFields = decoded
            print("📋 Loaded \(decoded.count) xprofile fields from cache")
        }

        if let cachedTime = UserDefaults.standard.object(forKey: "cachedProfileLoadTime") as? Date {
            lastLoadTime = cachedTime
        }
    }
}
