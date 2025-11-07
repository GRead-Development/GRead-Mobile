import Foundation
import SwiftUI

struct GroupsView: View {
    @State private var groups: [BPGroup] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading && groups.isEmpty {
                    ProgressView()
                } else if groups.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No groups found")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                } else {
                    List(groups) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            GroupRowView(group: group)
                        }
                    }
                    .refreshable {
                        await loadGroups()
                    }
                }
            }
            .navigationTitle("Groups")
            .task {
                await loadGroups()
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
        }
    }
    
    private func loadGroups() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // The API returns a dictionary with "groups" key
            let response: GroupsResponse = try await APIManager.shared.request(
                endpoint: "/groups?per_page=20"
            )
            await MainActor.run {
                groups = response.groups
                isLoading = false
            }
        } catch {
            print("Groups load error: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load groups: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

// New response model to match API structure
struct GroupsResponse: Codable {
    let groups: [BPGroup]
    let total: Int?
}

struct GroupRowView: View {
    let group: BPGroup
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: group.avatarUrls?.thumb ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 50, height: 50)
            .background(Color.blue.opacity(0.1))
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                
                if let desc = group.description?.rendered, !desc.isEmpty {
                    Text(desc.stripHTML())
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Text("\(group.totalMemberCount ?? 0) members")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct GroupDetailView: View {
    let group: BPGroup
    @State private var activities: [Activity] = []
    @State private var isLoading = false
    
    var body: some View {
        List {
            Section(header: Text("About")) {
                if let desc = group.description?.rendered, !desc.isEmpty {
                    Text(desc.stripHTML())
                }
                
                HStack {
                    Text("Members")
                    Spacer()
                    Text("\(group.totalMemberCount ?? 0)")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Status")
                    Spacer()
                    Text(group.status?.capitalized ?? "Public")
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("Activity")) {
                if isLoading {
                    ProgressView()
                } else if activities.isEmpty {
                    Text("No activity yet")
                        .foregroundColor(.gray)
                } else {
                    ForEach(activities) { activity in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(activity.displayName ?? "User \(activity.userId ?? 0)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                if let date = activity.dateRecorded {
                                    Text(date.toRelativeTime())
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            if let content = activity.content, !content.isEmpty {
                                Text(content.stripHTML())
                                    .font(.body)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadGroupActivity()
        }
    }
    
    private func loadGroupActivity() async {
        isLoading = true
        do {
            let response: ActivityResponse = try await APIManager.shared.request(
                endpoint: "/activity?group_id=\(group.id)&per_page=10"
            )
            await MainActor.run {
                activities = response.activities
                isLoading = false
            }
        } catch {
            print("Group activity error: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
}
