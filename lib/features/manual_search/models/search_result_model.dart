// ============================================================================
// Search Result Model — Manual ticket search response
//
// Returned by GET /api/scanner/ticket/search when a manual lookup is made.
// Represents the complete state of a ticket found by reference number.
//
// EXPECTED BACKEND RESPONSE:
// {
//   "ticket_reference": "TKT-2024-00123",
//   "order_reference": "ORD-2024-00456",
//   "holder_name": "John Smith",
//   "ticket_category": "VIP",
//   "ticket_source_type": "online",
//   "event_name": "Summer Festival 2024",
//   "validation_status": "valid",
//   "checked_in_at": null,              // or ISO 8601 string
//   "checked_in_by_device": null,       // or device name string
//   "checked_in_by_user": null          // or username string
// }
//
// DESIGN DECISION — Plain Dart class (not Freezed):
// - Constructed at one call site from JSON
// - Never used in a sealed switch expression
// - validationStatus string drives branching via string comparison
// - No copyWith needed — result is fully replaced on each new search
// - Avoids build_runner dependency for a simple display model
// ============================================================================

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/admission_info.dart';

/// Represents the complete state of a ticket found via manual search.
///
/// Constructed from the backend search response by [ManualSearchRepository].
/// Read-only — never mutated after construction.
class SearchResultModel {
  const SearchResultModel({
    required this.ticketReference,
    required this.orderReference,
    required this.holderName,
    required this.ticketCategory,
    required this.ticketSourceType,
    required this.eventName,
    required this.validationStatus,
    this.checkedInAt,
    this.checkedInByDevice,
    this.checkedInByUser,
    this.admission = const AdmissionInfo(),
  });

  // ==========================================================================
  // FIELDS
  // ==========================================================================

  /// Unique ticket reference code.
  /// Example: 'TKT-2024-00123'
  final String ticketReference;

  /// Order reference this ticket belongs to.
  /// Example: 'ORD-2024-00456'
  final String orderReference;

  /// Full name of the ticket holder.
  /// Example: 'John Smith'
  final String holderName;

  /// Ticket tier or category.
  /// Examples: 'VIP', 'General Admission', 'Early Bird', 'Staff'
  final String ticketCategory;

  /// How the ticket was acquired.
  /// Values: 'online', 'physical', 'complimentary'
  final String ticketSourceType;

  /// Name of the event this ticket is for.
  /// Should match the connected scanner event.
  final String eventName;

  /// Current validation/admission status of the ticket.
  ///
  /// Drives UI branching — determines which action buttons to show.
  /// Matches [AppConstants] status values:
  /// - 'valid'          → show Check In button
  /// - 'already_used'   → show already-checked-in details
  /// - 'wrong_event'    → show warning, no check-in
  /// - 'revoked'        → show revoked state, no check-in
  /// - 'cancelled'      → show cancelled state, no check-in
  /// - 'invalid'        → show invalid state, no check-in
  final String validationStatus;

  /// When the ticket was checked in.
  ///
  /// Non-null only when [validationStatus] is 'already_used' or
  /// 'already_checked_in'. Stored in local time after parsing.
  final DateTime? checkedInAt;

  /// Name of the device that recorded the check-in.
  /// Non-null only when [validationStatus] is 'already_used'.
  final String? checkedInByDevice;

  /// Username or operator identifier who performed the check-in.
  /// Non-null only when [validationStatus] is 'already_used'.
  final String? checkedInByUser;

  /// Multi-admission counters and server validation message.
  final AdmissionInfo admission;

  int get admissionsUsed => admission.admissionsUsed;
  int get admissionsMax => admission.admissionsMax;
  int get admissionsRemaining => admission.admissionsRemaining;
  String get validationMessage => admission.validationMessage;

  // ==========================================================================
  // FACTORY — fromJson
  // ==========================================================================

  /// Constructs a [SearchResultModel] from the API response JSON.
  ///
  /// Never throws — missing fields fall back to safe defaults.
  /// The [validationStatus] field is normalized to lowercase.
  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    return SearchResultModel(
      ticketReference: _str(json, 'ticket_reference'),
      orderReference: _str(json, 'order_reference'),
      holderName: _str(json, 'holder_name', fallback: 'Unknown Holder'),
      ticketCategory: _str(json, 'ticket_category', fallback: 'General'),
      ticketSourceType: _str(json, 'ticket_source_type', fallback: 'online'),
      eventName: _str(json, 'event_name'),
      validationStatus:
          _str(json, 'validation_status', fallback: 'invalid').toLowerCase(),
      checkedInAt: _dateTime(json, 'checked_in_at'),
      checkedInByDevice: json['checked_in_by_device'] as String?,
      checkedInByUser: json['checked_in_by_user'] as String?,
      admission: AdmissionInfo.fromJson(json),
    );
  }

  // ==========================================================================
  // COMPUTED PROPERTIES
  // ==========================================================================

  /// True when this ticket can be checked in ([validationStatus] is `valid`).
  bool get canCheckIn => validationStatus == AppConstants.statusValid;

  /// True when this ticket has already been used.
  bool get isAlreadyUsed =>
      validationStatus == AppConstants.statusAlreadyUsed ||
      validationStatus == 'already_checked_in';

  /// True when this ticket belongs to a different event.
  bool get isWrongEvent =>
      validationStatus == AppConstants.statusWrongEvent;

  /// True when this ticket has been revoked.
  bool get isRevoked =>
      validationStatus == AppConstants.statusRevoked;

  /// True when this ticket or order was cancelled.
  bool get isCancelled =>
      validationStatus == AppConstants.statusCancelled;

  /// True when this ticket reference is not recognized.
  bool get isInvalid =>
      validationStatus == AppConstants.statusInvalid;

  /// True when entry should be denied (not valid and not already used).
  bool get isDenied => isRevoked || isCancelled || isInvalid || isWrongEvent;

  // ==========================================================================
  // PRIVATE HELPERS
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

  // ==========================================================================
  // DEBUG
  // ==========================================================================

  @override
  String toString() => 'SearchResultModel('
      'ref: "$ticketReference", '
      'holder: "$holderName", '
      'status: "$validationStatus"'
      ')';
}