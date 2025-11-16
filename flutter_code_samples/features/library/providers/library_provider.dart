import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/book.dart';
import '../../auth/providers/auth_provider.dart';

/// Library items notifier
/// Mirrors iOS: LibraryView functionality
class LibraryNotifier extends StateNotifier<AsyncValue<List<LibraryItem>>> {
  final ApiClient _apiClient;

  LibraryNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    loadLibrary();
  }

  /// Load user's library
  /// Mirrors iOS: LibraryView.loadLibrary()
  Future<void> loadLibrary() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.get(ApiEndpoints.library);
      final items = (response as List)
          .map((json) => LibraryItem.fromJson(json))
          .toList();

      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Add book to library
  Future<void> addBook(int bookId, {String status = 'planned'}) async {
    try {
      await _apiClient.post(
        ApiEndpoints.addToLibrary,
        data: {
          'book_id': bookId,
          'status': status,
          'current_page': 0,
        },
      );

      await loadLibrary();
    } catch (e) {
      rethrow;
    }
  }

  /// Update reading progress
  /// Mirrors iOS: LibraryView.updateProgress()
  Future<void> updateProgress(int itemId, int currentPage) async {
    try {
      await _apiClient.put(
        ApiEndpoints.updateLibraryItem(itemId),
        data: {'current_page': currentPage},
      );

      // Update local state optimistically
      state = state.whenData((items) {
        return items.map((item) {
          if (item.id == itemId) {
            return item.copyWith(currentPage: currentPage);
          }
          return item;
        }).toList();
      });
    } catch (e) {
      // Reload on error
      await loadLibrary();
      rethrow;
    }
  }

  /// Update reading status
  /// Mirrors iOS: LibraryView.updateStatus()
  Future<void> updateStatus(int itemId, String status) async {
    try {
      await _apiClient.put(
        ApiEndpoints.updateLibraryItem(itemId),
        data: {'status': status},
      );

      // Update local state
      state = state.whenData((items) {
        return items.map((item) {
          if (item.id == itemId) {
            return item.copyWith(status: status);
          }
          return item;
        }).toList();
      });
    } catch (e) {
      await loadLibrary();
      rethrow;
    }
  }

  /// Remove book from library
  Future<void> removeBook(int itemId) async {
    try {
      await _apiClient.delete(ApiEndpoints.deleteLibraryItem(itemId));

      // Remove from local state
      state = state.whenData((items) {
        return items.where((item) => item.id != itemId).toList();
      });
    } catch (e) {
      await loadLibrary();
      rethrow;
    }
  }

  /// Filter library by status
  List<LibraryItem> filterByStatus(List<LibraryItem> items, ReadingStatus? status) {
    if (status == null) return items;
    return items.where((item) => item.status == status.value).toList();
  }
}

/// Library provider
final libraryProvider = StateNotifierProvider<LibraryNotifier, AsyncValue<List<LibraryItem>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LibraryNotifier(apiClient);
});

/// Filtered library provider by status
final filteredLibraryProvider = Provider.family<List<LibraryItem>, ReadingStatus?>((ref, status) {
  final libraryState = ref.watch(libraryProvider);
  return libraryState.maybeWhen(
    data: (items) {
      if (status == null) return items;
      return items.where((item) => item.status == status.value).toList();
    },
    orElse: () => [],
  );
});
