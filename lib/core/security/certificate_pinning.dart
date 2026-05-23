import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// Optional TLS certificate pinning for configured API hosts.
abstract final class CertificatePinning {
  CertificatePinning._();

  /// Returns true if [cert] matches a configured pin for [host].
  ///
  /// Used as [HttpClient.badCertificateCallback]. When no pins exist for
  /// [host], returns false so the system trust store is used.
  static bool acceptCertificate(X509Certificate cert, String host, int port) {
    final List<String>? expectedPins =
        AppSecurityConfig.certificatePinSha256[host.toLowerCase()];
    if (expectedPins == null || expectedPins.isEmpty) {
      return false;
    }

    final String fingerprint = _sha256Base64(cert.der);
    for (final String pin in expectedPins) {
      if (_pinMatches(fingerprint, pin)) {
        if (kDebugMode) {
          debugPrint('[CertificatePinning] Pin matched for $host:$port');
        }
        return true;
      }
    }

    if (kDebugMode) {
      debugPrint('[CertificatePinning] Pin mismatch for $host:$port');
    }
    return false;
  }

  static bool hasPinsForHost(String host) {
    final pins = AppSecurityConfig.certificatePinSha256[host.toLowerCase()];
    return pins != null && pins.isNotEmpty;
  }

  static String _sha256Base64(List<int> derBytes) {
    return base64.encode(sha256.convert(derBytes).bytes);
  }

  static bool _pinMatches(String fingerprintBase64, String configuredPin) {
    final String normalized = configuredPin
        .trim()
        .toLowerCase()
        .replaceFirst(RegExp(r'^sha256/'), '');
    return fingerprintBase64.toLowerCase() == normalized;
  }
}
