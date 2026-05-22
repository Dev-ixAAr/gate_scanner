// ============================================================================
// Setup QR Payload — Parsed data from admin setup QR code
//
// The admin panel generates a QR code containing JSON with these fields.
// The app scans this QR code to begin the setup token exchange flow.
//
// Expected QR JSON format:
// {
//   "server_url": "https://events.yourcompany.com",
//   "event_public_ref": "EVT-2024-SUMMER",
//   "setup_token": "tok_xxxxxxxxxxxxxxxx",
//   "expires_at": "2024-12-31T23:59:59.000Z"
// }
//
// Full implementation with freezed in Phase 4.
// Phase 1: Structure defined.
// ============================================================================

// TODO: Add freezed in Phase 4
// import 'package:freezed_annotation/freezed_annotation.dart';
// part 'setup_qr_payload.freezed.dart';
// part 'setup_qr_payload.g.dart';

/// Represents the data contained in an admin setup QR code.
///
/// Created by parsing the JSON string from the scanned QR code.
/// Validated before proceeding with token exchange.
class SetupQrPayload {
  const SetupQrPayload({
    required this.serverUrl,
    required this.eventPublicRef,
    required this.setupToken,
    required this.expiresAt,
  });

  // TODO: Replace with freezed fromJson in Phase 4

  /// Backend server base URL.
  final String serverUrl;

  /// Event public reference identifier.
  final String eventPublicRef;

  /// One-time setup token to exchange for a scanner session token.
  final String setupToken;

  /// When this setup QR code expires.
  final DateTime expiresAt;

  /// Returns true if the setup QR has passed its expiry time.
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}