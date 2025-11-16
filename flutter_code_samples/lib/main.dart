import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/landing_screen.dart';
import 'features/profile/providers/theme_provider.dart';
import 'shared/widgets/main_tab_view.dart';

/// Main entry point for GRead Flutter app
/// Mirrors iOS: GReadApp.swift
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared preferences
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Override SharedPreferences provider with actual instance
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const GReadApp(),
    ),
  );
}

class GReadApp extends ConsumerWidget {
  const GReadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme provider for dynamic theming
    final theme = ref.watch(themeProvider);

    return MaterialApp(
      title: 'GRead',
      debugShowCheckedModeBanner: false,

      // Dynamic theme from ThemeManager
      theme: theme,

      // Home screen based on auth state
      home: const AuthRouter(),
    );
  }
}

/// Router widget that determines initial screen based on auth state
/// Mirrors iOS: GReadApp ContentView logic
class AuthRouter extends ConsumerWidget {
  const AuthRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      // Loading state - show splash screen
      loading: () => const SplashScreen(),

      // Error state - show error screen
      error: (error, stack) => ErrorScreen(error: error.toString()),

      // Data state - route based on authentication
      data: (authData) {
        if (authData.isAuthenticated || authData.isGuest) {
          // User is authenticated or in guest mode - show main app
          return const MainTabView();
        } else {
          // User is not authenticated - show landing page
          return const LandingScreen();
        }
      },
    );
  }
}

/// Splash screen shown during initial auth check
/// Mirrors iOS: SplashScreenView
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            FlutterLogo(size: 120),
            SizedBox(height: 24),

            // Loading indicator
            CircularProgressIndicator(),
            SizedBox(height: 16),

            // App name
            Text(
              'GRead',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen for auth failures
class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 24),

              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                error,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {
                  // Retry initialization
                  // In real app, this would restart the app or retry auth check
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
