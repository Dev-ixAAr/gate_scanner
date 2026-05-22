// ============================================================================
// API Endpoints — Backend route path constants
//
// All backend API endpoint paths are defined here.
// Paths are relative to the base URL stored in session.
//
// Full implementation in Phase 5.
// Phase 1: Structure defined with placeholder paths.
// ============================================================================

/// Backend API endpoint path constants.
///
/// All paths are relative to the server base URL.
/// Example: If serverUrl = 'https://events.example.com'
/// And path = '/api/scanner/setup/verify'
/// Full URL = 'https://events.example.com/api/scanner/setup/verify'
///
/// TODO: Verify these paths match your backend implementation.
/// Adjust in Phase 5 to match the actual backend route structure.
abstract final class ApiEndpoints {
  ApiEndpoints._();

  // --------------------------------------------------------------------------
  // SETUP
  // --------------------------------------------------------------------------

  /// Exchange setup token for scanner session token.
  /// Method: POST
  /// Body: { setup_token, event_public_ref, device_name, ... }
  /// Response: { scanner_session_token, event_name, session_started_at }
  static const String verifySetupToken = '/api/scanner/setup/verify';

  // --------------------------------------------------------------------------
  // SESSION
  // --------------------------------------------------------------------------

  /// Get current scanner session details.
  /// Method: GET
  /// Auth: Bearer token required
  /// Response: { event_name, event_public_ref, session_started_at, is_active }
  static const String getScannerSession = '/api/scanner/session';

  /// Logout the current scanner session.
  /// Method: POST
  /// Auth: Bearer token required
  /// Response: { success: true }
  static const String logoutScannerSession = '/api/scanner/session/logout';

  // --------------------------------------------------------------------------
  // TICKET VALIDATION
  // --------------------------------------------------------------------------

  /// Validate a ticket QR code.
  /// Method: POST
  /// Auth: Bearer token required
  /// Body: { ticket_ref, event_public_ref, device_info }
  /// Response: { validation_status, ticket_data }
  static const String validateTicketQr = '/api/scanner/ticket/validate';

  /// Search for a ticket by reference number.
  /// Method: GET
  /// Auth: Bearer token required
  /// Query params: q=<search_query>, event_public_ref=<ref>
  /// Response: { ticket_data }
  static const String manualTicketSearch = '/api/scanner/ticket/search';

  /// Record a ticket check-in.
  /// Method: POST
  /// Auth: Bearer token required
  /// Body: { ticket_ref, event_public_ref, device_info }
  /// Response: { validation_status, ticket_data, checked_in_at }
  static const String checkinTicket = '/api/scanner/ticket/checkin';
}