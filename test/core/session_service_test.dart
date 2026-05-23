// ============================================================================
// Session Service Tests
//
// Unit tests for SessionService using mocktail to mock SecureStorageService.
//
// TESTING STRATEGY:
// - Mock SecureStorageService: prevents real storage operations in tests
// - Test each method in isolation: saveSession, getSession, clearSession,
//   isSessionActive, getSessionToken, getServerUrl
// - Test happy paths and edge cases (null values, partial storage)
//
// RUNNING TESTS:
// flutter test test/core/session_service_test.dart
//
// WITH COVERAGE:
// flutter test --coverage test/core/session_service_test.dart
// ============================================================================

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gate_scanner/core/constants/storage_keys.dart';
import 'package:gate_scanner/core/models/session_data.dart';
import 'package:gate_scanner/core/secure_storage/secure_storage_service.dart';
import 'package:gate_scanner/core/services/session_service.dart';

// ============================================================================
// MOCK CLASS
// mocktail generates mock implementations from this declaration.
// ============================================================================

class MockSecureStorageService extends Mock implements SecureStorageService {}

// ============================================================================
// TEST DATA
// Shared test fixtures used across multiple test groups.
// ============================================================================

const _testServerUrl = 'https://tickets.example.com';
const _testEventPublicRef = 'EVT-2024-TEST-001';
const _testEventName = 'Test Music Festival 2024';
const _testSessionToken = 'tok_test_xxxxxxxxxxxxxxxxxxxxxxxx';
final _testSessionStartedAt = DateTime(2024, 7, 15, 8, 30, 0);
const _testDeviceName = 'Samsung SM-A536B (Gate 1)';

// ============================================================================
// TESTS
// ============================================================================

void main() {
  late MockSecureStorageService mockStorage;
  late SessionService sessionService;

  setUp(() {
    mockStorage = MockSecureStorageService();
    sessionService = SessionService(storage: mockStorage);
  });

  // ==========================================================================
  // saveSession()
  // ==========================================================================

  group('saveSession', () {
    test('writes all required fields to storage', () async {
      // Arrange: stub all write calls to succeed (no-op).
      when(
        () => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')),
      ).thenAnswer((_) async {});

      // Act: save a complete session.
      await sessionService.saveSession(
        serverUrl: _testServerUrl,
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: _testSessionToken,
        sessionStartedAt: _testSessionStartedAt,
        deviceName: _testDeviceName,
      );

      // Assert: session written as a single atomic JSON bundle.
      final captured = verify(
        () => mockStorage.write(
          key: StorageKeys.sessionBundle,
          value: captureAny(named: 'value'),
        ),
      ).captured.single as String;

      final Map<String, dynamic> bundle =
          jsonDecode(captured) as Map<String, dynamic>;
      expect(bundle['server_url'], _testServerUrl);
      expect(bundle['event_public_ref'], _testEventPublicRef);
      expect(bundle['event_name'], _testEventName);
      expect(bundle['session_token'], _testSessionToken);
      expect(bundle['device_name'], _testDeviceName);
    });

    test('writes sessionStartedAt as UTC ISO 8601 string', () async {
      // Arrange.
      String? writtenDateValue;
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((invocation) async {
        final key = invocation.namedArguments[const Symbol('key')] as String;
        final value = invocation.namedArguments[const Symbol('value')] as String;
        if (key == StorageKeys.sessionBundle) {
          final Map<String, dynamic> bundle =
              jsonDecode(value) as Map<String, dynamic>;
          writtenDateValue = bundle['session_started_at'] as String?;
        }
      });

      // Act.
      final localTime = DateTime(2024, 7, 15, 8, 30, 0); // local time
      await sessionService.saveSession(
        serverUrl: _testServerUrl,
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: _testSessionToken,
        sessionStartedAt: localTime,
        deviceName: _testDeviceName,
      );

      // Assert: stored as UTC ISO 8601.
      expect(writtenDateValue, isNotNull);
      expect(writtenDateValue, contains('Z')); // UTC marker
      // Should parse back to the same UTC moment.
      final parsedBack = DateTime.parse(writtenDateValue!);
      expect(parsedBack.isUtc, isTrue);
    });

    test('trims whitespace from all string fields before writing', () async {
      // Arrange: stub writes.
      final writtenValues = <String, String>{};
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((invocation) async {
        final key = invocation.namedArguments[const Symbol('key')] as String;
        final value = invocation.namedArguments[const Symbol('value')] as String;
        writtenValues[key] = value;
      });

      // Act: call with values that have extra whitespace.
      await sessionService.saveSession(
        serverUrl: '  https://tickets.example.com  ',
        eventPublicRef: '  EVT-2024-TEST-001  ',
        eventName: '  Test Festival  ',
        sessionToken: '  tok_test_xxx  ',
        sessionStartedAt: _testSessionStartedAt,
        deviceName: '  Gate 1  ',
      );

      final bundleJson = writtenValues[StorageKeys.sessionBundle];
      expect(bundleJson, isNotNull);
      final Map<String, dynamic> bundle =
          jsonDecode(bundleJson!) as Map<String, dynamic>;
      expect(bundle['server_url'], 'https://tickets.example.com');
      expect(bundle['event_public_ref'], 'EVT-2024-TEST-001');
      expect(bundle['event_name'], 'Test Festival');
      expect(bundle['session_token'], 'tok_test_xxx');
      expect(bundle['device_name'], 'Gate 1');
    });

    test('propagates SecureStorageWriteException when write fails', () async {
      // Arrange: bundle write throws.
      when(
        () => mockStorage.write(
          key: StorageKeys.sessionBundle,
          value: any(named: 'value'),
        ),
      ).thenThrow(
        const SecureStorageWriteException(
          key: StorageKeys.sessionBundle,
          cause: 'Keystore unavailable',
        ),
      );

      // Act + Assert: exception propagates.
      await expectLater(
        () => sessionService.saveSession(
          serverUrl: _testServerUrl,
          eventPublicRef: _testEventPublicRef,
          eventName: _testEventName,
          sessionToken: _testSessionToken,
          sessionStartedAt: _testSessionStartedAt,
          deviceName: _testDeviceName,
        ),
        throwsA(isA<SecureStorageWriteException>()),
      );
    });
  });

  // ==========================================================================
  // getSession()
  // ==========================================================================

  group('getSession', () {
    test('returns SessionData when all fields are present and valid', () async {
      // Arrange: all storage reads return valid values.
      _stubAllStorageReads(
        mockStorage,
        serverUrl: _testServerUrl,
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: _testSessionToken,
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      );

      // Act.
      final session = await sessionService.getSession();

      // Assert: returns a valid SessionData.
      expect(session, isNotNull);
      expect(session!.serverUrl, _testServerUrl);
      expect(session.eventPublicRef, _testEventPublicRef);
      expect(session.eventName, _testEventName);
      expect(session.sessionToken, _testSessionToken);
      expect(session.deviceName, _testDeviceName);
      // Date should round-trip through ISO 8601 with UTC normalization.
      expect(
        session.sessionStartedAt.toIso8601String(),
        _testSessionStartedAt.toUtc().toIso8601String(),
      );
    });

    test('returns null when session token is missing', () async {
      // Arrange: sessionToken returns null (not configured).
      _stubAllStorageReads(
        mockStorage,
        serverUrl: _testServerUrl,
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: null, // ← missing
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      );

      // Act.
      final session = await sessionService.getSession();

      // Assert: null because required field is missing.
      expect(session, isNull);
    });

    test('returns null when server URL is missing', () async {
      _stubAllStorageReads(
        mockStorage,
        serverUrl: null, // ← missing
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: _testSessionToken,
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      );

      final session = await sessionService.getSession();
      expect(session, isNull);
    });

    test('returns null when event name is missing', () async {
      _stubAllStorageReads(
        mockStorage,
        serverUrl: _testServerUrl,
        eventPublicRef: _testEventPublicRef,
        eventName: null, // ← missing
        sessionToken: _testSessionToken,
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      );

      final session = await sessionService.getSession();
      expect(session, isNull);
    });

    test('returns null when all fields are null (fresh install)', () async {
      // Arrange: simulate fresh install — all reads return null.
      _stubAllStorageReads(
        mockStorage,
        serverUrl: null,
        eventPublicRef: null,
        eventName: null,
        sessionToken: null,
        sessionStartedAt: null,
        deviceName: null,
      );

      // Act.
      final session = await sessionService.getSession();

      // Assert: null — no session configured.
      expect(session, isNull);
    });

    test('returns null when sessionStartedAt cannot be parsed', () async {
      // Arrange: date is stored in an invalid format.
      _stubAllStorageReads(
        mockStorage,
        serverUrl: _testServerUrl,
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: _testSessionToken,
        sessionStartedAt: 'not-a-valid-date', // ← invalid
        deviceName: _testDeviceName,
      );

      // Act.
      final session = await sessionService.getSession();

      // Assert: null because date parsing failed.
      expect(session, isNull);
    });

    test('returns null when session token is empty string', () async {
      // Arrange: empty string (should be treated same as null).
      _stubAllStorageReads(
        mockStorage,
        serverUrl: _testServerUrl,
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: '', // ← empty
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      );

      final session = await sessionService.getSession();
      expect(session, isNull);
    });
  });

  // ==========================================================================
  // clearSession()
  // ==========================================================================

  group('clearSession', () {
    test('calls deleteAll on storage', () async {
      // Arrange.
      when(() => mockStorage.deleteAll()).thenAnswer((_) async {});

      // Act.
      await sessionService.clearSession();

      // Assert: deleteAll was called exactly once.
      verify(() => mockStorage.deleteAll()).called(1);
    });

    test('propagates SecureStorageDeleteException when deleteAll fails',
        () async {
      // Arrange: deleteAll throws.
      when(() => mockStorage.deleteAll()).thenThrow(
        const SecureStorageDeleteException(
          key: '<all>',
          cause: 'Storage unavailable',
        ),
      );

      // Act + Assert.
      await expectLater(
        () => sessionService.clearSession(),
        throwsA(isA<SecureStorageDeleteException>()),
      );
    });
  });

  // ==========================================================================
  // isSessionActive()
  // ==========================================================================

  group('isSessionActive', () {
    test('returns true when session token is present and non-empty', () async {
      _stubAllStorageReads(
        mockStorage,
        serverUrl: _testServerUrl,
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: 'tok_valid_token_here',
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      );

      final isActive = await sessionService.isSessionActive();

      expect(isActive, isTrue);
    });

    test('returns false when session token is null', () async {
      _stubAllStorageReads(
        mockStorage,
        serverUrl: _testServerUrl,
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: null,
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      );

      final isActive = await sessionService.isSessionActive();

      expect(isActive, isFalse);
    });

    test('returns false when session token is empty string', () async {
      _stubAllStorageReads(
        mockStorage,
        serverUrl: _testServerUrl,
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: '',
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      );

      final isActive = await sessionService.isSessionActive();

      expect(isActive, isFalse);
    });

    test('returns false when session token is whitespace only', () async {
      _stubAllStorageReads(
        mockStorage,
        serverUrl: _testServerUrl,
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: '   ',
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      );

      // Act.
      final isActive = await sessionService.isSessionActive();

      // Assert: whitespace-only token treated as inactive.
      expect(isActive, isFalse);
    });
  });

  // ==========================================================================
  // getSessionToken()
  // ==========================================================================

  group('getSessionToken', () {
    test('returns the stored session token', () async {
      _stubAllStorageReads(
        mockStorage,
        serverUrl: _testServerUrl,
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: _testSessionToken,
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      );

      final token = await sessionService.getSessionToken();

      expect(token, _testSessionToken);
    });

    test('returns null when no token is stored', () async {
      _stubAllStorageReads(
        mockStorage,
        serverUrl: null,
        eventPublicRef: null,
        eventName: null,
        sessionToken: null,
        sessionStartedAt: null,
        deviceName: null,
      );

      final token = await sessionService.getSessionToken();

      expect(token, isNull);
    });
  });

  // ==========================================================================
  // getServerUrl()
  // ==========================================================================

  group('getServerUrl', () {
    test('returns the stored server URL', () async {
      _stubAllStorageReads(
        mockStorage,
        serverUrl: _testServerUrl,
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: _testSessionToken,
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      );

      final url = await sessionService.getServerUrl();

      expect(url, _testServerUrl);
    });

    test('returns null when no URL is stored', () async {
      _stubAllStorageReads(
        mockStorage,
        serverUrl: null,
        eventPublicRef: null,
        eventName: null,
        sessionToken: null,
        sessionStartedAt: null,
        deviceName: null,
      );

      final url = await sessionService.getServerUrl();

      expect(url, isNull);
    });
  });

  // ==========================================================================
  // updateDeviceName()
  // ==========================================================================

  group('updateDeviceName', () {
    test('writes new device name when session is active', () async {
      _stubAllStorageReads(
        mockStorage,
        serverUrl: _testServerUrl,
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: _testSessionToken,
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      );

      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await sessionService.updateDeviceName('Gate 2 Scanner');

      final captured = verify(
        () => mockStorage.write(
          key: StorageKeys.sessionBundle,
          value: captureAny(named: 'value'),
        ),
      ).captured.last as String;
      final bundle = jsonDecode(captured) as Map<String, dynamic>;
      expect(bundle['device_name'], 'Gate 2 Scanner');
    });

    test('does not write when session is not active', () async {
      _stubAllStorageReads(
        mockStorage,
        serverUrl: null,
        eventPublicRef: null,
        eventName: null,
        sessionToken: null,
        sessionStartedAt: null,
        deviceName: null,
      );

      await sessionService.updateDeviceName('New Name');

      verifyNever(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    });
  });

  // ==========================================================================
  // SessionData model — unit tests
  // ==========================================================================

  group('SessionData.fromStorageValues', () {
    test('returns SessionData when all fields are valid', () {
      final session = SessionData.fromStorageValues(
        serverUrl: _testServerUrl,
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: _testSessionToken,
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      );

      expect(session, isNotNull);
      expect(session!.eventName, _testEventName);
    });

    test('returns null when any field is null', () {
      // Test each null field.
      final nullFields = [
        SessionData.fromStorageValues(
          serverUrl: null,
          eventPublicRef: _testEventPublicRef,
          eventName: _testEventName,
          sessionToken: _testSessionToken,
          sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
          deviceName: _testDeviceName,
        ),
        SessionData.fromStorageValues(
          serverUrl: _testServerUrl,
          eventPublicRef: null,
          eventName: _testEventName,
          sessionToken: _testSessionToken,
          sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
          deviceName: _testDeviceName,
        ),
        SessionData.fromStorageValues(
          serverUrl: _testServerUrl,
          eventPublicRef: _testEventPublicRef,
          eventName: null,
          sessionToken: _testSessionToken,
          sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
          deviceName: _testDeviceName,
        ),
        SessionData.fromStorageValues(
          serverUrl: _testServerUrl,
          eventPublicRef: _testEventPublicRef,
          eventName: _testEventName,
          sessionToken: null,
          sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
          deviceName: _testDeviceName,
        ),
        SessionData.fromStorageValues(
          serverUrl: _testServerUrl,
          eventPublicRef: _testEventPublicRef,
          eventName: _testEventName,
          sessionToken: _testSessionToken,
          sessionStartedAt: null,
          deviceName: _testDeviceName,
        ),
        SessionData.fromStorageValues(
          serverUrl: _testServerUrl,
          eventPublicRef: _testEventPublicRef,
          eventName: _testEventName,
          sessionToken: _testSessionToken,
          sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
          deviceName: null,
        ),
      ];

      for (final result in nullFields) {
        expect(result, isNull);
      }
    });

    test('returns null when any field is empty string', () {
      final result = SessionData.fromStorageValues(
        serverUrl: '',
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: _testSessionToken,
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      );
      expect(result, isNull);
    });

    test('copyWith returns new instance with updated fields', () {
      final original = SessionData.fromStorageValues(
        serverUrl: _testServerUrl,
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: _testSessionToken,
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      )!;

      final updated = original.copyWith(eventName: 'New Event Name');

      // Updated field changed.
      expect(updated.eventName, 'New Event Name');
      // All other fields unchanged.
      expect(updated.serverUrl, _testServerUrl);
      expect(updated.sessionToken, _testSessionToken);
      // Original not mutated.
      expect(original.eventName, _testEventName);
    });

    test('serverUrlDisplay strips https:// prefix', () {
      final session = SessionData.fromStorageValues(
        serverUrl: 'https://tickets.example.com',
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: _testSessionToken,
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      )!;

      expect(session.serverUrlDisplay, 'tickets.example.com');
    });

    test('serverUrlDisplay strips http:// prefix', () {
      final session = SessionData.fromStorageValues(
        serverUrl: 'http://192.168.1.100:8000',
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: _testSessionToken,
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      )!;

      expect(session.serverUrlDisplay, '192.168.1.100:8000');
    });

    test('equality: two sessions with same data are equal', () {
      final s1 = SessionData.fromStorageValues(
        serverUrl: _testServerUrl,
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: _testSessionToken,
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      )!;

      final s2 = SessionData.fromStorageValues(
        serverUrl: _testServerUrl,
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: _testSessionToken,
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      )!;

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
    });

    test('toString does not include sessionToken', () {
      final session = SessionData.fromStorageValues(
        serverUrl: _testServerUrl,
        eventPublicRef: _testEventPublicRef,
        eventName: _testEventName,
        sessionToken: _testSessionToken,
        sessionStartedAt: _testSessionStartedAt.toUtc().toIso8601String(),
        deviceName: _testDeviceName,
      )!;

      final str = session.toString();
      // Token must not appear in string representation.
      expect(str, isNot(contains(_testSessionToken)));
      // But other fields should appear.
      expect(str, contains(_testEventName));
      expect(str, contains(_testServerUrl));
    });
  });
}

// ============================================================================
// TEST HELPERS
// ============================================================================

/// Stubs session bundle (and legacy fallback) reads for tests.
void _stubAllStorageReads(
  MockSecureStorageService mockStorage, {
  required String? serverUrl,
  required String? eventPublicRef,
  required String? eventName,
  required String? sessionToken,
  required String? sessionStartedAt,
  required String? deviceName,
}) {
  final bool allPresent = serverUrl != null &&
      eventPublicRef != null &&
      eventName != null &&
      sessionToken != null &&
      sessionStartedAt != null &&
      deviceName != null;

  when(() => mockStorage.read(key: StorageKeys.sessionBundle)).thenAnswer(
    (_) async => allPresent
        ? jsonEncode({
            'server_url': serverUrl,
            'event_public_ref': eventPublicRef,
            'event_name': eventName,
            'session_token': sessionToken,
            'session_started_at': sessionStartedAt,
            'device_name': deviceName,
          })
        : null,
  );

  when(() => mockStorage.read(key: StorageKeys.serverUrl))
      .thenAnswer((_) async => serverUrl);
  when(() => mockStorage.read(key: StorageKeys.eventPublicRef))
      .thenAnswer((_) async => eventPublicRef);
  when(() => mockStorage.read(key: StorageKeys.eventName))
      .thenAnswer((_) async => eventName);
  when(() => mockStorage.read(key: StorageKeys.sessionToken))
      .thenAnswer((_) async => sessionToken);
  when(() => mockStorage.read(key: StorageKeys.sessionStartedAt))
      .thenAnswer((_) async => sessionStartedAt);
  when(() => mockStorage.read(key: StorageKeys.deviceName))
      .thenAnswer((_) async => deviceName);

  when(() => mockStorage.containsKey(key: any(named: 'key')))
      .thenAnswer((_) async => false);
  when(() => mockStorage.delete(key: any(named: 'key')))
      .thenAnswer((_) async {});
}