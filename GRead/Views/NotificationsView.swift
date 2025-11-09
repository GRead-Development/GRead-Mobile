import SwiftUI
import Foundation

struct NotificationsView: View {
    @State private var notifications: [Notification] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Group {
                if isLoading && notifications.isEmpty {
                    ProgressView()
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else if notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No notifications")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Text("You're all caught up!")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else {
                    List(notifications) { notification in
                        NotificationRowView(notification: notification)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteNotification(notification)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .refreshable {
                        await loadNotifications()
                    }
                }
            }
            .navigationTitle("Notifications")
            .task {
                await loadNotifications()
            }
        }
    }
    
    private func loadNotifications() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get current user ID
            guard let userId = AuthManager.shared.currentUser?.id else {
                await MainActor.run {
                    errorMessage = "User not logged in"
                    isLoading = false
                }
                return
            }
            
            // Fetch notifications with user_id parameter
            let response: [Notification] = try await APIManager.shared.request(
                endpoint: "/notifications?user_id=\(userId)&per_page=50&is_new=false"
            )
            
            await MainActor.run {
                notifications = response
                isLoading = false
            }
        } catch APIError.emptyResponse {
            // Empty response is fine - just no notifications
            await MainActor.run {
                notifications = []
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load notifications"
                print("Notifications error: \(error)")
                isLoading = false
            }
        }
    }
    
    private func deleteNotification(_ notification: Notification) {
        Task {
            do {
                let _: EmptyResponse = try await APIManager.shared.request(
                    endpoint: "/notifications/\(notification.id)",
                    method: "DELETE"
                )
                await MainActor.run {
                    notifications.removeAll { $0.id == notification.id }
                }
            } catch {
                print("Failed to delete notification: \(error)")
            }
        }
    }
}

struct NotificationRowView: View {
    let notification: Notification
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(notification.isNew ?? false ? Color.blue : Color.clear)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 4) {
                if let content = notification.content {
                    Text(content.stripHTML())
                        .font(.subheadline)
                        .fontWeight(notification.isNew ?? false ? .semibold : .regular)
                } else {
                    Text(notification.componentAction ?? "Notification")
                        .font(.subheadline)
                        .fontWeight(notification.isNew ?? false ? .semibold : .regular)
                }
                
                HStack(spacing: 4) {
                    if let componentName = notification.componentName {
                        Text(componentName.capitalized)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    if let date = notification.dateNotified {
                        if notification.componentName != nil {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Text(date.toRelativeTime())
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            if let href = notification.href, !href.isEmpty {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
        .opacity(notification.isNew ?? false ? 1 : 0.7)
    }
}
