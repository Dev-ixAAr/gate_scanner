// ============================================================================
// Secure Storage Service — flutter_secure_storage wrapper
//
// Full implementation required in Phase 2 because the router's
// session guard depends on reading the session token from storage.
//
// Android: Uses EncryptedSharedPreferences backed by Android Keystore.
// All data is encrypted at rest — appropriate for session tokens.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Riverpod provider for [SecureStorageService].
///
/// Accessible throughout the app via:
/// ```dart
/// final storage = ref.read(secureStorageServiceProvider);
/// ```
///
/// Use [ref.read] (not watch) for storage — it doesn't emit state changes.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService._();
});

/// Wrapper around [FlutterSecureStorage] for gate_scanner.
///
/// Provides a clean, tested interface with consistent error handling.
///
/// Key design decisions:
/// - All methods are async (storage operations must not block UI)
/// - Errors are caught and logged — never crash the app on storage failure
/// - Read returns null on missing key (not an exception)
/// - deleteAll() is used for full session clear on logout/reset
///
/// Do not access [FlutterSecureStorage] directly in feature code —
/// always go through this service.
class SecureStorageService {
  SecureStorageService._()
      : _storage = const FlutterSecureStorage(
          // Android-specific configuration.
          aOptions: AndroidOptions(
            // Use EncryptedSharedPreferences backed by Android Keystore.
            // This is the most secure option available on Android.
            // Data is encrypted using AES-256 with keys stored in Keystore.
            encryptedSharedPreferences: true,
          ),
          // iOS-specific configuration (for future iOS support).
          // iOptions: IOSOptions(
          //   accessibility: KeychainAccessibility.first_unlock,
          // ),
        );

  final FlutterSecureStorage _storage;

  // ==========================================================================
  // WRITE
  // ==========================================================================

  /// Writes [value] for [key] to encrypted secure storage.
  ///
  /// If an error occurs (e.g., Keystore unavailable), logs the error
  /// and rethrows so callers can handle it appropriately.
  ///
  /// Throws [SecureStorageException] if write fails.
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      debugPrint('[SecureStorage] Written: $key');
    } catch (e) {
      debugPrint('[SecureStorage] Write failed for key "$key": $e');
      throw SecureStorageException(
        operation: 'write',
        key: key,
        cause: e,
      );
    }
  }

  // ==========================================================================
  // READ
  // ==========================================================================

  /// Reads the value for [key] from encrypted secure storage.
  ///
  /// Returns null if the key does not exist.
  /// Returns null (does not throw) if a read error occurs — callers
  /// treat null as "not configured" which is the safe default.
  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value;
    } catch (e) {
      debugPrint('[SecureStorage] Read failed for key "$key": $e');
      // Return null on read failure — treat as "not found".
      // This is intentionally lenient: a storage read failure should not
      // crash the app or lock the user out permanently.
      return null;
    }
  }

  // ==========================================================================
  // DELETE (Single Key)
  // ==========================================================================

  /// Deletes the value for [key] from encrypted secure storage.
  ///
  /// No-op if the key doesn't exist.
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      debugPrint('[SecureStorage] Deleted: $key');
    } catch (e) {
      debugPrint('[SecureStorage] Delete failed for key "$key": $e');
      throw SecureStorageException(
        operation: 'delete',
        key: key,
        cause: e,
      );
    }
  }

  // ==========================================================================
  // DELETE ALL (Session Clear)
  // ==========================================================================

  /// Deletes ALL keys from encrypted secure storage.
  ///
  /// Called when:
  /// - User logs out the scanner session
  /// - User resets the event binding
  /// - Remote session revocation is detected (401 from API)
  /// - User switches to a new event
  ///
  /// After this call, the app will redirect to the setup screen
  /// because the session guard will find no session token.
  ///
  /// ⚠ This is a destructive operation. Always confirm with the user
  /// before calling, except in the case of remote revocation.
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      debugPrint('[SecureStorage] All keys deleted (session cleared)');
    } catch (e) {
      debugPrint('[SecureStorage] Delete all failed: $e');
      throw SecureStorageException(
        operation: 'deleteAll',
        key: '*',
        cause: e,
      );
    }
  }

  // ==========================================================================
  // CONTAINS KEY
  // ==========================================================================

  /// Returns true if [key] exists in secure storage.
  ///
  /// More explicit than checking if read() returns non-null.
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      debugPrint('[SecureStorage] containsKey failed for "$key": $e');
      return false;
    }
  }

  // ==========================================================================
  // READ ALL (Debug only)
  // ==========================================================================

  /// Reads all stored key-value pairs.
  ///
  /// ⚠ ONLY USE IN DEBUG BUILDS for diagnostic purposes.
  /// Never expose stored values in production UI.
  Future<Map<String, String>> readAll() async {
    if (!kDebugMode) {
      // Silently return empty map in production — never expose all storage.
      return {};
    }
    try {
      final all = await _storage.readAll();
      return all;
    } catch (e) {
      debugPrint('[SecureStorage] readAll failed: $e');
      return {};
    }
  }
}

// ============================================================================
// SECURE STORAGE EXCEPTION
// ============================================================================

/// Exception thrown when a secure storage operation fails.
///
/// Provides context about which operation and key caused the failure.
class SecureStorageException implements Exception {
  const SecureStorageException({
    required this.operation,
    required this.key,
    required this.cause,
  });

  /// The storage operation that failed (read, write, delete, deleteAll).
  final String operation;

  /// The key involved in the failed operation. '*' for deleteAll.
  final String key;

  /// The underlying error that caused the failure.
  final Object cause;

  @override
  String toString() =>
      'SecureStorageException: $operation("$key") failed — $cause';
}