// ============================================================================
// DateTime Extensions — Date/time formatting helpers
//
// Used in Phase 4 by the setup confirmation sheet.
// Provides consistent date formatting across the app.
// ============================================================================

import 'package:intl/intl.dart';

/// Extension methods on [DateTime] for the gate scanner app.
extension DateTimeExtensions on DateTime {
  /// Formats as a readable date and time string.
  ///
  /// Converts to local time before formatting.
  ///
  /// Example: 'Jul 15, 2024  8:30 AM'
  String get formattedDateTime {
    return DateFormat('MMM d, yyyy  h:mm a').format(toLocal());
  }

  /// Formats as a time-only string.
  ///
  /// Example: '8:30:45 AM'
  String get formattedTime {
    return DateFormat('h:mm:ss a').format(toLocal());
  }

  /// Formats as a date-only string.
  ///
  /// Example: 'July 15, 2024'
  String get formattedDate {
    return DateFormat('MMMM d, yyyy').format(toLocal());
  }

  /// Formats as a compact date-time string.
  ///
  /// Example: '15 Jul 2024, 08:30'
  String get formattedCompact {
    return DateFormat('d MMM yyyy, HH:mm').format(toLocal());
  }

  /// Returns a relative time description.
  ///
  /// Examples:
  /// - 'Just now' (< 60 seconds)
  /// - '5 minutes ago'
  /// - '2 hours ago'
  /// - 'Yesterday'
  /// - 'July 15, 2024' (older)
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(toLocal());

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return formattedDate;
    }
  }

  /// Returns true if this date is the same calendar day as [other].
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Returns true if this datetime is today.
  bool get isToday => isSameDay(DateTime.now());
}