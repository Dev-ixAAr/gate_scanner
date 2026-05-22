// ============================================================================
// API Client — Dio HTTP client factory
//
// Creates and configures the Dio instance used for all backend API calls.
// Reads base URL from session storage (set during setup token exchange).
// Attaches interceptors for auth, session revocation, and logging.
//
// Full implementation in Phase 5.
// Phase 1: Skeleton with TODO markers.
// ============================================================================

// TODO: Implement in Phase 5
// import 'package:dio/dio.dart';

/// Creates and provides the configured Dio HTTP client.
///
/// This client is configured with:
/// - Base URL from stored server URL
/// - Request/response timeouts
/// - Auth interceptor (Bearer token)
/// - Session revocation interceptor (401/403 handling)
/// - Logging interceptor (debug builds only)
class ApiClient {
  // TODO: Implement in Phase 5
  // Methods:
  // - Dio createDio(String baseUrl)
  // - Riverpod provider: apiClientProvider
}