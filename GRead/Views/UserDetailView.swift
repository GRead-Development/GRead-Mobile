import SwiftUI

struct UserDetailView: View {
    let userId: Int

    @EnvironmentObject var authManager: AuthManager
    @Environment(\.themeColors) var themeColors
    @Environment(\.dismiss) var dismiss

    @State private var user: User?
    @State private var userStats: UserStats?
    @State private var friends: [User] = []
    @State private var isLoading = true
    @State private var error: String?

    @State private var isFriend = false
    @State private var friendRequestSent = false
    @State private var isLoadingFriendAction = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let user = user {
                        // Header
                        VStack(spacing: 12) {
                            AsyncImage(url: URL(string: user.avatarUrl)) { image in
                                image.resizable()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(themeColors.primary)
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())

                            VStack(spacing: 4) {
                                Text(user.name.decodingHTMLEntities)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeColors.textPrimary)

                                if let username = user.userLogin {
                                    Text("@\(username.decodingHTMLEntities)")
                                        .foregroundColor(themeColors.textSecondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)

                        // Friend Action Button
                        if authManager.isAuthenticated && authManager.currentUser?.id != userId {
                            friendActionButton
                                .padding(.horizontal)
                        }

                        // Stats Section
                        if let stats = userStats {
                            VStack(spacing: 12) {
                                Text("Reading Stats")
                                    .font(.headline)
                                    .foregroundColor(themeColors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)

                                VStack(spacing: 12) {
                                    HStack(spacing: 12) {
                                        StatInfoCard(
                                            value: String(stats.booksCompleted),
                                            label: "Books",
                                            icon: "checkmark.circle.fill",
                                            color: themeColors.primary
                                        )
                                        StatInfoCard(
                                            value: String(stats.pagesRead),
                                            label: "Pages",
                                            icon: "book.fill",
                                            color: themeColors.secondary
                                        )
                                    }
                                    HStack(spacing: 12) {
                                        StatInfoCard(
                                            value: String(stats.booksAdded),
                                            label: "Added",
                                            icon: "plus.circle.fill",
                                            color: themeColors.accent
                                        )
                                        StatInfoCard(
                                            value: String(stats.points),
                                            label: "Points",
                                            icon: "star.fill",
                                            color: Color(hex: "#FFD700")
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 12)
                        }

                        // Friends Section
                        if !friends.isEmpty {
                            VStack(spacing: 12) {
                                Text("Friends (\(friends.count))")
                                    .font(.headline)
                                    .foregroundColor(themeColors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)

                                VStack(spacing: 8) {
                                    ForEach(friends.prefix(5)) { friend in
                                        NavigationLink(destination: UserDetailView(userId: friend.id)) {
                                            HStack(spacing: 12) {
                                                AsyncImage(url: URL(string: friend.avatarUrl)) { image in
                                                    image.resizable()
                                                } placeholder: {
                                                    Image(systemName: "person.circle.fill")
                                                        .foregroundColor(themeColors.primary)
                                                }
                                                .frame(width: 40, height: 40)
                                                .clipShape(Circle())

                                                VStack(alignment: .leading, spacing: 2) {
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
                                        }
                                    }
                                }
                                .padding(.horizontal)

                                if friends.count > 5 {
                                    NavigationLink(destination: FriendsListView(userId: userId)) {
                                        Text("View All Friends")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(themeColors.primary)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        Spacer()
                            .frame(height: 20)
                    } else if let error = error {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title)
                                .foregroundColor(themeColors.error)
                            Text(error)
                                .foregroundColor(themeColors.error)
                            Button("Retry") {
                                loadUserData()
                            }
                            .foregroundColor(themeColors.primary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("User Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadUserData()
            }
        }
    }

    private var friendActionButton: some View {
        Button(action: handleFriendAction) {
            HStack {
                if isLoadingFriendAction {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: friendRequestSent || isFriend ? "checkmark.circle.fill" : "person.badge.plus.fill")
                    Text(isFriend ? "Friends" : friendRequestSent ? "Request Sent" : "Add Friend")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(
                isFriend || friendRequestSent ?
                themeColors.success :
                themeColors.primary
            )
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isLoadingFriendAction || isFriend)
        .padding(.horizontal)
    }

    private func loadUserData() {
        isLoading = true
        error = nil

        Task {
            do {
                // Fetch user details (via members endpoint)
                let fetchedUser: User = try await APIManager.shared.request(
                    endpoint: "/members/\(userId)",
                    authenticated: false
                )

                // Fetch user stats
                let stats = try await APIManager.shared.getUserStats(userId: userId)

                // Fetch friends
                let friendsResponse = try await APIManager.shared.getFriends(userId: userId)

                await MainActor.run {
                    self.user = fetchedUser
                    self.userStats = stats
                    self.friends = friendsResponse.friends
                    self.isLoading = false

                    // Check friend status if authenticated
                    if authManager.isAuthenticated {
                        checkFriendStatus()
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to load user profile"
                    self.isLoading = false
                    Logger.error("Error loading user data: \(error)")
                }
            }
        }
    }

    private func checkFriendStatus() {
        Task {
            do {
                let pendingRequests = try await APIManager.shared.getPendingFriendRequests()
                let isRequestPending = pendingRequests.requests.contains {
                    $0.friendId == userId && $0.initiatorId == authManager.currentUser?.id
                }

                let friends = try await APIManager.shared.getFriends(userId: authManager.currentUser?.id ?? 0)
                let isFriendsAlready = friends.friends.contains { $0.id == userId }

                await MainActor.run {
                    self.friendRequestSent = isRequestPending
                    self.isFriend = isFriendsAlready
                }
            } catch {
                Logger.error("Error checking friend status: \(error)")
            }
        }
    }

    private func handleFriendAction() {
        if isFriend {
            // Remove friend
            removeFriend()
        } else if !friendRequestSent {
            // Send friend request
            sendFriendRequest()
        }
    }

    private func sendFriendRequest() {
        isLoadingFriendAction = true
        Task {
            do {
                _ = try await APIManager.shared.sendFriendRequest(friendId: userId)
                await MainActor.run {
                    friendRequestSent = true
                    isLoadingFriendAction = false
                }
            } catch let catchError {
                await MainActor.run {
                    isLoadingFriendAction = false
                    self.error = "Failed to send friend request"
                    Logger.error("Error sending friend request: \(catchError)")
                }
            }
        }
    }

    private func removeFriend() {
        isLoadingFriendAction = true
        Task {
            do {
                _ = try await APIManager.shared.removeFriend(friendId: userId)
                await MainActor.run {
                    isFriend = false
                    isLoadingFriendAction = false
                }
            } catch let catchError {
                await MainActor.run {
                    isLoadingFriendAction = false
                    self.error = "Failed to remove friend"
                    Logger.error("Error removing friend: \(catchError)")
                }
            }
        }
    }
}

// MARK: - Stat Info Card
struct StatInfoCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    @Environment(\.themeColors) var themeColors

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(themeColors.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundColor(themeColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(themeColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: themeColors.shadowColor, radius: 4, x: 0, y: 2)
    }
}

#Preview {
    UserDetailView(userId: 1)
        .environmentObject(ThemeManager.shared)
}
