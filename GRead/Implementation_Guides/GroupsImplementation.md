# Groups Implementation Guide

## Overview
The GRead Groups API allows users to create and join reading communities, book clubs, and discussion groups.

## API Endpoints

### 1. Get All Groups
```swift
GET /groups
```

**Implementation:**
```swift
extension APIManager {
    func getGroups(page: Int = 1, perPage: Int = 20) async throws -> GroupsResponse {
        return try await customRequest(
            endpoint: "/groups?page=\(page)&per_page=\(perPage)",
            authenticated: false
        )
    }
}
```

### 2. Get Specific Group
```swift
GET /groups/{id}
```

**Implementation:**
```swift
extension APIManager {
    func getGroup(id: Int) async throws -> Group {
        return try await customRequest(
            endpoint: "/groups/\(id)",
            authenticated: false
        )
    }
}
```

### 3. Create New Group
```swift
POST /groups
```

**Request Body:**
```json
{
  "name": "Sci-Fi Book Club",
  "description": "A community for science fiction enthusiasts",
  "status": "public" // or "private"
}
```

**Implementation:**
```swift
extension APIManager {
    func createGroup(name: String, description: String, status: String = "public") async throws -> Group {
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

### 4. Update Group
```swift
PUT /groups/{id}
```

**Implementation:**
```swift
extension APIManager {
    func updateGroup(id: Int, name: String?, description: String?, status: String?) async throws -> Group {
        var body: [String: Any] = [:]
        if let name = name { body["name"] = name }
        if let description = description { body["description"] = description }
        if let status = status { body["status"] = status }

        return try await customRequest(
            endpoint: "/groups/\(id)",
            method: "PUT",
            body: body,
            authenticated: true
        )
    }
}
```

### 5. Delete Group
```swift
DELETE /groups/{id}
```

**Implementation:**
```swift
extension APIManager {
    func deleteGroup(id: Int) async throws -> EmptyResponse {
        return try await customRequest(
            endpoint: "/groups/\(id)",
            method: "DELETE",
            authenticated: true
        )
    }
}
```

### 6. Get Group Members
```swift
GET /groups/{id}/members
```

**Implementation:**
```swift
extension APIManager {
    func getGroupMembers(groupId: Int, page: Int = 1, perPage: Int = 50) async throws -> GroupMembersResponse {
        return try await customRequest(
            endpoint: "/groups/\(groupId)/members?page=\(page)&per_page=\(perPage)",
            authenticated: false
        )
    }
}
```

### 7. Join Group
```swift
POST /groups/{id}/members/{user_id}
```

**Implementation:**
```swift
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

### 8. Leave Group
```swift
DELETE /groups/{id}/members/{user_id}
```

**Implementation:**
```swift
extension APIManager {
    func leaveGroup(groupId: Int, userId: Int) async throws -> EmptyResponse {
        return try await customRequest(
            endpoint: "/groups/\(groupId)/members/\(userId)",
            method: "DELETE",
            authenticated: true
        )
    }
}
```

## Data Models

### Group Model
```swift
struct Group: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let status: String // "public" or "private"
    let creatorId: Int
    let dateCreated: String
    let memberCount: Int
    let avatarUrl: String?
    let coverImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case status
        case creatorId = "creator_id"
        case dateCreated = "date_created"
        case memberCount = "member_count"
        case avatarUrl = "avatar_url"
        case coverImageUrl = "cover_image_url"
    }
}

struct GroupsResponse: Codable {
    let groups: [Group]
    let total: Int
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case groups
        case total
        case hasMore = "has_more"
    }
}

struct GroupMember: Codable, Identifiable {
    let id: Int
    let userId: Int
    let name: String
    let avatarUrl: String
    let isAdmin: Bool
    let dateJoined: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case avatarUrl = "avatar_url"
        case isAdmin = "is_admin"
        case dateJoined = "date_joined"
    }
}

struct GroupMembersResponse: Codable {
    let members: [GroupMember]
    let total: Int

    enum CodingKeys: String, CodingKey {
        case members
        case total
    }
}

struct MembershipResponse: Codable {
    let success: Bool
    let message: String
}
```

## UI Implementation

### Groups List View
```swift
import SwiftUI

struct GroupsListView: View {
    @Environment(\.themeColors) var themeColors
    @State private var groups: [Group] = []
    @State private var isLoading = false
    @State private var showCreateGroup = false

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading && groups.isEmpty {
                    ProgressView()
                } else if groups.isEmpty {
                    emptyState
                } else {
                    groupsList
                }
            }
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateGroup = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupView(onCreate: {
                    Task { await loadGroups() }
                })
            }
            .task {
                await loadGroups()
            }
            .refreshable {
                await loadGroups()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(themeColors.textSecondary)

            Text("No Groups Yet")
                .font(.headline)

            Text("Join or create a reading community")
                .font(.caption)
                .foregroundColor(themeColors.textSecondary)

            Button(action: { showCreateGroup = true }) {
                Label("Create Group", systemImage: "plus")
                    .padding()
                    .background(themeColors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }

    private var groupsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(groups) { group in
                    NavigationLink(destination: GroupDetailView(group: group)) {
                        GroupCard(group: group)
                    }
                }
            }
            .padding()
        }
    }

    private func loadGroups() async {
        isLoading = true
        do {
            let response = try await APIManager.shared.getGroups()
            groups = response.groups
            isLoading = false
        } catch {
            print("Failed to load groups: \(error)")
            isLoading = false
        }
    }
}

struct GroupCard: View {
    let group: Group
    @Environment(\.themeColors) var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Group Avatar
                AsyncImage(url: URL(string: group.avatarUrl ?? "")) { image in
                    image.resizable()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeColors.primary.opacity(0.2))
                        .overlay {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(themeColors.primary)
                        }
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                        .foregroundColor(themeColors.textPrimary)

                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(group.memberCount) members")
                            .font(.caption)
                    }
                    .foregroundColor(themeColors.textSecondary)

                    if group.status == "private" {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                            Text("Private")
                        }
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(themeColors.warning.opacity(0.2))
                        .foregroundColor(themeColors.warning)
                        .cornerRadius(4)
                    }
                }

                Spacer()
            }

            if let description = group.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(themeColors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(themeColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeColors.border, lineWidth: 1)
        )
    }
}
```

### Create Group View
```swift
struct CreateGroupView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColors) var themeColors
    @State private var name = ""
    @State private var description = ""
    @State private var isPrivate = false
    @State private var isCreating = false

    let onCreate: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("Group Details") {
                    TextField("Group Name", text: $name)
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }

                Section("Privacy") {
                    Toggle("Private Group", isOn: $isPrivate)
                    Text("Private groups require approval to join")
                        .font(.caption)
                        .foregroundColor(themeColors.textSecondary)
                }
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task { await createGroup() }
                    }
                    .disabled(name.isEmpty || isCreating)
                }
            }
        }
    }

    private func createGroup() async {
        isCreating = true
        do {
            _ = try await APIManager.shared.createGroup(
                name: name,
                description: description,
                status: isPrivate ? "private" : "public"
            )
            onCreate()
            dismiss()
        } catch {
            print("Failed to create group: \(error)")
            isCreating = false
        }
    }
}
```

## Usage Examples

### Load and Display Groups
```swift
class GroupsViewModel: ObservableObject {
    @Published var groups: [Group] = []
    @Published var isLoading = false

    func loadGroups() async {
        isLoading = true
        do {
            let response = try await APIManager.shared.getGroups(page: 1, perPage: 50)
            await MainActor.run {
                self.groups = response.groups
                self.isLoading = false
            }
        } catch {
            print("Error loading groups: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}
```

### Join a Group
```swift
func joinGroup(groupId: Int, userId: Int) async {
    do {
        let response = try await APIManager.shared.joinGroup(groupId: groupId, userId: userId)
        if response.success {
            print("Successfully joined group")
            // Refresh group data
        }
    } catch {
        print("Failed to join group: \(error)")
    }
}
```

## Features to Implement

1. **Group Discovery** - Browse and search public groups
2. **Group Feed** - Activity feed specific to group members
3. **Member Management** - Admin tools for managing members
4. **Invitations** - Invite friends to join groups
5. **Group Settings** - Edit group details and privacy settings
6. **Reading Lists** - Shared reading lists within groups
7. **Discussions** - Group-specific discussion threads
8. **Events** - Schedule book club meetings and events

## Best Practices

1. Cache group data locally for offline access
2. Use pagination for large member lists
3. Implement real-time updates for group activity
4. Add group notifications for new posts and events
5. Support group avatars and cover images
6. Implement role-based permissions (admin, moderator, member)
