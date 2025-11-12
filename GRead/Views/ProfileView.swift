//
//  ProfileView.swift
//  GRead
//
//  Created by apple on 11/6/25.
//

import SwiftUI


struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var stats: UserStats?
    @State private var showStatsView = false
    @State private var isLoadingStats = false
    @State private var statsLoadError: String?
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.themeColors) var themeColors

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    if let user = authManager.currentUser {

                        // Profile Header
                        VStack(spacing: 16) {
                            AsyncImage(url: URL(string: user.avatarUrls?.full ?? "")) { image in
                                image.resizable()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(themeColors.primary)
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())

                            VStack(spacing: 8) {
                                Text(user.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeColors.textPrimary)

                                if let username = user.userLogin {
                                    Text("@\(username)")
                                        .foregroundColor(themeColors.textSecondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(themeColors.headerBackground)

                        // Stats Grid
                        VStack(spacing: 16) {
                            Text("Your Reading Stats")
                                .font(.headline)
                                .foregroundColor(themeColors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.top, 16)

                            if let stats = stats {
                                VStack(spacing: 12) {
                                    HStack(spacing: 12) {
                                        ProfileStatCard(
                                            value: "\(stats.booksCompleted)",
                                            subtext: "completed",
                                            icon: "checkmark.circle.fill",
                                            themeColors: themeColors
                                        )
                                        ProfileStatCard(
                                            value: "\(stats.pagesRead)",
                                            subtext: "read",
                                            icon: "book.fill",
                                            themeColors: themeColors
                                        )
                                    }
                                    HStack(spacing: 12) {
                                        ProfileStatCard(
                                            value: "\(stats.booksAdded)",
                                            subtext: "total",
                                            icon: "plus.circle.fill",
                                            themeColors: themeColors
                                        )
                                        ProfileStatCard(
                                            value: "\(stats.points)",
                                            subtext: "earned",
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
                            } else if isLoadingStats {
                                ProgressView()
                                    .padding()
                            }
                        }
                        .background(themeColors.background)

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
                                    .border(themeColors.border, width: 1)
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Settings")
                                    .font(.headline)
                                    .foregroundColor(themeColors.textPrimary)
                                    .padding(.horizontal)

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
                                    .border(themeColors.border, width: 1)
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                }
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
                                    .border(themeColors.border, width: 1)
                                    .cornerRadius(8)
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
                                    .border(themeColors.border, width: 1)
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                }
                            }

                            Button(action: { authManager.logout() }) {
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

                            Spacer()
                                .frame(height: 20)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeColors.background)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(.stack)
            .task {
                loadUserStats()
            }
        }
    }

    private func loadUserStats() {
        guard let userId = authManager.currentUser?.id else { return }

        Task {
            isLoadingStats = true
            statsLoadError = nil
            do {
                stats = try await APIManager.shared.getUserStats(userId: userId)
            } catch {
                print("Failed to load user stats: \(error)")
                statsLoadError = "Failed to load stats. Please try again later."
            }
            isLoadingStats = false
        }
    }
}

struct ProfileStatCard: View {
    let value: String
    let subtext: String
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

                Text(subtext)
                    .font(.caption)
                    .foregroundColor(themeColors.textSecondary)
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
