//
//  ViewExtensions.swift
//  GRead
//
//  Created by Claude on 11/24/25.
//

import SwiftUI

// MARK: - Badge Modifier
struct BadgeModifier: ViewModifier {
    let count: Int
    let color: Color

    func body(content: Content) -> some View {
        ZStack(alignment: .topTrailing) {
            content

            if count > 0 {
                Text("\(min(count, 99))\(count > 99 ? "+" : "")")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(4)
                    .frame(minWidth: 20)
                    .background(color)
                    .clipShape(Circle())
                    .offset(x: 8, y: -8)
            }
        }
    }
}

extension View {
    func badge(count: Int, color: Color = .red) -> some View {
        modifier(BadgeModifier(count: count, color: color))
    }
}
