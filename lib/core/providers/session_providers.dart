// ============================================================================
// Session Providers — Reactive Riverpod providers for session state
//
// This file centralizes all session-related providers that are consumed
// by multiple features (router, home screen, settings screen, API client).
//
// PROVIDER HIERARCHY:
//
// secureStorageServiceProvider   ← raw encrypted storage
//        ↓
// sessionServiceProvider         ← session CRUD operations
//        ↓
// sessionDataProvider            ← current session as reactive state
//        ↓
// isSessionActiveProvider        ← bool: is there an active session?
// currentEventNameProvider       ← String?: active event name
// currentServerUrlProvider       ← String?: active server URL
// currentEventPublicRefProvider  ← String?: active event public ref
// currentDeviceNameProvider      ← String?: active device name
//
// HOW TO USE:
//
// In a screen that needs to show event info:
// ```dart
// final sessionAsync = ref.watch(sessionDataProvider);
// sessionAsync.when(
//   data: (session) => session != null
//     ? Text(session.eventName)
//     : Text('No session'),
//   loading: () => CircularProgressIndicator(),
//   error: (e, _) => Text('Error: $e'),
// );
// ```
//
// In a provider that needs the session token:
// ```dart
// final token = await ref.read(sessionServiceProvider).getSessionToken();
// ```
//
// REFRESH PATTERN:
// After saveSession() or clearSession(), invalidate the provider:
// ```dart
// ref.invalidate(sessionDataProvider);
// ```
// This causes all widgets watching sessionDataProvider to rebuild.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session_data.dart';
import '../services/session_service.dart';

// Re-export sessionServiceProvider here so features only need to import
// this one file for all session-related providers.
export '../services/session_service.dart' show sessionServiceProvider;

// ==========================================================================
// SESSION DATA PROVIDER
// Primary reactive session state used by UI screens.
// ==========================================================================

/// Provides the current [SessionData] as an async value.
///
/// Returns [null] when no session is active (device not configured).
/// Returns a complete [SessionData] when a session exists in storage.
///
/// This is a [FutureProvider] because reading from secure storage is async.
/// The UI handles loading, data, and error states with `.when()`.
///
/// INVALIDATION:
/// After any session change (save, clear, update), call:
/// ```dart
/// ref.invalidate(sessionDataProvider);
/// ```
/// This forces a re-read from storage and rebuilds all watching widgets.
///
/// WATCHING vs READING:
/// - Use [ref.watch] in ConsumerWidget.build() for reactive UI.
/// - Use [ref.read] in callbacks/handlers for one-time reads.
final sessionDataProvider = FutureProvider<SessionData?>((ref) async {
  // Watch the session service so this provider re-computes if the
  // service provider is replaced (e.g., in tests).
  final sessionService = ref.watch(sessionServiceProvider);
  return sessionService.getSession();
});

// ==========================================================================
// IS SESSION ACTIVE PROVIDER
// Lightweight bool check — used in guards and conditional renders.
// ==========================================================================

/// Provides a bool indicating whether an active session exists.
///
/// Derived from [sessionDataProvider] — returns true when the session
/// data is loaded and non-null.
///
/// Usage:
/// ```dart
/// final isActiveAsync = ref.watch(isSessionActiveProvider);
/// final isActive = isActiveAsync.valueOrNull ?? false;
/// ```
///
/// Note: Returns false during loading (AsyncValue.loading) and on error.
/// This is intentionally safe — default to "not active" when uncertain.
final isSessionActiveProvider = FutureProvider<bool>((ref) async {
  final sessionService = ref.watch(sessionServiceProvider);
  return sessionService.isSessionActive();
});

// ==========================================================================
// INDIVIDUAL FIELD PROVIDERS
// Convenience providers for screens that only need one session field.
// Avoids loading the full SessionData when only one field is needed.
// ==========================================================================

/// Provides the current event name, or [null] if no session is active.
///
/// Used by:
/// - AppBar titles in scanner-related screens
/// - Home screen event card
/// - Settings screen session info section
///
/// Usage:
/// ```dart
/// final eventNameAsync = ref.watch(currentEventNameProvider);
/// final eventName = eventNameAsync.valueOrNull ?? 'No event';
/// ```
final currentEventNameProvider = FutureProvider<String?>((ref) async {
  final session = await ref.watch(sessionDataProvider.future);
  return session?.eventName;
});

/// Provides the current server URL, or [null] if no session is active.
///
/// Used by:
/// - Home screen connection card
/// - Settings screen session info section
/// - API client base URL configuration
final currentServerUrlProvider = FutureProvider<String?>((ref) async {
  final session = await ref.watch(sessionDataProvider.future);
  return session?.serverUrl;
});

/// Provides the current event public reference, or [null] if not active.
///
/// Used by:
/// - Home screen event card
/// - Settings screen session info section
/// - Ticket validation requests (included in request body)
final currentEventPublicRefProvider = FutureProvider<String?>((ref) async {
  final session = await ref.watch(sessionDataProvider.future);
  return session?.eventPublicRef;
});

/// Provides the current device name, or [null] if no session is active.
///
/// Used by:
/// - Home screen connection card
/// - Settings screen device info section
/// - API request payloads
final currentDeviceNameProvider = FutureProvider<String?>((ref) async {
  final session = await ref.watch(sessionDataProvider.future);
  return session?.deviceName;
});

/// Provides the current session start time, or [null] if not active.
///
/// Used by:
/// - Home screen session card ("Session started at: ...")
/// - Settings screen session info section
final sessionStartedAtProvider = FutureProvider<DateTime?>((ref) async {
  final session = await ref.watch(sessionDataProvider.future);
  return session?.sessionStartedAt;
});

// ==========================================================================
// SESSION STATE NOTIFIER
//
// A StateProvider<bool> that acts as a synchronous "session changed" signal.
// Incrementing this value triggers any provider that reads it to refresh.
//
// USAGE PATTERN:
// This is the preferred way to trigger router redirect re-evaluation
// after session changes, because the router's redirect function cannot
// easily watch FutureProviders.
//
// After any session change:
// ```dart
// ref.read(sessionChangeSignalProvider.notifier).state++;
// // OR use the helper:
// ref.invalidate(sessionDataProvider);
// ```
// ==========================================================================

/// Signal counter used to trigger session state re-evaluation.
///
/// Increment this after any session change to notify dependents:
/// ```dart
/// ref.read(sessionChangeSignalProvider.notifier).state++;
/// ```
///
/// The router refresh notifier reads this to know when to re-run guards.
final sessionChangeSignalProvider = StateProvider<int>((ref) => 0);