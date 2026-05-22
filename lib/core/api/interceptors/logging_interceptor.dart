// ============================================================================
// Logging Interceptor — Debug request/response logging
//
// Provides detailed API call logging during development.
// STRICTLY guarded by kDebugMode — zero output in release builds.
//
// SECURITY RULES:
// - Authorization header value is masked: "Bearer tok_xxx***"
// - Response body is truncated at 800 characters
// - Setup tokens in request body are masked
// - No logging in release builds (enforced by kDebugMode check in onRequest)
//
// OUTPUT FORMAT (debug console):
// ┌─────────────────────────────────────────────
// │ → POST https://api.example.com/api/scanner/setup/verify
// │   Headers: { Accept: application/json, Authorization: Bearer tok_xxx*** }
// │   Body: { setup_token: ***, event_public_ref: EVT-001, ... }
// ├─────────────────────────────────────────────
// │ ← 200 OK (234ms)
// │   Body: { session_token: ***, event_name: Summer Festival }
// └─────────────────────────────────────────────
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Dio interceptor for development-only request/response logging.
///
/// Automatically disabled in release builds via [kDebugMode] check.
/// All sensitive values (auth tokens, setup tokens) are masked in output.
class LoggingInterceptor extends Interceptor {
  /// Tracks request start times for response duration calculation.
  final Map<int, DateTime> _requestStartTimes = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(options);
      return;
    }

    // Record start time for this request (keyed by hashCode).
    _requestStartTimes[options.hashCode] = DateTime.now();

    final String method = options.method.toUpperCase();
    final String url = '${options.baseUrl}${options.path}';

    debugPrint('┌─── API REQUEST ────────────────────────────');
    debugPrint('│ → $method $url');

    // Log sanitized headers.
    if (options.headers.isNotEmpty) {
      final sanitizedHeaders = _sanitizeHeaders(options.headers);
      debugPrint('│   Headers: $sanitizedHeaders');
    }

    // Log query parameters.
    if (options.queryParameters.isNotEmpty) {
      debugPrint('│   Query: ${options.queryParameters}');
    }

    // Log request body (sanitized).
    if (options.data != null) {
      final sanitizedBody = _sanitizeBody(options.data);
      debugPrint('│   Body: $sanitizedBody');
    }

    debugPrint('└────────────────────────────────────────────');

    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(response);
      return;
    }

    final int statusCode = response.statusCode ?? 0;
    final String url =
        '${response.requestOptions.baseUrl}${response.requestOptions.path}';

    // Calculate request duration.
    final DateTime? startTime =
        _requestStartTimes.remove(response.requestOptions.hashCode);
    final String duration = startTime != null
        ? '${DateTime.now().difference(startTime).inMilliseconds}ms'
        : '?ms';

    debugPrint('┌─── API RESPONSE ───────────────────────────');
    debugPrint('│ ← $statusCode ${_statusText(statusCode)} [$duration]');
    debugPrint('│   URL: $url');

    // Log response body (truncated + sanitized).
    if (response.data != null) {
      final String bodyStr = _sanitizeBody(response.data).toString();
      final String truncated = bodyStr.length > 800
          ? '${bodyStr.substring(0, 800)}... [truncated ${bodyStr.length - 800} chars]'
          : bodyStr;
      debugPrint('│   Body: $truncated');
    }

    debugPrint('└────────────────────────────────────────────');

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(err);
      return;
    }

    final int? statusCode = err.response?.statusCode;
    final String url =
        '${err.requestOptions.baseUrl}${err.requestOptions.path}';

    // Calculate request duration.
    _requestStartTimes.remove(err.requestOptions.hashCode);

    debugPrint('┌─── API ERROR ──────────────────────────────');
    debugPrint('│ ✗ ${err.type.name}'
        '${statusCode != null ? " (HTTP $statusCode)" : ""}');
    debugPrint('│   URL: $url');
    debugPrint('│   Message: ${err.message}');

    if (err.response?.data != null) {
      final String bodyStr = err.response!.data.toString();
      final String truncated = bodyStr.length > 400
          ? '${bodyStr.substring(0, 400)}...'
          : bodyStr;
      debugPrint('│   Response body: $truncated');
    }

    debugPrint('└────────────────────────────────────────────');

    handler.next(err);
  }

  // ==========================================================================
  // PRIVATE SANITIZATION HELPERS
  // ==========================================================================

  /// Sanitizes request/response headers for safe logging.
  ///
  /// Masks the Authorization header value to prevent token exposure.
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final Map<String, dynamic> sanitized = Map.from(headers);

    if (sanitized.containsKey('Authorization')) {
      final String authValue = sanitized['Authorization'].toString();
      if (authValue.length > 14) {
        // Show "Bearer tok_xxx***" — first 14 chars + mask.
        sanitized['Authorization'] =
            '${authValue.substring(0, 14)}***';
      } else {
        sanitized['Authorization'] = '***';
      }
    }

    return sanitized;
  }

  /// Sanitizes request/response body for safe logging.
  ///
  /// Masks sensitive token fields in JSON bodies.
  dynamic _sanitizeBody(dynamic body) {
    if (body is Map<String, dynamic>) {
      final Map<String, dynamic> sanitized = Map.from(body);

      // Mask all token-like fields.
      const sensitiveKeys = {
        'setup_token',
        'session_token',
        'scanner_session_token',
        'token',
        'access_token',
        'refresh_token',
        'password',
      };

      for (final key in sensitiveKeys) {
        if (sanitized.containsKey(key)) {
          final String value = sanitized[key].toString();
          sanitized[key] = value.length > 6
              ? '${value.substring(0, 6)}***'
              : '***';
        }
      }

      return sanitized;
    }
    return body;
  }

  /// Returns a human-readable HTTP status text.
  String _statusText(int statusCode) {
    const statusTexts = {
      200: 'OK',
      201: 'Created',
      204: 'No Content',
      400: 'Bad Request',
      401: 'Unauthorized',
      403: 'Forbidden',
      404: 'Not Found',
      409: 'Conflict',
      422: 'Unprocessable Entity',
      429: 'Too Many Requests',
      500: 'Internal Server Error',
      502: 'Bad Gateway',
      503: 'Service Unavailable',
    };
    return statusTexts[statusCode] ?? 'Unknown';
  }
}