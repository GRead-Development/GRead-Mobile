/// API error types matching common HTTP error scenarios
enum ApiErrorType {
  timeout,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  cancelled,
  unknown,
}

/// Custom API error class with user-friendly messages
class ApiError implements Exception {
  final String message;
  final int? statusCode;
  final ApiErrorType type;

  ApiError({
    required this.message,
    this.statusCode,
    this.type = ApiErrorType.unknown,
  });

  @override
  String toString() => message;

  /// Get user-friendly error message for display
  String get userFriendlyMessage {
    switch (type) {
      case ApiErrorType.timeout:
        return 'Connection timeout. Please check your internet connection.';
      case ApiErrorType.unauthorized:
        return 'Session expired. Please login again.';
      case ApiErrorType.forbidden:
        return 'You don\'t have permission to perform this action.';
      case ApiErrorType.notFound:
        return 'The requested resource was not found.';
      case ApiErrorType.serverError:
        return 'Server error. Please try again later.';
      case ApiErrorType.cancelled:
        return 'Request was cancelled.';
      default:
        return message;
    }
  }
}
