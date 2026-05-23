import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'certificate_pinning.dart';

/// Creates [HttpClient] / Dio adapters with optional certificate pinning.
abstract final class SecureHttpClientFactory {
  SecureHttpClientFactory._();

  /// Applies secure HTTP client settings to [dio] for requests to [baseUrl].
  static void configureDio(Dio dio, {String? baseUrl}) {
    final String? host = _hostFromBaseUrl(baseUrl ?? dio.options.baseUrl);
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => createHttpClient(expectedHost: host),
    );
  }

  static HttpClient createHttpClient({String? expectedHost}) {
    final HttpClient client = HttpClient();

    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      if (CertificatePinning.hasPinsForHost(host)) {
        return CertificatePinning.acceptCertificate(cert, host, port);
      }
      return false;
    };

    return client;
  }

  static String? _hostFromBaseUrl(String baseUrl) {
    if (baseUrl.isEmpty) return null;
    try {
      return Uri.parse(baseUrl).host.toLowerCase();
    } catch (_) {
      return null;
    }
  }
}
