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
    @State private var showingSearch = false
    @Environment(\.themeColors) var themeColors
    let hapticFeedback = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                ActivityFeedView()
                    .environmentObject(authManager)
                    .tag(0)
                    .tabItem {
                        Label("Activity", systemImage: "flame.fill")
                    }

                LibraryView()
                    .environmentObject(authManager)
                    .tag(1)
                    .tabItem {
                        Label("Library", systemImage: "books.vertical.fill")
                    }

                NotificationsView()
                    .tag(2)
                    .tabItem {
                        Label("Notifications", systemImage: "bell.fill")
                    }

                if authManager.isAuthenticated {
                    ProfileView()
                        .tag(3)
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                } else {
                    GuestProfileView()
                        .environmentObject(authManager)
                        .tag(3)
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                }
            }
            .onChange(of: selectedTab) { _ in
                hapticFeedback.impactOccurred()
            }
            .accentColor(themeColors.primary)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSearch = true }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(themeColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingSearch) {
                UserSearchView()
                    .environmentObject(authManager)
            }

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
    }
}
