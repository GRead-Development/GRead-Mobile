import SwiftUI

struct AuthorBooksView: View {
    let authorName: String
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColors) var themeColors
    @State private var books: [Book] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading books by \(authorName)...")
                        .padding()
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(themeColors.error)
                        Text(error)
                            .foregroundColor(themeColors.error)
                        Button("Try Again") {
                            Task {
                                await loadBooks()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else if books.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(themeColors.textSecondary)
                        Text("No books found")
                            .font(.headline)
                        Text("No other books by this author in our database")
                            .font(.caption)
                            .foregroundColor(themeColors.textSecondary)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(books) { book in
                            NavigationLink(destination: BookDetailView(bookId: book.id)) {
                                HStack(spacing: 12) {
                                    if let coverUrl = book.effectiveCoverUrl, let url = URL(string: coverUrl) {
                                        AsyncImage(url: url) { image in
                                            image.resizable()
                                        } placeholder: {
                                            Rectangle()
                                                .fill(themeColors.textSecondary.opacity(0.2))
                                        }
                                        .frame(width: 50, height: 75)
                                        .cornerRadius(4)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(book.title.decodingHTMLEntities)
                                            .font(.subheadline)
                                            .fontWeight(.medium)

                                        if let year = book.publicationYear {
                                            Text(year)
                                                .font(.caption)
                                                .foregroundColor(themeColors.textSecondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Books by \(authorName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadBooks()
            }
        }
    }

    private func loadBooks() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: BookSearchResponse = try await APIManager.shared.customRequest(
                endpoint: "/books/search?query=\(authorName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
                method: "GET",
                authenticated: false
            )

            await MainActor.run {
                // Filter books by this specific author
                books = response.books.filter { book in
                    book.author?.localizedCaseInsensitiveContains(authorName) ?? false
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load books"
                isLoading = false
            }
        }
    }
}
