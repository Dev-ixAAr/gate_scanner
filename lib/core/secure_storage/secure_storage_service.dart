// ============================================================================
// Secure Storage Service — Canonical Implementation
//
// This is the single access point for all encrypted key-value storage
// in the gate_scanner app. Every sensitive piece of data (session token,
// server URL, event reference) flows through this service.
//
// SECURITY MODEL:
// Android: EncryptedSharedPreferences backed by Android Keystore (AES-256).
// The encryption key is stored in the Android Keystore hardware security
// module where available, making it inaccessible to other apps and to
// extraction even on rooted devices (on supported hardware).
//
// DO NOT:
// - Store session tokens in SharedPreferences (unencrypted)
// - Store session tokens in memory-only variables (lost on app kill)
// - Access FlutterSecureStorage directly in feature code
// - Bypass this service by reading storage keys elsewhere
//
// DO:
// - Use ref.read(secureStorageServiceProvider) to access this service
// - Use StorageKeys constants for all key names
// - Await all methods (all storage operations are async)
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Riverpod provider for [SecureStorageService].
///
/// Declared here so it is co-located with the service implementation.
/// Re-exported from [service_providers.dart] for convenient access.
///
/// Access pattern:
/// ```dart
/// // In a Riverpod provider or notifier:
/// final storage = ref.read(secureStorageServiceProvider);
///
/// // In a widget (ConsumerWidget):
/// final storage = ref.read(secureStorageServiceProvider);
/// ```
///
/// Use [ref.read] — storage is a service, not reactive state.
/// Do not use [ref.watch] on this provider.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService._internal();
});

/// Encrypted key-value storage service for gate_scanner.
///
/// Wraps [FlutterSecureStorage] with:
/// - Consistent error handling (never crashes the app on storage failure)
/// - Debug logging (debug builds only, sanitized output)
/// - Clear method contracts (null = not found, not an exception)
/// - Android-optimized configuration
///
/// All methods are async. Always await them.
class SecureStorageService {
  /// Private constructor — use [secureStorageServiceProvider] to obtain
  /// an instance. Never instantiate this class directly in feature code.
  SecureStorageService._internal()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            // EncryptedSharedPreferences: true enables AES-256 encryption
            // backed by Android Keystore. This is the most secure storage
            // option available on Android without requiring biometric auth.
            //
            // Note: On API < 23, falls back to RSA key pairs stored in
            // Keystore + AES key encrypted with RSA. Still secure.
            encryptedSharedPreferences: true,
          ),
        );

  final FlutterSecureStorage _storage;

  // ==========================================================================
  // WRITE
  // ==========================================================================

  /// Persists [value] at [key] in encrypted storage.
  ///
  /// Overwrites any existing value for [key].
  ///
  /// Throws [SecureStorageWriteException] if the write fails.
  /// This should be caught by callers and presented as a user-visible error,
  /// as failing to write a session token means the setup flow failed.
  ///
  /// Parameters:
  /// - [key]: Storage key constant from [StorageKeys]
  /// - [value]: String value to store (all stored values are strings)
  Future<void> write({
    required String key,
    required String value,
  }) async {
    try {
      await _storage.write(key: key, value: value);
      _log('✓ write → $key');
    } on Exception catch (e, stackTrace) {
      _logError('✗ write failed → $key', e);
      throw SecureStorageWriteException(key: key, cause: e, stackTrace: stackTrace);
    }
  }

  // ==========================================================================
  // READ
  // ==========================================================================

  /// Reads the value stored at [key].
  ///
  /// Returns:
  /// - The stored [String] value if the key exists.
  /// - [null] if the key does not exist.
  /// - [null] if a read error occurs (logged, not thrown).
  ///
  /// Read failures are intentionally lenient — returning null means the app
  /// treats the session as non-existent, which is the safe default behaviour.
  /// This prevents a storage read error from permanently locking the user out.
  ///
  /// Parameters:
  /// - [key]: Storage key constant from [StorageKeys]
  Future<String?> read({required String key}) async {
    try {
      final value = await _storage.read(key: key);
      _log('✓ read → $key = ${_sanitizeLogValue(key, value)}');
      return value;
    } on Exception catch (e) {
      _logError('✗ read failed → $key (returning null)', e);
      // Return null — treat as "not found" to avoid blocking the app.
      return null;
    }
  }

  // ==========================================================================
  // DELETE (single key)
  // ==========================================================================

  /// Deletes the value stored at [key].
  ///
  /// No-op if [key] does not exist.
  ///
  /// Throws [SecureStorageDeleteException] if the delete operation fails.
  ///
  /// Parameters:
  /// - [key]: Storage key constant from [StorageKeys]
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
      _log('✓ delete → $key');
    } on Exception catch (e, stackTrace) {
      _logError('✗ delete failed → $key', e);
      throw SecureStorageDeleteException(key: key, cause: e, stackTrace: stackTrace);
    }
  }

  // ==========================================================================
  // DELETE ALL (session clear)
  // ==========================================================================

  /// Deletes ALL keys and values from encrypted storage.
  ///
  /// This is a complete session wipe. Called when:
  /// - User logs out the scanner session (with server notification)
  /// - User resets the event binding (local only)
  /// - User switches to a new event
  /// - Remote session revocation is detected (401 from API)
  ///
  /// After this call completes:
  /// - [read] for any key returns null
  /// - The router guard will detect no session and redirect to /setup
  /// - The device must scan a new setup QR code before scanning tickets
  ///
  /// ⚠ DESTRUCTIVE — Always confirm with the user before calling,
  /// except during automatic remote revocation handling.
  ///
  /// Throws [SecureStorageDeleteException] if the operation fails.
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      _log('✓ deleteAll → all session data cleared');
    } on Exception catch (e, stackTrace) {
      _logError('✗ deleteAll failed', e);
      throw SecureStorageDeleteException(
        key: '<all>',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ==========================================================================
  // CONTAINS KEY
  // ==========================================================================

  /// Returns [true] if [key] has a stored value.
  ///
  /// Returns [false] if the key does not exist OR if an error occurs.
  /// Error is logged but not thrown — false is the safe default.
  ///
  /// Parameters:
  /// - [key]: Storage key constant from [StorageKeys]
  Future<bool> containsKey({required String key}) async {
    try {
      final exists = await _storage.containsKey(key: key);
      _log('✓ containsKey → $key = $exists');
      return exists;
    } on Exception catch (e) {
      _logError('✗ containsKey failed → $key (returning false)', e);
      return false;
    }
  }

  // ==========================================================================
  // READ ALL (debug diagnostics only)
  // ==========================================================================

  /// Returns all stored key-value pairs as a Map.
  ///
  /// ⚠ ONLY available in debug builds (returns empty map in release).
  /// ⚠ NEVER display the raw output in production UI.
  ///
  /// Used for debugging storage state during development.
  /// Values are sanitized in logs — session token is partially masked.
  Future<Map<String, String>> readAll() async {
    if (!kDebugMode) {
      // In production, always return empty. Never expose all stored values.
      return {};
    }
    try {
      final all = await _storage.readAll();
      _log('✓ readAll → ${all.length} keys stored');
      return all;
    } on Exception catch (e) {
      _logError('✗ readAll failed', e);
      return {};
    }
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  /// Logs a debug message. Only active in debug builds.
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[SecureStorage] $message');
    }
  }

  /// Logs an error message. Only active in debug builds.
  void _logError(String message, Object error) {
    if (kDebugMode) {
      debugPrint('[SecureStorage] ERROR: $message — $error');
    }
  }

  /// Sanitizes a storage value for safe logging.
  ///
  /// Session tokens are partially masked to prevent accidental
  /// exposure in development logs or crash reports.
  String _sanitizeLogValue(String key, String? value) {
    if (value == null) return 'null';

    // Mask sensitive keys — show only first 6 chars + asterisks.
    const sensitiveKeys = {'scanner_session_token', 'device_uuid'};
    if (sensitiveKeys.contains(key)) {
      if (value.length <= 6) return '***';
      return '${value.substring(0, 6)}***';
    }

    return '"$value"';
  }
}

// ============================================================================
// EXCEPTIONS
// Typed exceptions for storage operations.
// Callers can catch these specifically to present appropriate UI errors.
// ============================================================================

/// Base class for all secure storage exceptions.
sealed class SecureStorageException implements Exception {
  const SecureStorageException({
    required this.key,
    required this.cause,
    this.stackTrace,
  });

  final String key;
  final Object cause;
  final StackTrace? stackTrace;
}

/// Thrown when a [SecureStorageService.write] operation fails.
final class SecureStorageWriteException extends SecureStorageException {
  const SecureStorageWriteException({
    required super.key,
    required super.cause,
    super.stackTrace,
  });

  @override
  String toString() =>
      'SecureStorageWriteException: Failed to write key "$key" — $cause';
}

/// Thrown when a [SecureStorageService.delete] or
/// [SecureStorageService.deleteAll] operation fails.
final class SecureStorageDeleteException extends SecureStorageException {
  const SecureStorageDeleteException({
    required super.key,
    required super.cause,
    super.stackTrace,
  });

  @override
  String toString() =>
      'SecureStorageDeleteException: Failed to delete key "$key" — $cause';
}