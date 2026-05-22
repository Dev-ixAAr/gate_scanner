// ============================================================================
// API Exception — Normalized HTTP error type
//
// Wraps Dio exceptions into a consistent error type used throughout the app.
//
// Full implementation in Phase 5.
// Phase 1: Structure defined.
// ============================================================================

/// Exception thrown when an API call fails.
///
/// Normalized from DioException to provide consistent error handling
/// across all API calls without exposing Dio internals to the UI layer.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.isNetworkError = false,
    this.isSessionRevoked = false,
  });

  // TODO: Add factory constructors in Phase 5:
  // - ApiException.fromDioException(DioException e)
  // - ApiException.networkError()
  // - ApiException.sessionRevoked()
  // - ApiException.serverError(int statusCode, String message)

  /// Human-readable error message for display.
  final String message;

  /// HTTP status code, if available.
  /// Null for network errors (no response received).
  final int? statusCode;

  /// Machine-readable error code from the backend response body.
  /// Example: 'SETUP_TOKEN_EXPIRED', 'TICKET_NOT_FOUND'
  final String? errorCode;

  /// True when the error was a network/connectivity issue.
  /// False when the server responded with an error status.
  final bool isNetworkError;

  /// True when the server returned 401 — session revoked.
  /// The app should clear session and redirect to setup.
  final bool isSessionRevoked;

  @override
  String toString() {
    return 'ApiException('
        'statusCode: $statusCode, '
        'message: $message, '
        'errorCode: $errorCode'
        ')';
  }
}