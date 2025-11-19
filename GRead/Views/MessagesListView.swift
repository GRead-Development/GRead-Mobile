import SwiftUI

// MARK: - Messages List View
struct MessagesListView: View {
    @Environment(\.themeColors) var themeColors
    @State private var conversations: [MessageThread] = []
    @State private var isLoading = false
    @State private var showNewMessage = false
    @State private var selectedThread: MessageThread?

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading && conversations.isEmpty {
                    ProgressView()
                } else if conversations.isEmpty {
                    emptyState
                } else {
                    conversationsList
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewMessage = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showNewMessage) {
                NewMessageView(onSent: {
                    Task { await loadConversations() }
                })
            }
            .sheet(item: $selectedThread) { thread in
                MessageThreadView(thread: thread)
            }
            .task {
                await loadConversations()
            }
            .refreshable {
                await loadConversations()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.fill")
                .font(.system(size: 60))
                .foregroundColor(themeColors.textSecondary)

            Text("No Messages Yet")
                .font(.headline)

            Text("Start a conversation with other readers")
                .font(.caption)
                .foregroundColor(themeColors.textSecondary)

            Button(action: { showNewMessage = true }) {
                Label("New Message", systemImage: "square.and.pencil")
                    .padding()
                    .background(themeColors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }

    private var conversationsList: some View {
        List(conversations) { conversation in
            Button(action: { selectedThread = conversation }) {
                MessageThreadRow(thread: conversation)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    deleteThread(conversation)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .listStyle(.plain)
    }

    private func loadConversations() async {
        isLoading = true
        do {
            conversations = try await APIManager.shared.getMessages()
            isLoading = false
        } catch {
            print("Failed to load messages: \(error)")
            isLoading = false
        }
    }

    private func deleteThread(_ thread: MessageThread) {
        Task {
            do {
                try await APIManager.shared.deleteMessage(threadId: thread.id)
                await loadConversations()
            } catch {
                print("Failed to delete message: \(error)")
            }
        }
    }
}

// MARK: - Message Thread Row
struct MessageThreadRow: View {
    let thread: MessageThread
    @Environment(\.themeColors) var themeColors

    var body: some View {
        HStack(spacing: 12) {
            // Sender Avatar
            AsyncImage(url: URL(string: thread.senderAvatar ?? "")) { image in
                image.resizable()
            } placeholder: {
                Circle()
                    .fill(themeColors.primary.opacity(0.2))
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(themeColors.primary)
                    }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(thread.subject ?? "No Subject")
                        .font(.headline)
                        .foregroundColor(themeColors.textPrimary)

                    Spacer()

                    if let date = thread.lastMessageDate {
                        Text(date.toRelativeTime())
                            .font(.caption)
                            .foregroundColor(themeColors.textSecondary)
                    }
                }

                if let excerpt = thread.excerpt {
                    Text(excerpt.stripHTML())
                        .font(.subheadline)
                        .foregroundColor(themeColors.textSecondary)
                        .lineLimit(2)
                }

                if thread.unreadCount > 0 {
                    Text("\(thread.unreadCount) unread")
                        .font(.caption)
                        .foregroundColor(themeColors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(themeColors.primary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Message Thread View
struct MessageThreadView: View {
    let thread: MessageThread
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColors) var themeColors
    @State private var messages: [Message] = []
    @State private var messageText = ""
    @State private var isSending = false
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding()
                }

                Divider()

                // Input Field
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(themeColors.inputBackground)
                        .cornerRadius(20)
                        .lineLimit(1...5)

                    Button(action: sendMessage) {
                        if isSending {
                            ProgressView()
                        } else {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(messageText.isEmpty ? themeColors.textSecondary : themeColors.primary)
                        }
                    }
                    .disabled(messageText.isEmpty || isSending)
                }
                .padding()
            }
            .navigationTitle(thread.subject ?? "Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await loadMessages()
            }
        }
    }

    private func loadMessages() async {
        isLoading = true
        do {
            messages = try await APIManager.shared.getMessageThread(threadId: thread.id)
            isLoading = false
        } catch {
            print("Failed to load thread: \(error)")
            isLoading = false
        }
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }

        isSending = true
        let content = messageText
        messageText = ""

        Task {
            do {
                try await APIManager.shared.sendMessage(
                    recipients: thread.recipients,
                    subject: thread.subject ?? "Re:",
                    content: content
                )
                await loadMessages()
                isSending = false
            } catch {
                print("Failed to send message: \(error)")
                messageText = content // Restore message on error
                isSending = false
            }
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: Message
    @Environment(\.themeColors) var themeColors
    @EnvironmentObject var authManager: AuthManager

    var isCurrentUser: Bool {
        message.senderId == authManager.currentUser?.id
    }

    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.senderName ?? "Unknown")
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                }

                Text(message.message?.stripHTML() ?? "")
                    .font(.body)
                    .padding(12)
                    .background(isCurrentUser ? themeColors.primary : themeColors.cardBackground)
                    .foregroundColor(isCurrentUser ? .white : themeColors.textPrimary)
                    .cornerRadius(16)

                if let date = message.dateSent {
                    Text(date.toRelativeTime())
                        .font(.caption2)
                        .foregroundColor(themeColors.textSecondary)
                }
            }

            if !isCurrentUser { Spacer() }
        }
    }
}

// MARK: - New Message View
struct NewMessageView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColors) var themeColors
    @State private var recipients: [User] = []
    @State private var subject = ""
    @State private var message = ""
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    @State private var isSending = false

    let onSent: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Recipients
                VStack(alignment: .leading, spacing: 8) {
                    Text("To:")
                        .font(.headline)

                    if !recipients.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(recipients) { user in
                                    HStack(spacing: 4) {
                                        Text(user.name)
                                            .font(.caption)

                                        Button(action: { removeRecipient(user) }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(themeColors.primary.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }

                    // User Search
                    TextField("Search users...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: searchText) { _ in
                            Task { await searchUsers() }
                        }

                    if isSearching {
                        ProgressView()
                    } else if !searchResults.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading) {
                                ForEach(searchResults) { user in
                                    Button(action: { addRecipient(user) }) {
                                        HStack {
                                            Text(user.name)
                                            Spacer()
                                            Image(systemName: "plus.circle")
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 150)
                    }
                }

                // Subject
                TextField("Subject", text: $subject)
                    .textFieldStyle(.roundedBorder)

                // Message
                TextEditor(text: $message)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(themeColors.inputBackground)
                    .cornerRadius(8)

                Spacer()
            }
            .padding()
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        Task { await sendMessage() }
                    }
                    .disabled(recipients.isEmpty || subject.isEmpty || message.isEmpty || isSending)
                }
            }
        }
    }

    private func searchUsers() async {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        do {
            let response = try await APIManager.shared.searchUsers(query: searchText, page: 1, perPage: 10)
            searchResults = response.users.filter { user in
                !recipients.contains { $0.id == user.id }
            }
            isSearching = false
        } catch {
            print("Search error: \(error)")
            isSearching = false
        }
    }

    private func addRecipient(_ user: User) {
        if !recipients.contains(where: { $0.id == user.id }) {
            recipients.append(user)
            searchText = ""
            searchResults = []
        }
    }

    private func removeRecipient(_ user: User) {
        recipients.removeAll { $0.id == user.id }
    }

    private func sendMessage() async {
        isSending = true
        do {
            try await APIManager.shared.sendMessage(
                recipients: recipients.map { $0.id },
                subject: subject,
                content: message
            )
            onSent()
            dismiss()
        } catch {
            print("Failed to send: \(error)")
            isSending = false
        }
    }
}

// MARK: - Models (Add to Models folder)
struct MessageThread: Codable, Identifiable {
    let id: Int
    let subject: String?
    let excerpt: String?
    let unreadCount: Int
    let lastMessageDate: String?
    let senderAvatar: String?
    let recipients: [Int]

    enum CodingKeys: String, CodingKey {
        case id
        case subject
        case excerpt
        case unreadCount = "unread_count"
        case lastMessageDate = "last_message_date"
        case senderAvatar = "sender_avatar"
        case recipients
    }
}

// MARK: - API Manager Extension
extension APIManager {
    func getMessages() async throws -> [MessageThread] {
        return try await customRequest(
            endpoint: "/messages",
            authenticated: true
        )
    }

    func getMessageThread(threadId: Int) async throws -> [Message] {
        return try await customRequest(
            endpoint: "/messages/\(threadId)",
            authenticated: true
        )
    }

    func sendMessage(recipients: [Int], subject: String, content: String) async throws -> Message {
        let body: [String: Any] = [
            "recipients": recipients,
            "subject": subject,
            "message": content
        ]
        return try await customRequest(
            endpoint: "/messages",
            method: "POST",
            body: body,
            authenticated: true
        )
    }

    func deleteMessage(threadId: Int) async throws -> EmptyResponse {
        return try await customRequest(
            endpoint: "/messages/\(threadId)",
            method: "DELETE",
            authenticated: true
        )
    }
}

#Preview {
    MessagesListView()
        .environmentObject(AuthManager.shared)
}
