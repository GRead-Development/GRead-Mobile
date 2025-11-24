//
//  UniversalCard.swift
//  GRead
//
//  Created by Claude on 11/24/25.
//

import SwiftUI

struct UniversalCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 16
    var shadowRadius: CGFloat = 6

    @Environment(\.themeColors) var themeColors

    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 6,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(themeColors.cardBackground)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(themeColors.border, lineWidth: 1)
            )
            .shadow(
                color: themeColors.shadowColor,
                radius: shadowRadius,
                x: 0,
                y: 3
            )
    }
}
