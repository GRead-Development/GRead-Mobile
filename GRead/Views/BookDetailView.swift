import SwiftUI

struct BookDetailView: View {
    let bookId: Int
    @Environment(\.themeColors) var themeColors
    @Environment(\.dismiss) var dismiss
    @State private var bookDetail: BookDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text("Loading book details...")
                        .font(.subheadline)
                        .foregroundColor(themeColors.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minHeight: 400)
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(themeColors.error)
                    Text("Failed to load book")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(themeColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Try Again") {
                        Task {
                            await loadBookDetail()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if let book = bookDetail {
                VStack(alignment: .leading, spacing: 20) {
                    // Cover Image Section
                    HStack {
                        Spacer()
                        if let coverUrl = book.effectiveCoverUrl, let url = URL(string: coverUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 200, height: 300)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: 200, maxHeight: 300)
                                        .cornerRadius(12)
                                        .shadow(color: themeColors.shadowColor, radius: 8, x: 0, y: 4)
                                case .failure:
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(themeColors.textSecondary)
                                        .frame(width: 200, height: 300)
                                        .background(themeColors.border.opacity(0.3))
                                        .cornerRadius(12)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image(systemName: "book.fill")
                                .font(.system(size: 80))
                                .foregroundColor(themeColors.textSecondary)
                                .frame(width: 200, height: 300)
                                .background(themeColors.border.opacity(0.3))
                                .cornerRadius(12)
                        }
                        Spacer()
                    }
                    .padding(.bottom)

                    // Title and Author
                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title.decodingHTMLEntities)
                            .font(.title)
                            .fontWeight(.bold)
                            .fixedSize(horizontal: false, vertical: true)

                        if let author = book.author {
                            Text(author.decodingHTMLEntities)
                                .font(.title3)
                                .foregroundColor(themeColors.textSecondary)
                        }
                    }
                    .padding(.horizontal)

                    // Statistics Section
                    if let stats = book.statistics {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Community")
                                .font(.headline)
                                .padding(.horizontal)

                            HStack(spacing: 20) {
                                StatItem(
                                    icon: "person.2.fill",
                                    value: formatNumber(stats.totalReaders),
                                    label: "Readers"
                                )

                                StatItem(
                                    icon: "star.fill",
                                    value: String(format: "%.1f", stats.averageRating),
                                    label: "Rating"
                                )

                                StatItem(
                                    icon: "text.bubble.fill",
                                    value: formatNumber(stats.reviewCount),
                                    label: "Reviews"
                                )
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .background(themeColors.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeColors.border, lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }

                    // Book Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Details")
                            .font(.headline)

                        if let pageCount = book.pageCount {
                            InfoRow(label: "Pages", value: "\(pageCount)")
                        }

                        if let year = book.publicationYear {
                            InfoRow(label: "Published", value: year)
                        }

                        if let isbn = book.isbn {
                            InfoRow(label: "ISBN", value: isbn)
                        }
                    }
                    .padding()
                    .background(themeColors.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeColors.border, lineWidth: 1)
                    )
                    .padding(.horizontal)

                    // Description
                    if let description = book.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.headline)

                            Text(description.decodingHTMLEntities)
                                .font(.body)
                                .foregroundColor(themeColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(themeColors.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeColors.border, lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadBookDetail()
        }
    }

    private func loadBookDetail() async {
        isLoading = true
        errorMessage = nil

        do {
            let detail = try await APIManager.shared.fetchBookDetail(bookId: bookId)
            bookDetail = detail
            isLoading = false
        } catch {
            errorMessage = "Could not load book details. Please try again."
            isLoading = false
            Logger.error("Failed to load book detail: \(error)")
        }
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            let thousands = Double(number) / 1000.0
            return String(format: "%.1fk", thousands)
        }
        return "\(number)"
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    @Environment(\.themeColors) var themeColors

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(themeColors.primary)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption)
                .foregroundColor(themeColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    @Environment(\.themeColors) var themeColors

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(themeColors.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationView {
        BookDetailView(bookId: 123)
    }
}
