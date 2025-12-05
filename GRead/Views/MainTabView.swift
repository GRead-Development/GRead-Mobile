//
//  MainTabView.swift
//  GRead
//
//  Created by apple on 11/6/25.
//

import SwiftUI


struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab: Int = 0
    @State private var showingProfile = false
    @Environment(\.themeColors) var themeColors
    @State private var lastHapticTab: Int = -1
    let hapticFeedback = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Background color that extends into safe areas
                themeColors.background
                    .ignoresSafeArea()

                TabView(selection: $selectedTab) {
                DashboardView()
                    .environmentObject(authManager)
                    .tag(0)

                ActivityFeedView()
                    .environmentObject(authManager)
                    .tag(1)

                LibraryView()
                    .environmentObject(authManager)
                    .tag(2)

                if authManager.isAuthenticated {
                    ProfileView()
                        .tag(3)
                } else {
                    GuestProfileView()
                        .environmentObject(authManager)
                        .tag(3)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: selectedTab) { newValue in
                // Only trigger haptic if tab actually changed
                if lastHapticTab != newValue {
                    hapticFeedback.impactOccurred()
                    lastHapticTab = newValue
                }
            }

            // Custom Frosted Glass Tab Bar
            VStack(spacing: 0) {
                Divider()
                    .background(Color.gray.opacity(0.3))

                HStack(spacing: 0) {
                    CustomTabButton(icon: "house.fill", label: "Home", isSelected: selectedTab == 0) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTab = 0
                        }
                    }

                    CustomTabButton(icon: "flame.fill", label: "Activity", isSelected: selectedTab == 1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTab = 1
                        }
                    }

                    CustomTabButton(icon: "books.vertical.fill", label: "Library", isSelected: selectedTab == 2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTab = 2
                        }
                    }

                    CustomTabButton(icon: "person.fill", label: "Profile", isSelected: selectedTab == 3) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTab = 3
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .background(.ultraThinMaterial)
            .edgesIgnoringSafeArea(.bottom)

            // Login prompt overlay for guest users trying to post
            if authManager.isGuestMode {
                VStack {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(themeColors.primary)
                        Text("Sign in to post and interact")
                            .font(.caption)
                            .foregroundColor(themeColors.textSecondary)
                        Spacer()
                    }
                    .padding()
                    .background(themeColors.primary.opacity(0.1))
                    .cornerRadius(10)
                    .padding()

                    Spacer()
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(false)
            }
        }
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Custom Tab Button
struct CustomTabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.themeColors) var themeColors

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? themeColors.primary : themeColors.textSecondary)

                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? themeColors.primary : themeColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
