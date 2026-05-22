// ============================================================================
// Auth Interceptor — Attach Bearer token to outgoing API requests
//
// Reads the scanner session token from SessionService on each request.
// Reads on each request (not cached in interceptor memory) to ensure
// the always-current token is used after session refresh.
//
// SKIPS auth header for:
// - The setup token exchange endpoint (no session exists yet)
// - Requests that already have an Authorization header set
//
// THREAD SAFETY:
// Riverpod providers are not directly accessible from Dio interceptors.
// The SessionService is injected via constructor (not via ref) to
// avoid BuildContext dependency.
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../constants/app_constants.dart';
import '../../services/session_service.dart';
import '../api_endpoints.dart';

/// Dio interceptor that attaches the scanner session token to requests.
///
/// Added to the authenticated Dio instance in [ApiClient].
/// Not added to the temporary setup Dio instance used for token exchange.
class AuthInterceptor extends Interceptor {
  const AuthInterceptor({required SessionService sessionService})
      : _sessionService = sessionService;

  final SessionService _sessionService;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip the setup token exchange endpoint — it uses a separate
    // unauthenticated Dio instance, but guard here as a safety net.
    if (options.path.contains(ApiEndpoints.verifySetupToken)) {
      handler.next(options);
      return;
    }

    // Skip if an Authorization header is already set.
    // Allows individual requests to override auth if needed.
    if (options.headers.containsKey('Authorization')) {
      handler.next(options);
      return;
    }

    // Read the current session token from secure storage.
    final String? token = await _sessionService.getSessionToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      _log('Attached Bearer token to ${options.method} ${options.path}');
    } else {
      // No token found — proceed without auth header.
      // The server will return 401, which the SessionRevokeInterceptor handles.
      _log('WARNING: No session token found for ${options.method} ${options.path}');
    }

    // Always include the app version header for server-side analytics.
    options.headers['X-App-Version'] = AppConstants.fallbackVersion;
    options.headers['X-Platform'] = AppConstants.osAndroid;
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';

    handler.next(options);
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AuthInterceptor] $message');
    }
  }
}