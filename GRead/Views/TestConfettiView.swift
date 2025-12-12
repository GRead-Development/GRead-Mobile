//
//  TestConfettiView.swift
//  GRead
//
//  Created by apple on 12/11/25.
//

import SwiftUI

struct TestConfettiView: View {
    @State private var showConfetti = false
    @State private var confettiCount = 0
    @Environment(\.themeColors) var themeColors

    var body: some View {
        ZStack {
            themeColors.background.ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Confetti Test")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(themeColors.textPrimary)

                Text("Tap the button to celebrate!")
                    .font(.headline)
                    .foregroundColor(themeColors.textSecondary)

                Spacer()

                // Trophy icon that scales up with confetti
                ZStack {
                    Circle()
                        .fill(themeColors.primary.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundColor(themeColors.warning)
                }
                .scaleEffect(showConfetti ? 1.3 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showConfetti)

                Text("Celebrations: \(confettiCount)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeColors.textPrimary)
                    .padding()
                    .background(themeColors.cardBackground)
                    .cornerRadius(12)

                Spacer()

                // Test Button
                Button(action: {
                    triggerConfetti()
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Celebrate!")
                        Image(systemName: "sparkles")
                    }
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [themeColors.primary, themeColors.accent]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: themeColors.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(showConfetti ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showConfetti)
                .padding(.horizontal)

                // Different color sets
                HStack(spacing: 12) {
                    Button("Rainbow") {
                        triggerConfetti(colors: [.red, .orange, .yellow, .green, .blue, .purple])
                    }
                    .buttonStyle(ColorSetButtonStyle(color: .purple))

                    Button("Gold") {
                        triggerConfetti(colors: [
                            Color(red: 1.0, green: 0.84, blue: 0.0),
                            Color(red: 1.0, green: 0.65, blue: 0.0),
                            .yellow
                        ])
                    }
                    .buttonStyle(ColorSetButtonStyle(color: .yellow))

                    Button("Theme") {
                        triggerConfetti(colors: [
                            themeColors.primary,
                            themeColors.secondary,
                            themeColors.accent
                        ])
                    }
                    .buttonStyle(ColorSetButtonStyle(color: themeColors.primary))
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .confetti(
                isActive: $showConfetti,
                colors: currentColors,
                particleCount: 50,
                duration: 3.0
            )
        }
        .navigationTitle("Test Confetti")
        .navigationBarTitleDisplayMode(.inline)
    }

    @State private var currentColors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]

    private func triggerConfetti(colors: [Color]? = nil) {
        // Update colors if provided
        if let colors = colors {
            currentColors = colors
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Show confetti
        showConfetti = true
        confettiCount += 1
    }
}

// Custom button style for color set buttons
struct ColorSetButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(color)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    NavigationView {
        TestConfettiView()
            .environmentObject(ThemeManager.shared)
    }
}
