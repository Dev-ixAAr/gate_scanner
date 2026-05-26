// ============================================================================
// Scanner Repository — Ticket validation and check-in API calls
//
// ENDPOINTS USED:
// POST /api/scanner/ticket/validate → validate a scanned QR code
// POST /api/scanner/ticket/checkin  → explicitly check in a ticket
//
// REQUEST BODY (both endpoints):
// {
//   "ticket_ref": "TKT-2024-00123",
//   "event_public_ref": "EVT-2024-001",
//   "device_name": "Samsung SM-A536B",
//   "device_type": "phone",
//   "device_brand": "Samsung",
//   "device_model": "SM-A536B",
//   "operating_system": "Android",
//   "os_version": "13",
//   "app_version": "1.0.0"
// }
//
// RESPONSE:
// { "validation_status": "valid", ...variant-specific fields }
//
// ERROR HANDLING:
// - DioException → ApiException.fromDioException → rethrown
// - 401: SessionRevokeInterceptor handles before reaching here
// - Parse error → ErrorResult returned (not thrown)
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/providers/session_providers.dart';
import '../../../core/services/app_info_service.dart';
import '../../../core/services/device_info_service.dart';
import '../../../core/services/session_service.dart';
import '../models/ticket_validation_result.dart';

/// Riverpod provider for [ScannerRepository].
final scannerRepositoryProvider = Provider<ScannerRepository>((ref) {
  return ScannerRepository(ref: ref);
});

/// Handles ticket validation and check-in API calls.
///
/// Uses the authenticated Dio instance ([authenticatedDioProvider]) which
/// automatically attaches the Bearer token and handles 401 via interceptor.
class ScannerRepository {
  const ScannerRepository({required Ref ref}) : _ref = ref;

  final Ref _ref;

  // ==========================================================================
  // VALIDATE TICKET QR
  // ==========================================================================

  /// Validates a scanned ticket QR code against the backend.
  ///
  /// Sends the raw QR value, event public ref, and device info to the backend.
  /// Returns a [TicketValidationResult] variant based on the response.
  ///
  /// THROWS [ApiException] for:
  /// - Network errors (no connectivity, timeout)
  /// - Server errors (5xx)
  /// - 401/403 (handled by interceptor before reaching here)
  ///
  /// Returns [ErrorResult] for:
  /// - Response parse failures (malformed JSON)
  /// - Missing validation_status field
  Future<TicketValidationResult> validateTicketQr(String ticketRef) async {
    _log('validateTicketQr → ref: "$ticketRef"');
    return _callValidationEndpoint(
      endpoint: ApiEndpoints.validateTicketQr,
      ticketRef: ticketRef,
    );
  }

  // ==========================================================================
  // CHECKIN TICKET
  // ==========================================================================

  /// Explicitly records a ticket check-in.
  ///
  /// Called when the backend requires a separate check-in call after
  /// validation (as opposed to auto-check-in on validate).
  /// Returns the updated [TicketValidationResult] after check-in.
  ///
  /// Same error handling contract as [validateTicketQr].
  Future<TicketValidationResult> checkinTicket(
    String ticketRef, {
    int? admissionsToUse,
  }) async {
    _log('checkinTicket → ref: "$ticketRef"');
    return _callValidationEndpoint(
      endpoint: ApiEndpoints.checkinTicket,
      ticketRef: ticketRef,
      admissionsToUse: admissionsToUse,
    );
  }

  // ==========================================================================
  // PRIVATE — SHARED ENDPOINT CALLER
  // ==========================================================================

  /// Calls a validation or check-in endpoint with a consistent payload.
  ///
  /// Both [validateTicketQr] and [checkinTicket] use the same request format.
  Future<TicketValidationResult> _callValidationEndpoint({
    required String endpoint,
    required String ticketRef,
    int? admissionsToUse,
  }) async {
    try {
      // Build the request payload.
      final Map<String, dynamic> body =
          await _buildRequestBody(ticketRef: ticketRef, admissionsToUse: admissionsToUse);

      // Get the authenticated Dio instance.
      final Dio dio = await _ref.read(authenticatedDioProvider.future);

      // Make the POST request.
      final Response<Map<String, dynamic>> response =
          await dio.post<Map<String, dynamic>>(endpoint, data: body);

      final dynamic responseData = response.data;

      // Guard: ensure response is a Map.
      if (responseData == null || responseData is! Map<String, dynamic>) {
        _log('ERROR: null or non-map response from $endpoint');
        return const ErrorResult(
          message: 'Server returned an empty response. Please try again.',
        );
      }

      // Parse the validation result from the response.
      final TicketValidationResult result =
          TicketValidationResult.fromJson(responseData);

      _log('Result: ${result.runtimeType}');
      return result;
    } on DioException catch (e) {
      final ApiException apiException = ApiException.fromDioException(e);
      _log('DioException: $apiException');

      // Session revocation is handled by the interceptor.
      // Re-throw all API exceptions — provider handles the error display.
      throw apiException;
    } catch (e) {
      _log('Unexpected error: $e');
      throw ApiException.serverError(null, 'Unexpected error: $e');
    }
  }

  // ==========================================================================
  // PRIVATE — REQUEST BODY BUILDER
  // ==========================================================================

  /// Builds the request body with ticket ref, event ref, and device info.
  Future<Map<String, dynamic>> _buildRequestBody({
    required String ticketRef,
    int? admissionsToUse,
  }) async {
    // Read session data for event_public_ref.
    final SessionService sessionService = _ref.read(sessionServiceProvider);
    final String? eventPublicRef = await sessionService.getEventPublicRef();
    final String? deviceName = await sessionService.getDeviceName();

    // Read device info.
    final DeviceInfoService deviceInfoService =
        _ref.read(deviceInfoServiceProvider);
    final deviceInfo = await deviceInfoService.getDeviceInfo();

    // Read app version.
    final AppInfoService appInfoService = _ref.read(appInfoServiceProvider);
    final String appVersion = await appInfoService.getAppVersion();

    final Map<String, dynamic> payload = {
      'ticket_ref': ticketRef.trim(),
      'event_public_ref': eventPublicRef ?? '',
      'device_name': deviceName ?? deviceInfo.deviceName,
      'device_type': deviceInfo.deviceType,
      'device_brand': deviceInfo.deviceBrand,
      'device_model': deviceInfo.deviceModel,
      'operating_system': deviceInfo.operatingSystem,
      'os_version': deviceInfo.osVersion,
      'app_version': appVersion,
    };

    if (admissionsToUse != null && admissionsToUse > 0) {
      payload['admissions_to_use'] = admissionsToUse;
    }

    return payload;
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[ScannerRepository] $message');
  }
}