// ============================================================================
// Session Service — Scanner session lifecycle management
//
// This service is the authoritative source for session operations.
// It reads from and writes to SecureStorageService using StorageKeys constants.
//
// RESPONSIBILITIES:
// 1. Save a new session after successful setup token exchange
// 2. Load the current session on app startup for route guard + UI
// 3. Clear the session on logout, reset, or remote revocation
// 4. Provide convenience accessors for individual session fields
//    (used by API client interceptors without loading the full session)
//
// USAGE PATTERN:
// - Feature code uses [sessionServiceProvider] via Riverpod ref
// - The router uses [secureStorageServiceProvider] directly (lighter)
// - The home screen and settings use [sessionDataProvider] (reactive)
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/storage_keys.dart';
import '../models/session_data.dart';
import '../secure_storage/secure_storage_service.dart';

/// Riverpod provider for [SessionService].
///
/// Access pattern:
/// ```dart
/// final sessionService = ref.read(sessionServiceProvider);
/// await sessionService.saveSession(...);
/// ```
final sessionServiceProvider = Provider<SessionService>((ref) {
  final storage = ref.read(secureStorageServiceProvider);
  return SessionService(storage: storage);
});

/// Manages the complete lifecycle of a scanner session.
///
/// All session state is persisted in encrypted storage — there is no
/// in-memory cache. This ensures:
/// - Session survives app restarts and background kills
/// - No stale in-memory state after a remote revocation
/// - No risk of session token exposure via memory dumps
///
/// If in-memory caching is needed for performance in a later phase,
/// add it here as a private nullable field with invalidation on write/delete.
class SessionService {
  const SessionService({required SecureStorageService storage})
      : _storage = storage;

  final SecureStorageService _storage;

  // ==========================================================================
  // SAVE SESSION
  // ==========================================================================

  /// Persists all session fields to encrypted storage.
  ///
  /// Called after a successful setup token exchange with the backend.
  /// Writes all fields atomically — if any write fails, the session is
  /// considered invalid (subsequent reads will return null for missing keys).
  ///
  /// Parameters correspond directly to [StorageKeys] constants.
  ///
  /// Throws [SecureStorageWriteException] if any write fails.
  ///
  /// Example:
  /// ```dart
  /// await sessionService.saveSession(
  ///   serverUrl: 'https://tickets.example.com',
  ///   eventPublicRef: 'EVT-2024-001',
  ///   eventName: 'Summer Festival 2024',
  ///   sessionToken: 'tok_xxxxxxxxxxxxxxxx',
  ///   sessionStartedAt: DateTime.now(),
  ///   deviceName: 'Samsung Galaxy A53 (Gate 1)',
  /// );
  /// ```
  Future<void> saveSession({
    required String serverUrl,
    required String eventPublicRef,
    required String eventName,
    required String sessionToken,
    required DateTime sessionStartedAt,
    required String deviceName,
  }) async {
    _debugLog('saveSession → event: "$eventName" server: "$serverUrl"');

    // Write all fields. If any write fails, the exception propagates to
    // the setup flow where it is shown as a user-visible error.
    await _storage.write(key: StorageKeys.serverUrl, value: serverUrl.trim());
    await _storage.write(key: StorageKeys.eventPublicRef, value: eventPublicRef.trim());
    await _storage.write(key: StorageKeys.eventName, value: eventName.trim());
    await _storage.write(key: StorageKeys.sessionToken, value: sessionToken.trim());
    await _storage.write(
      key: StorageKeys.sessionStartedAt,
      value: sessionStartedAt.toUtc().toIso8601String(),
    );
    await _storage.write(key: StorageKeys.deviceName, value: deviceName.trim());

    _debugLog('saveSession → complete');
  }

  // ==========================================================================
  // GET SESSION
  // ==========================================================================

  /// Loads the current session from encrypted storage.
  ///
  /// Returns a complete [SessionData] if all required fields are present
  /// and valid. Returns [null] if:
  /// - The device has never been configured (first install)
  /// - The session was cleared (logout/reset/revocation)
  /// - Any required field is missing (partial write failure)
  /// - The session start timestamp cannot be parsed
  ///
  /// This method reads all fields from storage. For performance-sensitive
  /// contexts (e.g., the router guard), use [getSessionToken] or
  /// [isSessionActive] instead which only read the token key.
  ///
  /// Example:
  /// ```dart
  /// final session = await sessionService.getSession();
  /// if (session == null) {
  ///   // Navigate to setup
  /// } else {
  ///   // Show home screen with session.eventName
  /// }
  /// ```
  Future<SessionData?> getSession() async {
    _debugLog('getSession → reading all keys');

    // Read all fields in parallel for performance.
    final results = await Future.wait([
      _storage.read(key: StorageKeys.serverUrl),
      _storage.read(key: StorageKeys.eventPublicRef),
      _storage.read(key: StorageKeys.eventName),
      _storage.read(key: StorageKeys.sessionToken),
      _storage.read(key: StorageKeys.sessionStartedAt),
      _storage.read(key: StorageKeys.deviceName),
    ]);

    final session = SessionData.fromStorageValues(
      serverUrl: results[0],
      eventPublicRef: results[1],
      eventName: results[2],
      sessionToken: results[3],
      sessionStartedAt: results[4],
      deviceName: results[5],
    );

    _debugLog(
      session != null
          ? 'getSession → loaded: ${session.eventName}'
          : 'getSession → no valid session found',
    );

    return session;
  }

  // ==========================================================================
  // CLEAR SESSION
  // ==========================================================================

  /// Clears all session data from encrypted storage.
  ///
  /// This is a complete wipe — all stored keys are deleted.
  /// After this call, [getSession] returns null and [isSessionActive]
  /// returns false, causing the router to redirect to /setup.
  ///
  /// Called when:
  /// - [logoutScannerSession] API call succeeds (server-side logout)
  /// - User confirms "Reset Event Binding" in settings
  /// - User confirms "Switch Event" in settings
  /// - The API interceptor detects a 401 (remote revocation)
  ///
  /// Throws [SecureStorageDeleteException] if the clear operation fails.
  Future<void> clearSession() async {
    _debugLog('clearSession → wiping all session data');
    await _storage.deleteAll();
    _debugLog('clearSession → complete');
  }

  // ==========================================================================
  // IS SESSION ACTIVE
  // ==========================================================================

  /// Returns [true] if a session token is stored and non-empty.
  ///
  /// This is a fast check — only reads the session token key.
  /// Used by the router guard for quick authentication checks.
  ///
  /// Note: A token being present does not guarantee it is still valid
  /// on the server. The session may have been revoked remotely.
  /// Server-side validation is performed by [getScannerSession] API call
  /// in the home screen and by the 401 interceptor on every request.
  Future<bool> isSessionActive() async {
    final token = await _storage.read(key: StorageKeys.sessionToken);
    final isActive = token != null && token.trim().isNotEmpty;
    _debugLog('isSessionActive → $isActive');
    return isActive;
  }

  // ==========================================================================
  // GET SESSION TOKEN
  // ==========================================================================

  /// Returns the session token string, or [null] if not set.
  ///
  /// Used directly by [AuthInterceptor] to attach the Bearer token
  /// to outgoing API requests. The interceptor reads the token on
  /// each request (not cached) to always use the current value.
  ///
  /// Returns null if no session is active.
  Future<String?> getSessionToken() async {
    return _storage.read(key: StorageKeys.sessionToken);
  }

  // ==========================================================================
  // GET SERVER URL
  // ==========================================================================

  /// Returns the server URL string, or [null] if not set.
  ///
  /// Used by [ApiClient] to configure the Dio base URL.
  /// Also used by the API client factory to create a new Dio instance
  /// when the session URL changes (e.g., after switching events).
  ///
  /// Returns null if no session is active.
  Future<String?> getServerUrl() async {
    return _storage.read(key: StorageKeys.serverUrl);
  }

  // ==========================================================================
  // GET EVENT PUBLIC REF
  // ==========================================================================

  /// Returns the event public reference, or [null] if not set.
  ///
  /// Included in ticket validation API requests to scope the lookup.
  ///
  /// Returns null if no session is active.
  Future<String?> getEventPublicRef() async {
    return _storage.read(key: StorageKeys.eventPublicRef);
  }

  // ==========================================================================
  // GET DEVICE NAME
  // ==========================================================================

  /// Returns the stored device name, or [null] if not set.
  ///
  /// Included in API request payloads for audit trail purposes.
  ///
  /// Returns null if no session is active.
  Future<String?> getDeviceName() async {
    return _storage.read(key: StorageKeys.deviceName);
  }

  // ==========================================================================
  // UPDATE DEVICE NAME
  // ==========================================================================

  /// Updates the stored device name.
  ///
  /// Called when the user sets a custom device name in settings.
  /// The updated name is used in subsequent API requests.
  ///
  /// Does nothing if no session is active (no session to update).
  Future<void> updateDeviceName(String newDeviceName) async {
    final isActive = await isSessionActive();
    if (!isActive) return;

    await _storage.write(
      key: StorageKeys.deviceName,
      value: newDeviceName.trim(),
    );
    _debugLog('updateDeviceName → "$newDeviceName"');
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[SessionService] $message');
    }
  }
}