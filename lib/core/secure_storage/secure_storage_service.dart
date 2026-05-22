// ============================================================================
// Secure Storage Service — flutter_secure_storage wrapper
//
// Provides a clean interface over flutter_secure_storage.
// All sensitive data (session tokens, server URLs, event refs) must
// be stored through this service only.
//
// Full implementation in Phase 3.
// Phase 1: Skeleton with TODO markers.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provider for [SecureStorageService].
///
/// Use ref.read(secureStorageServiceProvider) to access secure storage.
/// Declared as a top-level provider for easy access in interceptors and router.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Wrapper around [FlutterSecureStorage] for the gate scanner app.
///
/// Provides simple read/write/delete methods with consistent error handling.
/// All storage operations are async — always await them.
///
/// Android: Uses Android Keystore for encryption.
/// iOS: Uses Keychain (when iOS support is added).
class SecureStorageService {
  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          // Android-specific options.
          aOptions: AndroidOptions(
            // Use encrypted shared preferences backed by Android Keystore.
            encryptedSharedPreferences: true,
          ),
        );

  final FlutterSecureStorage _storage;

  // TODO: Implement the following methods in Phase 3:
  // - write(String key, String value) → Future<void>
  // - read(String key) → Future<String?>
  // - delete(String key) → Future<void>
  // - deleteAll() → Future<void>
  // - containsKey(String key) → Future<bool>

  /// Writes a value to secure storage.
  ///
  /// If [value] is null, the key is deleted instead.
  Future<void> write(String key, String value) async {
    // TODO: Implement in Phase 3
    await _storage.write(key: key, value: value);
  }

  /// Reads a value from secure storage.
  ///
  /// Returns null if the key does not exist.
  Future<String?> read(String key) async {
    // TODO: Add error handling in Phase 3
    return await _storage.read(key: key);
  }

  /// Deletes a specific key from secure storage.
  Future<void> delete(String key) async {
    // TODO: Implement in Phase 3
    await _storage.delete(key: key);
  }

  /// Deletes ALL keys from secure storage.
  ///
  /// Called on logout, event binding reset, and session revocation.
  /// This completely clears the device binding — the user must
  /// scan a new setup QR code after this is called.
  Future<void> deleteAll() async {
    // TODO: Implement in Phase 3
    await _storage.deleteAll();
  }

  /// Checks whether a key exists in secure storage.
  Future<bool> containsKey(String key) async {
    // TODO: Implement in Phase 3
    return await _storage.containsKey(key: key);
  }
}