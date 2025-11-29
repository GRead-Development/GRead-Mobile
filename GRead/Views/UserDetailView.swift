import SwiftUI

struct UserDetailView: View {
    let userId: Int

    @EnvironmentObject var authManager: AuthManager
    @Environment(\.themeColors) var themeColors
    @Environment(\.dismiss) var dismiss

    @State private var user: User?
    @State private var userProfile: UserProfile?
    @State private var xprofileFields: [XProfileField] = []
    @State private var userStats: UserStats?
    @State private var friends: [User] = []
    @State private var isLoading = true
    @State private var error: String?

    @State private var isFriend = false
    @State private var friendRequestSent = false
    @State private var isLoadingFriendAction = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let user = user {
                        // Header
                        VStack(spacing: 12) {
                            AsyncImage(url: URL(string: userProfile?.avatarUrl ?? user.avatarUrl)) { image in
                                image.resizable()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(themeColors.primary)
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())

                            VStack(spacing: 4) {
                                Text(userProfile?.displayName ?? user.name.decodingHTMLEntities)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeColors.textPrimary)

                                if let username = userProfile?.username ?? user.userLogin {
                                    Text("@\(username.decodingHTMLEntities)")
                                        .foregroundColor(themeColors.textSecondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(themeColors.headerBackground)

                        // Friend Action Button
                        if authManager.isAuthenticated && authManager.currentUser?.id != userId {
                            friendActionButton
                                .padding(.horizontal)
                        }

                        // Profile Info Section
                        if let profile = userProfile {
                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("About")
                                        .font(.headline)
                                        .foregroundColor(themeColors.textPrimary)
                                        .padding(.horizontal)

                                    // Bio
                                    if let bio = profile.bio, !bio.isEmpty {
                                        HStack(spacing: 12) {
                                            Image(systemName: "text.quote")
                                                .foregroundColor(themeColors.primary)
                                                .frame(width: 30)
                                            Text(bio)
                                                .font(.body)
                                                .foregroundColor(themeColors.textPrimary)
                                            Spacer()
                                        }
                                        .padding()
                                        .background(themeColors.cardBackground)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(themeColors.border, lineWidth: 1)
                                        )
                                        .padding(.horizontal)
                                    }

                                    // Website
                                    if let website = profile.website, !website.isEmpty {
                                        Link(destination: URL(string: website) ?? URL(string: "https://example.com")!) {
                                            HStack(spacing: 12) {
                                                Image(systemName: "link")
                                                    .foregroundColor(themeColors.primary)
                                                    .frame(width: 30)
                                                Text(website)
                                                    .font(.body)
                                                    .foregroundColor(themeColors.primary)
                                                Spacer()
                                                Image(systemName: "arrow.up.right")
                                                    .font(.caption)
                                                    .foregroundColor(themeColors.textSecondary)
                                            }
                                            .padding()
                                            .background(themeColors.cardBackground)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(themeColors.border, lineWidth: 1)
                                            )
                                        }
                                        .padding(.horizontal)
                                    }

                                    // Location
                                    if let location = profile.location, !location.isEmpty {
                                        HStack(spacing: 12) {
                                            Image(systemName: "location.fill")
                                                .foregroundColor(themeColors.primary)
                                                .frame(width: 30)
                                            Text(location)
                                                .font(.body)
                                                .foregroundColor(themeColors.textPrimary)
                                            Spacer()
                                        }
                                        .padding()
                                        .background(themeColors.cardBackground)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(themeColors.border, lineWidth: 1)
                                        )
                                        .padding(.horizontal)
                                    }

                                    // Social Stats
                                    if let social = profile.social {
                                        HStack(spacing: 12) {
                                            VStack(spacing: 4) {
                                                Text("\(social.followersCount)")
                                                    .font(.title3)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(themeColors.textPrimary)
                                                Text("Followers")
                                                    .font(.caption)
                                                    .foregroundColor(themeColors.textSecondary)
                                            }
                                            .frame(maxWidth: .infinity)

                                            Divider()

                                            VStack(spacing: 4) {
                                                Text("\(social.followingCount)")
                                                    .font(.title3)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(themeColors.textPrimary)
                                                Text("Following")
                                                    .font(.caption)
                                                    .foregroundColor(themeColors.textSecondary)
                                            }
                                            .frame(maxWidth: .infinity)
                                        }
                                        .padding()
                                        .background(themeColors.cardBackground)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(themeColors.border, lineWidth: 1)
                                        )
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.vertical, 16)
                        }

                        // Extended Profile Fields
                        if !xprofileFields.isEmpty {
                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Reading Preferences")
                                        .font(.headline)
                                        .foregroundColor(themeColors.textPrimary)
                                        .padding(.horizontal)

                                    ForEach(xprofileFields.filter { $0.name != "Name" && $0.name != "Bio" }) { field in
                                        if let value = field.value, !value.isEmpty {
                                            HStack(spacing: 12) {
                                                Image(systemName: iconForFieldType(field.type))
                                                    .foregroundColor(themeColors.primary)
                                                    .frame(width: 30)
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(field.name)
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(themeColors.textSecondary)
                                                    Text(value)
                                                        .font(.body)
                                                        .foregroundColor(themeColors.textPrimary)
                                                }
                                                Spacer()
                                            }
                                            .padding()
                                            .background(themeColors.cardBackground)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(themeColors.border, lineWidth: 1)
                                            )
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 16)
                        }

                        // Stats Section
                        if let profileStats = userProfile?.stats {
                            VStack(spacing: 12) {
                                Text("Reading Stats")
                                    .font(.headline)
                                    .foregroundColor(themeColors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)

                                VStack(spacing: 12) {
                                    HStack(spacing: 12) {
                                        StatInfoCard(
                                            value: String(profileStats.booksCompleted),
                                            label: "Books Read",
                                            icon: "books.vertical.fill",
                                            color: themeColors.primary
                                        )
                                        StatInfoCard(
                                            value: String(profileStats.pagesRead),
                                            label: "Pages Read",
                                            icon: "doc.text.fill",
                                            color: themeColors.secondary
                                        )
                                    }
                                    HStack(spacing: 12) {
                                        StatInfoCard(
                                            value: String(profileStats.booksAdded),
                                            label: "Books Added",
                                            icon: "plus.circle.fill",
                                            color: themeColors.accent
                                        )
                                        StatInfoCard(
                                            value: String(profileStats.points),
                                            label: "Points",
                                            icon: "star.fill",
                                            color: Color(hex: "#FFD700")
                                        )
                                    }
                                    HStack(spacing: 12) {
                                        StatInfoCard(
                                            value: String(profileStats.approvedReports),
                                            label: "Contributions",
                                            icon: "checkmark.seal.fill",
                                            color: themeColors.success
                                        )
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 12)
                        } else if let stats = userStats {
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

                        // Bottom padding to prevent tab bar overlap
                        Color.clear
                            .frame(height: 80)
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
        }
        .scrollContentBackground(.hidden)
        .background(themeColors.background)
        .onAppear {
            loadUserData()
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

                // Try to fetch user profile with full info (optional, may fail with 500)
                var profile: UserProfile?
                do {
                    profile = try await APIManager.shared.getUserProfile(userId: userId)
                } catch {
                    Logger.error("Failed to load full profile for user \(userId): \(error)")
                    // Continue without full profile
                }

                // Try to fetch extended profile fields (optional, may fail)
                var fields: [XProfileField] = []
                do {
                    fields = try await APIManager.shared.getUserXProfileFields(userId: userId)
                } catch {
                    Logger.error("Failed to load xprofile fields for user \(userId): \(error)")
                    // Continue without xprofile fields
                }

                // Try to fetch user stats (optional, may fail)
                var stats: UserStats?
                do {
                    stats = try await APIManager.shared.getUserStats(userId: userId)
                } catch {
                    Logger.error("Failed to load stats for user \(userId): \(error)")
                    // Continue without stats
                }

                // Try to fetch friends (optional, may fail)
                var friendsList: [User] = []
                do {
                    let friendsResponse = try await APIManager.shared.getFriends(userId: userId)
                    friendsList = friendsResponse.friends
                } catch {
                    Logger.error("Failed to load friends for user \(userId): \(error)")
                    // Continue without friends
                }

                await MainActor.run {
                    self.user = fetchedUser
                    self.userProfile = profile
                    self.xprofileFields = fields.sorted { $0.order ?? 0 < $1.order ?? 0 }
                    self.userStats = stats
                    self.friends = friendsList
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

    private func iconForFieldType(_ type: String) -> String {
        switch type {
        case "textbox":
            return "text.alignleft"
        case "wp-biography":
            return "doc.text"
        default:
            return "tag"
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
