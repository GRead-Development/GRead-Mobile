import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/activity.dart';
import '../../auth/providers/auth_provider.dart';

/// Activities state with pagination support
class ActivitiesState {
  final List<Activity> activities;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const ActivitiesState({
    required this.activities,
    required this.isLoading,
    required this.hasMore,
    required this.currentPage,
    this.error,
  });

  ActivitiesState copyWith({
    List<Activity>? activities,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return ActivitiesState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error ?? this.error,
    );
  }
}

/// Activities notifier with infinite scroll support
/// Mirrors iOS: ActivityFeedView pagination logic
class ActivitiesNotifier extends StateNotifier<ActivitiesState> {
  final ApiClient _apiClient;
  static const int _perPage = 20;

  ActivitiesNotifier(this._apiClient)
      : super(const ActivitiesState(
          activities: [],
          isLoading: false,
          hasMore: true,
          currentPage: 1,
        )) {
    loadActivities();
  }

  /// Load activities (initial or refresh)
  /// Mirrors iOS: ActivityFeedView.loadActivities()
  Future<void> loadActivities({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = const ActivitiesState(
        activities: [],
        isLoading: true,
        hasMore: true,
        currentPage: 1,
      );
    } else {
      state = state.copyWith(isLoading: true);
    }

    try {
      final response = await _apiClient.get(
        ApiEndpoints.activities,
        queryParameters: {
          'per_page': _perPage,
          'page': refresh ? 1 : state.currentPage,
        },
      );

      final newActivities = (response as List)
          .map((json) => Activity.fromJson(json))
          .toList();

      if (refresh) {
        state = ActivitiesState(
          activities: newActivities,
          isLoading: false,
          hasMore: newActivities.length == _perPage,
          currentPage: 2,
        );
      } else {
        state = ActivitiesState(
          activities: [...state.activities, ...newActivities],
          isLoading: false,
          hasMore: newActivities.length == _perPage,
          currentPage: state.currentPage + 1,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more activities (infinite scroll)
  /// Mirrors iOS: ActivityFeedView scroll detection
  Future<void> loadMore() async {
    if (state.hasMore && !state.isLoading) {
      await loadActivities();
    }
  }

  /// Post new activity
  /// Mirrors iOS: PostActivitySheet.postActivity()
  Future<void> postActivity(String content) async {
    try {
      await _apiClient.post(
        ApiEndpoints.createActivity,
        data: {'content': content},
      );

      // Refresh feed after posting
      await loadActivities(refresh: true);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete activity
  Future<void> deleteActivity(int activityId) async {
    try {
      await _apiClient.delete(ApiEndpoints.deleteActivity(activityId));

      // Remove from local state
      state = state.copyWith(
        activities: state.activities.where((a) => a.id != activityId).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Post comment on activity
  Future<void> postComment(int activityId, String content) async {
    try {
      await _apiClient.post(
        ApiEndpoints.activityComments(activityId),
        data: {'content': content},
      );

      // Refresh to get new comment
      await loadActivities(refresh: true);
    } catch (e) {
      rethrow;
    }
  }
}

/// Activities provider
/// Usage:
///   final activitiesState = ref.watch(activitiesProvider);
///   if (activitiesState.isLoading && activitiesState.activities.isEmpty) {
///     return LoadingIndicator();
///   }
///   return ListView.builder(...);
final activitiesProvider = StateNotifierProvider<ActivitiesNotifier, ActivitiesState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ActivitiesNotifier(apiClient);
});
