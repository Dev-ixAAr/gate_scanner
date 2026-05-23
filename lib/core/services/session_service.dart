// ============================================================================
// Session Service — Scanner session lifecycle management
// ============================================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/storage_keys.dart';
import '../models/session_data.dart';
import '../secure_storage/secure_storage_service.dart';

final sessionServiceProvider = Provider<SessionService>((ref) {
  final storage = ref.read(secureStorageServiceProvider);
  return SessionService(storage: storage);
});

/// Manages the complete lifecycle of a scanner session.
class SessionService {
  const SessionService({required SecureStorageService storage})
      : _storage = storage;

  final SecureStorageService _storage;

  Future<void> saveSession({
    required String serverUrl,
    required String eventPublicRef,
    required String eventName,
    required String sessionToken,
    required DateTime sessionStartedAt,
    required String deviceName,
  }) async {
    _debugLog('saveSession → event: "$eventName" server: "$serverUrl"');

    final Map<String, String> bundle = {
      'server_url': serverUrl.trim(),
      'event_public_ref': eventPublicRef.trim(),
      'event_name': eventName.trim(),
      'session_token': sessionToken.trim(),
      'session_started_at': sessionStartedAt.toUtc().toIso8601String(),
      'device_name': deviceName.trim(),
    };

    // Single write — avoids partial session state if a write fails mid-flight.
    await _storage.write(
      key: StorageKeys.sessionBundle,
      value: jsonEncode(bundle),
    );

    await _purgeLegacySessionKeys();
    _debugLog('saveSession → complete');
  }

  Future<SessionData?> getSession() async {
    _debugLog('getSession → reading session');

    final SessionData? fromBundle = await _readSessionFromBundle();
    if (fromBundle != null) {
      _debugLog('getSession → loaded from bundle: ${fromBundle.eventName}');
      return fromBundle;
    }

    final SessionData? fromLegacy = await _readSessionFromLegacyKeys();
    if (fromLegacy != null) {
      _debugLog('getSession → migrating legacy keys to bundle');
      await saveSession(
        serverUrl: fromLegacy.serverUrl,
        eventPublicRef: fromLegacy.eventPublicRef,
        eventName: fromLegacy.eventName,
        sessionToken: fromLegacy.sessionToken,
        sessionStartedAt: fromLegacy.sessionStartedAt,
        deviceName: fromLegacy.deviceName,
      );
      return fromLegacy;
    }

    _debugLog('getSession → no valid session found');
    return null;
  }

  Future<void> clearSession() async {
    _debugLog('clearSession → wiping all session data');
    await _storage.deleteAll();
    _debugLog('clearSession → complete');
  }

  Future<bool> isSessionActive() async {
    final token = await getSessionToken();
    final isActive = token != null && token.trim().isNotEmpty;
    _debugLog('isSessionActive → $isActive');
    return isActive;
  }

  Future<String?> getSessionToken() async {
    final session = await getSession();
    return session?.sessionToken;
  }

  Future<String?> getServerUrl() async {
    final session = await getSession();
    return session?.serverUrl;
  }

  Future<String?> getEventPublicRef() async {
    final session = await getSession();
    return session?.eventPublicRef;
  }

  Future<String?> getDeviceName() async {
    final session = await getSession();
    return session?.deviceName;
  }

  Future<void> updateDeviceName(String newDeviceName) async {
    final session = await getSession();
    if (session == null) return;

    await saveSession(
      serverUrl: session.serverUrl,
      eventPublicRef: session.eventPublicRef,
      eventName: session.eventName,
      sessionToken: session.sessionToken,
      sessionStartedAt: session.sessionStartedAt,
      deviceName: newDeviceName,
    );
    _debugLog('updateDeviceName → "$newDeviceName"');
  }

  Future<SessionData?> _readSessionFromBundle() async {
    final String? raw = await _storage.read(key: StorageKeys.sessionBundle);
    if (raw == null || raw.isEmpty) return null;

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await _storage.delete(key: StorageKeys.sessionBundle);
        return null;
      }

      final session = SessionData.fromStorageValues(
        serverUrl: decoded['server_url']?.toString(),
        eventPublicRef: decoded['event_public_ref']?.toString(),
        eventName: decoded['event_name']?.toString(),
        sessionToken: decoded['session_token']?.toString(),
        sessionStartedAt: decoded['session_started_at']?.toString(),
        deviceName: decoded['device_name']?.toString(),
      );

      if (session == null) {
        await _storage.delete(key: StorageKeys.sessionBundle);
      }
      return session;
    } catch (e) {
      _debugLog('getSession → corrupt bundle: $e');
      await _storage.delete(key: StorageKeys.sessionBundle);
      return null;
    }
  }

  Future<SessionData?> _readSessionFromLegacyKeys() async {
    final results = await Future.wait([
      _storage.read(key: StorageKeys.serverUrl),
      _storage.read(key: StorageKeys.eventPublicRef),
      _storage.read(key: StorageKeys.eventName),
      _storage.read(key: StorageKeys.sessionToken),
      _storage.read(key: StorageKeys.sessionStartedAt),
      _storage.read(key: StorageKeys.deviceName),
    ]);

    return SessionData.fromStorageValues(
      serverUrl: results[0],
      eventPublicRef: results[1],
      eventName: results[2],
      sessionToken: results[3],
      sessionStartedAt: results[4],
      deviceName: results[5],
    );
  }

  Future<void> _purgeLegacySessionKeys() async {
    const legacyKeys = [
      StorageKeys.serverUrl,
      StorageKeys.eventPublicRef,
      StorageKeys.eventName,
      StorageKeys.sessionToken,
      StorageKeys.sessionStartedAt,
      StorageKeys.deviceName,
    ];

    for (final key in legacyKeys) {
      try {
        if (await _storage.containsKey(key: key)) {
          await _storage.delete(key: key);
        }
      } catch (_) {
        // Best-effort cleanup.
      }
    }
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[SessionService] $message');
    }
  }
}
