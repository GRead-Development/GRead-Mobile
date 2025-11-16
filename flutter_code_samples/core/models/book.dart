import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';
part 'book.g.dart';

/// Book model matching iOS Book struct
@freezed
class Book with _$Book {
  const factory Book({
    required int id,
    required String title,
    String? author,
    String? description,
    @JsonKey(name: 'cover_url') String? coverUrl,
    @JsonKey(name: 'total_pages') int? totalPages,
    String? isbn,
    @JsonKey(name: 'published_date') String? publishedDate,
    String? publisher,
    List<String>? categories,
  }) = _Book;

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
}

/// Library item model matching iOS LibraryItem struct
/// Tracks a user's reading progress for a book
@freezed
class LibraryItem with _$LibraryItem {
  const factory LibraryItem({
    required int id,
    Book? book,
    @JsonKey(name: 'book_id') int? bookId,
    @JsonKey(name: 'current_page') required int currentPage,
    String? status,  // "reading", "completed", "paused", "planned"
    @JsonKey(name: 'added_date') String? addedDate,
    @JsonKey(name: 'completed_date') String? completedDate,
    @JsonKey(name: 'last_updated') String? lastUpdated,

    // Optional rating/review
    double? rating,
    String? review,
  }) = _LibraryItem;

  factory LibraryItem.fromJson(Map<String, dynamic> json) => _$LibraryItemFromJson(json);
}

/// Reading status enum
enum ReadingStatus {
  reading,
  completed,
  paused,
  planned,
}

extension ReadingStatusExtension on ReadingStatus {
  String get displayName {
    switch (this) {
      case ReadingStatus.reading:
        return 'Currently Reading';
      case ReadingStatus.completed:
        return 'Completed';
      case ReadingStatus.paused:
        return 'Paused';
      case ReadingStatus.planned:
        return 'Want to Read';
    }
  }

  String get value {
    switch (this) {
      case ReadingStatus.reading:
        return 'reading';
      case ReadingStatus.completed:
        return 'completed';
      case ReadingStatus.paused:
        return 'paused';
      case ReadingStatus.planned:
        return 'planned';
    }
  }
}
