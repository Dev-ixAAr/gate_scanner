// ============================================================================
// Setup Repository — Setup token exchange API call
//
// Handles the single API call that converts a setup QR token into
// a scanner session token. This is the most critical API call in the app —
// if it fails, the device cannot be used for scanning.
//
// IMPORTANT: This repository uses a TEMPORARY, UNAUTHENTICATED Dio instance.
// The regular apiClientProvider (Phase 5) requires an active session, which
// doesn't exist yet during setup. This repository creates its own Dio pointed
// at the server URL from the QR code.
//
// REQUEST BODY SENT TO BACKEND:
// {
//   "setup_token": "tok_setup_xxx",
//   "event_public_ref": "EVT-2024-001",
//   "device_name": "Samsung SM-A536B",
//   "device_type": "phone",
//   "device_brand": "Samsung",
//   "device_model": "SM-A536B",
//   "operating_system": "Android",
//   "os_version": "13",
//   "app_version": "1.0.0"
// }
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/models/device_info_model.dart';
import '../../../core/services/app_info_service.dart';
import '../models/scanner_session_model.dart';
import '../models/setup_qr_payload.dart';

/// Riverpod provider for [SetupRepository].
final setupRepositoryProvider = Provider<SetupRepository>((ref) {
  final appInfoService = ref.read(appInfoServiceProvider);
  return SetupRepository(appInfoService: appInfoService);
});

/// Handles the setup token exchange API call.
///
/// Creates a temporary unauthenticated Dio for each call,
/// pointed at the server URL extracted from the QR code.
/// This ensures the correct server is called regardless of any
/// previously stored session URL.
class SetupRepository {
  const SetupRepository({required AppInfoService appInfoService})
      : _appInfoService = appInfoService;

  final AppInfoService _appInfoService;

  // ==========================================================================
  // VERIFY SETUP TOKEN
  // ==========================================================================

  /// Exchanges a setup token for a scanner session token.
  ///
  /// Sends the setup token, event reference, and device information to
  /// the backend. On success, returns a [ScannerSessionModel] containing
  /// the scanner session token and event details.
  ///
  /// THROWS:
  /// - [ApiException] on any API error (network, HTTP 4xx/5xx, timeout)
  ///
  /// The session is NOT saved here — [SetupExchangeNotifier] calls
  /// [SessionService.saveSession] after this method returns successfully.
  ///
  /// Parameters:
  /// - [payload]: parsed setup QR code data (server URL, event ref, token)
  /// - [deviceInfo]: device hardware info to register with the backend
  Future<ScannerSessionModel> verifySetupToken({
    required SetupQrPayload payload,
    required DeviceInfoModel deviceInfo,
  }) async {
    // Get the current app version to include in the request.
    final String appVersion = await _appInfoService.getAppVersion();

    // Create a temporary unauthenticated Dio for this specific server.
    final Dio setupDio = ApiClientFactory.createForSetup(
      serverUrl: payload.serverUrlNormalized,
    );

    try {
      _log('Exchanging setup token for event: ${payload.eventPublicRef}');
      _log('Server: ${payload.serverUrlDisplay}');

      final Response<Map<String, dynamic>> response =
          await setupDio.post<Map<String, dynamic>>(
        ApiEndpoints.verifySetupToken,
        data: _buildRequestBody(
          payload: payload,
          deviceInfo: deviceInfo,
          appVersion: appVersion,
        ),
      );

      // Validate response structure.
      final dynamic responseData = response.data;
      if (responseData == null || responseData is! Map<String, dynamic>) {
        throw ApiException.serverError(
          response.statusCode,
          'Server returned an empty or malformed response.',
        );
      }

      // Parse the session model from the response.
      try {
        final ScannerSessionModel session =
            ScannerSessionModel.fromJson(responseData);
        _log('Token exchange successful — event: ${session.eventName}');
        return session;
      } on ScannerSessionParseException catch (e) {
        _log('Response parse error: $e');
        throw ApiException.serverError(
          response.statusCode,
          'Server response is missing required fields: ${e.message}',
        );
      }
    } on DioException catch (e) {
      _log('DioException during token exchange: ${e.type}');
      throw ApiException.fromDioException(e);
    } on ApiException {
      // Re-throw ApiException (e.g., from the parse error block above).
      rethrow;
    } catch (e) {
      _log('Unexpected error during token exchange: $e');
      throw ApiException.serverError(null, 'An unexpected error occurred: $e');
    } finally {
      // Always close the temporary Dio to release resources.
      setupDio.close();
    }
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  /// Builds the request body for the setup token exchange.
  ///
  /// Merges the setup token fields with the device information.
  Map<String, dynamic> _buildRequestBody({
    required SetupQrPayload payload,
    required DeviceInfoModel deviceInfo,
    required String appVersion,
  }) {
    return {
      // Setup token fields
      'setup_token': payload.setupToken,
      'event_public_ref': payload.eventPublicRef,

      // Device information fields (matching DeviceInfoModel.toJson keys)
      'device_name': deviceInfo.deviceName,
      'device_type': deviceInfo.deviceType,
      'device_brand': deviceInfo.deviceBrand,
      'device_model': deviceInfo.deviceModel,
      'operating_system': deviceInfo.operatingSystem,
      'os_version': deviceInfo.osVersion,

      // App version — use live value, not DeviceInfoModel's fallback.
      'app_version': appVersion,
    };
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[SetupRepository] $message');
    }
  }
}