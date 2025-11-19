# GRead API - Complete Quick Reference

## Table of Contents
1. [Authentication](#authentication)
2. [User Stats](#user-stats)
3. [Library Management](#library-management)
4. [Books & ISBN](#books--isbn)
5. [Achievements](#achievements)
6. [Mentions](#mentions)
7. [Activity Feed](#activity-feed)
8. [Friends](#friends)
9. [Messages](#messages)
10. [Groups](#groups)
11. [Notifications](#notifications)
12. [Moderation](#moderation)

---

## Authentication

### Login with JWT
```swift
// Already implemented in AuthManager.swift
func login(username: String, password: String) async throws {
    let response: JWTResponse = try await request(
        endpoint: "/jwt-auth/v1/token",
        method: "POST",
        body: ["username": username, "password": password],
        authenticated: false
    )
    // Store token
}
```

---

## User Stats

### Get User Statistics
```swift
// GET /user/{id}/stats
func loadUserStats(userId: Int) async {
    do {
        let stats = try await APIManager.shared.getUserStats(userId: userId)
        print("Books Completed: \(stats.booksCompleted)")
        print("Pages Read: \(stats.pagesRead)")
        print("Points: \(stats.points)")
    } catch {
        print("Error: \(error)")
    }
}
```

**Response includes:**
- `books_completed` - Total books finished
- `pages_read` - Total pages read
- `books_added` - Books added to database
- `approved_reports` - Approved user reports
- `points` - Gamification points

---

## Library Management

### Get User's Library
```swift
// GET /library
func loadLibrary() async {
    do {
        let items: [LibraryItem] = try await APIManager.shared.customRequest(
            endpoint: "/library",
            authenticated: true
        )
        print("Library has \(items.count) books")
    } catch {
        print("Error: \(error)")
    }
}
```

### Add Book to Library
```swift
// POST /library/add?book_id={id}
func addBookToLibrary(bookId: Int) async {
    do {
        let _: EmptyResponse = try await APIManager.shared.customRequest(
            endpoint: "/library/add?book_id=\(bookId)",
            method: "POST",
            body: ["book_id": bookId],
            authenticated: true
        )
        print("Book added!")
    } catch {
        print("Error: \(error)")
    }
}
```

### Update Reading Progress
```swift
// POST /library/progress?book_id={id}&current_page={page}
func updateProgress(bookId: Int, currentPage: Int) async {
    do {
        let _: EmptyResponse = try await APIManager.shared.customRequest(
            endpoint: "/library/progress?book_id=\(bookId)&current_page=\(currentPage)",
            method: "POST",
            body: ["current_page": currentPage],
            authenticated: true
        )
        print("Progress updated!")
    } catch {
        print("Error: \(error)")
    }
}
```

### Remove Book from Library
```swift
// DELETE /library/remove?book_id={id}
func removeBook(bookId: Int) async {
    do {
        let _: EmptyResponse = try await APIManager.shared.customRequest(
            endpoint: "/library/remove?book_id=\(bookId)",
            method: "DELETE",
            authenticated: true
        )
        print("Book removed!")
    } catch {
        print("Error: \(error)")
    }
}
```

---

## Books & ISBN

### Search Books
```swift
// GET /books/search?query={query}
extension APIManager {
    func searchBooks(query: String) async throws -> [Book] {
        return try await customRequest(
            endpoint: "/books/search?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
            authenticated: true
        )
    }
}

// Usage:
let books = try await APIManager.shared.searchBooks(query: "Harry Potter")
```

### Get Book by ID
```swift
// GET /book/{id}
extension APIManager {
    func getBook(id: Int) async throws -> Book {
        return try await customRequest(
            endpoint: "/book/\(id)",
            authenticated: false
        )
    }
}
```

### Lookup Book by ISBN
```swift
// GET /books/isbn?isbn={isbn}
// Already implemented - use:
let book = try await APIManager.shared.customRequest(
    endpoint: "/books/isbn?isbn=9780545010221",
    method: "GET",
    authenticated: true
) as Book
```

### Manage ISBNs for a Book
```swift
// GET /books/{id}/isbns - Get all ISBNs
// POST /books/{id}/isbns - Add new ISBN
// DELETE /books/isbn/{isbn} - Remove ISBN
// PUT /books/{id}/isbns/primary - Set primary ISBN

extension APIManager {
    func getBookISBNs(bookId: Int) async throws -> [ISBN] {
        return try await customRequest(
            endpoint: "/books/\(bookId)/isbns",
            authenticated: false
        )
    }

    func addISBN(bookId: Int, isbn: String, edition: String, year: Int, isPrimary: Bool) async throws -> ISBN {
        let body: [String: Any] = [
            "isbn": isbn,
            "edition": edition,
            "year": year,
            "is_primary": isPrimary
        ]
        return try await customRequest(
            endpoint: "/books/\(bookId)/isbns",
            method: "POST",
            body: body,
            authenticated: true
        )
    }
}
```

---

## Achievements

### Get All Achievements
```swift
// GET /achievements?show_hidden={bool}
// Already implemented:
let achievements = try await APIManager.shared.getAllAchievements(showHidden: false)
```

### Get User's Achievements
```swift
// GET /user/{id}/achievements?filter={all|unlocked|locked}
// Already implemented:
let response = try await APIManager.shared.getUserAchievements(
    userId: userId,
    filter: "all"
)
```

### Get My Achievements
```swift
// GET /me/achievements?filter={all|unlocked|locked}
// Already implemented:
let myAchievements = try await APIManager.shared.getMyAchievements(filter: "unlocked")
```

### Check & Unlock Achievements
```swift
// POST /me/achievements/check
// Already implemented:
let updated = try await APIManager.shared.checkAndUnlockAchievements()
```

### Get Achievement Stats
```swift
// GET /achievements/stats
// Already implemented:
let stats = try await APIManager.shared.getAchievementStats()
// Returns: total_achievements, total_unlocks, top_achievers
```

### Get Leaderboard
```swift
// GET /achievements/leaderboard?limit={int}&offset={int}
// Already implemented:
let leaderboard = try await APIManager.shared.getAchievementsLeaderboard(
    limit: 20,
    offset: 0
)
```

---

## Mentions

### Search Users to Mention
```swift
// GET /mentions/search?query={query}&limit={int}
// Already implemented:
let users = try await APIManager.shared.searchMentionUsers(
    query: "john",
    limit: 10
)
```

### Get Mentionable Users
```swift
// GET /mentions/users?limit={int}&offset={int}
// Already implemented:
let response = try await APIManager.shared.getMentionableUsers(
    limit: 50,
    offset: 0
)
```

### Get My Mentions
```swift
// GET /me/mentions?limit={int}&offset={int}&unread_only={bool}
// Already implemented:
let mentions = try await APIManager.shared.getMyMentions(
    limit: 20,
    offset: 0,
    unreadOnly: true
)
```

### Mark Mentions as Read
```swift
// POST /me/mentions/read
// Already implemented:
let response = try await APIManager.shared.markMentionsAsRead()
```

### Get Mention Activity
```swift
// GET /mentions/activity?user_id={int}&limit={int}&offset={int}
// Already implemented:
let activity = try await APIManager.shared.getMentionsActivity(
    userId: nil,
    limit: 20,
    offset: 0
)
```

---

## Activity Feed

### Get Activity Feed
```swift
// GET /activity?per_page={int}&page={int}&type={type}
let response: ActivityResponse = try await APIManager.shared.request(
    endpoint: "/activity?per_page=20&page=1&type=activity_update",
    authenticated: false
)
```

### Post Activity Update
```swift
// POST /activity
let body: [String: Any] = [
    "content": "Just finished reading Harry Potter!",
    "type": "activity_update",
    "component": "activity"
]

let _: AnyCodable = try await APIManager.shared.request(
    endpoint: "/activity",
    method: "POST",
    body: body,
    authenticated: true
)
```

### Comment on Activity
```swift
// POST /activity (with parent parameter)
let body: [String: Any] = [
    "content": "Great book!",
    "parent": activityId
]

let _: AnyCodable = try await APIManager.shared.request(
    endpoint: "/activity",
    method: "POST",
    body: body,
    authenticated: true
)
```

### Delete Activity
```swift
// DELETE /activity/{id}
let _: EmptyResponse = try await APIManager.shared.request(
    endpoint: "/activity/\(activityId)",
    method: "DELETE",
    authenticated: true
)
```

### Favorite Activity
```swift
// POST /activity/{id}/favorite
extension APIManager {
    func favoriteActivity(id: Int) async throws -> EmptyResponse {
        return try await customRequest(
            endpoint: "/activity/\(id)/favorite",
            method: "POST",
            authenticated: true
        )
    }
}
```

---

## Friends

### Get Friends List
```swift
// GET /friends/{user_id}
// Already implemented:
let response = try await APIManager.shared.getFriends(userId: userId)
```

### Get Pending Friend Requests
```swift
// GET /friends/requests/pending
// Already implemented:
let requests = try await APIManager.shared.getPendingFriendRequests()
```

### Send Friend Request
```swift
// POST /friends/request
// Already implemented:
let response = try await APIManager.shared.sendFriendRequest(friendId: userId)
```

### Accept Friend Request
```swift
// POST /friends/request/{id}/accept
// Already implemented:
let response = try await APIManager.shared.acceptFriendRequest(requestId: requestId)
```

### Reject Friend Request
```swift
// POST /friends/request/{id}/reject
// Already implemented:
let response = try await APIManager.shared.rejectFriendRequest(requestId: requestId)
```

### Remove Friend
```swift
// POST /friends/{id}/remove
// Already implemented:
let response = try await APIManager.shared.removeFriend(friendId: friendId)
```

---

## Messages

### Get Message Threads
```swift
// GET /messages
extension APIManager {
    func getMessages() async throws -> [MessageThread] {
        return try await customRequest(
            endpoint: "/messages",
            authenticated: true
        )
    }
}
```

### Get Specific Thread
```swift
// GET /messages/{id}
extension APIManager {
    func getMessageThread(threadId: Int) async throws -> [Message] {
        return try await customRequest(
            endpoint: "/messages/\(threadId)",
            authenticated: true
        )
    }
}
```

### Send Message
```swift
// POST /messages
extension APIManager {
    func sendMessage(
        recipients: [Int],
        subject: String,
        content: String
    ) async throws -> Message {
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
}
```

### Delete Message Thread
```swift
// DELETE /messages/{id}
extension APIManager {
    func deleteMessage(threadId: Int) async throws -> EmptyResponse {
        return try await customRequest(
            endpoint: "/messages/\(threadId)",
            method: "DELETE",
            authenticated: true
        )
    }
}
```

---

## Groups

### Get All Groups
```swift
// GET /groups?page={int}&per_page={int}
extension APIManager {
    func getGroups(page: Int = 1, perPage: Int = 20) async throws -> GroupsResponse {
        return try await customRequest(
            endpoint: "/groups?page=\(page)&per_page=\(perPage)",
            authenticated: false
        )
    }
}
```

### Get Group Details
```swift
// GET /groups/{id}
extension APIManager {
    func getGroup(id: Int) async throws -> Group {
        return try await customRequest(
            endpoint: "/groups/\(id)",
            authenticated: false
        )
    }
}
```

### Create Group
```swift
// POST /groups
extension APIManager {
    func createGroup(
        name: String,
        description: String,
        status: String = "public"
    ) async throws -> Group {
        let body: [String: Any] = [
            "name": name,
            "description": description,
            "status": status
        ]
        return try await customRequest(
            endpoint: "/groups",
            method: "POST",
            body: body,
            authenticated: true
        )
    }
}
```

### Join Group
```swift
// POST /groups/{id}/members/{user_id}
extension APIManager {
    func joinGroup(groupId: Int, userId: Int) async throws -> MembershipResponse {
        return try await customRequest(
            endpoint: "/groups/\(groupId)/members/\(userId)",
            method: "POST",
            authenticated: true
        )
    }
}
```

### Get Group Members
```swift
// GET /groups/{id}/members
extension APIManager {
    func getGroupMembers(groupId: Int) async throws -> [GroupMember] {
        return try await customRequest(
            endpoint: "/groups/\(groupId)/members",
            authenticated: false
        )
    }
}
```

---

## Notifications

### Get Notifications
```swift
// GET /notifications
extension APIManager {
    func getNotifications(page: Int = 1, perPage: Int = 20) async throws -> [Notification] {
        return try await request(
            endpoint: "/notifications?page=\(page)&per_page=\(perPage)",
            authenticated: true
        )
    }
}
```

### Mark Notification as Read
```swift
// PUT /notifications/{id}
extension APIManager {
    func markNotificationRead(id: Int, isRead: Bool) async throws -> Notification {
        let body: [String: Any] = ["is_new": !isRead]
        return try await request(
            endpoint: "/notifications/\(id)",
            method: "PUT",
            body: body,
            authenticated: true
        )
    }
}
```

### Delete Notification
```swift
// DELETE /notifications/{id}
extension APIManager {
    func deleteNotification(id: Int) async throws -> EmptyResponse {
        return try await request(
            endpoint: "/notifications/\(id)",
            method: "DELETE",
            authenticated: true
        )
    }
}
```

---

## Moderation

### Block User
```swift
// POST /user/block
// Already implemented:
let response = try await APIManager.shared.blockUser(userId: userId)
```

### Unblock User
```swift
// POST /user/unblock
// Already implemented:
let response = try await APIManager.shared.unblockUser(userId: userId)
```

### Mute User
```swift
// POST /user/mute
// Already implemented:
let response = try await APIManager.shared.muteUser(userId: userId)
```

### Unmute User
```swift
// POST /user/unmute
// Already implemented:
let response = try await APIManager.shared.unmuteUser(userId: userId)
```

### Report User
```swift
// POST /user/report
// Already implemented:
let response = try await APIManager.shared.reportUser(
    userId: userId,
    reason: "Spam content"
)
```

### Get Blocked List
```swift
// GET /user/blocked_list
// Already implemented:
let blockedList = try await APIManager.shared.getBlockedList()
```

### Get Muted List
```swift
// GET /user/muted_list
// Already implemented:
let mutedList = try await APIManager.shared.getMutedList()
```

---

## Error Handling Best Practices

### Universal Error Handler
```swift
func handleAPIError(_ error: Error) -> String {
    if let apiError = error as? APIError {
        switch apiError {
        case .invalidURL:
            return "Invalid request URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            switch code {
            case 401:
                return "Please log in again"
            case 403:
                return "You don't have permission"
            case 404:
                return "Content not found"
            case 500:
                return "Server error. Please try again later"
            default:
                return "Error: \(code)"
            }
        case .emptyResponse:
            return "No data available"
        case .decodingError(let error):
            return "Data format error: \(error.localizedDescription)"
        }
    }
    return error.localizedDescription
}

// Usage:
do {
    let stats = try await APIManager.shared.getUserStats(userId: userId)
} catch {
    let message = handleAPIError(error)
    print(message)
}
```

---

## Rate Limiting

### Respect API Limits
- **Anonymous requests**: 60 per minute
- **Authenticated requests**: 120 per minute

### Implement Request Queue
```swift
actor APIRequestQueue {
    private var lastRequestTime: Date = .distantPast
    private let minimumInterval: TimeInterval = 0.5 // 500ms between requests

    func enqueue<T>(_ request: @escaping () async throws -> T) async throws -> T {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastRequestTime)

        if elapsed < minimumInterval {
            try await Task.sleep(nanoseconds: UInt64((minimumInterval - elapsed) * 1_000_000_000))
        }

        lastRequestTime = Date()
        return try await request()
    }
}

// Usage:
let queue = APIRequestQueue()
let stats = try await queue.enqueue {
    try await APIManager.shared.getUserStats(userId: userId)
}
```

---

## Testing API Calls

### Mock Responses for Testing
```swift
#if DEBUG
extension APIManager {
    static let mock = APIManager()

    func mockUserStats() -> UserStats {
        return UserStats(
            id: 1,
            userId: 1,
            displayName: "Test User",
            avatarUrl: "https://example.com/avatar.jpg",
            points: 1000,
            booksCompleted: 42,
            pagesRead: 15420,
            booksAdded: 100,
            approvedReports: 5
        )
    }
}
#endif

// Usage in SwiftUI Previews:
#Preview {
    StatsView(userId: 1)
        .task {
            // Use mock data in preview
            #if DEBUG
            stats = APIManager.mock.mockUserStats()
            #endif
        }
}
```

---

## Quick Start Checklist

### Essential Implementations:
- [x] User authentication (login/logout)
- [x] User stats display
- [x] Library management (add/remove/update progress)
- [x] Activity feed (view/post/comment)
- [x] Achievements (view/unlock)
- [x] User search
- [x] Friends management
- [x] Moderation (block/mute/report)
- [ ] Messages system
- [ ] Groups functionality
- [ ] Mentions in posts
- [ ] Notifications management

### Nice-to-Have Features:
- [ ] Book recommendations
- [ ] Reading challenges
- [ ] Reading statistics graphs
- [ ] Export reading data
- [ ] Offline mode with sync
- [ ] Push notifications
- [ ] Widget support

---

This completes the GRead API quick reference! All the endpoints are documented with Swift code examples ready to use in your app.
