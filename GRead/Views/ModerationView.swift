//
//  ModerationView.swift
//  GRead
//
//  Created by apple on 11/8/25.
//

import SwiftUI

struct ModerationView: View {
    let userId: Int
    let userName: String

    @State private var isBlocked = false
    @State private var isMuted = false
    @State private var showReportSheet = false
    @State private var reportReason = ""
    @State private var isLoading = false
    @State private var successMessage: String?
    @State private var errorMessage: String?
    @State private var blockedList: [Int] = []
    @State private var mutedList: [Int] = []

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Moderation Actions")) {
                    // Block User
                    Button(action: { toggleBlockUser() }) {
                        HStack {
                            Image(systemName: isBlocked ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isBlocked ? .red : .gray)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(isBlocked ? "Blocked" : "Block User")
                                    .foregroundColor(.primary)
                                if isBlocked {
                                    Text("This user is blocked")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }

                            Spacer()

                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .disabled(isLoading)

                    // Mute User
                    Button(action: { toggleMuteUser() }) {
                        HStack {
                            Image(systemName: isMuted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isMuted ? .orange : .gray)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(isMuted ? "Muted" : "Mute User")
                                    .foregroundColor(.primary)
                                if isMuted {
                                    Text("You won't see this user's posts")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }

                            Spacer()

                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .disabled(isLoading)

                    // Report User
                    Button(action: { showReportSheet = true }) {
                        HStack {
                            Image(systemName: "flag.fill")
                                .foregroundColor(.red)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Report User")
                                    .foregroundColor(.red)
                                Text("Report inappropriate behavior")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .disabled(isLoading)
                }

                // Messages
                if let successMessage = successMessage {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(successMessage)
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 4)
                    }
                }

                if let errorMessage = errorMessage {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Moderation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showReportSheet) {
                ReportUserSheet(
                    userName: userName,
                    reason: $reportReason,
                    onSubmit: { submitReport() },
                    isLoading: isLoading
                )
            }
            .task {
                loadModerationLists()
            }
        }
    }

    private func toggleBlockUser() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                if isBlocked {
                    _ = try await APIManager.shared.unblockUser(userId: userId)
                    isBlocked = false
                    successMessage = "User unblocked"
                } else {
                    _ = try await APIManager.shared.blockUser(userId: userId)
                    isBlocked = true
                    successMessage = "User blocked"
                }
                errorMessage = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    successMessage = nil
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func toggleMuteUser() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                if isMuted {
                    _ = try await APIManager.shared.unmuteUser(userId: userId)
                    isMuted = false
                    successMessage = "User unmuted"
                } else {
                    _ = try await APIManager.shared.muteUser(userId: userId)
                    isMuted = true
                    successMessage = "User muted"
                }
                errorMessage = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    successMessage = nil
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func submitReport() {
        guard !reportReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please provide a reason for reporting"
            return
        }

        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                _ = try await APIManager.shared.reportUser(userId: userId, reason: reportReason)
                successMessage = "User reported. Thank you."
                reportReason = ""
                showReportSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    successMessage = nil
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func loadModerationLists() {
        Task {
            do {
                let blockedResponse = try await APIManager.shared.getBlockedList()
                blockedList = blockedResponse.blockedUsers
                isBlocked = blockedList.contains(userId)

                let mutedResponse = try await APIManager.shared.getMutedList()
                mutedList = mutedResponse.mutedUsers
                isMuted = mutedList.contains(userId)
            } catch {
                print("Error loading moderation lists: \(error)")
            }
        }
    }
}

// MARK: - Report User Sheet

struct ReportUserSheet: View {
    let userName: String
    @Binding var reason: String
    let onSubmit: () -> Void
    let isLoading: Bool

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Report \(userName)")) {
                    Text("Help us understand what's wrong")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Section(header: Text("Reason")) {
                    TextEditor(text: $reason)
                        .frame(minHeight: 120)
                        .disabled(isLoading)
                }

                Section {
                    Text("Please be as specific as possible. Your report helps us keep the community safe.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Report User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Submit") {
                            onSubmit()
                        }
                        .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }
}

#Preview {
    ModerationView(userId: 1, userName: "Example User")
}
