import Foundation
import SwiftUI
import Combine

class GuidesManager: ObservableObject {
    static let shared = GuidesManager()

    @Published var guides: [Guide] = []
    @Published var categories: [GuideCategory] = []
    @Published var isLoading = false
    @Published var lastLoadTime: Date?

    private var hasLoadedOnce = false

    private init() {
        // Load cached data from UserDefaults on initialization
        loadFromCache()
    }

    /// Load guides from server (only if not already loaded)
    func loadGuidesIfNeeded() async {
        guard !hasLoadedOnce else {
            print("📖 Guides already cached, skipping reload")
            return
        }

        await loadGuides()
    }

    /// Force reload guides from server
    func loadGuides() async {
        guard !isLoading else {
            print("📖 Guides already loading, skipping duplicate request")
            return
        }

        await MainActor.run {
            isLoading = true
        }

        do {
            let loadedGuides: [Guide] = try await APIManager.shared.request(
                endpoint: "/guides",
                authenticated: false
            )

            await MainActor.run {
                guides = loadedGuides.sorted { $0.order < $1.order }
                lastLoadTime = Date()
                hasLoadedOnce = true
                isLoading = false

                // Save to cache
                saveToCache()
            }
        } catch is CancellationError {
            await MainActor.run {
                isLoading = false
            }
        } catch {
            if let urlError = error as? URLError, urlError.code == .cancelled {
                await MainActor.run {
                    isLoading = false
                }
                return
            }
            print("Failed to load guides: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }

    /// Get featured guides (first 3 for dashboard)
    var featuredGuides: [Guide] {
        Array(guides.prefix(3))
    }

    // MARK: - Caching

    private func saveToCache() {
        if let encodedGuides = try? JSONEncoder().encode(guides) {
            UserDefaults.standard.set(encodedGuides, forKey: "cachedGuides")
        }
        if let lastLoadTime = lastLoadTime {
            UserDefaults.standard.set(lastLoadTime, forKey: "guidesLastLoadTime")
        }
    }

    private func loadFromCache() {
        // Load guides
        if let guidesData = UserDefaults.standard.data(forKey: "cachedGuides"),
           let cachedGuides = try? JSONDecoder().decode([Guide].self, from: guidesData) {
            guides = cachedGuides
            hasLoadedOnce = true
        }

        // Load last load time
        if let cachedLoadTime = UserDefaults.standard.object(forKey: "guidesLastLoadTime") as? Date {
            lastLoadTime = cachedLoadTime
        }
    }

    func clearCache() {
        UserDefaults.standard.removeObject(forKey: "cachedGuides")
        UserDefaults.standard.removeObject(forKey: "guidesLastLoadTime")
        guides = []
        hasLoadedOnce = false
        lastLoadTime = nil
    }
}
