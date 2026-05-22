// ============================================================================
// Session Service — Session read/write/clear logic
//
// Manages the scanner session lifecycle:
// - Save session after successful setup token exchange
// - Read session data for display and API calls
// - Clear session on logout, reset, or remote revocation
//
// Full implementation in Phase 3.
// Phase 1: Skeleton with TODO markers.
// ============================================================================

// TODO: Implement full SessionService in Phase 3
// This file defines the structure and contract.

/// Manages the active scanner session stored in secure storage.
///
/// All session operations go through this service.
/// Do not read storage keys directly — use this service.
class SessionService {
  // TODO: Implement in Phase 3 with SecureStorageService injection

  // Methods to implement in Phase 3:
  // - Future<void> saveSession({...}) → stores all session fields
  // - Future<SessionData?> getSession() → reads and assembles SessionData
  // - Future<void> clearSession() → deletes all stored session keys
  // - Future<bool> isSessionActive() → checks if token exists
  // - Future<String?> getSessionToken() → reads token only
  // - Future<String?> getServerUrl() → reads server URL only
}