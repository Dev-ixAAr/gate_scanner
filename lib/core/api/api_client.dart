// ============================================================================
// API Client — Authenticated Dio HTTP client factory
//
// Creates and configures the Dio instance used for all AUTHENTICATED
// backend API calls (session-protected endpoints).
//
// NOT used for:
// - Setup token exchange (uses a temporary unauthenticated Dio in SetupRepository)
//
// CONFIGURATION:
// - Base URL: loaded from SessionService (stored during setup)
// - Interceptors: Auth + SessionRevoke + Logging (in that order)
// - Timeouts: connect 10s, receive 30s, send 10s
//
// PROVIDER STRATEGY:
// The [apiClientProvider] is a Provider<Dio> that reads the session URL
// each time it is called. The provider is invalidated when the session
// changes (new event binding) so the Dio base URL is always current.
//
// INTERCEPTOR ORDER MATTERS:
// 1. LoggingInterceptor — logs the raw outgoing request (before auth)
// 2. AuthInterceptor — attaches Bearer token
// 3. SessionRevokeInterceptor — catches 401/403 on response
//
// The logging interceptor is first so it sees the request before auth
// modification, making it easier to debug auth header issues.
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart' show navigatorKey;
import '../constants/app_constants.dart';
import '../router/app_router.dart';
import '../services/session_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/session_revoke_interceptor.dart';

/// Riverpod provider for the authenticated [Dio] instance.
///
/// This Dio instance is configured with:
/// - Base URL from the current session's server URL
/// - All three interceptors (auth, revoke, logging)
/// - Production-appropriate timeouts
///
/// Use this provider in all repository classes that call authenticated endpoints.
///
/// IMPORTANT: If the session server URL changes (e.g., after switching events),
/// call [ref.invalidate(apiClientProvider)] to force a new Dio instance
/// with the updated base URL.
///
/// Access pattern:
/// ```dart
/// final dio = ref.read(apiClientProvider);
/// final response = await dio.get(ApiEndpoints.getScannerSession);
/// ```
final apiClientProvider = Provider<Dio>((ref) {
  final sessionService = ref.read(sessionServiceProvider);
  final routerRefreshNotifier = ref.read(routerRefreshNotifierProvider);

  return ApiClientFactory.create(
    sessionService: sessionService,
    routerRefreshNotifier: routerRefreshNotifier,
  );
});

/// Factory class that creates configured Dio instances.
///
/// Separated from the provider to allow easy testing — tests can
/// call [ApiClientFactory.create] with mock services without needing
/// a Riverpod container.
class ApiClientFactory {
  ApiClientFactory._();

  /// Creates a fully configured authenticated [Dio] instance.
  ///
  /// The base URL is loaded asynchronously from session storage.
  /// If no session URL is found, uses an empty string (all requests will fail
  /// with a URL error, which is the correct behaviour — session is invalid).
  ///
  /// [sessionService]: provides session token and server URL
  /// [routerRefreshNotifier]: used by [SessionRevokeInterceptor] to trigger redirect
  static Dio create({
    required SessionService sessionService,
    required RouterRefreshNotifier routerRefreshNotifier,
    String? baseUrl,
  }) {
    final dio = Dio(
      BaseOptions(
        // Base URL: will be empty if no session (interceptor will return 401).
        // In practice, this provider is only used when a session is active.
        baseUrl: baseUrl ?? '',

        // Timeouts — per AppConstants.
        connectTimeout: Duration(milliseconds: AppConstants.apiConnectTimeoutMs),
        receiveTimeout: Duration(milliseconds: AppConstants.apiReceiveTimeoutMs),
        sendTimeout: Duration(milliseconds: AppConstants.apiSendTimeoutMs),

        // Default headers applied to all requests.
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Platform': AppConstants.osAndroid,
        },

        // Don't follow redirects automatically for API calls.
        followRedirects: false,

        // Validate status: accept 2xx as success.
        // 4xx and 5xx will throw DioException caught by interceptors.
        validateStatus: (status) {
          return status != null && status >= 200 && status < 300;
        },
      ),
    );

    // -------------------------------------------------------------------------
    // ATTACH INTERCEPTORS (order matters)
    // -------------------------------------------------------------------------

    // 1. Logging interceptor — first so it sees the raw request.
    //    Only active in debug builds (kDebugMode check inside the interceptor).
    dio.interceptors.add(LoggingInterceptor());

    // 2. Auth interceptor — attaches Bearer token to each request.
    dio.interceptors.add(
      AuthInterceptor(sessionService: sessionService),
    );

    // 3. Session revoke interceptor — catches 401/403 on response.
    //    Must be after auth so it only fires on authenticated requests.
    dio.interceptors.add(
      SessionRevokeInterceptor(
        sessionService: sessionService,
        routerRefreshNotifier: routerRefreshNotifier,
        navigatorKey: navigatorKey,
      ),
    );

    // -------------------------------------------------------------------------
    // DEBUG: Disable certificate verification for local development
    // NEVER enable this in production.
    // Uncomment only when testing against a local HTTP backend.
    // -------------------------------------------------------------------------
    // if (kDebugMode) {
    //   (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    //     final client = HttpClient();
    //     client.badCertificateCallback = (cert, host, port) => true;
    //     return client;
    //   };
    // }

    _log('ApiClient created — base URL will be set per request');
    return dio;
  }

  /// Creates a temporary UNAUTHENTICATED Dio instance for setup token exchange.
  ///
  /// This Dio instance:
  /// - Has NO auth interceptor (no session token exists yet)
  /// - Has NO session revoke interceptor (401 here means bad setup token)
  /// - Has the logging interceptor in debug builds
  /// - Uses the provided [serverUrl] as base URL
  ///
  /// Used exclusively by [SetupRepository.verifySetupToken].
  static Dio createForSetup({required String serverUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: serverUrl.endsWith('/')
            ? serverUrl.substring(0, serverUrl.length - 1)
            : serverUrl,
        connectTimeout: Duration(milliseconds: AppConstants.apiConnectTimeoutMs),
        receiveTimeout: Duration(milliseconds: AppConstants.apiReceiveTimeoutMs),
        sendTimeout: Duration(milliseconds: AppConstants.apiSendTimeoutMs),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Platform': AppConstants.osAndroid,
        },
        validateStatus: (status) {
          return status != null && status >= 200 && status < 300;
        },
      ),
    );

    // Only add logging in debug builds.
    if (kDebugMode) {
      dio.interceptors.add(LoggingInterceptor());
    }

    _log('Setup Dio created — baseUrl: $serverUrl');
    return dio;
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ApiClientFactory] $message');
    }
  }
}

// ============================================================================
// ASYNC API CLIENT PROVIDER
//
// An AsyncProvider variant that properly loads the base URL from
// secure storage before creating the Dio instance.
// Used by repositories that need a ready-to-use Dio with correct base URL.
// ============================================================================

/// Provides a fully configured [Dio] instance with the session base URL loaded.
///
/// Unlike [apiClientProvider] which creates Dio with empty base URL,
/// this provider reads the stored server URL first and injects it.
///
/// Use this in repositories:
/// ```dart
/// final dio = await ref.read(authenticatedDioProvider.future);
/// ```
final authenticatedDioProvider = FutureProvider<Dio>((ref) async {
  final sessionService = ref.read(sessionServiceProvider);
  final routerRefreshNotifier = ref.read(routerRefreshNotifierProvider);

  // Load the server URL from session storage.
  final String? serverUrl = await sessionService.getServerUrl();

  if (serverUrl == null || serverUrl.isEmpty) {
    // No session URL — return a Dio with empty base URL.
    // All requests will fail, and SessionRevokeInterceptor will clear the session.
    return ApiClientFactory.create(
      sessionService: sessionService,
      routerRefreshNotifier: routerRefreshNotifier,
      baseUrl: '',
    );
  }

  final String normalizedUrl = serverUrl.endsWith('/')
      ? serverUrl.substring(0, serverUrl.length - 1)
      : serverUrl;

  return ApiClientFactory.create(
    sessionService: sessionService,
    routerRefreshNotifier: routerRefreshNotifier,
    baseUrl: normalizedUrl,
  );
});