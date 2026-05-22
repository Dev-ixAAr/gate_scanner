// ============================================================================
// Setup Repository — API calls for the setup flow
//
// Handles the setup token verification API call.
// Uses a temporary Dio instance (not the session-authenticated one)
// because the session token does not exist yet during setup.
//
// Full implementation in Phase 5.
// Phase 1: Skeleton with TODO markers.
// ============================================================================

// TODO: Implement in Phase 5

/// Handles API communication for the setup token exchange flow.
///
/// Uses a fresh Dio instance pointed at the server URL from the QR code
/// rather than the session-authenticated API client.
class SetupRepository {
  // TODO: Implement in Phase 5:
  // - Future<ScannerSessionModel> verifySetupToken(
  //     SetupQrPayload payload,
  //     DeviceInfoModel deviceInfo,
  //   )
}