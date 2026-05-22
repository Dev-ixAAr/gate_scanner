// ============================================================================
// String Extensions — Helper methods on String
//
// Confirmed from Phase 1 — extended here with truncation helper
// used by home screen for long server URLs.
// ============================================================================

/// Extension methods on [String] for gate_scanner.
extension StringExtensions on String {
  /// Returns true if the string is not empty after trimming whitespace.
  bool get isNotBlank => trim().isNotEmpty;

  /// Returns true if the string is empty or only whitespace.
  bool get isBlank => trim().isEmpty;

  /// Truncates the string to [maxLength] characters and appends '…' if longer.
  ///
  /// Used for displaying long URLs and references in limited space.
  ///
  /// Example: 'https://very-long-domain.example.com'.truncate(30)
  ///          → 'https://very-long-domain.exam…'
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}…';
  }

  /// Capitalizes the first letter of the string.
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Converts snake_case or UPPER_SNAKE_CASE to Title Case.
  ///
  /// Used for displaying validation status labels from the API.
  ///
  /// Examples:
  /// - 'already_used' → 'Already Used'
  /// - 'wrong_event'  → 'Wrong Event'
  /// - 'VALID'        → 'Valid'
  String get titleCaseFromSnake {
    return toLowerCase()
        .split('_')
        .map((word) => word.isEmpty ? '' : word.capitalized)
        .join(' ');
  }

  /// Strips the protocol prefix from a URL for compact display.
  ///
  /// Example: 'https://events.company.com' → 'events.company.com'
  String get urlDisplayValue {
    return replaceFirst('https://', '').replaceFirst('http://', '');
  }
}