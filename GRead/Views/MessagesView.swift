//
//  MessagesView.swift
//  GRead
//
//  Created by apple on 11/6/25.
//

import UIKit
import SwiftUI
import Foundation

struct MessagesView: View {
    @Environment(\.themeColors) var themeColors
    @State private var messages: [Message] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            SwiftUI.Group {
                if isLoading && messages.isEmpty {
                    ProgressView()
                } else if messages.isEmpty {
                    Text("No messages")
                        .foregroundColor(themeColors.textSecondary)
                } else {
                    List(messages) { message in
                        NavigationLink(destination: MessageThreadView(message: message)) {
                            MessageRowView(message: message)
                        }
                    }
                    .refreshable {
                        await loadMessages()
                    }
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { /* New message */ }) {
                        Image(systemName: "square.and.pencil")
                    }
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
            let userId = AuthManager.shared.currentUser?.id ?? 0
            let response: [Message] = try await APIManager.shared.request(
                endpoint: "/messages?user_id=\(userId)&per_page=20"
            )
            await MainActor.run {
                messages = response
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct MessageRowView: View {
    let message: Message
    @Environment(\.themeColors) var themeColors

    var body: some View {
        HStack {
            Circle()
                .fill(message.unreadCount ?? 0 > 0 ? themeColors.primary : themeColors.textSecondary.opacity(0.3))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text((message.subject?.rendered ?? "No subject").decodingHTMLEntities)
                    .font(.headline)
                    .fontWeight(message.unreadCount ?? 0 > 0 ? .bold : .regular)

                if let content = message.message?.rendered {
                    Text(content.decodingHTMLEntities.stripHTML())
                        .font(.subheadline)
                        .foregroundColor(themeColors.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if let date = message.dateSent {
                Text(date.toRelativeTime())
                    .font(.caption)
                    .foregroundColor(themeColors.textSecondary)
            }
        }
    }
}

struct MessageThreadView: View {
    let message: Message
    @Environment(\.themeColors) var themeColors

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let content = message.message?.rendered {
                        Text(content.stripHTML())
                            .padding()
                            .background(themeColors.cardBackground)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            
            HStack {
                TextField("Type a message...", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: { /* Send message */ }) {
                    Image(systemName: "paperplane.fill")
                }
            }
            .padding()
        }
        .navigationTitle((message.subject?.rendered ?? "Message").decodingHTMLEntities)
        .navigationBarTitleDisplayMode(.inline)
    }
}
