import Foundation
import SwiftUI
import Combine

class LibraryManager: ObservableObject {
    static let shared = LibraryManager()

    @Published var libraryItems: [LibraryItem] = []
    @Published var isLoading = false
    @Published var lastLoadTime: Date?

    private var hasLoadedOnce = false

    private init() {
        // Load cached library from UserDefaults on initialization
        loadFromCache()
    }

    /// Load library from server (only if not already loaded)
    func loadLibraryIfNeeded() async {
        guard !hasLoadedOnce else {
            print("📚 Library already cached, skipping reload")
            return
        }

        await loadLibrary()
    }

    /// Force reload library from server
    func loadLibrary() async {
        guard !isLoading else {
            print("📚 Library already loading, skipping duplicate request")
            return
        }

        await MainActor.run {
            isLoading = true
        }

        do {
            print("🔍 Loading library from server...")
            let items: [LibraryItem] = try await APIManager.shared.customRequest(
                endpoint: "/library",
                method: "GET",
                authenticated: true
            )

            await MainActor.run {
                libraryItems = items
                lastLoadTime = Date()
                hasLoadedOnce = true
                isLoading = false
                print("✅ Successfully loaded \(items.count) items")

                // Debug: Log cover URLs
                for item in items {
                    if let book = item.book {
                        print("📚 Book: \(book.title)")
                        print("   API Cover URL: \(book.coverUrl ?? "nil")")
                        print("   Effective Cover URL: \(book.effectiveCoverUrl ?? "nil")")
                        print("   ISBN: \(book.isbn ?? "nil")")
                    }
                }

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
            await MainActor.run {
                print("❌ Error loading library: \(error)")
                isLoading = false
            }
        }
    }

    /// Add a book to library and reload
    func addBook(_ bookId: Int) async throws {
        let body = ["book_id": bookId]
        let _: EmptyResponse = try await APIManager.shared.customRequest(
            endpoint: "/library/add?book_id=\(bookId)",
            method: "POST",
            body: body,
            authenticated: true
        )

        // Reload library after adding
        await loadLibrary()
    }

    /// Remove a book from library and reload
    func removeBook(_ bookId: Int) async throws {
        let _: EmptyResponse = try await APIManager.shared.customRequest(
            endpoint: "/library/remove?book_id=\(bookId)",
            method: "DELETE",
            authenticated: true
        )

        // Reload library after removing
        await loadLibrary()
    }

    /// Update book progress and reload
    func updateProgress(bookId: Int, currentPage: Int) async throws {
        let body = ["current_page": currentPage]
        let _: EmptyResponse = try await APIManager.shared.customRequest(
            endpoint: "/library/progress?book_id=\(bookId)&current_page=\(currentPage)",
            method: "POST",
            body: body,
            authenticated: true
        )

        // Reload library after updating progress
        await loadLibrary()
    }

    /// Clear cache (useful for logout or manual refresh)
    func clearCache() {
        libraryItems = []
        hasLoadedOnce = false
        lastLoadTime = nil

        // Remove from UserDefaults
        UserDefaults.standard.removeObject(forKey: "cachedLibraryItems")
        UserDefaults.standard.removeObject(forKey: "cachedLibraryLoadTime")
    }

    // MARK: - Persistence

    private func saveToCache() {
        if let encoded = try? JSONEncoder().encode(libraryItems) {
            UserDefaults.standard.set(encoded, forKey: "cachedLibraryItems")
        }
        if let lastLoadTime = lastLoadTime {
            UserDefaults.standard.set(lastLoadTime, forKey: "cachedLibraryLoadTime")
        }
    }

    private func loadFromCache() {
        if let data = UserDefaults.standard.data(forKey: "cachedLibraryItems"),
           let decoded = try? JSONDecoder().decode([LibraryItem].self, from: data) {
            libraryItems = decoded
            // Don't set hasLoadedOnce here - cache data should not prevent fresh server loads
            print("📚 Loaded \(decoded.count) items from cache")
        }

        if let cachedTime = UserDefaults.standard.object(forKey: "cachedLibraryLoadTime") as? Date {
            lastLoadTime = cachedTime
        }
    }
}
