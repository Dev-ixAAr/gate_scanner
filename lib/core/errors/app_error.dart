// ============================================================================
// App Error — Sealed error classes for the gate scanner app
//
// Provides a type-safe way to represent all possible error states.
// Using a sealed class forces all call sites to handle every error type.
//
// Full implementation in Phase 7 (API Client).
// Phase 1: Structure defined as placeholder.
// ============================================================================

/// Sealed base class for all application errors.
///
/// Using sealed classes ensures exhaustive handling with switch expressions.
/// Every error type the app can encounter is represented as a subclass.
///
/// Usage:
/// ```dart
/// switch (error) {
///   case NetworkError(:final message):
///     showMessage(message);
///   case SessionRevokedError():
///     navigateToSetup();
///   // ... handle all cases
/// }
/// ```
sealed class AppError implements Exception {
  const AppError();
}

/// Network connectivity error.
/// Thrown when the device has no internet connection or the server
/// is unreachable (DNS failure, timeout, etc.).
class NetworkError extends AppError {
  const NetworkError({
    this.message = 'No internet connection. Please check your network.',
  });

  final String message;

  @override
  String toString() => 'NetworkError: $message';
}

/// API returned an error response.
/// Thrown when the server returns a non-2xx HTTP status code.
class ApiError extends AppError {
  const ApiError({
    required this.statusCode,
    required this.message,
    this.errorCode,
  });

  /// HTTP status code from the server response.
  final int statusCode;

  /// Human-readable error message from the server.
  final String message;

  /// Optional machine-readable error code from the server.
  /// Example: 'TICKET_ALREADY_USED', 'SETUP_TOKEN_EXPIRED'
  final String? errorCode;

  @override
  String toString() => 'ApiError($statusCode): $message';
}

/// Session has been revoked remotely by an administrator.
/// Triggered when the API returns HTTP 401.
/// The app must clear the session and redirect to setup screen.
class SessionRevokedError extends AppError {
  const SessionRevokedError({
    this.message = 'Your session has been revoked. Please scan a new setup QR code.',
  });

  final String message;

  @override
  String toString() => 'SessionRevokedError: $message';
}

/// Setup token has expired.
/// Thrown when the QR code's expires_at timestamp is in the past.
class SetupTokenExpiredError extends AppError {
  const SetupTokenExpiredError({
    this.message = 'This setup QR code has expired. Please generate a new one from the admin panel.',
  });

  final String message;

  @override
  String toString() => 'SetupTokenExpiredError: $message';
}

/// Invalid QR code format.
/// Thrown when a scanned QR code cannot be parsed as expected JSON.
class InvalidQrFormatError extends AppError {
  const InvalidQrFormatError({
    this.message = 'Invalid QR code format. Please scan a valid setup QR code.',
  });

  final String message;

  @override
  String toString() => 'InvalidQrFormatError: $message';
}

/// Server returned an unexpected response format.
/// Thrown when response JSON cannot be parsed into the expected model.
class ParseError extends AppError {
  const ParseError({
    required this.message,
    this.field,
  });

  final String message;

  /// The specific field that failed to parse, if known.
  final String? field;

  @override
  String toString() => 'ParseError: $message${field != null ? ' (field: $field)' : ''}';
}

/// Unknown or unexpected error.
/// Catch-all for errors that don't fit other categories.
class UnknownError extends AppError {
  const UnknownError({
    this.message = 'An unexpected error occurred. Please try again.',
    this.originalError,
  });

  final String message;
  final Object? originalError;

  @override
  String toString() => 'UnknownError: $message';
}