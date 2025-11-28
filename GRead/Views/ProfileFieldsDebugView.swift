import SwiftUI

struct ProfileFieldsDebugView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.themeColors) var themeColors
    @State private var profile: UserProfile?
    @State private var xprofileFields: [XProfileField] = []
    @State private var xprofileGroups: [XProfileGroup] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var rawProfileResponse: String?
    @State private var rawXProfileResponse: String?
    @State private var rawGroupsResponse: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Basic Profile Section
                    SectionHeader(title: "Basic Profile", icon: "person.fill")

                    if let profile = profile {
                        DebugCard(title: "Profile Data") {
                            DebugRow(label: "ID", value: "\(profile.id)")
                            DebugRow(label: "Display Name", value: profile.displayName)
                            DebugRow(label: "Bio", value: profile.bio ?? "None")
                            DebugRow(label: "Website", value: profile.website ?? "None")
                            DebugRow(label: "Location", value: profile.location ?? "None")
                            DebugRow(label: "Avatar URL", value: profile.avatarUrl ?? "None")
                        }
                    } else if !isLoading {
                        Text("No profile data loaded")
                            .foregroundColor(themeColors.textSecondary)
                            .padding()
                    }

                    // Extended Profile Fields Section
                    SectionHeader(title: "Extended Profile Fields", icon: "list.bullet.rectangle")

                    if !xprofileFields.isEmpty {
                        ForEach(xprofileFields) { field in
                            DebugCard(title: field.name) {
                                DebugRow(label: "ID", value: "\(field.id)")
                                DebugRow(label: "Type", value: field.type)
                                DebugRow(label: "Value", value: field.value ?? "Empty")
                                DebugRow(label: "Group", value: field.group)
                                DebugRow(label: "Group ID", value: "\(field.groupId)")
                                if let description = field.description {
                                    DebugRow(label: "Description", value: description)
                                }
                                if let order = field.order {
                                    DebugRow(label: "Order", value: "\(order)")
                                }
                                if let canDelete = field.canDelete {
                                    DebugRow(label: "Can Delete", value: canDelete == 1 ? "Yes" : "No")
                                }
                                if let isRequired = field.isRequired {
                                    DebugRow(label: "Required", value: isRequired == 1 ? "Yes" : "No")
                                }
                            }
                        }
                    } else if !isLoading {
                        Text("No extended fields found")
                            .foregroundColor(themeColors.textSecondary)
                            .padding()
                    }

                    // Profile Groups Section
                    SectionHeader(title: "Profile Field Groups", icon: "folder.fill")

                    if !xprofileGroups.isEmpty {
                        ForEach(xprofileGroups) { group in
                            DebugCard(title: group.name) {
                                DebugRow(label: "ID", value: "\(group.id)")
                                DebugRow(label: "Description", value: group.description ?? "None")
                                DebugRow(label: "Can Delete", value: group.canDelete == 1 ? "Yes" : "No")
                                DebugRow(label: "Fields Count", value: "\(group.fields.count)")

                                if !group.fields.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Fields:")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(themeColors.textSecondary)
                                        ForEach(group.fields) { field in
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("• \(field.name) (\(field.type))")
                                                    .font(.caption)
                                                    .foregroundColor(themeColors.textSecondary)
                                                if let desc = field.description, !desc.isEmpty {
                                                    Text("  \(desc)")
                                                        .font(.caption2)
                                                        .foregroundColor(themeColors.textSecondary.opacity(0.7))
                                                }
                                            }
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                    } else if !isLoading {
                        Text("No field groups found")
                            .foregroundColor(themeColors.textSecondary)
                            .padding()
                    }

                    // Raw API Responses Section
                    SectionHeader(title: "Raw API Responses", icon: "doc.text.fill")

                    if let rawProfileResponse = rawProfileResponse {
                        DebugCard(title: "Profile Response") {
                            Text(rawProfileResponse)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(themeColors.textSecondary)
                                .textSelection(.enabled)
                        }
                    }

                    if let rawXProfileResponse = rawXProfileResponse {
                        DebugCard(title: "XProfile Fields Response") {
                            Text(rawXProfileResponse)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(themeColors.textSecondary)
                                .textSelection(.enabled)
                        }
                    }

                    if let rawGroupsResponse = rawGroupsResponse {
                        DebugCard(title: "XProfile Groups Response") {
                            Text(rawGroupsResponse)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(themeColors.textSecondary)
                                .textSelection(.enabled)
                        }
                    }

                    // Error Message
                    if let errorMessage = errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(themeColors.error)
                                Text("Error")
                                    .font(.headline)
                                    .foregroundColor(themeColors.error)
                            }
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(themeColors.textSecondary)
                        }
                        .padding()
                        .background(themeColors.error.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Bottom padding for tab bar
                    Color.clear
                        .frame(height: 80)
                }
                .padding()
            }
            .background(themeColors.background)
            .navigationTitle("Profile Fields Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await loadAllData()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .tint(themeColors.primary)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(themeColors.primary)
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .task {
                await loadAllData()
            }
        }
    }

    private func loadAllData() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            rawProfileResponse = nil
            rawXProfileResponse = nil
            rawGroupsResponse = nil
        }

        // Load basic profile
        do {
            let raw = try await fetchRawResponse(endpoint: "/me/profile")
            print("========== PROFILE API RESPONSE START ==========")
            print(raw)
            print("========== PROFILE API RESPONSE END ==========")

            await MainActor.run {
                rawProfileResponse = raw
            }

            let profileData = try await APIManager.shared.getMyProfile()
            await MainActor.run {
                profile = profileData
            }
        } catch {
            print("========== PROFILE API ERROR ==========")
            print(error)
            print("========================================")

            await MainActor.run {
                errorMessage = "Failed to load profile: \(error.localizedDescription)"
            }
        }

        // Load extended profile fields
        do {
            let raw = try await fetchRawResponse(endpoint: "/me/xprofile/fields")
            print("========== XPROFILE FIELDS API RESPONSE START ==========")
            print(raw)
            print("========== XPROFILE FIELDS API RESPONSE END ==========")

            await MainActor.run {
                rawXProfileResponse = raw
            }

            let fields = try await APIManager.shared.getXProfileFields()
            await MainActor.run {
                xprofileFields = fields
            }
        } catch {
            print("========== XPROFILE FIELDS API ERROR ==========")
            print(error)
            print("================================================")

            await MainActor.run {
                if errorMessage == nil {
                    errorMessage = "Failed to load xprofile fields: \(error.localizedDescription)"
                } else {
                    errorMessage! += "\n\nFailed to load xprofile fields: \(error.localizedDescription)"
                }
            }
        }

        // Load xprofile groups
        do {
            let raw = try await fetchRawResponse(endpoint: "/xprofile/groups")
            print("========== XPROFILE GROUPS API RESPONSE START ==========")
            print(raw)
            print("========== XPROFILE GROUPS API RESPONSE END ==========")

            await MainActor.run {
                rawGroupsResponse = raw
            }

            let groups = try await APIManager.shared.getXProfileGroups()
            await MainActor.run {
                xprofileGroups = groups
            }
        } catch {
            print("========== XPROFILE GROUPS API ERROR ==========")
            print(error)
            print("================================================")

            await MainActor.run {
                if errorMessage == nil {
                    errorMessage = "Failed to load xprofile groups: \(error.localizedDescription)"
                } else {
                    errorMessage! += "\n\nFailed to load xprofile groups: \(error.localizedDescription)"
                }
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    private func fetchRawResponse(endpoint: String) async throws -> String {
        guard let url = URL(string: "https://gread.fun/wp-json/gread/v1" + endpoint) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authManager.jwtToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, _) = try await URLSession.shared.data(for: request)

        if let jsonString = String(data: data, encoding: .utf8) {
            // Pretty print the JSON
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                return prettyString
            }
            return jsonString
        }

        return "Unable to decode response"
    }
}

// MARK: - Helper Views

struct SectionHeader: View {
    let title: String
    let icon: String
    @Environment(\.themeColors) var themeColors

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(themeColors.primary)
            Text(title)
                .font(.headline)
                .foregroundColor(themeColors.textPrimary)
        }
        .padding(.top, 8)
    }
}

struct DebugCard<Content: View>: View {
    let title: String
    let content: Content
    @Environment(\.themeColors) var themeColors

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(themeColors.textPrimary)

            content
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

struct DebugRow: View {
    let label: String
    let value: String
    @Environment(\.themeColors) var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(themeColors.textSecondary)
            Text(value)
                .font(.body)
                .foregroundColor(themeColors.textPrimary)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    ProfileFieldsDebugView()
        .environmentObject(AuthManager.shared)
}
