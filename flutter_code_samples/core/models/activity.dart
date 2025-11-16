import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity.freezed.dart';
part 'activity.g.dart';

/// Activity model matching iOS Activity struct
/// Represents a social activity in the feed (posts, updates, etc.)
@freezed
class Activity with _$Activity {
  const factory Activity({
    required int id,
    @JsonKey(name: 'user_id') int? userId,
    String? content,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'user_login') String? userLogin,
    @JsonKey(name: 'user_avatar') String? userAvatar,
    @JsonKey(name: 'date_recorded') String? dateRecorded,
    @JsonKey(name: 'type') String? type,
    @JsonKey(name: 'component') String? component,

    // Threading support for comments/replies
    List<Activity>? children,

    @JsonKey(name: 'reply_count') @Default(0) int replyCount,
    @JsonKey(name: 'is_favorite') @Default(false) bool isFavorite,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) => _$ActivityFromJson(json);
}

/// Activity comment (threaded reply)
@freezed
class ActivityComment with _$ActivityComment {
  const factory ActivityComment({
    required int id,
    @JsonKey(name: 'activity_id') required int activityId,
    @JsonKey(name: 'user_id') required int userId,
    required String content,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'user_avatar') String? userAvatar,
    @JsonKey(name: 'date_recorded') String? dateRecorded,
  }) = _ActivityComment;

  factory ActivityComment.fromJson(Map<String, dynamic> json) => _$ActivityCommentFromJson(json);
}
