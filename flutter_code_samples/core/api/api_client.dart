import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'api_error.dart';

/// Main API client for GRead app
/// Handles all HTTP requests with automatic JWT token injection
class ApiClient {
  static const String baseUrl = 'https://gread.fun/wp-json';

  final Dio _dio;
  final Logger _logger;
  String? _authToken;

  ApiClient({Dio? dio, Logger? logger})
      : _dio = dio ?? Dio(),
        _logger = logger ?? Logger() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Request interceptor - Add auth token and logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Inject JWT token if available
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }

          _logger.d('REQUEST[${options.method}] => ${options.uri}');
          _logger.d('Headers: ${options.headers}');
          if (options.data != null) {
            _logger.d('Data: ${options.data}');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}');
          _logger.d('Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e(
            'ERROR[${error.response?.statusCode}] => ${error.requestOptions.uri}',
            error: error.error,
            stackTrace: error.stackTrace,
          );
          return handler.next(error);
        },
      ),
    );
  }

  /// Set authentication token for subsequent requests
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  /// Generic GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generic POST request
  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generic PUT request
  Future<dynamic> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generic DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle successful responses
  dynamic _handleResponse(Response response) {
    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return response.data;
    } else {
      throw ApiError(
        message: 'Request failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }

  /// Handle Dio errors and convert to ApiError
  ApiError _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiError(
          message: 'Connection timeout. Please check your internet connection.',
          type: ApiErrorType.timeout,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] as String? ??
            error.response?.data?['error'] as String? ??
            'Request failed';

        return ApiError(
          message: message,
          statusCode: statusCode,
          type: _getErrorType(statusCode),
        );

      case DioExceptionType.cancel:
        return ApiError(
          message: 'Request cancelled',
          type: ApiErrorType.cancelled,
        );

      default:
        return ApiError(
          message: error.message ?? 'Unknown error occurred',
          type: ApiErrorType.unknown,
        );
    }
  }

  /// Determine error type based on HTTP status code
  ApiErrorType _getErrorType(int? statusCode) {
    if (statusCode == null) return ApiErrorType.unknown;

    if (statusCode == 401) return ApiErrorType.unauthorized;
    if (statusCode == 403) return ApiErrorType.forbidden;
    if (statusCode == 404) return ApiErrorType.notFound;
    if (statusCode >= 500) return ApiErrorType.serverError;

    return ApiErrorType.unknown;
  }
}
