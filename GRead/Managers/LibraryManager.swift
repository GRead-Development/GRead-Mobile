import Foundation
import SwiftUI
import Combine

class LibraryManager: ObservableObject {
    static let shared = LibraryManager()

    @Published var libraryItems: [LibraryItem] = []
    @Published var isLoading = false
    @Published var lastLoadTime: Date?

    private var hasLoadedOnce = false
    private var nextGuestBookId = -1 // Negative IDs for guest books

    private init() {
        // Load cached library from UserDefaults on initialization
        loadFromCache()
    }

    /// Load library (from server if authenticated, local if guest)
    func loadLibraryIfNeeded() async {
        guard !hasLoadedOnce else {
            print("📚 Library already cached, skipping reload")
            return
        }

        await loadLibrary()
    }

    /// Force reload library (from server if authenticated, local if guest)
    func loadLibrary() async {
        // Guest mode: Use local storage only
        if AuthManager.shared.isGuestMode {
            await MainActor.run {
                print("📚 Guest mode: Using local library (\(libraryItems.count) items)")
                hasLoadedOnce = true
            }
            return
        }

        // Authenticated mode: Load from server
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

    /// Add a book to library by ID (authenticated users only)
    func addBook(_ bookId: Int) async throws {
        guard !AuthManager.shared.isGuestMode else {
            throw NSError(domain: "LibraryManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Guest users cannot add books by ID. Please pass Book object instead."])
        }

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

    /// Add a book to library (locally if guest, server if authenticated)
    func addBook(_ book: Book, status: String = "reading") async throws {
        if AuthManager.shared.isGuestMode {
            // Guest mode: Add to local storage
            await addBookLocally(book, status: status)
        } else {
            // Authenticated: Add to server
            let body = ["book_id": book.id]
            let _: EmptyResponse = try await APIManager.shared.customRequest(
                endpoint: "/library/add?book_id=\(book.id)",
                method: "POST",
                body: body,
                authenticated: true
            )

            // Reload library after adding
            await loadLibrary()
        }
    }

    /// Add a book locally (for guest mode)
    private func addBookLocally(_ book: Book, status: String) async {
        await MainActor.run {
            // Format current date as ISO 8601 string
            let formatter = ISO8601DateFormatter()
            let dateString = formatter.string(from: Date())

            // Create a new library item with negative ID
            let libraryItem = LibraryItem(
                id: nextGuestBookId,
                userId: 0, // Guest user ID
                book: book,
                status: status,
                currentPage: 0,
                progressPercentage: 0.0,
                dateAdded: dateString
            )

            libraryItems.append(libraryItem)
            nextGuestBookId -= 1
            saveToCache()

            print("📚 Added book locally: \(book.title)")
        }
    }

    /// Remove a book from library (locally if guest, server if authenticated)
    func removeBook(_ bookId: Int) async throws {
        if AuthManager.shared.isGuestMode {
            // Guest mode: Remove from local storage
            await MainActor.run {
                libraryItems.removeAll { $0.book?.id == bookId || $0.id == bookId }
                saveToCache()
                print("📚 Removed book locally")
            }
        } else {
            // Authenticated: Remove from server
            let _: EmptyResponse = try await APIManager.shared.customRequest(
                endpoint: "/library/remove?book_id=\(bookId)",
                method: "DELETE",
                authenticated: true
            )

            // Reload library after removing
            await loadLibrary()
        }
    }

    /// Update book progress (locally if guest, server if authenticated)
    func updateProgress(bookId: Int, currentPage: Int) async throws {
        if AuthManager.shared.isGuestMode {
            // Guest mode: Update local storage
            await MainActor.run {
                if let index = libraryItems.firstIndex(where: { $0.book?.id == bookId || $0.id == bookId }) {
                    var updatedItem = libraryItems[index]

                    // Create a new LibraryItem with updated progress
                    let totalPages = updatedItem.book?.totalPages ?? 1
                    let progressPercentage = totalPages > 0 ? Double(currentPage) / Double(totalPages) : 0.0

                    // Determine status based on progress
                    var status = updatedItem.status
                    if currentPage >= totalPages {
                        status = "completed"
                    } else if currentPage > 0 {
                        status = "reading"
                    }

                    let newItem = LibraryItem(
                        id: updatedItem.id,
                        userId: updatedItem.userId,
                        book: updatedItem.book,
                        status: status,
                        currentPage: currentPage,
                        progressPercentage: progressPercentage,
                        dateAdded: updatedItem.dateAdded
                    )

                    libraryItems[index] = newItem
                    saveToCache()
                    print("📚 Updated progress locally: \(currentPage) pages")
                }
            }
        } else {
            // Authenticated: Update on server
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
    }

    /// Calculate local stats from library items (for guest mode)
    func getLocalStats() -> (booksCompleted: Int, pagesRead: Int, booksAdded: Int, points: Int) {
        var completed = 0
        var pagesRead = 0
        let booksAdded = libraryItems.count

        for item in libraryItems {
            if item.status == "completed" {
                completed += 1
                if let totalPages = item.book?.totalPages {
                    pagesRead += totalPages
                }
            } else {
                pagesRead += item.currentPage
            }
        }

        // Calculate points (simple formula: 10 points per book, 1 point per 10 pages)
        let points = (completed * 10) + (pagesRead / 10)

        return (completed, pagesRead, booksAdded, points)
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
