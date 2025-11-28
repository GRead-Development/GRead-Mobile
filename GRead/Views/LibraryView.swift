import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.themeColors) var themeColors
    @StateObject var libraryManager = LibraryManager.shared
    @State private var showAddBook = false
    @State private var showISBNImport = false
    @State private var searchText = ""
    @State private var selectedFilter: String = "all"
    @State private var listRefreshID = UUID()

    let filterOptions = ["all", "reading", "completed"]

    var filteredItems: [LibraryItem] {
        // Auto-mark as completed if progress equals page count
        let items = libraryManager.libraryItems.map { item -> LibraryItem in
            var mutableItem = item
            if let totalPages = item.book?.totalPages, totalPages > 0, item.currentPage >= totalPages {
                mutableItem.status = "completed"
            }
            return mutableItem
        }

        let filtered = selectedFilter == "all"
            ? items
            : items.filter { $0.status == selectedFilter }

        if searchText.isEmpty {
            return filtered
        }
        return filtered.filter { item in
            item.book?.title.localizedCaseInsensitiveContains(searchText) ?? false ||
            item.book?.author?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                if libraryManager.isLoading {
                    ProgressView()
                } else if libraryManager.libraryItems.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 60))
                            .foregroundColor(themeColors.textSecondary)

                        Text("Your Library is Empty")
                            .font(.headline)
                            .foregroundColor(themeColors.textPrimary)

                        Text("Add books to get started tracking your reading")
                            .font(.subheadline)
                            .foregroundColor(themeColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: { showAddBook = true }) {
                            Label("Add First Book", systemImage: "plus.circle.fill")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(themeColors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .padding()
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                } else {
                    VStack {
                        // Search and Filter
                        VStack(spacing: 12) {
                            SearchBar(text: $searchText)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(filterOptions, id: \.self) { option in
                                        FilterButton(
                                            label: option.capitalized,
                                            isSelected: selectedFilter == option,
                                            action: { selectedFilter = option }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 12)
                        .background(themeColors.cardBackground)

                        // Library Items List
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(filteredItems, id: \.id) { item in
                                    LibraryItemCard(libraryItem: item, onDelete: {
                                        deleteBook(item)
                                    }, onProgressUpdate: { newPage in
                                        updateProgress(item: item, currentPage: newPage)
                                    })
                                }
                                .padding()
                            }
                            .id(listRefreshID)
                        }
                    }
                }
            }
            .navigationTitle("My Library")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showISBNImport = true }) {
                        Image(systemName: "barcode")
                    }
                    Button(action: { showAddBook = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddBook) {
                AddBookSheet(isPresented: $showAddBook, onBookAdded: {
                    Task {
                        await libraryManager.loadLibrary()
                    }
                })
                .environmentObject(authManager)
            }
            .sheet(isPresented: $showISBNImport) {
                ISBNImportSheet(isPresented: $showISBNImport, onBookAdded: {
                    Task {
                        await libraryManager.loadLibrary()
                    }
                })
                .environmentObject(authManager)
            }
            .task {
                await libraryManager.loadLibraryIfNeeded()
            }
            .refreshable {
                await libraryManager.loadLibrary()
            }
        }
    }

    private func deleteBook(_ item: LibraryItem) {
        Task {
            do {
                guard let bookId = item.book?.id else { return }
                try await libraryManager.removeBook(bookId)
            } catch {
                print("Error removing book: \(error)")
            }
        }
    }

    private func updateProgress(item: LibraryItem, currentPage: Int) {
        Task {
            do {
                guard let bookId = item.book?.id else { return }
                try await libraryManager.updateProgress(bookId: bookId, currentPage: currentPage)
            } catch {
                print("Error updating progress: \(error)")
            }
        }
    }
}

// MARK: - Library Item Card
struct LibraryItemCard: View {
    let libraryItem: LibraryItem
    let onDelete: () -> Void
    let onProgressUpdate: (Int) -> Void
    @Environment(\.themeColors) var themeColors

    @State private var showProgressEditor = false
    @State private var newPageCount = 0

    var progressPercentage: Double {
        guard let totalPages = libraryItem.book?.totalPages, totalPages > 0 else { return 0 }
        return Double(libraryItem.currentPage) / Double(totalPages) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text((libraryItem.book?.title ?? "Unknown Book").decodingHTMLEntities)
                        .font(.headline)
                        .lineLimit(2)

                    if let author = libraryItem.book?.author {
                        Text(author.decodingHTMLEntities)
                            .font(.subheadline)
                            .foregroundColor(themeColors.textSecondary)
                    }

                    HStack(spacing: 8) {
                        if !libraryItem.status.isEmpty {
                            StatusBadge(status: libraryItem.status)
                        }
                    }

                    Spacer()

                    Text("\(libraryItem.currentPage) / \(libraryItem.book?.totalPages ?? 0) pages")
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                }

                Spacer()

                Menu {
                    Button(role: .destructive, action: onDelete) {
                        Label("Remove from Library", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(themeColors.textSecondary)
                }
            }

            // Progress Bar
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(themeColors.textSecondary.opacity(0.3))
                    .frame(maxWidth: .infinity, maxHeight: 8)

                Capsule()
                    .fill(themeColors.primary)
                    .frame(maxWidth: .infinity, maxHeight: 8)
                    .scaleEffect(x: min(progressPercentage / 100.0, 1.0), anchor: .leading)
            }

            Text("\(Int(progressPercentage))% complete")
                .font(.caption)
                .foregroundColor(themeColors.textSecondary)
        }
        .padding(14)
        .background(themeColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeColors.border, lineWidth: 1)
        )
        .shadow(color: themeColors.shadowColor, radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            showProgressEditor = true
        }
        .sheet(isPresented: $showProgressEditor) {
            ProgressEditorSheet(
                isPresented: $showProgressEditor,
                currentPage: libraryItem.currentPage,
                totalPages: libraryItem.book?.totalPages ?? 0,
                onSave: { newPage in
                    onProgressUpdate(newPage)
                    showProgressEditor = false
                }
            )
        }
    }
}

// MARK: - Progress Editor Sheet
struct ProgressEditorSheet: View {
    @Binding var isPresented: Bool
    let currentPage: Int
    let totalPages: Int
    let onSave: (Int) -> Void
    @Environment(\.themeColors) var themeColors

    @State private var pageInput = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Progress")
                        .font(.headline)

                    Text("\(currentPage) / \(totalPages) pages")
                        .font(.title3)
                        .foregroundColor(themeColors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Update to page:")
                        .font(.headline)

                    HStack {
                        TextField("Page number", text: $pageInput)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)

                        Stepper("", value: Binding(
                            get: { Int(pageInput) ?? currentPage },
                            set: { pageInput = String($0) }
                        ), in: 0...totalPages)
                    }
                }

                VStack(spacing: 12) {
                    Slider(
                        value: Binding(
                            get: { Double(Int(pageInput) ?? currentPage) },
                            set: { pageInput = String(Int($0)) }
                        ),
                        in: 0...Double(totalPages)
                    )

                    HStack {
                        Text("0p")
                            .font(.caption)
                            .foregroundColor(themeColors.textSecondary)
                        Spacer()
                        Text("\(totalPages)p")
                            .font(.caption)
                            .foregroundColor(themeColors.textSecondary)
                    }
                }

                Spacer()

                Button(action: {
                    let page = Int(pageInput) ?? currentPage
                    let finalPage = min(max(page, 0), totalPages)
                    onSave(finalPage)
                }) {
                    Text("Save Progress")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeColors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(pageInput.isEmpty)
            }
            .padding()
            .navigationTitle("Update Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            pageInput = String(currentPage)
        }
    }
}

// MARK: - Add Book Sheet
struct AddBookSheet: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.themeColors) var themeColors
    @Binding var isPresented: Bool
    let onBookAdded: () -> Void

    @State private var searchQuery = ""
    @State private var searchResults: [Book] = []
    @State private var isSearching = false
    @State private var selectedBook: Book?
    @State private var showConfirmation = false

    var body: some View {
        NavigationView {
            if #available(iOS 17.0, *) {
                VStack(spacing: 16) {
                    SearchBar(text: $searchQuery)
                        .padding()
                    
                    if isSearching {
                        ProgressView()
                            .frame(maxHeight: .infinity, alignment: .center)
                    } else if !searchResults.isEmpty {
                        List(searchResults) { book in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(book.title.decodingHTMLEntities)
                                    .font(.headline)

                                if let author = book.author {
                                    Text(author.decodingHTMLEntities)
                                        .font(.subheadline)
                                        .foregroundColor(themeColors.textSecondary)
                                }

                                if let description = book.description {
                                    Text(description.decodingHTMLEntities)
                                        .font(.caption)
                                        .foregroundColor(themeColors.textSecondary)
                                        .lineLimit(2)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedBook = book
                                showConfirmation = true
                            }
                        }
                    } else if !searchQuery.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 50))
                                .foregroundColor(themeColors.textSecondary)

                            Text("No books found")
                                .font(.headline)
                                .foregroundColor(themeColors.textPrimary)

                            Text("Try searching with different keywords")
                                .font(.caption)
                                .foregroundColor(themeColors.textSecondary)
                        }
                        .frame(maxHeight: .infinity, alignment: .center)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(themeColors.textSecondary)

                            Text("Search for books")
                                .font(.headline)
                                .foregroundColor(themeColors.textPrimary)

                            Text("Enter a book title or author name")
                                .font(.caption)
                                .foregroundColor(themeColors.textSecondary)
                        }
                        .frame(maxHeight: .infinity, alignment: .center)
                    }
                }
                .navigationTitle("Add Book")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                }
                .onChange(of: searchQuery) {
                    if !searchQuery.isEmpty {
                        performSearch()
                    } else {
                        searchResults = []
                    }
                }
                .alert("Add Book", isPresented: $showConfirmation, actions: {
                    Button("Cancel", role: .cancel) { }
                    Button("Add") {
                        if let book = selectedBook {
                            addBook(book)
                        }
                    }
                }, message: {
                    if let book = selectedBook {
                        Text("Add '\(book.title)' to your library?")
                    }
                })
            } else {
                // Fallback on earlier versions
            }
        }
    }

    private func performSearch() {
        isSearching = true
        Task {
            do {
                searchResults = try await APIManager.shared.customRequest(
                    endpoint: "/books/search?query=\(searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
                    method: "GET",
                    authenticated: true
                )
                isSearching = false
            } catch {
                print("Error searching books: \(error)")
                isSearching = false
                searchResults = []
            }
        }
    }

    private func addBook(_ book: Book) {
        Task {
            do {
                try await LibraryManager.shared.addBook(book.id)
                onBookAdded()
                isPresented = false
            } catch {
                print("Error adding book: \(error)")
            }
        }
    }
}

// MARK: - Helper Views
struct SearchBar: View {
    @Binding var text: String
    @Environment(\.themeColors) var themeColors

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeColors.textSecondary)

            TextField("Search...", text: $text)
                .textFieldStyle(.roundedBorder)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeColors.textSecondary)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct FilterButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.themeColors) var themeColors

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? themeColors.primary : themeColors.cardBackground)
                .foregroundColor(isSelected ? .white : themeColors.textPrimary)
                .cornerRadius(16)
        }
    }
}

struct StatusBadge: View {
    let status: String

    var statusColor: Color {
        switch status.lowercased() {
        case "reading":
            return .blue
        case "completed":
            return .green
        case "paused":
            return .orange
        default:
            return .gray
        }
    }

    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }
}

// MARK: - ISBN Import Sheet
struct ISBNImportSheet: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.themeColors) var themeColors
    @Binding var isPresented: Bool
    let onBookAdded: () -> Void

    @State private var isbnInput = ""
    @State private var isSearching = false
    @State private var searchResults: [Book] = []
    @State private var selectedBook: Book?
    @State private var showConfirmation = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    Text("Import by ISBN")
                        .font(.headline)
                        .padding(.top)

                    VStack(spacing: 12) {
                        TextField("Enter ISBN...", text: $isbnInput)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.default)

                        Button(action: searchByISBN) {
                            HStack {
                                if isSearching {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "barcode.viewfinder")
                                }
                                Text(isSearching ? "Searching..." : "Search ISBN")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeColors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .font(.headline)
                        }
                        .disabled(isbnInput.isEmpty || isSearching)
                    }
                    .padding()
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(themeColors.error)
                        .padding()
                }

                if !searchResults.isEmpty {
                    List(searchResults) { book in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(book.title.decodingHTMLEntities)
                                .font(.headline)

                            if let author = book.author {
                                Text(author.decodingHTMLEntities)
                                    .font(.subheadline)
                                    .foregroundColor(themeColors.textSecondary)
                            }

                            if let isbn = book.isbn {
                                Text("ISBN: \(isbn)")
                                    .font(.caption)
                                    .foregroundColor(themeColors.textSecondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedBook = book
                            showConfirmation = true
                        }
                    }
                } else if !isbnInput.isEmpty && !isSearching && errorMessage == nil {
                    VStack(spacing: 16) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 50))
                            .foregroundColor(themeColors.textSecondary)

                        Text("No books found")
                            .font(.headline)
                            .foregroundColor(themeColors.textPrimary)

                        Text("Try a different ISBN")
                            .font(.caption)
                            .foregroundColor(themeColors.textSecondary)
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                } else {
                    Spacer()
                }

                Spacer()
            }
            .navigationTitle("Import by ISBN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .alert("Add Book", isPresented: $showConfirmation, actions: {
                Button("Cancel", role: .cancel) { }
                Button("Add") {
                    if let book = selectedBook {
                        addBook(book)
                    }
                }
            }, message: {
                if let book = selectedBook {
                    Text("Add '\(book.title)' to your library?")
                }
            })
        }
    }

    private func searchByISBN() {
        isSearching = true
        errorMessage = nil

        // Validate ISBN format (basic check)
        let cleanISBN = isbnInput.trimmingCharacters(in: .whitespaces)
        if cleanISBN.isEmpty {
            errorMessage = "Please enter an ISBN"
            isSearching = false
            return
        }

        Task {
            do {
                // Call the ISBN-specific endpoint that queries OpenLibrary via the WordPress plugin
                let result: Book = try await APIManager.shared.customRequest(
                    endpoint: "/books/isbn?isbn=\(cleanISBN.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
                    method: "GET",
                    authenticated: true
                )
                await MainActor.run {
                    searchResults = [result]
                    isSearching = false
                }
            } catch let error as APIError {
                // Handle specific API errors
                await MainActor.run {
                    switch error {
                    case .httpError(404):
                        errorMessage = "Book not found. Please check the ISBN and try again."
                    case .decodingError:
                        errorMessage = "Book not found. Please check the ISBN and try again."
                    case .emptyResponse:
                        errorMessage = "Book not found. Please check the ISBN and try again."
                    default:
                        errorMessage = "Failed to search ISBN. Please try again."
                    }
                    isSearching = false
                    searchResults = []
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to search ISBN. Please try again."
                    isSearching = false
                    searchResults = []
                }
            }
        }
    }

    private func addBook(_ book: Book) {
        Task {
            do {
                try await LibraryManager.shared.addBook(book.id)
                onBookAdded()
                isPresented = false
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to add book: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    LibraryView()
        .environmentObject(AuthManager())
}
