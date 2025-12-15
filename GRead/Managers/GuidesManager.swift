import Foundation
import SwiftUI
import Combine

class GuidesManager: ObservableObject {
    static let shared = GuidesManager()

    @Published var guides: [Guide] = []
    @Published var categories: [GuideCategory] = []
    @Published var isLoading = false
    @Published var lastLoadTime: Date?

    private var hasLoadedOnce = false

    private init() {
        // Load local guides on initialization
        loadLocalGuides()
    }

    /// Load guides (local only - no server call)
    func loadGuidesIfNeeded() async {
        // Guides are loaded locally in init, no async needed
    }

    /// Force reload guides (local only - no server call)
    func loadGuides() async {
        // Guides are loaded locally in init, no async needed
    }

    /// Get featured guides (first 3 for dashboard)
    var featuredGuides: [Guide] {
        Array(guides.prefix(3))
    }

    // MARK: - Local Guides

    private func loadLocalGuides() {
        guides = [
            Guide(
                id: 1,
                title: "Getting Started",
                description: "Learn how to add books and start tracking your reading progress",
                icon: "book.fill",
                content: """
Welcome to GRead! Here's how to get started:

1. Add Books to Your Library
   • Tap the 📷 scan button on the dashboard
   • Scan a book's barcode with your camera
   • Or search for books manually

2. Track Your Progress
   • Tap on any book in your library
   • Update your current page number
   • Watch your stats grow!

3. Explore the Community
   • View the Activity Feed to see what others are reading
   • Share your own reading updates
   • Connect with fellow readers

4. Earn Achievements
   • Complete reading milestones
   • Unlock badges and rewards
   • Climb the leaderboards

Happy reading!
""",
                order: 1,
                category: "Basics"
            ),
            Guide(
                id: 2,
                title: "Adding Books",
                description: "Multiple ways to add books to your library",
                icon: "plus.circle.fill",
                content: """
There are several ways to add books to your library:

Scanning Barcodes:
   • Tap the scan button on the dashboard
   • Point your camera at the book's ISBN barcode
   • The book will be automatically added

Manual Search:
   • Use the search feature
   • Enter the book title or ISBN
   • Select from search results

Importing from Open Library:
   • Books are automatically enriched with cover images
   • ISBN lookup provides accurate book information
   • Cover images from Open Library API

Tips:
   • Make sure the barcode is well-lit for best results
   • If a book isn't found, try entering the ISBN manually
   • You can edit book details after adding
""",
                order: 2,
                category: "Library"
            ),
            Guide(
                id: 3,
                title: "Tracking Progress",
                description: "Keep track of your reading journey",
                icon: "chart.line.uptrend.xyaxis",
                content: """
Track your reading progress effectively:

Updating Page Numbers:
   • Tap on a book in your library
   • Tap "Update Progress"
   • Enter your current page number
   • Your progress percentage updates automatically

Reading Status:
   • Reading: Books you're currently reading
   • Paused: Books you've set aside
   • Completed: Finished books
   • DNF (Did Not Finish): Books you decided not to complete

Your Stats:
   • Books Completed: Total finished books
   • Pages Read: Total pages you've read
   • Points: Earned from reading achievements
   • Books Added: Total books in your library

View Detailed Stats:
   • Tap "View All" on the dashboard stats
   • See reading trends over time
   • Compare with friends (coming soon!)
""",
                order: 3,
                category: "Progress"
            ),
            Guide(
                id: 4,
                title: "Guest Mode vs Account",
                description: "Understanding the difference between trying the app and signing up",
                icon: "person.crop.circle.badge.questionmark",
                content: """
You can try GRead without signing up!

Guest Mode Features:
   ✓ Add books to your library (stored locally)
   ✓ Track reading progress
   ✓ View your local stats
   ✓ Browse the activity feed
   ✓ Explore all app features

What You Get with an Account:
   ☁️ Cloud Backup: Your data is saved to the cloud
   🔄 Sync Across Devices: Access your library anywhere
   🌐 Web Access: Use GRead on the web
   👥 Social Features: Connect with friends
   🏆 Global Achievements: Compete on leaderboards
   💾 Add Books to Database: Help build the community library

Your guest data is stored only on your device. When you sign up, you can choose to sync your local library to the cloud and never lose your reading progress!

Ready to sign up?
   • Tap your profile tab
   • Choose "Sign In or Create Account"
   • Your local library can be synced after signup
""",
                order: 4,
                category: "Account"
            ),
            Guide(
                id: 5,
                title: "Achievements & Points",
                description: "Earn rewards for your reading milestones",
                icon: "trophy.fill",
                content: """
Unlock achievements as you read:

How It Works:
   • Complete reading milestones
   • Earn points for each achievement
   • Track your progress toward unlocking badges

Achievement Categories:
   📚 Reading Milestones
      - First book completed
      - 10, 50, 100+ books read
      - Reading streaks

   📖 Page Turner
      - Total pages read milestones
      - Daily reading goals
      - Speed reading achievements

   🌟 Community
      - Sharing updates
      - Helping others find books
      - Active participation

   🎯 Special Achievements
      - Genre variety
      - Reading challenges
      - Seasonal events

Check the "Almost There" section on your dashboard to see which achievements you're closest to unlocking!
""",
                order: 5,
                category: "Features"
            ),
            Guide(
                id: 6,
                title: "Privacy & Data",
                description: "How we handle your reading data",
                icon: "lock.shield.fill",
                content: """
Your privacy matters to us:

Guest Mode:
   • All data stored locally on your device
   • No account required
   • No data sent to servers
   • You have complete control

With an Account:
   • Your library syncs to secure cloud storage
   • Reading progress backed up
   • Profile information you choose to share
   • Activity feed posts are public

What We Store:
   • Books in your library
   • Reading progress and stats
   • Profile information (if you have an account)
   • Activity feed posts

What We Don't Store:
   • We don't track what you're reading without permission
   • Your reading data is never sold
   • Guest mode data never leaves your device

Data Control:
   • Delete your account anytime
   • Export your data
   • Control what you share publicly

Questions? Contact us through the app settings.
""",
                order: 6,
                category: "Privacy"
            )
        ]

        hasLoadedOnce = true
        lastLoadTime = Date()
    }

    func clearCache() {
        // No cache to clear for local guides
    }
}
