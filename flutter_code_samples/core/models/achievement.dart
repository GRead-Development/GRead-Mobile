import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement.freezed.dart';
part 'achievement.g.dart';

/// Achievement model matching iOS Achievement struct
@freezed
class Achievement with _$Achievement {
  const factory Achievement({
    required int id,
    required String slug,
    required String name,
    required String description,
    required AchievementIcon icon,
    @JsonKey(name: 'unlock_requirements') required UnlockRequirements unlockRequirements,
    required int reward,
    AchievementProgress? progress,
    @JsonKey(name: 'is_unlocked') @Default(false) bool isUnlocked,
    @JsonKey(name: 'is_hidden') @Default(false) bool isHidden,
  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) => _$AchievementFromJson(json);
}

/// Achievement icon configuration
@freezed
class AchievementIcon with _$AchievementIcon {
  const factory AchievementIcon({
    required String symbol,
    required String color,
  }) = _AchievementIcon;

  factory AchievementIcon.fromJson(Map<String, dynamic> json) => _$AchievementIconFromJson(json);
}

/// Requirements to unlock an achievement
@freezed
class UnlockRequirements with _$UnlockRequirements {
  const factory UnlockRequirements({
    required String metric,  // e.g., "booksCompleted", "pagesRead"
    required int value,      // Required value to unlock
  }) = _UnlockRequirements;

  factory UnlockRequirements.fromJson(Map<String, dynamic> json) => _$UnlockRequirementsFromJson(json);
}

/// Progress towards unlocking an achievement
@freezed
class AchievementProgress with _$AchievementProgress {
  const factory AchievementProgress({
    required int current,
    required int required,
    required double percentage,
  }) = _AchievementProgress;

  factory AchievementProgress.fromJson(Map<String, dynamic> json) => _$AchievementProgressFromJson(json);
}

/// Leaderboard entry
@freezed
class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required int rank,
    @JsonKey(name: 'user_id') required int userId,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'achievements_count') required int achievementsCount,
    required int points,
  }) = _LeaderboardEntry;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => _$LeaderboardEntryFromJson(json);
}
