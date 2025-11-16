import 'package:freezed_annotation/freezed_annotation.dart';

part 'cosmetics.freezed.dart';
part 'cosmetics.g.dart';

/// App theme model matching iOS AppTheme struct
@freezed
class AppTheme with _$AppTheme {
  const factory AppTheme({
    required String id,
    required String name,
    required String description,
    @JsonKey(name: 'primary_color') required String primaryColor,  // Hex color
    @JsonKey(name: 'secondary_color') required String secondaryColor,  // Hex color
    @JsonKey(name: 'accent_color') String? accentColor,  // Hex color
    @JsonKey(name: 'background_color') required String backgroundColor,  // Hex color
    @JsonKey(name: 'is_dark_theme') required bool isDarkTheme,
    @JsonKey(name: 'unlock_requirement') UnlockRequirement? unlockRequirement,
  }) = _AppTheme;

  factory AppTheme.fromJson(Map<String, dynamic> json) => _$AppThemeFromJson(json);
}

/// App font model matching iOS AppFont struct
@freezed
class AppFont with _$AppFont {
  const factory AppFont({
    required String id,
    required String name,
    required String description,
    @JsonKey(name: 'font_family') required String fontFamily,
    @JsonKey(name: 'unlock_requirement') UnlockRequirement? unlockRequirement,
  }) = _AppFont;

  factory AppFont.fromJson(Map<String, dynamic> json) => _$AppFontFromJson(json);
}

/// App icon model
@freezed
class AppIcon with _$AppIcon {
  const factory AppIcon({
    required String id,
    required String name,
    required String description,
    @JsonKey(name: 'icon_url') required String iconUrl,
    @JsonKey(name: 'unlock_requirement') UnlockRequirement? unlockRequirement,
  }) = _AppIcon;

  factory AppIcon.fromJson(Map<String, dynamic> json) => _$AppIconFromJson(json);
}

/// Unlock requirement for cosmetics
@freezed
class UnlockRequirement with _$UnlockRequirement {
  const factory UnlockRequirement({
    required String stat,  // "booksCompleted", "pagesRead", "points", etc.
    required int value,    // Required value to unlock
  }) = _UnlockRequirement;

  factory UnlockRequirement.fromJson(Map<String, dynamic> json) => _$UnlockRequirementFromJson(json);
}

/// User cosmetics state matching iOS UserCosmetics struct
@freezed
class UserCosmetics with _$UserCosmetics {
  const factory UserCosmetics({
    @JsonKey(name: 'active_theme') String? activeTheme,
    @JsonKey(name: 'active_icon') String? activeIcon,
    @JsonKey(name: 'active_font') String? activeFont,
    @JsonKey(name: 'unlocked_cosmetics') @Default([]) List<String> unlockedCosmetics,
  }) = _UserCosmetics;

  factory UserCosmetics.fromJson(Map<String, dynamic> json) => _$UserCosmeticsFromJson(json);
}
