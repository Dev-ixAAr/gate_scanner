// ============================================================================
// Search Result Model — Manual ticket search response
//
// Full implementation with freezed in Phase 8.
// Phase 1: Structure defined.
// ============================================================================

// TODO: Add freezed in Phase 8

/// Result model for manual ticket search.
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
  });

  final String ticketReference;
  final String orderReference;
  final String holderName;
  final String ticketCategory;
  final String ticketSourceType;
  final String eventName;
  final String validationStatus;
  final DateTime? checkedInAt;
  final String? checkedInByDevice;
}