// ============================================================================
// API Exception — Normalized error type for all API call failures
//
// Wraps Dio exceptions into a consistent, typed error that feature code
// can handle without knowing about Dio internals.
//
// ERROR CATEGORIES:
// - Network errors: no connectivity, DNS failure, timeout
// - HTTP errors: server responded with 4xx or 5xx
// - Parse errors: response body could not be parsed
// - Session revoked: server returned 401 (special category)
//
// USAGE IN REPOSITORIES:
// ```dart
// try {
//   final response = await dio.post(...);
//   return SomeModel.fromJson(response.data);
// } on DioException catch (e) {
//   throw ApiException.fromDioException(e);
// }
// ```
//
// USAGE IN UI (providers):
// ```dart
// } on ApiException catch (e) {
//   if (e.isSessionRevoked) {
//     // Session revoke interceptor handles this automatically
//   } else {
//     state = AsyncError(e, StackTrace.current);
//   }
// }
// ```
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// A normalized exception for all API call failures in gate_scanner.
///
/// Created by [ApiException.fromDioException] when a Dio request fails.
/// Provides typed access to:
/// - HTTP status code (null for network errors)
/// - Human-readable message (safe to display to the operator)
/// - Machine-readable error code (from backend response body)
/// - Typed flags: isNetworkError, isSessionRevoked, isServerError
class ApiException implements Exception {
  const ApiException._({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.isNetworkError = false,
    this.isSessionRevoked = false,
    this.isServerError = false,
    this.isTimeout = false,
    this.originalError,
  });

  // ==========================================================================
  // FIELDS
  // ==========================================================================

  /// Human-readable error message.
  ///
  /// Safe to display directly to the operator in the UI.
  /// Derived from the backend response body or from the Dio error type.
  final String message;

  /// HTTP status code from the server response.
  ///
  /// Null when the error occurred before a response was received
  /// (network error, timeout, DNS failure).
  final int? statusCode;

  /// Machine-readable error code from the backend response body.
  ///
  /// Examples: 'SETUP_TOKEN_EXPIRED', 'SETUP_TOKEN_INVALID',
  ///           'TICKET_NOT_FOUND', 'SESSION_REVOKED'
  ///
  /// Null if the backend did not include an error code field,
  /// or if the response could not be parsed.
  final String? errorCode;

  /// True when the failure was a network/connectivity issue.
  ///
  /// The server was not reached. Causes: no internet, DNS failure,
  /// server down, wrong URL. The operator should check connectivity.
  final bool isNetworkError;

  /// True when the server returned HTTP 401 (Unauthorized).
  ///
  /// Indicates the scanner session has been revoked or has expired.
  /// The [SessionRevokeInterceptor] catches this automatically and
  /// clears the session + navigates to /setup.
  final bool isSessionRevoked;

  /// True when the server returned HTTP 5xx.
  ///
  /// Indicates a backend error unrelated to the scanner.
  /// The operator should retry or contact support.
  final bool isServerError;

  /// True when the request timed out.
  ///
  /// Either connect timeout or receive timeout was exceeded.
  final bool isTimeout;

  /// The original Dio exception, for debugging purposes.
  ///
  /// Not displayed to the user. Available for logging in debug mode.
  final Object? originalError;

  // ==========================================================================
  // NAMED CONSTRUCTORS
  // ==========================================================================

  /// Creates an [ApiException] from a [DioException].
  ///
  /// This is the primary factory used by repositories.
  /// Maps all Dio error types to the appropriate [ApiException] variant.
  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      // ----------------------------------------------------------------------
      // CONNECTION / NETWORK ERRORS
      // No response received from server.
      // ----------------------------------------------------------------------
      case DioExceptionType.connectionTimeout:
        return ApiException._(
          message:
              'Connection timed out. Please check your network and ensure '
              'the server is reachable.',
          isNetworkError: true,
          isTimeout: true,
          originalError: e,
        );

      case DioExceptionType.receiveTimeout:
        return ApiException._(
          message:
              'The server took too long to respond. Please try again.',
          isNetworkError: false,
          isTimeout: true,
          originalError: e,
        );

      case DioExceptionType.sendTimeout:
        return ApiException._(
          message: 'Request timed out while sending data. Please try again.',
          isNetworkError: false,
          isTimeout: true,
          originalError: e,
        );

      case DioExceptionType.connectionError:
        return ApiException._(
          message:
              'Cannot connect to the server. Please check your internet '
              'connection and verify the server URL is correct.',
          isNetworkError: true,
          originalError: e,
        );

      case DioExceptionType.cancel:
        return ApiException._(
          message: 'Request was cancelled.',
          isNetworkError: false,
          originalError: e,
        );

      // ----------------------------------------------------------------------
      // HTTP RESPONSE ERRORS
      // Server responded with a non-2xx status code.
      // ----------------------------------------------------------------------
      case DioExceptionType.badResponse:
        return _fromBadResponse(e);

      // ----------------------------------------------------------------------
      // OTHER / UNKNOWN
      // ----------------------------------------------------------------------
      case DioExceptionType.badCertificate:
        return ApiException._(
          message:
              'SSL certificate error. The server certificate could not be '
              'verified. Contact your administrator.',
          isNetworkError: true,
          originalError: e,
        );

      case DioExceptionType.unknown:
        // Check if it's a socket exception (no internet).
        final String errorString = e.toString().toLowerCase();
        if (errorString.contains('socketexception') ||
            errorString.contains('failed host lookup') ||
            errorString.contains('network is unreachable')) {
          return ApiException._(
            message:
                'No internet connection. Please check your network settings.',
            isNetworkError: true,
            originalError: e,
          );
        }
        return ApiException._(
          message: 'An unexpected error occurred. Please try again.',
          originalError: e,
        );
    }
  }

  /// Creates an [ApiException] from a bad response (HTTP error status).
  ///
  /// Attempts to extract a human-readable message and error code from
  /// the response body. Falls back to generic messages by status code.
  static ApiException _fromBadResponse(DioException e) {
    final int? statusCode = e.response?.statusCode;
    final dynamic responseData = e.response?.data;

    // Attempt to extract message and errorCode from the response body.
    String? serverMessage;
    String? errorCode;

    if (responseData is Map<String, dynamic>) {
      // Try common message field names used by backends.
      serverMessage = (responseData['message'] as String?) ??
          (responseData['error'] as String?) ??
          (responseData['detail'] as String?);

      // Try common error code field names.
      errorCode = (responseData['error_code'] as String?) ??
          (responseData['code'] as String?);
    }

    // Map status codes to typed exceptions and user messages.
    switch (statusCode) {
      case 400:
        return ApiException._(
          statusCode: statusCode,
          errorCode: errorCode,
          message: serverMessage ?? 'Invalid request. Please check the setup QR code.',
          originalError: e,
        );

      case 401:
        return ApiException._(
          statusCode: statusCode,
          errorCode: errorCode,
          message: serverMessage ??
              'Session expired or revoked. Please scan a new setup QR code.',
          isSessionRevoked: true,
          originalError: e,
        );

      case 403:
        return ApiException._(
          statusCode: statusCode,
          errorCode: errorCode,
          message: serverMessage ??
              'Access denied. Your scanner session may have been revoked.',
          isSessionRevoked: true,
          originalError: e,
        );

      case 404:
        return ApiException._(
          statusCode: statusCode,
          errorCode: errorCode,
          message: serverMessage ?? 'The requested resource was not found.',
          originalError: e,
        );

      case 409:
        return ApiException._(
          statusCode: statusCode,
          errorCode: errorCode,
          message: serverMessage ?? 'Conflict: the request could not be processed.',
          originalError: e,
        );

      case 422:
        return ApiException._(
          statusCode: statusCode,
          errorCode: errorCode,
          message: serverMessage ??
              'Setup token is invalid or has already been used.',
          originalError: e,
        );

      case 429:
        return ApiException._(
          statusCode: statusCode,
          errorCode: errorCode,
          message: serverMessage ??
              'Too many requests. Please wait a moment before trying again.',
          originalError: e,
        );

      default:
        if (statusCode != null && statusCode >= 500) {
          return ApiException._(
            statusCode: statusCode,
            errorCode: errorCode,
            message: serverMessage ??
                'Server error ($statusCode). Please try again or contact support.',
            isServerError: true,
            originalError: e,
          );
        }
        return ApiException._(
          statusCode: statusCode,
          errorCode: errorCode,
          message: serverMessage ??
              'An error occurred (HTTP $statusCode). Please try again.',
          originalError: e,
        );
    }
  }

  // ==========================================================================
  // CONVENIENCE CONSTRUCTORS
  // Used in tests and for manually creating specific error types.
  // ==========================================================================

  /// Creates a network error exception.
  factory ApiException.networkError([String? message]) {
    return ApiException._(
      message: message ??
          'No internet connection. Please check your network settings.',
      isNetworkError: true,
    );
  }

  /// Creates a session revoked exception.
  factory ApiException.sessionRevoked([String? message]) {
    return ApiException._(
      statusCode: 401,
      message: message ??
          'Your scanner session has been revoked. Please scan a new setup QR code.',
      isSessionRevoked: true,
    );
  }

  /// Creates a server error exception.
  factory ApiException.serverError([int? statusCode, String? message]) {
    return ApiException._(
      statusCode: statusCode ?? 500,
      message: message ?? 'Server error. Please try again or contact support.',
      isServerError: true,
    );
  }

  /// Creates an unauthorized exception.
  factory ApiException.unauthorized([String? message]) {
    return ApiException._(
      statusCode: 401,
      message: message ?? 'Unauthorized. Please reconnect the scanner.',
      isSessionRevoked: true,
    );
  }

  // ==========================================================================
  // DEBUG HELPERS
  // ==========================================================================

  @override
  String toString() {
    final buffer = StringBuffer('ApiException(');
    if (statusCode != null) buffer.write('HTTP $statusCode, ');
    if (errorCode != null) buffer.write('code: $errorCode, ');
    buffer.write('message: "$message"');
    if (isNetworkError) buffer.write(', [network]');
    if (isSessionRevoked) buffer.write(', [revoked]');
    if (isServerError) buffer.write(', [server]');
    if (isTimeout) buffer.write(', [timeout]');
    buffer.write(')');
    return buffer.toString();
  }

  /// Logs full error details in debug mode.
  void debugLog() {
    if (kDebugMode) {
      debugPrint('[ApiException] $this');
      if (originalError != null) {
        debugPrint('[ApiException] Original: $originalError');
      }
    }
  }
}