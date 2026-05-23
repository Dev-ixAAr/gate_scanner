/// Sanitizes sensitive values before logging.
abstract final class SensitiveLog {
  SensitiveLog._();

  static const Set<String> sensitiveStorageKeys = {
    'scanner_session_token',
    'device_uuid',
    'scanner_session_bundle',
  };

  static const Set<String> sensitiveJsonKeys = {
    'setup_token',
    'session_token',
    'scanner_session_token',
    'token',
    'access_token',
    'refresh_token',
    'password',
    'authorization',
  };

  /// Masks any sensitive string for logs — never exposes partial tokens.
  static String mask(String? value) => '***';

  static String sanitizeStorageKey(String key, String? value) {
    if (value == null) return 'null';
    if (sensitiveStorageKeys.contains(key)) return '***';
    return '"$value"';
  }

  static Map<String, dynamic> sanitizeHeaders(Map<String, dynamic> headers) {
    final Map<String, dynamic> sanitized = Map<String, dynamic>.from(headers);
    for (final entry in sanitized.entries) {
      if (entry.key.toLowerCase() == 'authorization') {
        sanitized[entry.key] = '***';
      }
    }
    return sanitized;
  }

  static dynamic sanitizeBody(dynamic body) {
    if (body is Map<String, dynamic>) {
      final Map<String, dynamic> sanitized =
          Map<String, dynamic>.from(body);
      for (final key in sensitiveJsonKeys) {
        if (sanitized.containsKey(key)) {
          sanitized[key] = '***';
        }
      }
      return sanitized;
    }
    return body;
  }
}
