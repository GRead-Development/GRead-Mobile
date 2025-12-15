import SwiftUI

struct BookDetailView: View {
    let bookId: Int
    let heroNamespace: Namespace.ID
    let heroID: String
    @Environment(\.themeColors) var themeColors
    @Environment(\.dismiss) var dismiss
    @ObservedObject var libraryManager = LibraryManager.shared
    @State private var bookDetail: BookDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showProgressEditor = false
    @State private var showAddToLibrary = false

    // Check if this book is in the user's library
    var libraryItem: LibraryItem? {
        libraryManager.libraryItems.first { $0.book?.id == bookId }
    }

    var isInLibrary: Bool {
        libraryItem != nil
    }

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
                        ZStack {
                            if let coverUrl = book.effectiveCoverUrl, let url = URL(string: coverUrl) {
                                CachedAsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: 200, maxHeight: 300)
                                        .cornerRadius(12)
                                        .shadow(color: themeColors.shadowColor, radius: 8, x: 0, y: 4)
                                } placeholder: {
                                    ProgressView()
                                        .frame(width: 200, height: 300)
                                        .background(themeColors.border.opacity(0.1))
                                        .cornerRadius(12)
                                }
                            } else {
                                ZStack {
                                    Rectangle()
                                        .fill(themeColors.primary)
                                        .frame(width: 200, height: 300)
                                        .cornerRadius(12)

                                    VStack(spacing: 8) {
                                        Image(systemName: "book.fill")
                                            .font(.system(size: 80))
                                            .foregroundColor(.white.opacity(0.9))

                                        if let title = bookDetail?.title {
                                            Text(title)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(3)
                                                .padding(.horizontal, 12)
                                        }
                                    }
                                }
                                .shadow(color: themeColors.shadowColor, radius: 8, x: 0, y: 4)
                            }
                        }
                        .frame(width: 200, height: 300)
                        .matchedGeometryEffect(id: heroID, in: heroNamespace)
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

                    // Action Buttons
                    VStack(spacing: 12) {
                        if isInLibrary, let item = libraryItem {
                            Button {
                                showProgressEditor = true
                            } label: {
                                HStack {
                                    Image(systemName: "book.pages")
                                    Text("Update Progress")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(themeColors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }

                            Button(role: .destructive) {
                                Task {
                                    await removeFromLibrary()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Remove from Library")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(themeColors.error.opacity(0.1))
                                .foregroundColor(themeColors.error)
                                .cornerRadius(12)
                            }
                        } else {
                            Button {
                                showAddToLibrary = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add to Library")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(themeColors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showProgressEditor) {
            if let item = libraryItem {
                ProgressEditorSheet(
                    isPresented: $showProgressEditor,
                    currentPage: item.currentPage,
                    totalPages: item.book?.totalPages ?? 0,
                    onSave: { newPage in
                        Task {
                            await updateProgress(newPage: newPage)
                        }
                        showProgressEditor = false
                    }
                )
            }
        }
        .sheet(isPresented: $showAddToLibrary) {
            AddToLibrarySheet(
                isPresented: $showAddToLibrary,
                bookId: bookId,
                totalPages: bookDetail?.pageCount ?? 0
            )
        }
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

    private func updateProgress(newPage: Int) async {
        guard let item = libraryItem, let bookId = item.book?.id else { return }

        do {
            try await libraryManager.updateProgress(bookId: bookId, currentPage: newPage)
            Logger.debug("Progress updated successfully")
        } catch {
            Logger.error("Failed to update progress: \(error)")
        }
    }

    private func removeFromLibrary() async {
        guard let item = libraryItem, let bookId = item.book?.id else { return }

        do {
            try await libraryManager.removeBook(bookId)
            Logger.debug("Book removed from library")
        } catch {
            Logger.error("Failed to remove book: \(error)")
        }
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

struct AddToLibrarySheet: View {
    @Binding var isPresented: Bool
    let bookId: Int
    let totalPages: Int
    @Environment(\.themeColors) var themeColors
    @ObservedObject var libraryManager = LibraryManager.shared

    @State private var selectedStatus: String = "reading"
    @State private var currentPage: String = "0"
    @State private var isAdding = false

    let statuses = [
        ("reading", "Currently Reading"),
        ("completed", "Completed"),
        ("paused", "Paused")
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reading Status")) {
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(statuses, id: \.0) { status, label in
                            Text(label).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Current Page")) {
                    HStack {
                        TextField("Current Page", text: $currentPage)
                            .keyboardType(.numberPad)

                        Text("/ \(totalPages)")
                            .foregroundColor(themeColors.textSecondary)
                    }
                }
            }
            .navigationTitle("Add to Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await addToLibrary()
                        }
                    }
                    .disabled(isAdding)
                }
            }
        }
    }

    private func addToLibrary() async {
        isAdding = true

        let page = Int(currentPage) ?? 0

        do {
            try await libraryManager.addBook(bookId)
            // Update progress if needed
            if page > 0 {
                try await libraryManager.updateProgress(bookId: bookId, currentPage: page)
            }
            Logger.debug("Book added to library successfully")
            await MainActor.run {
                isPresented = false
            }
        } catch {
            Logger.error("Failed to add book to library: \(error)")
        }

        isAdding = false
    }
}

#Preview {
    @Namespace var namespace
    return NavigationView {
        BookDetailView(bookId: 123, heroNamespace: namespace, heroID: "preview-bookCover-123")
    }
}
