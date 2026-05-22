// ============================================================================
// Device Info Model — Device hardware payload for API requests
//
// Collects and structures device information sent to the backend with:
// 1. Setup token exchange — registers the device with the session
// 2. Ticket validation requests — included in audit trail
// 3. Check-in requests — recorded as "checked_in_by_device"
//
// All fields are collected once via DeviceInfoService and cached.
// The model is serialized to JSON when included in API request bodies.
// ============================================================================

import '../constants/app_constants.dart';

/// Device hardware and software information for API payloads.
///
/// Constructed by [DeviceInfoService.getDeviceInfo()].
/// Serialized via [toJson()] for inclusion in API request bodies.
///
/// Backend uses this data to:
/// - Display "Checked in by: Samsung Galaxy A53 (Gate 1)" in admin panel
/// - Associate scan activity with specific physical devices
/// - Track device types for usage analytics
/// - Revoke access for a specific device by name/model
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

  // ==========================================================================
  // FIELDS
  // ==========================================================================

  /// Human-readable device display name.
  ///
  /// On Android: Manufacturer + Model (e.g., "Samsung SM-A536B")
  /// May be overridden by a custom device name set in settings.
  ///
  /// This is the value shown to administrators in the backend panel
  /// as the scanner device identifier.
  final String deviceName;

  /// Device form factor.
  ///
  /// Values: [AppConstants.deviceTypePhone] or [AppConstants.deviceTypeTablet]
  /// Determined by screen size heuristics in [DeviceInfoService].
  final String deviceType;

  /// Device manufacturer brand name.
  ///
  /// Examples: 'Samsung', 'Google', 'OnePlus', 'Xiaomi', 'Motorola'
  /// Source: AndroidDeviceInfo.brand (capitalized)
  final String deviceBrand;

  /// Device model identifier.
  ///
  /// Examples: 'SM-A536B', 'Pixel 7', 'XT2175-2', 'IN2013'
  /// Source: AndroidDeviceInfo.model
  final String deviceModel;

  /// Operating system name.
  ///
  /// Value: [AppConstants.osAndroid] ('Android')
  /// iOS value would be 'iOS' when iOS support is added.
  final String operatingSystem;

  /// Human-readable OS version string.
  ///
  /// Examples: '13', '12', '11', '10'
  /// Source: AndroidDeviceInfo.version.release
  final String osVersion;

  /// App version from pubspec.yaml.
  ///
  /// Format: 'major.minor.patch' (e.g., '1.0.0')
  /// Source: PackageInfo.version via AppInfoService.
  final String appVersion;

  // ==========================================================================
  // FACTORY CONSTRUCTORS
  // ==========================================================================

  /// Creates a [DeviceInfoModel] with fallback/unknown values.
  ///
  /// Used when device info cannot be retrieved (plugin failure, tests).
  /// Ensures API calls still have valid (if placeholder) device fields.
  factory DeviceInfoModel.unknown() {
    return const DeviceInfoModel(
      deviceName: 'Unknown Device',
      deviceType: AppConstants.deviceTypePhone,
      deviceBrand: 'Unknown',
      deviceModel: 'Unknown',
      operatingSystem: AppConstants.osAndroid,
      osVersion: 'Unknown',
      appVersion: AppConstants.fallbackVersion,
    );
  }

  // ==========================================================================
  // SERIALIZATION
  // ==========================================================================

  /// Serializes this model to a JSON-compatible Map for API request bodies.
  ///
  /// Field names use snake_case to match the backend API contract.
  /// This Map is merged into the API request body when sending
  /// setup token exchange and ticket validation requests.
  ///
  /// Example output:
  /// ```json
  /// {
  ///   "device_name": "Samsung SM-A536B",
  ///   "device_type": "phone",
  ///   "device_brand": "Samsung",
  ///   "device_model": "SM-A536B",
  ///   "operating_system": "Android",
  ///   "os_version": "13",
  ///   "app_version": "1.0.0"
  /// }
  /// ```
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

  /// Deserializes a [DeviceInfoModel] from a JSON Map.
  ///
  /// Used when the backend returns device info in a session response.
  /// Falls back to 'Unknown' for any missing fields.
  factory DeviceInfoModel.fromJson(Map<String, dynamic> json) {
    return DeviceInfoModel(
      deviceName: (json['device_name'] as String?) ?? 'Unknown Device',
      deviceType: (json['device_type'] as String?) ?? AppConstants.deviceTypePhone,
      deviceBrand: (json['device_brand'] as String?) ?? 'Unknown',
      deviceModel: (json['device_model'] as String?) ?? 'Unknown',
      operatingSystem: (json['operating_system'] as String?) ?? AppConstants.osAndroid,
      osVersion: (json['os_version'] as String?) ?? 'Unknown',
      appVersion: (json['app_version'] as String?) ?? AppConstants.fallbackVersion,
    );
  }

  // ==========================================================================
  // COMPUTED PROPERTIES
  // ==========================================================================

  /// Full display string for the device.
  ///
  /// Used in the settings screen and scan audit display.
  /// Example: 'Samsung SM-A536B (Android 13)'
  String get fullDisplayName => '$deviceBrand $deviceModel ($operatingSystem $osVersion)';

  /// Compact display string for the device.
  ///
  /// Used in info rows where space is limited.
  /// Example: 'Samsung SM-A536B'
  String get compactDisplayName => '$deviceBrand $deviceModel';

  // ==========================================================================
  // COPY WITH
  // ==========================================================================

  /// Returns a copy with specified fields replaced.
  ///
  /// Used when the user sets a custom device name in settings.
  DeviceInfoModel copyWith({
    String? deviceName,
    String? deviceType,
    String? deviceBrand,
    String? deviceModel,
    String? operatingSystem,
    String? osVersion,
    String? appVersion,
  }) {
    return DeviceInfoModel(
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      deviceBrand: deviceBrand ?? this.deviceBrand,
      deviceModel: deviceModel ?? this.deviceModel,
      operatingSystem: operatingSystem ?? this.operatingSystem,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  // ==========================================================================
  // EQUALITY AND HASH
  // ==========================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceInfoModel &&
        other.deviceName == deviceName &&
        other.deviceType == deviceType &&
        other.deviceBrand == deviceBrand &&
        other.deviceModel == deviceModel &&
        other.operatingSystem == operatingSystem &&
        other.osVersion == osVersion &&
        other.appVersion == appVersion;
  }

  @override
  int get hashCode {
    return Object.hash(
      deviceName,
      deviceType,
      deviceBrand,
      deviceModel,
      operatingSystem,
      osVersion,
      appVersion,
    );
  }

  @override
  String toString() {
    return 'DeviceInfoModel('
        'deviceName: "$deviceName", '
        'deviceType: "$deviceType", '
        'deviceBrand: "$deviceBrand", '
        'deviceModel: "$deviceModel", '
        'os: "$operatingSystem $osVersion", '
        'appVersion: "$appVersion"'
        ')';
  }
}