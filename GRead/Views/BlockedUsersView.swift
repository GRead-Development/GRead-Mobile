//
//  BlockedUsersView.swift
//  GRead
//
//  Created by apple on 11/8/25.
//

import SwiftUI

struct BlockedUsersView: View {
    @Environment(\.themeColors) var themeColors
    @State private var blockedUsers: [User] = []
    @State private var blockedUserIds: [Int] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading blocked users...")
            } else if blockedUsers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(themeColors.success)
                    Text("No blocked users")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("You haven't blocked anyone yet")
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(themeColors.background)
            } else {
                List {
                    ForEach(blockedUsers) { user in
                        HStack(spacing: 12) {
                            // User avatar
                            AsyncImage(url: URL(string: user.avatarUrls?.full ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(themeColors.textSecondary)
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())

                            // User info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.headline)
                                    .lineLimit(1)

                                if let username = user.userLogin {
                                    Text("@\(username)")
                                        .font(.caption)
                                        .foregroundColor(themeColors.textSecondary)
                                        .lineLimit(1)
                                }
                            }

                            Spacer()

                            // Unblock button
                            Button(action: { unblockUser(user.id) }) {
                                Text("Unblock")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeColors.error)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(themeColors.error.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .alert("Success", isPresented: .constant(successMessage != nil)) {
            Button("OK") {
                successMessage = nil
            }
        } message: {
            if let message = successMessage {
                Text(message)
            }
        }
        .task {
            await loadBlockedUsers()
        }
    }

    private func loadBlockedUsers() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch blocked user IDs
            let blockedListResponse = try await APIManager.shared.getBlockedList()
            blockedUserIds = blockedListResponse.blockedUsers

            // Fetch user details for each blocked user ID
            var users: [User] = []
            for userId in blockedUserIds {
                do {
                    let user: User = try await APIManager.shared.request(
                        endpoint: "/members/\(userId)"
                    )
                    users.append(user)
                } catch {
                    // Skip users that can't be loaded
                    print("Failed to load user \(userId): \(error)")
                }
            }

            await MainActor.run {
                blockedUsers = users
                isLoading = false
            }
        } catch is CancellationError {
            // Ignore cancellation errors
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load blocked users: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func unblockUser(_ userId: Int) {
        Task {
            do {
                _ = try await APIManager.shared.unblockUser(userId: userId)

                await MainActor.run {
                    blockedUsers.removeAll { $0.id == userId }
                    blockedUserIds.removeAll { $0 == userId }
                    successMessage = "User unblocked"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.successMessage = nil
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to unblock user: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    BlockedUsersView()
}
