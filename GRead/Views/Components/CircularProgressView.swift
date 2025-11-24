//
//  CircularProgressView.swift
//  GRead
//
//  Created by Claude on 11/24/25.
//

import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0), value: progress)
        }
    }
}

struct AnimatedStatCard: View {
    let value: Int
    let total: Int
    let label: String
    let icon: String
    let color: Color

    @Environment(\.themeColors) var themeColors

    var progress: Double {
        total > 0 ? Double(value) / Double(total) : 0
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                CircularProgressView(
                    progress: progress,
                    lineWidth: 8,
                    color: color
                )
                .frame(width: 80, height: 80)

                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)

                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(themeColors.textPrimary)
                }
            }

            Text(label)
                .font(.caption)
                .foregroundColor(themeColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}
