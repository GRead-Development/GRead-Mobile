import Foundation

// MARK: - Achievement Icon
struct AchievementIcon: Codable {
    let type: String
    let color: String
    let symbol: String
}

// MARK: - Unlock Requirements
struct UnlockRequirements: Codable {
    let metric: String
    let value: Int
    let condition: String
}

// MARK: - Achievement Progress
struct AchievementProgress: Codable {
    let current: Int
    let required: Int
    let percentage: Double
}

// MARK: - Achievement
struct Achievement: Codable, Identifiable {
    let id: Int
    let slug: String
    let name: String
    let description: String
    let icon: AchievementIcon
    let unlockRequirements: UnlockRequirements
    let reward: Int
    let isHidden: Bool
    let displayOrder: Int

    // Optional fields for user-specific achievement data
    let progress: AchievementProgress?
    let isUnlocked: Bool?
    let dateUnlocked: String?

    enum CodingKeys: String, CodingKey {
        case id, slug, name, description, icon, reward, progress
        case unlockRequirements = "unlock_requirements"
        case isHidden = "is_hidden"
        case displayOrder = "display_order"
        case isUnlocked = "is_unlocked"
        case dateUnlocked = "date_unlocked"
    }
}

// MARK: - User Achievements Response
struct UserAchievementsResponse: Codable {
    let userId: Int
    let total: Int
    let unlockedCount: Int
    let achievements: [Achievement]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case total
        case unlockedCount = "unlocked_count"
        case achievements
    }
}

// MARK: - Achievement Stats
struct AchievementStats: Codable {
    let totalAchievements: Int
    let totalUnlocks: Int
    let averageUnlocksPerAchievement: Double
    let mostUnlocked: AchievementStatEntry?
    let leastUnlocked: AchievementStatEntry?
    let topAchievers: [TopAchiever]

    enum CodingKeys: String, CodingKey {
        case totalAchievements = "total_achievements"
        case totalUnlocks = "total_unlocks"
        case averageUnlocksPerAchievement = "average_unlocks_per_achievement"
        case mostUnlocked = "most_unlocked"
        case leastUnlocked = "least_unlocked"
        case topAchievers = "top_achievers"
    }
}

struct AchievementStatEntry: Codable {
    let id: Int
    let name: String
    let slug: String
    let unlockCount: Int

    enum CodingKeys: String, CodingKey {
        case id, name, slug
        case unlockCount = "unlock_count"
    }
}

struct TopAchiever: Codable {
    let userId: Int
    let userName: String
    let achievementCount: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
        case achievementCount = "achievement_count"
    }
}

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Codable, Identifiable {
    var id: Int { userId }
    let rank: Int
    let userId: Int
    let userName: String
    let userAvatarUrl: String
    let achievementCount: Int

    enum CodingKeys: String, CodingKey {
        case rank
        case userId = "user_id"
        case userName = "user_name"
        case userAvatarUrl = "user_avatar_url"
        case achievementCount = "achievement_count"
    }
}
