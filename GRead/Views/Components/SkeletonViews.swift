import SwiftUI

// MARK: - Skeleton Loading Modifier
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    var duration: Double = 1.5

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            Color.white.opacity(0.3),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width)
                    .offset(x: phase * geometry.size.width)
                }
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: duration)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer(duration: Double = 1.5) -> some View {
        modifier(ShimmerEffect(duration: duration))
    }
}

// MARK: - Skeleton Activity Card
struct SkeletonActivityCard: View {
    @Environment(\.themeColors) var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(themeColors.textSecondary.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .shimmer()

                VStack(alignment: .leading, spacing: 6) {
                    // Username
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeColors.textSecondary.opacity(0.2))
                        .frame(width: 120, height: 14)
                        .shimmer()

                    // Date
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeColors.textSecondary.opacity(0.2))
                        .frame(width: 80, height: 12)
                        .shimmer()
                }

                Spacer()
            }

            // Content lines
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(themeColors.textSecondary.opacity(0.2))
                    .frame(height: 14)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(themeColors.textSecondary.opacity(0.2))
                    .frame(height: 14)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(themeColors.textSecondary.opacity(0.2))
                    .frame(width: 200, height: 14)
                    .shimmer()
            }

            // Action buttons
            HStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(themeColors.textSecondary.opacity(0.2))
                    .frame(width: 60, height: 12)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(themeColors.textSecondary.opacity(0.2))
                    .frame(width: 60, height: 12)
                    .shimmer()
            }
        }
        .padding()
        .background(themeColors.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Skeleton Stat Card
struct SkeletonStatCard: View {
    @Environment(\.themeColors) var themeColors

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(themeColors.textSecondary.opacity(0.2))
                    .frame(width: 24, height: 24)
                    .shimmer()
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(themeColors.textSecondary.opacity(0.2))
                    .frame(width: 60, height: 24)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(themeColors.textSecondary.opacity(0.2))
                    .frame(width: 80, height: 12)
                    .shimmer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(themeColors.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Skeleton Book Card
struct SkeletonBookCard: View {
    @Environment(\.themeColors) var themeColors

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            RoundedRectangle(cornerRadius: 4)
                .fill(themeColors.textSecondary.opacity(0.2))
                .frame(height: 16)
                .shimmer()

            RoundedRectangle(cornerRadius: 4)
                .fill(themeColors.textSecondary.opacity(0.2))
                .frame(width: 100, height: 16)
                .shimmer()

            // Author
            RoundedRectangle(cornerRadius: 4)
                .fill(themeColors.textSecondary.opacity(0.2))
                .frame(width: 120, height: 12)
                .shimmer()

            Spacer()

            // Progress bar
            RoundedRectangle(cornerRadius: 4)
                .fill(themeColors.textSecondary.opacity(0.2))
                .frame(height: 8)
                .shimmer()

            // Progress text
            RoundedRectangle(cornerRadius: 4)
                .fill(themeColors.textSecondary.opacity(0.2))
                .frame(width: 80, height: 10)
                .shimmer()
        }
        .padding()
        .frame(width: 160, height: 200)
        .background(themeColors.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Skeleton List
struct SkeletonListView: View {
    var count: Int = 5

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(0..<count, id: \.self) { _ in
                    SkeletonActivityCard()
                }
            }
            .padding()
        }
    }
}

#Preview("Skeleton Cards") {
    VStack(spacing: 20) {
        SkeletonActivityCard()
        SkeletonStatCard()
        SkeletonBookCard()
    }
    .padding()
}
