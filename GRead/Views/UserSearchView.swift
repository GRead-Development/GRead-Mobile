import SwiftUI

struct UserSearchView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.themeColors) var themeColors
    @Environment(\.dismiss) var dismiss

    @State private var searchQuery = ""
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var error: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(themeColors.textSecondary)

                    TextField("Search users...", text: $searchQuery)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: searchQuery) { _ in
                            if !searchQuery.isEmpty {
                                performSearch()
                            } else {
                                searchResults = []
                                hasSearched = false
                            }
                        }

                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(themeColors.textSecondary)
                        }
                    }
                }
                .padding(12)
                .background(themeColors.inputBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeColors.border, lineWidth: 1)
                )
                .padding(14)

                // Results or Empty State
                if isSearching {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else if let error = error {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title)
                            .foregroundColor(themeColors.error)
                        Text(error)
                            .foregroundColor(themeColors.error)
                        Button("Retry") {
                            performSearch()
                        }
                        .foregroundColor(themeColors.primary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else if searchResults.isEmpty && hasSearched {
                    VStack(spacing: 12) {
                        Image(systemName: "person.slash")
                            .font(.title)
                            .foregroundColor(themeColors.textSecondary)
                        Text("No users found")
                            .foregroundColor(themeColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else if !searchResults.isEmpty {
                    List {
                        ForEach(searchResults) { user in
                            NavigationLink(destination: UserDetailView(userId: user.id)) {
                                UserSearchResultRow(user: user)
                            }
                        }
                    }
                    .listStyle(.plain)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.title)
                            .foregroundColor(themeColors.textSecondary)
                        Text("Search for users to follow")
                            .foregroundColor(themeColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Find Users")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeColors.textSecondary)
                    }
                }
            }
        }
    }

    private func performSearch() {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            hasSearched = false
            return
        }

        isSearching = true
        error = nil
        hasSearched = true

        Task {
            do {
                let response = try await APIManager.shared.searchUsers(query: searchQuery)
                await MainActor.run {
                    searchResults = response.users
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Search failed"
                    isSearching = false
                    Logger.error("Search error: \(error)")
                }
            }
        }
    }
}

// MARK: - Search Result Row
struct UserSearchResultRow: View {
    let user: User
    @Environment(\.themeColors) var themeColors

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: user.avatarUrl)) { image in
                image.resizable()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(themeColors.primary)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(user.name.decodingHTMLEntities)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeColors.textPrimary)

                if let username = user.userLogin {
                    Text("@\(username.decodingHTMLEntities)")
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                }
            }

            Spacer()
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    UserSearchView()
        .environmentObject(ThemeManager.shared)
}
