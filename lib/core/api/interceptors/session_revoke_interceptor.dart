// ============================================================================
// Session Revoke Interceptor — Handle 401/403 globally
//
// Catches 401 (Unauthorized) responses from any API call.
// Clears the stored session and navigates to the setup screen.
// This handles remote session revocation by administrators.
//
// Full implementation in Phase 5 + Phase 9.
// Phase 1: Skeleton with TODO markers.
// ============================================================================

// TODO: Implement in Phase 5 + Phase 9
// import 'package:dio/dio.dart';

/// Dio interceptor that handles session revocation globally.
///
/// When any API call returns HTTP 401:
/// 1. Clear all session data from secure storage
/// 2. Navigate to /setup screen
/// 3. Show "Session revoked" message to the user
///
/// This interceptor ensures the app always returns to a safe state
/// even if the session is revoked while the scanner is actively being used.
class SessionRevokeInterceptor {
  // TODO: Implement in Phase 5 + Phase 9
  // onError: check if e.response?.statusCode == 401
  // If 401: clear session, navigate to setup, show message
  // Prevent multiple triggers (isHandlingRevoke flag)
}