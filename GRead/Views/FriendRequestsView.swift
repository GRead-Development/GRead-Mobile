import SwiftUI

struct FriendRequestsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.themeColors) var themeColors

    @State private var pendingRequests: [FriendRequest] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var acceptingRequestId: Int?
    @State private var rejectingRequestId: Int?

    var body: some View {
        NavigationView {
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
                                loadPendingRequests()
                            }
                            .foregroundColor(themeColors.primary)
                        }
                    } else if pendingRequests.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundColor(themeColors.success)
                            Text("No pending friend requests")
                                .foregroundColor(themeColors.textSecondary)
                        }
                    } else {
                        VStack(spacing: 0) {
                            Text("Friend Requests (\(pendingRequests.count))")
                                .font(.headline)
                                .foregroundColor(themeColors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)

                            VStack(spacing: 12) {
                                ForEach(pendingRequests) { request in
                                    FriendRequestCard(
                                        request: request,
                                        onAccept: { acceptRequest(request) },
                                        onReject: { rejectRequest(request) },
                                        isAccepting: acceptingRequestId == request.id,
                                        isRejecting: rejectingRequestId == request.id
                                    )
                                }
                            }
                            .padding(14)
                        }
                    }
                }
            }
            .navigationTitle("Friend Requests")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadPendingRequests()
            }
        }
    }

    private func loadPendingRequests() {
        isLoading = true
        error = nil

        Task {
            do {
                let response = try await APIManager.shared.getPendingFriendRequests()
                await MainActor.run {
                    self.pendingRequests = response.requests
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to load friend requests"
                    self.isLoading = false
                    Logger.error("Error loading pending requests: \(error)")
                }
            }
        }
    }

    private func acceptRequest(_ request: FriendRequest) {
        acceptingRequestId = request.id

        Task {
            do {
                _ = try await APIManager.shared.acceptFriendRequest(requestId: request.id)
                await MainActor.run {
                    pendingRequests.removeAll { $0.id == request.id }
                    acceptingRequestId = nil
                }
            } catch let catchError {
                await MainActor.run {
                    acceptingRequestId = nil
                    self.error = "Failed to accept request"
                    Logger.error("Error accepting request: \(catchError)")
                }
            }
        }
    }

    private func rejectRequest(_ request: FriendRequest) {
        rejectingRequestId = request.id

        Task {
            do {
                _ = try await APIManager.shared.rejectFriendRequest(requestId: request.id)
                await MainActor.run {
                    pendingRequests.removeAll { $0.id == request.id }
                    rejectingRequestId = nil
                }
            } catch let catchError {
                await MainActor.run {
                    rejectingRequestId = nil
                    self.error = "Failed to reject request"
                    Logger.error("Error rejecting request: \(catchError)")
                }
            }
        }
    }
}

// MARK: - Friend Request Card
struct FriendRequestCard: View {
    let request: FriendRequest
    let onAccept: () -> Void
    let onReject: () -> Void
    let isAccepting: Bool
    let isRejecting: Bool

    @Environment(\.themeColors) var themeColors

    var requestUser: User? {
        request.user ?? request.friend
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                if let user = requestUser {
                    NavigationLink(destination: UserDetailView(userId: user.id)) {
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
                        }
                    }

                    Spacer()
                }
            }

            HStack(spacing: 8) {
                Button(action: onReject) {
                    HStack {
                        if isRejecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: themeColors.error))
                        } else {
                            Image(systemName: "xmark")
                        }
                        Text("Reject")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(themeColors.error.opacity(0.1))
                    .foregroundColor(themeColors.error)
                    .cornerRadius(8)
                }
                .disabled(isRejecting || isAccepting)

                Button(action: onAccept) {
                    HStack {
                        if isAccepting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "checkmark")
                        }
                        Text("Accept")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(themeColors.success)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isAccepting || isRejecting)
            }
        }
        .padding(14)
        .background(themeColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeColors.border, lineWidth: 1)
        )
    }
}

#Preview {
    FriendRequestsView()
        .environmentObject(ThemeManager.shared)
}
