import SwiftUI

struct UserProfileView: View {
    let userId: Int
    let onModerationTap: ((String) -> Void)?

    @EnvironmentObject var authManager: AuthManager
    @Environment(\.themeColors) var themeColors
    @Environment(\.dismiss) var dismiss

    @State private var user: User?
    @State private var userProfile: UserProfile?

    init(userId: Int, onModerationTap: ((String) -> Void)? = nil) {
        self.userId = userId
        self.onModerationTap = onModerationTap
    }

    var body: some View {
        NavigationView {
            UserDetailView(userId: userId)
                .navigationTitle(userProfile?.displayName ?? user?.name ?? "User Profile")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(themeColors.textSecondary)
                        }
                    }

                    if authManager.isAuthenticated && authManager.currentUser?.id != userId {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                if let userName = userProfile?.displayName ?? user?.name {
                                    onModerationTap?(userName)
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundColor(themeColors.primary)
                            }
                        }
                    }
                }
                .task {
                    await loadBasicUserInfo()
                }
        }
        .navigationViewStyle(.stack)
    }

    private func loadBasicUserInfo() async {
        do {
            let fetchedUser: User = try await APIManager.shared.request(
                endpoint: "/members/\(userId)",
                authenticated: false
            )

            // Try to load full profile (may fail with 500 error)
            var profile: UserProfile?
            do {
                profile = try await APIManager.shared.getUserProfile(userId: userId)
            } catch {
                Logger.error("Failed to load full profile for user \(userId): \(error)")
                // Continue without full profile
            }

            await MainActor.run {
                self.user = fetchedUser
                self.userProfile = profile
            }
        } catch {
            Logger.error("Error loading basic user info: \(error)")
        }
    }
}

#Preview {
    UserProfileView(userId: 1)
        .environmentObject(AuthManager.shared)
        .environmentObject(ThemeManager.shared)
}
