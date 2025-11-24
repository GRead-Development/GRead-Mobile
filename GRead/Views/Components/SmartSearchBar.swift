//
//  SmartSearchBar.swift
//  GRead
//
//  Created by Claude on 11/24/25.
//

import SwiftUI

struct SmartSearchBar: View {
    @Binding var text: String
    @State private var isEditing = false
    @Environment(\.themeColors) var themeColors

    var placeholder: String = "Search..."
    var onSearch: (String) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeColors.textSecondary)
                    .animation(.easeInOut, value: isEditing)

                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .foregroundColor(themeColors.textPrimary)
                    .onSubmit {
                        onSearch(text)
                    }

                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeColors.textSecondary)
                    }
                    .transition(.scale)
                }
            }
            .padding(10)
            .background(themeColors.inputBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isEditing ? themeColors.primary : Color.clear,
                        lineWidth: 2
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isEditing)

            if isEditing {
                Button("Cancel") {
                    text = ""
                    isEditing = false
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
                .foregroundColor(themeColors.primary)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .onChange(of: text) { newValue in
            isEditing = !newValue.isEmpty
        }
        .animation(.easeInOut(duration: 0.2), value: isEditing)
    }
}
