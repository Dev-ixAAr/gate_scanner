// ============================================================================
// API Client — Updated for Phase 9
//
// Changes from Phase 5:
// - SessionRevokeInterceptor now receives a Ref parameter so it can
//   invalidate sessionDataProvider after clearing the session
// - Both create() and the provider pass ref to the interceptor
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
final apiClientProvider = Provider<Dio>((ref) {
  final sessionService = ref.read(sessionServiceProvider);
  final routerRefreshNotifier = ref.read(routerRefreshNotifierProvider);

  return ApiClientFactory.create(
    sessionService: sessionService,
    routerRefreshNotifier: routerRefreshNotifier,
    ref: ref,
  );
});

/// Factory for creating configured Dio instances.
class ApiClientFactory {
  ApiClientFactory._();

  /// Creates a fully configured authenticated [Dio] instance.
  static Dio create({
    required SessionService sessionService,
    required RouterRefreshNotifier routerRefreshNotifier,
    required Ref ref,
    String? baseUrl,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout:
            Duration(milliseconds: AppConstants.apiConnectTimeoutMs),
        receiveTimeout:
            Duration(milliseconds: AppConstants.apiReceiveTimeoutMs),
        sendTimeout: Duration(milliseconds: AppConstants.apiSendTimeoutMs),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Platform': AppConstants.osAndroid,
        },
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    // 1. Logging interceptor (debug builds only)
    if (kDebugMode) {
      dio.interceptors.add(LoggingInterceptor());
    }

    // 2. Auth interceptor — attaches Bearer token
    dio.interceptors.add(AuthInterceptor(sessionService: sessionService));

    // 3. Session revoke interceptor — catches 401/403
    //    Phase 9: receives ref so it can invalidate sessionDataProvider
    dio.interceptors.add(
      SessionRevokeInterceptor(
        sessionService: sessionService,
        routerRefreshNotifier: routerRefreshNotifier,
        navigatorKey: navigatorKey,
        ref: ref,
      ),
    );

    _log('ApiClient created');
    return dio;
  }

  /// Creates a temporary unauthenticated Dio for setup token exchange.
  static Dio createForSetup({required String serverUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: serverUrl.endsWith('/')
            ? serverUrl.substring(0, serverUrl.length - 1)
            : serverUrl,
        connectTimeout:
            Duration(milliseconds: AppConstants.apiConnectTimeoutMs),
        receiveTimeout:
            Duration(milliseconds: AppConstants.apiReceiveTimeoutMs),
        sendTimeout: Duration(milliseconds: AppConstants.apiSendTimeoutMs),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Platform': AppConstants.osAndroid,
        },
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(LoggingInterceptor());
    }

    _log('Setup Dio created — baseUrl: $serverUrl');
    return dio;
  }

  static void _log(String message) {
    if (kDebugMode) debugPrint('[ApiClientFactory] $message');
  }
}

/// Provides a fully configured [Dio] with the session base URL loaded.
final authenticatedDioProvider = FutureProvider<Dio>((ref) async {
  final sessionService = ref.read(sessionServiceProvider);
  final routerRefreshNotifier = ref.read(routerRefreshNotifierProvider);

  final String? serverUrl = await sessionService.getServerUrl();

  if (serverUrl == null || serverUrl.isEmpty) {
    return ApiClientFactory.create(
      sessionService: sessionService,
      routerRefreshNotifier: routerRefreshNotifier,
      ref: ref,
      baseUrl: '',
    );
  }

  final String normalizedUrl = serverUrl.endsWith('/')
      ? serverUrl.substring(0, serverUrl.length - 1)
      : serverUrl;

  return ApiClientFactory.create(
    sessionService: sessionService,
    routerRefreshNotifier: routerRefreshNotifier,
    ref: ref,
    baseUrl: normalizedUrl,
  );
});