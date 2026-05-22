// ============================================================================
// Ticket Validation Result — Sealed union for all validation outcomes
//
// DESIGN DECISION — Plain Dart sealed classes (not Freezed):
// Dart 3 sealed classes provide exhaustive switch expressions natively.
// For this 7-variant union, sealed classes give full type safety and
// exhaustive matching without code generation overhead.
//
// BACKEND CONTRACT:
// The backend returns a JSON object with a top-level 'validation_status'
// field that determines which variant to construct.
//
// EXPECTED RESPONSE FORMAT:
// {
//   "validation_status": "valid",   // determines the variant
//   "ticket_reference": "TKT-001",
//   "order_reference": "ORD-2024-001",
//   "holder_name": "John Smith",
//   "ticket_category": "VIP",
//   "ticket_source_type": "online",
//   "event_name": "Summer Festival",
//   "checkin_status": "checked_in",
//   // ... other fields depending on status
// }
//
// STATUS → VARIANT MAPPING:
// "valid"          → ValidResult
// "already_used"   → AlreadyUsedResult
// "already_checked_in" → AlreadyUsedResult (alias)
// "wrong_event"    → WrongEventResult
// "revoked"        → RevokedResult
// "cancelled"      → CancelledResult
// "invalid"        → InvalidResult
// anything else    → InvalidResult (safe fallback)
// ============================================================================

/// Sealed base class for all ticket validation outcomes.
///
/// Use exhaustive switch expressions to handle all variants:
/// ```dart
/// switch (result) {
///   case ValidResult():
///     // Show green admit UI
///   case AlreadyUsedResult():
///     // Show amber already-scanned UI
///   case WrongEventResult():
///     // Show orange wrong-event UI
///   case RevokedResult():
///   case CancelledResult():
///   case InvalidResult():
///   case ErrorResult():
///     // Show red deny UI
/// }
/// ```
sealed class TicketValidationResult {
  const TicketValidationResult();

  // ==========================================================================
  // fromJson FACTORY
  // ==========================================================================

  /// Constructs the correct [TicketValidationResult] variant from a JSON map.
  ///
  /// Reads the 'validation_status' field to determine which variant to create.
  /// Falls back to [InvalidResult] for any unrecognized status value.
  ///
  /// Never throws — always returns a valid result variant.
  /// Network/parse errors should be caught before calling this method
  /// and converted to [ErrorResult] by the repository.
  factory TicketValidationResult.fromJson(Map<String, dynamic> json) {
    final String status =
        (json['validation_status'] as String? ?? '').toLowerCase().trim();

    switch (status) {
      // ── Valid ──────────────────────────────────────────────────────────────
      case 'valid':
        return ValidResult(
          ticketReference: _str(json, 'ticket_reference'),
          orderReference: _str(json, 'order_reference'),
          holderName: _str(json, 'holder_name', fallback: 'Unknown Holder'),
          ticketCategory: _str(json, 'ticket_category', fallback: 'General'),
          ticketSourceType: _str(json, 'ticket_source_type', fallback: 'online'),
          eventName: _str(json, 'event_name'),
          checkinStatus: _str(json, 'checkin_status', fallback: 'checked_in'),
        );

      // ── Already Used ───────────────────────────────────────────────────────
      case 'already_used':
      case 'already_checked_in':
        return AlreadyUsedResult(
          ticketReference: _str(json, 'ticket_reference'),
          checkedInAt: _dateTime(json, 'checked_in_at') ?? DateTime.now(),
          checkedInByDevice:
              _str(json, 'checked_in_by_device', fallback: 'Unknown Device'),
          checkedInByUser:
              _str(json, 'checked_in_by_user', fallback: 'Unknown'),
        );

      // ── Wrong Event ────────────────────────────────────────────────────────
      case 'wrong_event':
        return WrongEventResult(
          message: _str(
            json,
            'message',
            fallback: 'This ticket belongs to a different event.',
          ),
          ticketReference: _str(json, 'ticket_reference'),
          actualEventName: json['actual_event_name'] as String?,
        );

      // ── Revoked ────────────────────────────────────────────────────────────
      case 'revoked':
        return RevokedResult(
          ticketReference: _str(json, 'ticket_reference'),
          reason: json['reason'] as String?,
        );

      // ── Cancelled ──────────────────────────────────────────────────────────
      case 'cancelled':
        return CancelledResult(
          ticketReference: _str(json, 'ticket_reference'),
          reason: json['reason'] as String?,
        );

      // ── Invalid ────────────────────────────────────────────────────────────
      case 'invalid':
        return InvalidResult(
          message: _str(
            json,
            'message',
            fallback: 'This QR code is not a valid ticket.',
          ),
        );

      // ── Fallback ───────────────────────────────────────────────────────────
      default:
        return InvalidResult(
          message: status.isNotEmpty
              ? 'Unrecognized ticket status: "$status".'
              : 'No validation status returned from server.',
        );
    }
  }

  // ==========================================================================
  // PRIVATE PARSING HELPERS
  // ==========================================================================

  static String _str(
    Map<String, dynamic> json,
    String key, {
    String fallback = '',
  }) {
    final dynamic value = json[key];
    if (value == null) return fallback;
    final String str = value.toString().trim();
    return str.isEmpty ? fallback : str;
  }

  static DateTime? _dateTime(Map<String, dynamic> json, String key) {
    final dynamic value = json[key];
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}

// ============================================================================
// VARIANT 1 — VALID
// Ticket is valid and has been checked in.
// Gate operator should ADMIT the holder.
// ============================================================================

/// Ticket is valid. Admit the holder.
///
/// All fields are populated from the validation response.
/// These are displayed on the green result screen.
final class ValidResult extends TicketValidationResult {
  const ValidResult({
    required this.ticketReference,
    required this.orderReference,
    required this.holderName,
    required this.ticketCategory,
    required this.ticketSourceType,
    required this.eventName,
    required this.checkinStatus,
  });

  /// The ticket's unique reference code.
  /// Example: 'TKT-2024-00123'
  final String ticketReference;

  /// The order this ticket belongs to.
  /// Example: 'ORD-2024-00456'
  final String orderReference;

  /// Name of the ticket holder.
  /// Displayed prominently — the most important field for gate operators.
  final String holderName;

  /// Ticket category/tier.
  /// Examples: 'VIP', 'General Admission', 'Early Bird', 'Staff'
  final String ticketCategory;

  /// How the ticket was acquired.
  /// Values: 'online', 'physical', 'complimentary'
  final String ticketSourceType;

  /// Name of the event this ticket is for.
  /// Should match the connected event — shown for confirmation.
  final String eventName;

  /// Check-in status after this validation.
  /// Typically 'checked_in' after a successful scan.
  final String checkinStatus;

  @override
  String toString() => 'ValidResult(holder: "$holderName", ref: "$ticketReference")';
}

// ============================================================================
// VARIANT 2 — ALREADY USED
// Ticket has already been scanned. Possible duplicate entry attempt.
// Gate operator should investigate.
// ============================================================================

/// Ticket was already scanned. Possible duplicate or tailgating.
///
/// Shows when and by whom the original check-in was recorded.
final class AlreadyUsedResult extends TicketValidationResult {
  const AlreadyUsedResult({
    required this.ticketReference,
    required this.checkedInAt,
    required this.checkedInByDevice,
    required this.checkedInByUser,
  });

  final String ticketReference;

  /// When the ticket was first checked in.
  /// Displayed as a formatted local datetime.
  final DateTime checkedInAt;

  /// Device name that recorded the original check-in.
  /// Example: 'Samsung SM-A536B (Gate 2)'
  final String checkedInByDevice;

  /// Username/operator who performed the original check-in.
  /// Example: 'scanner_gate1' or 'John (Operator)'
  final String checkedInByUser;

  @override
  String toString() =>
      'AlreadyUsedResult(ref: "$ticketReference", checkedInAt: $checkedInAt)';
}

// ============================================================================
// VARIANT 3 — WRONG EVENT
// Ticket is valid but for a different event.
// Gate operator should DENY and redirect the holder.
// ============================================================================

/// Ticket belongs to a different event. Block entry.
final class WrongEventResult extends TicketValidationResult {
  const WrongEventResult({
    required this.message,
    this.ticketReference = '',
    this.actualEventName,
  });

  final String message;
  final String ticketReference;

  /// The event this ticket actually belongs to, if returned by backend.
  final String? actualEventName;

  @override
  String toString() => 'WrongEventResult(message: "$message")';
}

// ============================================================================
// VARIANT 4 — REVOKED
// Ticket was explicitly revoked by the organizer.
// Gate operator must DENY entry.
// ============================================================================

/// Ticket has been revoked by the event organizer.
final class RevokedResult extends TicketValidationResult {
  const RevokedResult({
    required this.ticketReference,
    this.reason,
  });

  final String ticketReference;

  /// Optional reason for revocation provided by the organizer.
  /// Example: 'Refunded', 'Fraudulent purchase', 'Organizer decision'
  final String? reason;

  @override
  String toString() => 'RevokedResult(ref: "$ticketReference")';
}

// ============================================================================
// VARIANT 5 — CANCELLED
// Order or ticket was cancelled.
// Gate operator must DENY entry.
// ============================================================================

/// Ticket or its order has been cancelled.
final class CancelledResult extends TicketValidationResult {
  const CancelledResult({
    required this.ticketReference,
    this.reason,
  });

  final String ticketReference;

  /// Optional reason for cancellation.
  /// Example: 'Order refunded', 'Payment failed'
  final String? reason;

  @override
  String toString() => 'CancelledResult(ref: "$ticketReference")';
}

// ============================================================================
// VARIANT 6 — INVALID
// QR code not recognized or malformed.
// Gate operator must DENY entry.
// ============================================================================

/// QR code is not recognized as a valid ticket.
///
/// Could be: random QR code, wrong format, not in system.
final class InvalidResult extends TicketValidationResult {
  const InvalidResult({required this.message});

  /// Human-readable explanation of why the ticket is invalid.
  final String message;

  @override
  String toString() => 'InvalidResult(message: "$message")';
}

// ============================================================================
// VARIANT 7 — ERROR
// Network or server error during validation.
// Not a ticket status — a scanner communication failure.
// ============================================================================

/// Scanner encountered an error during validation.
///
/// This is NOT a ticket validation state — it indicates a technical
/// failure (network error, server error, timeout).
/// The operator should retry or check connectivity.
final class ErrorResult extends TicketValidationResult {
  const ErrorResult({
    required this.message,
    this.isNetworkError = false,
  });

  /// Human-readable error description.
  final String message;

  /// True when the error was a network connectivity issue.
  final bool isNetworkError;

  @override
  String toString() => 'ErrorResult(message: "$message")';
}