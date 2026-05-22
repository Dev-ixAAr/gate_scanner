// ============================================================================
// String Extensions — Helper methods on String type
//
// Full implementation added as needed through phases.
// ============================================================================

/// Extension methods on [String] for the gate scanner app.
extension StringExtensions on String {
  /// Returns true if the string is not empty after trimming whitespace.
  bool get isNotBlank => trim().isNotEmpty;

  /// Returns true if the string is empty or only whitespace.
  bool get isBlank => trim().isEmpty;

  /// Truncates the string to [maxLength] characters and adds '...' if longer.
  ///
  /// Used for displaying long URLs and references in limited space.
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  /// Capitalizes the first letter of the string.
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Converts snake_case or UPPER_CASE to Title Case.
  ///
  /// Used for displaying validation status labels from API.
  /// Example: 'already_used' → 'Already Used'
  String get titleCaseFromSnake {
    return split('_')
        .map((word) => word.isEmpty ? '' : word.capitalized)
        .join(' ');
  }
}