// ============================================================================
// Ticket Validation Result — Validation response model
//
// Sealed class with variants for each possible validation state.
// Full implementation with freezed in Phase 7.
// Phase 1: Structure defined.
// ============================================================================

// TODO: Convert to freezed sealed class in Phase 7

/// Sealed base class for all ticket validation results.
///
/// Variants correspond to validation_status field from backend response.
/// The UI renders completely different content for each variant.
sealed class TicketValidationResult {
  const TicketValidationResult();
}

/// Ticket is valid — admit the holder.
class ValidTicketResult extends TicketValidationResult {
  const ValidTicketResult({
    required this.ticketReference,
    required this.orderReference,
    required this.holderName,
    required this.ticketCategory,
    required this.ticketSourceType,
    required this.eventName,
    required this.checkinStatus,
  });

  final String ticketReference;
  final String orderReference;
  final String holderName;
  final String ticketCategory;
  final String ticketSourceType;
  final String eventName;
  final String checkinStatus;
}

/// Ticket has already been used — duplicate scan.
class AlreadyUsedResult extends TicketValidationResult {
  const AlreadyUsedResult({
    required this.ticketReference,
    required this.checkedInAt,
    required this.checkedInByDevice,
    required this.checkedInByUser,
  });

  final String ticketReference;
  final DateTime checkedInAt;
  final String checkedInByDevice;
  final String checkedInByUser;
}

/// Ticket belongs to a different event — block entry.
class WrongEventResult extends TicketValidationResult {
  const WrongEventResult({
    required this.message,
  });

  final String message;
}

/// Ticket has been revoked — deny entry.
class RevokedResult extends TicketValidationResult {
  const RevokedResult({
    required this.ticketReference,
    this.reason,
  });

  final String ticketReference;
  final String? reason;
}

/// Ticket/order has been cancelled — deny entry.
class CancelledResult extends TicketValidationResult {
  const CancelledResult({
    required this.ticketReference,
    this.reason,
  });

  final String ticketReference;
  final String? reason;
}

/// QR code is not recognized — invalid ticket.
class InvalidResult extends TicketValidationResult {
  const InvalidResult({
    required this.message,
  });

  final String message;
}