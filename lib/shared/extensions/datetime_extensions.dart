// ============================================================================
// DateTime Extensions — Date formatting helpers
//
// Full implementation added as needed through phases.
// ============================================================================

import 'package:intl/intl.dart';

/// Extension methods on [DateTime] for the gate scanner app.
extension DateTimeExtensions on DateTime {
  /// Formats the datetime as a readable date and time string.
  ///
  /// Example: 'Jul 15, 2024 08:30 AM'
  String get formattedDateTime {
    return DateFormat('MMM d, yyyy hh:mm a').format(toLocal());
  }

  /// Formats the datetime as a time-only string.
  ///
  /// Example: '08:30:45 AM'
  String get formattedTime {
    return DateFormat('hh:mm:ss a').format(toLocal());
  }

  /// Formats the datetime as a date-only string.
  ///
  /// Example: 'July 15, 2024'
  String get formattedDate {
    return DateFormat('MMMM d, yyyy').format(toLocal());
  }

  /// Returns a relative time description.
  ///
  /// Examples: 'Just now', '5 minutes ago', '2 hours ago', 'Yesterday'
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
}