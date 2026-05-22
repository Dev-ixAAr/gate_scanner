// ============================================================================
// Auth Interceptor — Attach Bearer token to API requests
//
// Reads session token from secure storage and attaches it to
// every outgoing request's Authorization header.
//
// Full implementation in Phase 5.
// Phase 1: Skeleton with TODO markers.
// ============================================================================

// TODO: Implement in Phase 5
// import 'package:dio/dio.dart';

/// Dio interceptor that attaches the scanner session token to requests.
///
/// Added to the Dio instance in ApiClient.
/// Reads the token from SessionService on each request
/// to ensure it always uses the current valid token.
class AuthInterceptor {
  // TODO: Implement in Phase 5
  // onRequest: attach Authorization: Bearer <token> header
  // If no token found: let request proceed (setup endpoint doesn't need auth)
}