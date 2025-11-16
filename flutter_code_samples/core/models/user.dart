import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// User model matching iOS User struct
/// Represents a BuddyPress user
@freezed
class User with _$User {
  const factory User({
    required int id,
    required String name,
    @JsonKey(name: 'user_login') String? userLogin,
    @JsonKey(name: 'avatar_urls') AvatarUrls? avatarUrls,
    @JsonKey(name: 'member_types') List<String>? memberTypes,
    @JsonKey(name: 'registered_date') String? registeredDate,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

/// Avatar URLs for different sizes
@freezed
class AvatarUrls with _$AvatarUrls {
  const factory AvatarUrls({
    String? thumb,
    String? full,
  }) = _AvatarUrls;

  factory AvatarUrls.fromJson(Map<String, dynamic> json) => _$AvatarUrlsFromJson(json);
}

/// User statistics matching iOS UserStats struct
@freezed
class UserStats with _$UserStats {
  const factory UserStats({
    required int id,
    required int points,
    @JsonKey(name: 'books_completed') required int booksCompleted,
    @JsonKey(name: 'pages_read') required int pagesRead,
    @JsonKey(name: 'books_added') required int booksAdded,
    @JsonKey(name: 'approved_reports') required int approvedReports,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'avatar_url') required String avatarUrl,
  }) = _UserStats;

  factory UserStats.fromJson(Map<String, dynamic> json) => _$UserStatsFromJson(json);
}
