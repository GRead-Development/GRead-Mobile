//
//  ParallaxView.swift
//  GRead
//
//  Created by apple on 12/11/25.
//

import SwiftUI

// MARK: - Parallax Modifier
struct ParallaxMotionModifier: ViewModifier {
    let magnitude: CGFloat
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .offset(y: offset)
                .onChange(of: geometry.frame(in: .global).minY) { newValue in
                    // Calculate parallax offset based on scroll position
                    offset = -newValue * magnitude
                }
        }
    }
}

// MARK: - Scroll-based Parallax Modifier
struct ScrollParallaxModifier: ViewModifier {
    let magnitude: CGFloat
    let coordinateSpace: String

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            let offset = geometry.frame(in: .named(coordinateSpace)).minY

            content
                .offset(y: offset * magnitude)
        }
    }
}

// MARK: - View Extensions
extension View {
    /// Adds a parallax effect that responds to the view's position in the scroll view
    /// - Parameter magnitude: The strength of the parallax effect (0.0 - 1.0). Lower values = slower movement
    func parallax(magnitude: CGFloat = 0.3) -> some View {
        self.modifier(ParallaxMotionModifier(magnitude: magnitude))
    }

    /// Adds a parallax effect based on scroll position in a named coordinate space
    /// - Parameters:
    ///   - coordinateSpace: The name of the coordinate space to track
    ///   - magnitude: The strength of the parallax effect (0.0 - 1.0)
    func scrollParallax(coordinateSpace: String = "scroll", magnitude: CGFloat = 0.3) -> some View {
        self.modifier(ScrollParallaxModifier(magnitude: magnitude, coordinateSpace: coordinateSpace))
    }
}

// MARK: - Parallax Header
struct ParallaxHeader<Content: View>: View {
    let content: Content
    let height: CGFloat
    let coordinateSpace: String

    init(height: CGFloat = 200, coordinateSpace: String = "scroll", @ViewBuilder content: () -> Content) {
        self.height = height
        self.coordinateSpace = coordinateSpace
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            let offset = geometry.frame(in: .named(coordinateSpace)).minY
            let heightMultiplier = offset > 0 ? 1 + (offset / height) : 1
            let yOffset = offset > 0 ? -offset : 0

            content
                .frame(width: geometry.size.width, height: height * heightMultiplier)
                .offset(y: yOffset)
        }
        .frame(height: height)
    }
}

// MARK: - Layered Parallax Container
struct LayeredParallaxView<Background: View, Foreground: View>: View {
    let background: Background
    let foreground: Foreground
    let coordinateSpace: String

    init(coordinateSpace: String = "scroll", @ViewBuilder background: () -> Background, @ViewBuilder foreground: () -> Foreground) {
        self.coordinateSpace = coordinateSpace
        self.background = background()
        self.foreground = foreground()
    }

    var body: some View {
        ZStack {
            background
                .scrollParallax(coordinateSpace: coordinateSpace, magnitude: 0.5)

            foreground
                .scrollParallax(coordinateSpace: coordinateSpace, magnitude: 0.2)
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 0) {
            // Parallax Header Example
            ParallaxHeader(height: 250, coordinateSpace: "scroll") {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [.purple, .pink]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    VStack {
                        Image(systemName: "book.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)

                        Text("Parallax Demo")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }

            // Content with layered parallax
            VStack(spacing: 20) {
                ForEach(0..<10) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 100)
                            .scrollParallax(coordinateSpace: "scroll", magnitude: CGFloat(index) * 0.02)

                        Text("Card \(index + 1)")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    .coordinateSpace(name: "scroll")
}
