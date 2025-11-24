//
//  FloatingActionButton.swift
//  GRead
//
//  Created by Claude on 11/24/25.
//

import SwiftUI

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void

    @Environment(\.themeColors) var themeColors
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(
                        colors: [themeColors.primary, themeColors.primary.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(
                    color: themeColors.primary.opacity(0.4),
                    radius: isPressed ? 4 : 12,
                    x: 0,
                    y: isPressed ? 2 : 6
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}
