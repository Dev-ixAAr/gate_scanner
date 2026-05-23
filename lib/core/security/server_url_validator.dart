import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// Validates backend [server_url] values from setup QR / manual entry.
///
/// **Multi-tenant / per-event domains:** leave [AppSecurityConfig.enforceHostAllowlist]
/// as `false` (default). Each setup QR may point to a different API host.
abstract final class ServerUrlValidator {
  ServerUrlValidator._();

  /// Validates [serverUrl] for setup flows.
  ///
  /// Throws [ServerUrlValidationException] when invalid.
  static void validate(String serverUrl) {
    final Uri? uri = _parseUri(serverUrl);
    if (uri == null) {
      throw const ServerUrlValidationException(
        'Server URL is not a valid URL.',
      );
    }

    if (uri.scheme != 'https' && uri.scheme != 'http') {
      throw const ServerUrlValidationException(
        'Server URL must use http:// or https://',
      );
    }

    if (kReleaseMode && uri.scheme != 'https') {
      throw const ServerUrlValidationException(
        'Only HTTPS server URLs are allowed in release builds.',
      );
    }

    if (uri.userInfo.isNotEmpty) {
      throw const ServerUrlValidationException(
        'Server URL must not contain username or password.',
      );
    }

    final String host = uri.host.toLowerCase();
    if (host.isEmpty) {
      throw const ServerUrlValidationException(
        'Server URL must include a hostname.',
      );
    }

    if (AppSecurityConfig.enforceHostAllowlist && !_hostMatchesAllowlist(host)) {
      throw ServerUrlValidationException(
        'Server host "$host" is not on the allowed list. '
        'Contact your administrator.',
      );
    }
  }

  static Uri? _parseUri(String serverUrl) {
    final String trimmed = serverUrl.trim();
    if (trimmed.isEmpty) return null;
    try {
      return Uri.parse(trimmed);
    } catch (_) {
      return null;
    }
  }

  static bool _hostMatchesAllowlist(String host) {
    for (final String suffix in AppSecurityConfig.allowedServerHostSuffixes) {
      final String normalized = suffix.toLowerCase().trim();
      if (normalized.isEmpty) continue;
      if (host == normalized || host.endsWith('.$normalized')) {
        return true;
      }
    }
    return false;
  }
}

/// Thrown when [serverUrl] fails security validation.
final class ServerUrlValidationException implements Exception {
  const ServerUrlValidationException(this.message);

  final String message;

  @override
  String toString() => 'ServerUrlValidationException: $message';
}
