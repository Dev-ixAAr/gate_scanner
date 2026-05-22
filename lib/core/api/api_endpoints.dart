// ============================================================================
// API Endpoints — Backend route path constants
//
// All backend API endpoint paths are defined here as constants.
// Paths are relative to the server base URL stored in the session.
//
// FULL URL CONSTRUCTION:
// base URL (from session) + path (from this file)
// Example:
//   base: 'https://events.yourcompany.com'
//   path: '/api/scanner/setup/verify'
//   full: 'https://events.yourcompany.com/api/scanner/setup/verify'
//
// ASSUMPTION:
// These paths match the backend API implementation.
// If your backend uses different paths, update the constants here —
// no other file needs to change.
//
// All endpoints require the scanner session Bearer token EXCEPT:
// - verifySetupToken: uses a temporary unauthenticated Dio instance
// ============================================================================

/// Backend API endpoint path constants.
///
/// Always use these constants — never hardcode paths in repository files.
abstract final class ApiEndpoints {
  ApiEndpoints._();

  // ==========================================================================
  // SETUP FLOW
  // ==========================================================================

  /// Exchange a setup token for a scanner session token.
  ///
  /// Method:    POST
  /// Auth:      None (unauthenticated — token not yet established)
  /// Body:      SetupTokenExchangeRequest (see setup_repository.dart)
  /// Response:  ScannerSessionModel
  ///
  /// Called once during device setup. The setup_token from the QR code
  /// is submitted here. On success, the returned session_token is stored
  /// and used for all subsequent authenticated requests.
  static const String verifySetupToken = '/api/scanner/setup/verify';

  // ==========================================================================
  // SESSION MANAGEMENT
  // ==========================================================================

  /// Get the current scanner session details.
  ///
  /// Method:    GET
  /// Auth:      Bearer token required
  /// Response:  ScannerSessionModel
  ///
  /// Used by the home screen to verify the session is still active
  /// and to refresh displayed session info. If 401 is returned,
  /// the session has been revoked remotely.
  static const String getScannerSession = '/api/scanner/session';

  /// Logout the current scanner session on the server.
  ///
  /// Method:    POST
  /// Auth:      Bearer token required
  /// Body:      Empty or { device_name }
  /// Response:  { success: true }
  ///
  /// Called when the operator explicitly logs out from settings.
  /// After this call succeeds, clear the local session and navigate to /setup.
  static const String logoutScannerSession = '/api/scanner/session/logout';

  // ==========================================================================
  // TICKET VALIDATION
  // ==========================================================================

  /// Validate a ticket QR code.
  ///
  /// Method:    POST
  /// Auth:      Bearer token required
  /// Body:      { ticket_ref, event_public_ref, device_info }
  /// Response:  TicketValidationResult
  ///
  /// The primary scanning endpoint. Validates the scanned QR code value
  /// against the backend event database. Returns the validation status
  /// and ticket details.
  ///
  /// NOTE: This endpoint may also perform check-in atomically (depending
  /// on backend implementation). If a separate checkin call is required,
  /// use [checkinTicket] after receiving a 'valid' response.
  static const String validateTicketQr = '/api/scanner/ticket/validate';

  /// Search for a ticket by reference.
  ///
  /// Method:    GET
  /// Auth:      Bearer token required
  /// Query:     ?q=<search_query>&event_public_ref=<ref>
  /// Response:  SearchResultModel or { results: [...] }
  ///
  /// Used by the manual search screen. Allows lookup by ticket reference,
  /// order reference, or attendee name (backend determines search scope).
  static const String manualTicketSearch = '/api/scanner/ticket/search';

  /// Record a ticket check-in.
  ///
  /// Method:    POST
  /// Auth:      Bearer token required
  /// Body:      { ticket_ref, event_public_ref, device_info }
  /// Response:  TicketValidationResult with checked_in_at
  ///
  /// Called after the operator confirms a manual check-in, or if the
  /// backend requires explicit check-in confirmation separate from validation.
  static const String checkinTicket = '/api/scanner/ticket/checkin';
}