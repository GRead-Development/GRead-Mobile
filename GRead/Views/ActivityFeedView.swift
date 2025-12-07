import SwiftUI

struct ActivityFeedView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.themeColors) var themeColors
    @State private var activities: [Activity] = []
    @State private var organizedActivities: [Activity] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var page = 1
    @State private var hasMorePages = true
    @State private var selectedActivity: Activity?
    @State private var showingLoginPrompt = false
    @State private var blockedUserIds: [Int] = []
    @State private var mutedUserIds: [Int] = []
    @State private var listRefreshID = UUID()
    @State private var showLoginSheet = false
    @State private var isLoadingModeration = false

    // Sheet state - only one sheet can be open at a time
    enum SheetType: Identifiable {
        case newPost
        case userProfile(userId: Int)
        case moderation(userId: Int, userName: String)
        case comments(activity: Activity)

        var id: String {
            switch self {
            case .newPost: return "newPost"
            case .userProfile: return "userProfile"
            case .moderation: return "moderation"
            case .comments: return "comments"
            }
        }
    }
    @State private var activeSheet: SheetType?
    
    var body: some View {
        ZStack {
            Group {
                    // Content
                    if isLoading && organizedActivities.isEmpty {
                        ProgressView("Loading activities...")
                    } else if organizedActivities.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 60))
                                .foregroundColor(themeColors.textSecondary.opacity(0.5))
                            Text("No activity yet")
                                .font(.title3)
                                .foregroundColor(themeColors.textSecondary)
                            Text("Be the first to post something!")
                                .font(.caption)
                                .foregroundColor(themeColors.textSecondary)
                        }
                    } else {
                        List {
                            ForEach(organizedActivities, id: \.id) { activity in
                                ThreadedActivityView(
                                    activity: activity,
                                    onUserTap: { userId in
                                        activeSheet = .userProfile(userId: userId)
                                    },
                                    onCommentsTap: {
                                        activeSheet = .comments(activity: activity)
                                    },
                                    onReport: {
                                        selectedActivity = activity
                                    },
                                    onDelete: { activityToDelete in
                                        deleteActivity(activityToDelete)
                                    }
                                )

                                if activity.id == organizedActivities.last?.id && hasMorePages && !isLoading {
                                    ProgressView()
                                        .onAppear {
                                            Task {
                                                await loadMoreActivities()
                                            }
                                        }
                                }
                            }

                            // Bottom padding to prevent tab bar overlap
                            Color.clear
                                .frame(height: 60)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        .listStyle(.plain)
                        .refreshable {
                            page = 1
                            hasMorePages = true
                            await loadModerationLists()
                            await loadActivities()
                        }
                    }
                }
                .navigationTitle("Activity")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            if authManager.isGuestMode {
                                showingLoginPrompt = true
                            } else {
                                activeSheet = .newPost
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                }
                .alert("Sign In Required", isPresented: $showingLoginPrompt) {
                    Button("Sign In") {
                        showLoginSheet = true
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("You need to sign in to create posts. Please sign in or create an account.")
                }
                .sheet(isPresented: $showLoginSheet) {
                    LoginRegisterView()
                        .environmentObject(authManager)
                }
                .alert("Report Activity", isPresented: Binding(
                    get: { selectedActivity != nil },
                    set: { if !$0 { selectedActivity = nil } }
                )) {
                    if let activity = selectedActivity {
                        Button("Spam", role: .destructive) {
                            reportActivity(activity, reason: "spam")
                        }
                        Button("Inappropriate Content", role: .destructive) {
                            reportActivity(activity, reason: "inappropriate")
                        }
                        Button("Harassment", role: .destructive) {
                            reportActivity(activity, reason: "harassment")
                        }
                        Button("Cancel", role: .cancel) {
                            selectedActivity = nil
                        }
                    }
                } message: {
                    Text("Why are you reporting this post?")
                }
                .task {
                    await loadModerationLists()
                    if organizedActivities.isEmpty {
                        await loadActivities()
                    }
                }
                .alert("Error", isPresented: .constant(errorMessage != nil)) {
                    Button("OK") {
                        errorMessage = nil
                    }
                } message: {
                    if let error = errorMessage {
                        Text(error)
                    }
                }
            .id(1)  // Stable ID to prevent rebuilding when sheet state changes
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .newPost:
                NewActivityView(onPost: {
                    Task {
                        page = 1
                        hasMorePages = true
                        await loadActivities()
                    }
                })
            case .userProfile(let userId):
                UserProfileView(
                    userId: userId,
                    onModerationTap: { userName in
                        activeSheet = .moderation(userId: userId, userName: userName)
                    }
                )
                .presentationDetents([.medium, .large])
            case .moderation(let userId, let userName):
                ModerationView(userId: userId, userName: userName)
            case .comments(let activity):
                CommentView(
                    activity: activity,
                    onPost: {
                        Task {
                            page = 1
                            hasMorePages = true
                            await loadActivities()
                        }
                    },
                    onUserTap: { userId in
                        activeSheet = .userProfile(userId: userId)
                    }
                )
            }
        }
    }
    
    private func loadActivities() async {
        isLoading = true
        errorMessage = nil

        do {
            // Request activity feed with user info and comments
            let activityResponse: ActivityResponse = try await APIManager.shared.request(
                endpoint: "/activity?per_page=20&page=\(page)&display_comments=true",
                authenticated: false
            )
            let response = activityResponse.activities

            print("=== ACTIVITY RESPONSE DEBUG ===")
            print("Total from response: \(activityResponse.total ?? -1)")
            print("Has more items: \(activityResponse.hasMoreItems ?? false)")
            print("Activities array count: \(response.count)")

            // Activity feed loaded successfully
            print("📦 Loaded \(response.count) activities")
            
            await MainActor.run {
                if page == 1 {
                    activities = response
                } else {
                    // Append new activities, but deduplicate in case of overlaps
                    let existingIds = Set(activities.map { $0.id })
                    let uniqueNewActivities = response.filter { !existingIds.contains($0.id) }
                    activities.append(contentsOf: uniqueNewActivities)
                }
                // Organize flat list into hierarchy
                organizedActivities = organizeActivitiesIntoThreads(activities)

                hasMorePages = response.count >= 20
                isLoading = false
            }
        } catch APIError.emptyResponse {
            await MainActor.run {
                if page == 1 {
                    activities = []
                    organizedActivities = []
                }
                hasMorePages = false
                isLoading = false
            }
        } catch is CancellationError {
            // Task was cancelled - this is normal and expected when view is dismissed
            await MainActor.run {
                isLoading = false
            }
        } catch {
            // Don't show error for cancelled requests (URLError code -999)
            if let urlError = error as? URLError, urlError.code == .cancelled {
                await MainActor.run {
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    errorMessage = "Failed to load activities: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func loadMoreActivities() async {
        guard !isLoading && hasMorePages else { return }
        page += 1
        await loadActivities()
    }

    private func deleteActivity(_ activity: Activity) {
        Task {
            do {
                let _: EmptyResponse = try await APIManager.shared.request(
                    endpoint: "/activity/\(activity.id)",
                    method: "DELETE"
                )
                await MainActor.run {
                    activities.removeAll { $0.id == activity.id }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete activity"
                }
            }
        }
    }
    
    private func reportActivity(_ activity: Activity, reason: String) {
        selectedActivity = nil

        Task {
            do {
                var userId: Int?

                if let uid = activity.userId {
                    userId = uid
                } else if let itemId = activity.itemId {
                    userId = itemId
                } else if let secondaryItemId = activity.secondaryItemId {
                    userId = secondaryItemId
                }

                guard let finalUserId = userId else {
                    await MainActor.run {
                        errorMessage = "Cannot report: User ID not found"
                    }
                    return
                }

                let response = try await APIManager.shared.reportUser(
                    userId: finalUserId,
                    reason: reason
                )

                await MainActor.run {
                    if response.success {
                        errorMessage = "Report submitted successfully"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            if errorMessage == "Report submitted successfully" {
                                errorMessage = nil
                            }
                        }
                    } else {
                        errorMessage = response.message
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to report: \(error.localizedDescription)"
                }
            }
        }
    }

    private func loadModerationLists() async {
        // Prevent concurrent loads
        guard !isLoadingModeration else { return }

        await MainActor.run {
            isLoadingModeration = true
        }

        defer {
            Task { @MainActor in
                isLoadingModeration = false
            }
        }

        do {
            let blockedListResponse = try await APIManager.shared.getBlockedList()
            let mutedListResponse = try await APIManager.shared.getMutedList()

            await MainActor.run {
                blockedUserIds = blockedListResponse.blockedUsers
                mutedUserIds = mutedListResponse.mutedUsers
            }
        } catch is CancellationError {
            // Task was cancelled - this is normal, don't log
            return
        } catch {
            // Don't show error for cancelled requests (URLError code -999)
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }
            // Silently fail - moderation lists are optional
            print("Failed to load moderation lists: \(error)")
        }
    }

    private func organizeActivitiesIntoThreads(_ flatActivities: [Activity]) -> [Activity] {
        // Create a dictionary for quick lookup and organize activities
        var activityById: [Int: Activity] = [:]

        // Initialize all activities with empty children
        for activity in flatActivities {
            var mutableActivity = activity
            mutableActivity.children = []
            activityById[activity.id] = mutableActivity
        }

        // Build parent-child relationships based on activity type
        for activity in flatActivities {
            // For activity_comment, the parent ID is in itemId or secondaryItemId
            let parentId: Int?
            if activity.type == "activity_comment" {
                // Comments use itemId/secondaryItemId to reference parent
                parentId = activity.itemId ?? activity.secondaryItemId
            } else {
                // Other types don't have comments in this feed
                parentId = nil
            }

            if let parentId = parentId, parentId > 0, var parent = activityById[parentId] {
                // Add this activity as a child of its parent
                if let organizedChild = activityById[activity.id] {
                    parent.children?.append(organizedChild)
                    activityById[parentId] = parent
                }
            }
        }

        // Return only posts (activity_update) without filtering out other types
        // But organize comments under their parent posts
        // Also filter out posts from blocked and muted users
        return flatActivities.filter { activity in
            let isActivityUpdate = activity.type == "activity_update"
            let userId = activity.userId ?? -1
            let isNotBlocked = !blockedUserIds.contains(userId)
            let isNotMuted = !mutedUserIds.contains(userId)
            return isActivityUpdate && isNotBlocked && isNotMuted
        }.compactMap { activityById[$0.id] }
    }
}

struct ThreadedActivityView: View {
    let activity: Activity
    let onUserTap: (Int) -> Void
    let onCommentsTap: () -> Void
    let onReport: () -> Void
    let onDelete: (Activity) -> Void
    @Environment(\.themeColors) var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main post
            ActivityRowView(
                activity: activity,
                onUserTap: onUserTap,
                onCommentsTap: onCommentsTap,
                onReport: onReport,
                indentLevel: 0
            )
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if activity.userId == AuthManager.shared.currentUser?.id {
                    Button(role: .destructive) {
                        onDelete(activity)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            // Comments (children) with indentation - sorted by date (oldest first)
            if let children = activity.children, !children.isEmpty {
                let sortedChildren = children.sorted { child1, child2 in
                    let date1 = child1.dateRecorded ?? ""
                    let date2 = child2.dateRecorded ?? ""
                    return date1 < date2
                }
                ForEach(sortedChildren) { child in
                    CommentThreadView(
                        comment: child,
                        onUserTap: onUserTap,
                        onCommentsTap: onCommentsTap,
                        onReport: onReport,
                        onDelete: onDelete,
                        indentLevel: 1
                    )
                }
            }
        }
    }
}

struct CommentThreadView: View {
    let comment: Activity
    let onUserTap: (Int) -> Void
    let onCommentsTap: () -> Void
    let onReport: () -> Void
    let onDelete: (Activity) -> Void
    let indentLevel: Int
    @Environment(\.themeColors) var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                // Indentation
                VStack {
                    if indentLevel > 0 {
                        Divider()
                            .frame(height: 60)
                    }
                }
                .frame(width: CGFloat(indentLevel) * 16)

                // Comment content
                ActivityRowView(
                    activity: comment,
                    onUserTap: onUserTap,
                    onCommentsTap: onCommentsTap,
                    onReport: onReport,
                    indentLevel: indentLevel
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if comment.userId == AuthManager.shared.currentUser?.id {
                        Button(role: .destructive) {
                            onDelete(comment)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }

            // Nested replies
            if let children = comment.children, !children.isEmpty {
                ForEach(children) { child in
                    CommentThreadView(
                        comment: child,
                        onUserTap: onUserTap,
                        onCommentsTap: onCommentsTap,
                        onReport: onReport,
                        onDelete: onDelete,
                        indentLevel: indentLevel + 1
                    )
                }
            }
        }
    }
}

struct ActivityRowView: View {
    let activity: Activity
    let onUserTap: (Int) -> Void
    let onCommentsTap: () -> Void
    let onReport: () -> Void
    let indentLevel: Int
    @Environment(\.themeColors) var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // Avatar with fallback
                AsyncImage(url: URL(string: activity.avatarURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        Circle()
                            .fill(themeColors.primary.opacity(0.2))
                            .overlay {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                    case .failure:
                        Circle()
                            .fill(themeColors.primary.opacity(0.2))
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundColor(themeColors.primary)
                                    .font(.system(size: 16))
                            }
                    @unknown default:
                        Circle()
                            .fill(themeColors.primary.opacity(0.2))
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .onTapGesture {
                    if let userId = activity.userId {
                        onUserTap(userId)
                    }
                }

                // Fallback if we still need it
                if false {
                    Circle()
                        .fill(themeColors.primary.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundColor(themeColors.primary)
                                .font(.system(size: 18))
                        }
                        .onTapGesture {
                            if let userId = activity.userId {
                                onUserTap(userId)
                            }
                        }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Button(action: {
                        if let userId = activity.userId {
                            onUserTap(userId)
                        }
                    }) {
                        Text(activity.bestUserName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 4) {
                        if let type = activity.type {
                            Text(type.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption)
                                .foregroundColor(themeColors.primary)
                        }

                        if let date = activity.dateRecorded {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(themeColors.textSecondary)

                            Text(date.toRelativeTime())
                                .font(.caption)
                                .foregroundColor(themeColors.textSecondary)
                        }
                    }
                }

                Spacer()
            }
            
            if let content = activity.content, !content.isEmpty {
                Text(content.decodingHTMLEntities.stripHTML())
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
            
            // Only show comment button for top-level posts
            if indentLevel == 0 {
                HStack(spacing: 20) {
                    Button {
                        onCommentsTap()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.right")
                            Text("Comment")
                        }
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                    }

                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
}

struct CommentView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColors) var themeColors
    let activity: Activity
    let onPost: () -> Void
    let onUserTap: (Int) -> Void
    @State private var commentText = ""
    @State private var isPosting = false
    @State private var commentError: String?
    @State private var userCache: [Int: User] = [:]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Comments")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Original post
                    if let content = activity.content {
                        Text(content.stripHTML())
                            .font(.body)
                            .fontWeight(.medium)
                            .padding()
                            .background(themeColors.textSecondary.opacity(0.1))
                            .cornerRadius(8)
                    }

                    Divider()

                    // Error message
                    if let error = commentError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(themeColors.error)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(themeColors.error)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(themeColors.error.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }

                    // Display existing comments - sorted by date (oldest first)
                    if let children = activity.children, !children.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            let sortedComments = children.sorted { c1, c2 in
                                let date1 = c1.dateRecorded ?? ""
                                let date2 = c2.dateRecorded ?? ""
                                return date1 < date2
                            }
                            ForEach(sortedComments) { comment in
                                CommentItemView(
                                    comment: comment,
                                    user: comment.userId.flatMap { userCache[$0] },
                                    userCache: userCache,
                                    onUserTap: onUserTap
                                )
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        Text("No comments yet")
                            .font(.caption)
                            .foregroundColor(themeColors.textSecondary)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }

            Divider()

            HStack(spacing: 12) {
                TextField("Add a comment...", text: $commentText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(themeColors.textSecondary.opacity(0.1))
                    .cornerRadius(20)
                    .lineLimit(1...5)

                Button {
                    postComment()
                } label: {
                    if isPosting {
                        ProgressView()
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(commentText.isEmpty ? themeColors.textSecondary : themeColors.primary)
                    }
                }
                .disabled(commentText.isEmpty || isPosting)
                .animation(.easeInOut(duration: 0.2), value: isPosting)
            }
            .padding()
        }
        .task {
            await loadUsersForComments()
        }
    }

    private func loadUsersForComments() async {
        // Get unique user IDs from activity children (comments)
        guard let children = activity.children else { return }

        func collectUserIds(from activities: [Activity]) -> Set<Int> {
            var ids = Set<Int>()
            for activity in activities {
                if let userId = activity.userId {
                    ids.insert(userId)
                }
                if let children = activity.children {
                    ids.formUnion(collectUserIds(from: children))
                }
            }
            return ids
        }

        let userIds = collectUserIds(from: children)

        // Fetch users
        for userId in userIds {
            do {
                let user: User = try await APIManager.shared.request(
                    endpoint: "/members/\(userId)",
                    authenticated: false
                )

                await MainActor.run {
                    userCache[userId] = user
                }
            } catch {
                print("Failed to load user \(userId): \(error)")
            }
        }
    }

    private func postComment() {
        isPosting = true
        commentError = nil
        Task {
            do {
                let body: [String: Any] = [
                    "content": commentText,
                    "parent": activity.id
                ]

                let _: AnyCodable = try await APIManager.shared.request(
                    endpoint: "/activity",
                    method: "POST",
                    body: body
                )

                await MainActor.run {
                    commentText = ""
                    isPosting = false
                    onPost()
                    // Dismiss the comment view to show the nested comment in the main feed
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isPosting = false
                    commentError = "Failed to post comment. Please try again."
                }
            }
        }
    }
}

struct CommentItemView: View {
    @Environment(\.themeColors) var themeColors
    let comment: Activity
    let user: User?
    let userCache: [Int: User]
    let onUserTap: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // Avatar with fallback - use User.avatarUrl if available
                AsyncImage(url: URL(string: user?.avatarUrl ?? comment.avatarURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        Circle()
                            .fill(themeColors.primary.opacity(0.15))
                            .overlay {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                    case .failure:
                        Circle()
                            .fill(themeColors.primary.opacity(0.15))
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundColor(themeColors.primary)
                                    .font(.system(size: 12))
                            }
                    @unknown default:
                        Circle()
                            .fill(themeColors.primary.opacity(0.15))
                    }
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .onTapGesture {
                    if let userId = comment.userId {
                        onUserTap(userId)
                    }
                }

                if false {
                    Circle()
                        .fill(themeColors.primary.opacity(0.15))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundColor(themeColors.primary)
                                .font(.system(size: 14))
                        }
                        .onTapGesture {
                            if let userId = comment.userId {
                                onUserTap(userId)
                            }
                        }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Button(action: {
                        if let userId = comment.userId {
                            onUserTap(userId)
                        }
                    }) {
                        Text(comment.bestUserName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }

                    if let date = comment.dateRecorded {
                        Text(date.toRelativeTime())
                            .font(.caption2)
                            .foregroundColor(themeColors.textSecondary)
                    }
                }

                Spacer()
            }

            if let content = comment.content {
                Text(content.decodingHTMLEntities.stripHTML())
                    .font(.caption)
                    .lineLimit(nil)
            }

            // Recursively show nested replies if any
            if let children = comment.children, !children.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.vertical, 4)

                    ForEach(children) { child in
                        CommentItemView(
                            comment: child,
                            user: child.userId.flatMap { userCache[$0] },
                            userCache: userCache,
                            onUserTap: onUserTap
                        )
                        .padding(.leading, 8)
                    }
                }
            }
        }
        .padding(8)
        .background(themeColors.textSecondary.opacity(0.05))
        .cornerRadius(12)
    }
}

struct NewActivityView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColors) var themeColors
    @State private var content = ""
    @State private var isPosting = false
    @State private var errorMessage: String?
    let onPost: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Text("New Post")
                    .font(.headline)
                Spacer()
                Button {
                    postActivity()
                } label: {
                    if isPosting {
                        ProgressView()
                    } else {
                        Text("Post")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPosting)
            }
            .padding()

            Divider()

            MentionTextEditor(
                text: $content,
                placeholder: "What's on your mind? Use @ to mention users...",
                minHeight: 150
            )
            .padding(.horizontal)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(themeColors.error)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
    }
    
    private func postActivity() {
        isPosting = true
        errorMessage = nil
        
        Task {
            do {
                let body: [String: Any] = [
                    "content": content,
                    "type": "activity_update",
                    "component": "activity"
                ]
                
                let _: AnyCodable = try await APIManager.shared.request(
                    endpoint: "/activity",
                    method: "POST",
                    body: body
                )
                
                await MainActor.run {
                    onPost()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to post: \(error.localizedDescription)"
                    isPosting = false
                }
            }
        }
    }
}
