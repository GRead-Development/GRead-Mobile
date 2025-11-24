import SwiftUI

struct FriendsListView: View {
    let userId: Int
    var isCurrentUser: Bool = false

    @EnvironmentObject var authManager: AuthManager
    @Environment(\.themeColors) var themeColors

    @State private var friends: [User] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else if let error = error {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title)
                            .foregroundColor(themeColors.error)
                        Text(error)
                            .foregroundColor(themeColors.error)
                        Button("Retry") {
                            loadFriends()
                        }
                        .foregroundColor(themeColors.primary)
                    }
                } else if friends.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.slash")
                            .font(.title)
                            .foregroundColor(themeColors.textSecondary)
                        Text("No friends yet")
                            .foregroundColor(themeColors.textSecondary)
                    }
                } else {
                    VStack(spacing: 0) {
                        Text("Friends (\(friends.count))")
                            .font(.headline)
                            .foregroundColor(themeColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)

                        VStack(spacing: 8) {
                            ForEach(friends) { friend in
                                NavigationLink(destination: UserDetailView(userId: friend.id)) {
                                    FriendCard(friend: friend)
                                }
                            }
                        }
                        .padding(14)
                    }
                }
            }
        }
        .navigationTitle(isCurrentUser ? "Friends" : "User's Friends")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadFriends()
        }
    }

    private func loadFriends() {
        isLoading = true
        error = nil

        Task {
            do {
                let response = try await APIManager.shared.getFriends(userId: userId)
                await MainActor.run {
                    self.friends = response.friends
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to load friends"
                    self.isLoading = false
                    Logger.error("Error loading friends: \(error)")
                }
            }
        }
    }
}

// MARK: - Friend Card
struct FriendCard: View {
    let friend: User
    @Environment(\.themeColors) var themeColors

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: friend.avatarUrl)) { image in
                image.resizable()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(themeColors.primary)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name.decodingHTMLEntities)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeColors.textPrimary)

                if let username = friend.userLogin {
                    Text("@\(username.decodingHTMLEntities)")
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(themeColors.textSecondary)
        }
        .padding(12)
        .background(themeColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeColors.border, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationView {
        FriendsListView(userId: 1, isCurrentUser: true)
            .environmentObject(ThemeManager.shared)
    }
}
