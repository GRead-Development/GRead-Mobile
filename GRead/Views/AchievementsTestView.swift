//
//  AchievementsTestView.swift
//  GRead
//
//  Created by apple on 11/15/25.
//

import SwiftUI

/// Test view to verify achievement endpoints are working
struct AchievementsTestView: View {
    @State private var testResult = "Tap button to test endpoints"
    @State private var isLoading = false
    @Environment(\.themeColors) var themeColors

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Achievement Endpoint Tester")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(testResult)
                    .font(.body)
                    .foregroundColor(themeColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding()

                if isLoading {
                    ProgressView()
                }

                VStack(spacing: 12) {
                    Button("Test: Get All Achievements (Public)") {
                        testPublicEndpoint()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)

                    Button("Test: Get My Achievements (Auth)") {
                        testAuthEndpoint()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading)

                    Button("Test: Get Leaderboard (Public)") {
                        testLeaderboard()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading)
                }
            }
            .padding()
        }
        .navigationTitle("API Test")
    }

    private func testPublicEndpoint() {
        isLoading = true
        testResult = "Testing public endpoint..."

        Task {
            do {
                let achievements = try await APIManager.shared.getAllAchievements()
                testResult = "✅ SUCCESS! Got \(achievements.count) achievements\n\nEndpoint: /achievements\nStatus: Working"
            } catch let error as APIError {
                switch error {
                case .httpError(let code):
                    testResult = "❌ HTTP Error \(code)\n\nEndpoint: /achievements\nThis means the endpoint doesn't exist or returned an error."
                case .invalidURL:
                    testResult = "❌ Invalid URL"
                case .invalidResponse:
                    testResult = "❌ Invalid Response"
                case .emptyResponse:
                    testResult = "⚠️ Empty Response\n\nThe endpoint exists but returned no data."
                case .decodingError(let err):
                    testResult = "❌ Decoding Error\n\n\(err.localizedDescription)\n\nThe endpoint exists but the response format is wrong."
                }
            } catch {
                testResult = "❌ Error: \(error.localizedDescription)"
            }

            isLoading = false
        }
    }

    private func testAuthEndpoint() {
        isLoading = true
        testResult = "Testing authenticated endpoint..."

        Task {
            do {
                let result = try await APIManager.shared.getMyAchievements()
                testResult = "✅ SUCCESS! Got \(result.achievements.count) achievements\n\nEndpoint: /me/achievements\nStatus: Working\nUnlocked: \(result.unlockedCount)/\(result.total)"
            } catch let error as APIError {
                switch error {
                case .httpError(let code):
                    if code == 404 {
                        testResult = "❌ HTTP 404 Not Found\n\nEndpoint: /me/achievements\n\nThe achievement endpoints may not be deployed to the server yet."
                    } else if code == 401 || code == 403 {
                        testResult = "❌ HTTP \(code) Authentication Failed\n\nThe endpoint exists but authentication is failing."
                    } else {
                        testResult = "❌ HTTP Error \(code)\n\nEndpoint: /me/achievements"
                    }
                default:
                    testResult = "❌ Error: \(error.localizedDescription)"
                }
            } catch {
                testResult = "❌ Error: \(error.localizedDescription)"
            }

            isLoading = false
        }
    }

    private func testLeaderboard() {
        isLoading = true
        testResult = "Testing leaderboard endpoint..."

        Task {
            do {
                let leaderboard = try await APIManager.shared.getAchievementsLeaderboard()
                testResult = "✅ SUCCESS! Got \(leaderboard.count) entries\n\nEndpoint: /achievements/leaderboard\nStatus: Working"
            } catch let error as APIError {
                switch error {
                case .httpError(let code):
                    testResult = "❌ HTTP Error \(code)\n\nEndpoint: /achievements/leaderboard"
                default:
                    testResult = "❌ Error: \(error.localizedDescription)"
                }
            } catch {
                testResult = "❌ Error: \(error.localizedDescription)"
            }

            isLoading = false
        }
    }
}

#Preview {
    NavigationView {
        AchievementsTestView()
    }
}
