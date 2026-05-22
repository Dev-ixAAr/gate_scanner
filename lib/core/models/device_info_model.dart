// ============================================================================
// Device Info Model — Device payload sent with API requests
//
// This model encapsulates all device information that must be sent
// to the backend with setup token exchange and scan requests.
//
// Full implementation in Phase 3 (Device Info Service).
// Phase 1: Model structure defined.
// ============================================================================

// TODO: Add freezed annotation in Phase 3
// import 'package:freezed_annotation/freezed_annotation.dart';
// part 'device_info_model.freezed.dart';
// part 'device_info_model.g.dart';

/// Device information payload sent to the backend.
///
/// Collected via device_info_plus and package_info_plus.
/// Sent with:
/// - Setup token exchange (to register device)
/// - Ticket validation requests (for audit trail)
/// - Check-in requests (for checked_in_by_device field)
class DeviceInfoModel {
  const DeviceInfoModel({
    required this.deviceName,
    required this.deviceType,
    required this.deviceBrand,
    required this.deviceModel,
    required this.operatingSystem,
    required this.osVersion,
    required this.appVersion,
  });

  // TODO: Replace with fromJson factory (Freezed) in Phase 3

  /// Human-readable device name.
  /// On Android: model name (e.g., "Samsung Galaxy A53")
  /// May be overridden by a custom name set in settings.
  final String deviceName;

  /// Device form factor.
  /// Values: 'phone', 'tablet'
  /// Used to distinguish scanner types in the backend audit log.
  final String deviceType;

  /// Device manufacturer brand.
  /// Examples: 'Samsung', 'Google', 'OnePlus', 'Xiaomi'
  final String deviceBrand;

  /// Device model identifier.
  /// Examples: 'SM-A536B', 'Pixel 7', 'IN2013'
  final String deviceModel;

  /// Operating system name.
  /// Value: 'Android' (iOS support can be added later)
  final String operatingSystem;

  /// OS version string.
  /// Examples: '13', '12', '11'
  final String osVersion;

  /// App version from pubspec.yaml.
  /// Example: '1.0.0'
  final String appVersion;

  /// Serialize to JSON Map for API request body.
  Map<String, dynamic> toJson() {
    return {
      'device_name': deviceName,
      'device_type': deviceType,
      'device_brand': deviceBrand,
      'device_model': deviceModel,
      'operating_system': operatingSystem,
      'os_version': osVersion,
      'app_version': appVersion,
    };
  }

  @override
  String toString() {
    return 'DeviceInfoModel('
        'deviceName: $deviceName, '
        'deviceBrand: $deviceBrand, '
        'deviceModel: $deviceModel, '
        'os: $operatingSystem $osVersion, '
        'appVersion: $appVersion'
        ')';
  }
}