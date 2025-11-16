import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/cosmetics.dart';
import '../../auth/providers/auth_provider.dart';

/// Theme service for managing cosmetics
/// Mirrors iOS: ThemeManager functionality
class ThemeService {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  static const String _themeKey = 'active_theme';
  static const String _fontKey = 'active_font';

  ThemeService(this._apiClient, this._prefs);

  /// Fetch available themes
  Future<List<AppTheme>> getAvailableThemes() async {
    final response = await _apiClient.get(ApiEndpoints.themes);
    return (response as List).map((json) => AppTheme.fromJson(json)).toList();
  }

  /// Get current theme ID
  String? getCurrentThemeId() {
    return _prefs.getString(_themeKey);
  }

  /// Set active theme
  Future<void> setTheme(String themeId) async {
    await _apiClient.post(
      ApiEndpoints.setTheme,
      data: {'theme_id': themeId},
    );

    await _prefs.setString(_themeKey, themeId);
  }

  /// Convert AppTheme to Flutter ThemeData
  /// Mirrors iOS: ThemeColors struct
  ThemeData toThemeData(AppTheme appTheme) {
    final primaryColor = _parseColor(appTheme.primaryColor);
    final secondaryColor = _parseColor(appTheme.secondaryColor);
    final backgroundColor = _parseColor(appTheme.backgroundColor);
    final accentColor = appTheme.accentColor != null
        ? _parseColor(appTheme.accentColor!)
        : primaryColor;

    return ThemeData(
      useMaterial3: true,
      brightness: appTheme.isDarkTheme ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme(
        brightness: appTheme.isDarkTheme ? Brightness.dark : Brightness.light,
        primary: primaryColor,
        onPrimary: appTheme.isDarkTheme ? Colors.black : Colors.white,
        secondary: secondaryColor,
        onSecondary: appTheme.isDarkTheme ? Colors.black : Colors.white,
        tertiary: accentColor,
        onTertiary: appTheme.isDarkTheme ? Colors.black : Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: backgroundColor,
        onSurface: appTheme.isDarkTheme ? Colors.white : Colors.black,
      ),
      scaffoldBackgroundColor: backgroundColor,
    );
  }

  /// Parse hex color string to Color
  /// Mirrors iOS: Color(hex:) extension
  Color _parseColor(String hex) {
    // Remove # if present
    final hexCode = hex.replaceAll('#', '');

    // Add alpha channel if not present
    final colorHex = hexCode.length == 6 ? 'FF$hexCode' : hexCode;

    return Color(int.parse('0x$colorHex'));
  }
}

/// Theme notifier
/// Mirrors iOS: ThemeManager ObservableObject
class ThemeNotifier extends StateNotifier<ThemeData> {
  final ThemeService _themeService;
  AppTheme? _currentAppTheme;

  ThemeNotifier(this._themeService) : super(ThemeData.light()) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final themes = await _themeService.getAvailableThemes();
      final currentThemeId = _themeService.getCurrentThemeId();

      if (currentThemeId != null) {
        final theme = themes.firstWhere(
          (t) => t.id == currentThemeId,
          orElse: () => themes.first,
        );
        _currentAppTheme = theme;
        state = _themeService.toThemeData(theme);
      } else if (themes.isNotEmpty) {
        _currentAppTheme = themes.first;
        state = _themeService.toThemeData(themes.first);
      }
    } catch (e) {
      // Use default theme on error
      state = ThemeData.light();
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    await _themeService.setTheme(theme.id);
    _currentAppTheme = theme;
    state = _themeService.toThemeData(theme);
  }

  AppTheme? get currentAppTheme => _currentAppTheme;
}

// Providers

/// Shared preferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

/// Theme service provider
final themeServiceProvider = Provider<ThemeService>((ref) {
  return ThemeService(
    ref.watch(apiClientProvider),
    ref.watch(sharedPreferencesProvider),
  );
});

/// Main theme provider
/// Usage in MaterialApp:
///   final theme = ref.watch(themeProvider);
///   return MaterialApp(theme: theme, ...);
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeData>((ref) {
  return ThemeNotifier(ref.watch(themeServiceProvider));
});

/// Current app theme provider (for theme selection UI)
final currentAppThemeProvider = Provider<AppTheme?>((ref) {
  return ref.watch(themeProvider.notifier).currentAppTheme;
});

/// Available themes provider
final availableThemesProvider = FutureProvider<List<AppTheme>>((ref) async {
  final service = ref.watch(themeServiceProvider);
  return service.getAvailableThemes();
});
