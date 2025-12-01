//
//  ProfileView.swift
//  GRead
//
//  Created by apple on 11/6/25.
//

import SwiftUI


struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var dashboardManager = DashboardManager.shared
    @ObservedObject var profileManager = ProfileManager.shared
    @State private var showStatsView = false
    @State private var statsLoadError: String?
    @State private var showNotifications = false
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.themeColors) var themeColors

    let hapticFeedback = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    if let user = authManager.currentUser {

                        // Profile Header
                        VStack(spacing: 16) {
                            AsyncImage(url: URL(string: {
                                // Try profileManager first, but check for non-empty string
                                if let avatarUrl = profileManager.userProfile?.avatarUrl, !avatarUrl.isEmpty {
                                    return avatarUrl
                                }
                                // Fall back to user.avatarUrl which has better fallback logic
                                return user.avatarUrl
                            }())) { image in
                                image.resizable()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(themeColors.primary)
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())

                            VStack(spacing: 8) {
                                Text(profileManager.userProfile?.displayName ?? user.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeColors.textPrimary)

                                if let username = profileManager.userProfile?.username ?? user.userLogin {
                                    Text("@\(username)")
                                        .foregroundColor(themeColors.textSecondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(themeColors.headerBackground)

                        // Profile Info Section
                        if let profile = profileManager.userProfile {
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
                        if !profileManager.xprofileFields.isEmpty {
                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Reading Preferences")
                                        .font(.headline)
                                        .foregroundColor(themeColors.textPrimary)
                                        .padding(.horizontal)

                                    ForEach(profileManager.xprofileFields.filter { $0.name != "Name" && $0.name != "Bio" }) { field in
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

                        // Stats Grid
                        VStack(spacing: 16) {
                            Text("Your Reading Stats")
                                .font(.headline)
                                .foregroundColor(themeColors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.top, 16)

                            if let profileStats = profileManager.userProfile?.stats {
                                VStack(spacing: 12) {
                                    HStack(spacing: 12) {
                                        ProfileStatCard(
                                            value: "\(profileStats.booksCompleted)",
                                            label: "Books Read",
                                            icon: "books.vertical.fill",
                                            themeColors: themeColors
                                        )
                                        ProfileStatCard(
                                            value: "\(profileStats.pagesRead)",
                                            label: "Pages Read",
                                            icon: "doc.text.fill",
                                            themeColors: themeColors
                                        )
                                    }

                                    HStack(spacing: 12) {
                                        ProfileStatCard(
                                            value: "\(profileStats.booksAdded)",
                                            label: "Books Added",
                                            icon: "plus.circle.fill",
                                            themeColors: themeColors
                                        )
                                        ProfileStatCard(
                                            value: "\(profileStats.points)",
                                            label: "Points",
                                            icon: "star.fill",
                                            themeColors: themeColors
                                        )
                                    }

                                    HStack(spacing: 12) {
                                        ProfileStatCard(
                                            value: "\(profileStats.approvedReports)",
                                            label: "Contributions",
                                            icon: "checkmark.seal.fill",
                                            themeColors: themeColors
                                        )
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                            } else if let stats = dashboardManager.stats {
                                VStack(spacing: 12) {
                                    HStack(spacing: 12) {
                                        ProfileStatCard(
                                            value: "\(stats.booksCompleted)",
                                            label: "Books Completed",
                                            icon: "checkmark.circle.fill",
                                            themeColors: themeColors
                                        )
                                        ProfileStatCard(
                                            value: "\(stats.pagesRead)",
                                            label: "Pages Read",
                                            icon: "book.fill",
                                            themeColors: themeColors
                                        )
                                    }
                                    HStack(spacing: 12) {
                                        ProfileStatCard(
                                            value: "\(stats.booksAdded)",
                                            label: "Books Added",
                                            icon: "plus.circle.fill",
                                            themeColors: themeColors
                                        )
                                        ProfileStatCard(
                                            value: "\(stats.points)",
                                            label: "Points Earned",
                                            icon: "star.fill",
                                            themeColors: themeColors
                                        )
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 16)
                            } else if let error = statsLoadError {
                                VStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.title2)
                                        .foregroundColor(themeColors.warning)
                                    Text("Unable to Load Stats")
                                        .font(.headline)
                                        .foregroundColor(themeColors.textPrimary)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(themeColors.textSecondary)
                                        .multilineTextAlignment(.center)
                                    Button(action: loadUserStats) {
                                        Text("Retry")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(themeColors.primary)
                                            .cornerRadius(6)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                            } else if dashboardManager.isLoading {
                                ProgressView()
                                    .padding()
                            }
                        }
                        .background(themeColors.background)

                        // Progress Section
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Progress")
                                    .font(.headline)
                                    .foregroundColor(themeColors.textPrimary)
                                    .padding(.horizontal)

                                NavigationLink(destination: AchievementsView().environmentObject(authManager)) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "trophy.fill")
                                            .foregroundColor(themeColors.warning)
                                            .frame(width: 30)
                                        Text("Achievements")
                                            .foregroundColor(themeColors.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(themeColors.textSecondary)
                                    }
                                    .padding()
                                    .background(themeColors.background)
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

                        // Social Sections (Hidden for now)
                        /*
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Social")
                                    .font(.headline)
                                    .foregroundColor(themeColors.textPrimary)
                                    .padding(.horizontal)

                                NavigationLink(destination: FriendsListView(userId: user.id, isCurrentUser: true)) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.2.fill")
                                            .foregroundColor(themeColors.primary)
                                            .frame(width: 30)
                                        Text("Friends")
                                            .foregroundColor(themeColors.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(themeColors.textSecondary)
                                    }
                                    .padding()
                                    .background(themeColors.background)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(themeColors.border, lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                                }

                                NavigationLink(destination: FriendRequestsView()) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.badge.plus.fill")
                                            .foregroundColor(themeColors.secondary)
                                            .frame(width: 30)
                                        Text("Friend Requests")
                                            .foregroundColor(themeColors.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(themeColors.textSecondary)
                                    }
                                    .padding()
                                    .background(themeColors.background)
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
                        */

                        // Settings Sections
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Customization")
                                    .font(.headline)
                                    .foregroundColor(themeColors.textPrimary)
                                    .padding(.horizontal)

                                NavigationLink(destination: ThemeSelectionView()) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "paintpalette.fill")
                                            .foregroundColor(themeColors.primary)
                                            .frame(width: 30)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Active Theme")
                                                .foregroundColor(themeColors.textPrimary)
                                            Text(themeManager.currentTheme.name)
                                                .font(.caption)
                                                .foregroundColor(themeColors.textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(themeColors.textSecondary)
                                    }
                                    .padding()
                                    .background(themeColors.background)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(themeColors.border, lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                                }

                                NavigationLink(destination: FontSelectionView()) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "textformat")
                                            .foregroundColor(themeColors.secondary)
                                            .frame(width: 30)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Font Selection")
                                                .foregroundColor(themeColors.textPrimary)
                                            Text(themeManager.currentFont?.name ?? "System Default")
                                                .font(.caption)
                                                .foregroundColor(themeColors.textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(themeColors.textSecondary)
                                    }
                                    .padding()
                                    .background(themeColors.background)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(themeColors.border, lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Settings")
                                    .font(.headline)
                                    .foregroundColor(themeColors.textPrimary)
                                    .padding(.horizontal)

                                NavigationLink(destination: CacheSettingsView()) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "externaldrive.fill")
                                            .foregroundColor(themeColors.primary)
                                            .frame(width: 30)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Cache Settings")
                                                .foregroundColor(themeColors.textPrimary)
                                            Text(CacheManager.shared.formatBytes(CacheManager.shared.cacheSize))
                                                .font(.caption)
                                                .foregroundColor(themeColors.textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(themeColors.textSecondary)
                                    }
                                    .padding()
                                    .background(themeColors.background)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(themeColors.border, lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                                }

                                NavigationLink(destination: BlockedUsersView()) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "hand.raised.fill")
                                            .foregroundColor(themeColors.error)
                                            .frame(width: 30)
                                        Text("Blocked Users")
                                            .foregroundColor(themeColors.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(themeColors.textSecondary)
                                    }
                                    .padding()
                                    .background(themeColors.background)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(themeColors.border, lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                                }

                                // DEBUG: Hidden from users - uncomment to show debug profile fields view
                                // NavigationLink(destination: ProfileFieldsDebugView().environmentObject(authManager)) {
                                //     HStack(spacing: 12) {
                                //         Image(systemName: "ant.fill")
                                //             .foregroundColor(themeColors.warning)
                                //             .frame(width: 30)
                                //         Text("Debug Profile Fields")
                                //             .foregroundColor(themeColors.textPrimary)
                                //         Spacer()
                                //         Image(systemName: "chevron.right")
                                //             .foregroundColor(themeColors.textSecondary)
                                //     }
                                //     .padding()
                                //     .background(themeColors.background)
                                //     .cornerRadius(8)
                                //     .overlay(
                                //         RoundedRectangle(cornerRadius: 8)
                                //             .stroke(themeColors.border, lineWidth: 1)
                                //     )
                                //     .padding(.horizontal)
                                // }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Support")
                                    .font(.headline)
                                    .foregroundColor(themeColors.textPrimary)
                                    .padding(.horizontal)

                                if let mailURL = URL(string: "mailto:admin@gread.fun?subject=Contact%20Request") {
                                    Link(destination: mailURL) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "envelope.fill")
                                                .foregroundColor(themeColors.primary)
                                                .frame(width: 30)
                                            Text("Contact Developers")
                                                .foregroundColor(themeColors.textPrimary)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(themeColors.textSecondary)
                                        }
                                        .padding()
                                        .background(themeColors.background)
                                        .border(themeColors.border, width: 1)
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                    }
                                }

                                if let tutorialsURL = URL(string: "https://gread.fun/tutorials") {
                                    Link(destination: tutorialsURL) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "book.circle.fill")
                                                .foregroundColor(themeColors.primary)
                                                .frame(width: 30)
                                            Text("Tutorials")
                                                .foregroundColor(themeColors.textPrimary)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(themeColors.textSecondary)
                                        }
                                        .padding()
                                        .background(themeColors.background)
                                        .border(themeColors.border, width: 1)
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                    }
                                }

                                if let deleteURL = URL(string: "mailto:admin@gread.fun?subject=Request%20Data%20Deletion") {
                                    Link(destination: deleteURL) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "trash.fill")
                                                .foregroundColor(themeColors.warning)
                                                .frame(width: 30)
                                            Text("Request Data Deletion")
                                                .foregroundColor(themeColors.textPrimary)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(themeColors.textSecondary)
                                        }
                                        .padding()
                                        .background(themeColors.background)
                                        .border(themeColors.border, width: 1)
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Legal")
                                    .font(.headline)
                                    .foregroundColor(themeColors.textPrimary)
                                    .padding(.horizontal)

                                Link(destination: URL(string: "https://gread.fun/privacy-policy")!) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "shield.fill")
                                            .foregroundColor(themeColors.primary)
                                            .frame(width: 30)
                                        Text("Privacy Policy")
                                            .foregroundColor(themeColors.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(themeColors.textSecondary)
                                    }
                                    .padding()
                                    .background(themeColors.background)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(themeColors.border, lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                                }

                                Link(destination: URL(string: "https://gread.fun/tos")!) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "doc.text.fill")
                                            .foregroundColor(themeColors.primary)
                                            .frame(width: 30)
                                        Text("Terms of Service")
                                            .foregroundColor(themeColors.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(themeColors.textSecondary)
                                    }
                                    .padding()
                                    .background(themeColors.background)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(themeColors.border, lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                                }
                            }

                            Button(action: {
                                hapticFeedback.impactOccurred()
                                authManager.logout()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                    Text("Logout")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(themeColors.error.opacity(0.1))
                                .foregroundColor(themeColors.error)
                                .cornerRadius(8)
                            }
                            .padding()

                            // Bottom padding to prevent tab bar overlap
                            Color.clear
                                .frame(height: 80)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeColors.background)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(.stack)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NotificationsView()) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(themeColors.primary)
                            .font(.body)
                    }
                }
            }
            .task {
                loadUserStats()
            }
        }
    }

    private func loadUserStats() {
        guard let userId = authManager.currentUser?.id else { return }

        Task {
            statsLoadError = nil
            await dashboardManager.loadDashboardIfNeeded(userId: userId)
            await profileManager.loadProfileIfNeeded()
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

struct ProfileStatCard: View {
    let value: String
    let label: String
    let icon: String
    let themeColors: ThemeColors

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(themeColors.primary)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeColors.textPrimary)

                Text(label)
                    .font(.caption)
                    .foregroundColor(themeColors.textSecondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(themeColors.primary.opacity(0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(themeColors.primary.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: themeColors.shadowColor, radius: 4, x: 0, y: 2)
    }
}
