//
//  ConfettiView.swift
//  GRead
//
//  Created by apple on 12/11/25.
//

import SwiftUI

// MARK: - Confetti Particle Model
struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var scale: CGFloat
    var rotation: Double
    var velocity: CGPoint
    var opacity: Double = 1.0
}

// MARK: - Confetti View Modifier
struct ConfettiModifier: ViewModifier {
    @Binding var isActive: Bool
    @State private var particles: [ConfettiParticle] = []
    @State private var timer: Timer?

    let colors: [Color]
    let particleCount: Int
    let duration: Double

    init(isActive: Binding<Bool>, colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink], particleCount: Int = 50, duration: Double = 3.0) {
        self._isActive = isActive
        self.colors = colors
        self.particleCount = particleCount
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    ZStack {
                        ForEach(particles) { particle in
                            Circle()
                                .fill(particle.color)
                                .frame(width: 8 * particle.scale, height: 8 * particle.scale)
                                .rotationEffect(.degrees(particle.rotation))
                                .opacity(particle.opacity)
                                .position(x: particle.x, y: particle.y)
                        }
                    }
                }
                .allowsHitTesting(false)
            )
            .onChange(of: isActive) { active in
                if active {
                    startConfetti()
                }
            }
    }

    private func startConfetti() {
        // Create initial particles
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                x: UIScreen.main.bounds.width / 2,
                y: UIScreen.main.bounds.height / 2,
                color: colors.randomElement() ?? .pink,
                scale: CGFloat.random(in: 0.5...1.5),
                rotation: Double.random(in: 0...360),
                velocity: CGPoint(
                    x: CGFloat.random(in: -200...200),
                    y: CGFloat.random(in: -300...(-100))
                )
            )
        }

        // Animate particles
        withAnimation(.easeOut(duration: duration)) {
            particles = particles.map { particle in
                var updated = particle
                updated.y = UIScreen.main.bounds.height + 100
                updated.x += particle.velocity.x
                updated.opacity = 0
                updated.rotation += Double.random(in: 360...720)
                return updated
            }
        }

        // Clear particles after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            particles.removeAll()
            isActive = false
        }
    }
}

// MARK: - View Extension
extension View {
    func confetti(isActive: Binding<Bool>, colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink], particleCount: Int = 50, duration: Double = 3.0) -> some View {
        self.modifier(ConfettiModifier(isActive: isActive, colors: colors, particleCount: particleCount, duration: duration))
    }
}

// MARK: - Standalone Confetti View
struct ConfettiView: View {
    @Binding var isActive: Bool
    let colors: [Color]
    let particleCount: Int
    let duration: Double

    init(isActive: Binding<Bool>, colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink], particleCount: Int = 50, duration: Double = 3.0) {
        self._isActive = isActive
        self.colors = colors
        self.particleCount = particleCount
        self.duration = duration
    }

    var body: some View {
        Color.clear
            .confetti(isActive: $isActive, colors: colors, particleCount: particleCount, duration: duration)
    }
}

// MARK: - Preview
#Preview {
    struct ConfettiPreview: View {
        @State private var showConfetti = false

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack {
                    Button("Celebrate!") {
                        showConfetti = true
                    }
                    .padding()
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .confetti(isActive: $showConfetti)
            }
        }
    }

    return ConfettiPreview()
}
