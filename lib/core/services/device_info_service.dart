// ============================================================================
// Device Info Service — Hardware and OS information collector
//
// Collects device information using the device_info_plus package.
// This data is sent with API requests per the backend contract.
//
// ANDROID-FIRST IMPLEMENTATION:
// Phase 3 implements full Android support.
// iOS support structure is included but returns fallback values.
// Add iOS implementation when iOS platform support is needed.
//
// CACHING STRATEGY:
// Device info does not change during app lifetime, so results are
// cached in memory after the first collection. Subsequent calls to
// [getDeviceInfo] return the cached result without a plugin round-trip.
//
// TABLET DETECTION:
// Flutter does not have a built-in tablet detection API.
// We use the Android-specific physicalScreenSize to estimate.
// Screens >= 7 inches (diagonal) are classified as tablets.
// ============================================================================

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../models/device_info_model.dart';

/// Riverpod provider for [DeviceInfoService].
///
/// Access pattern:
/// ```dart
/// final deviceInfoService = ref.read(deviceInfoServiceProvider);
/// final deviceInfo = await deviceInfoService.getDeviceInfo();
/// ```
final deviceInfoServiceProvider = Provider<DeviceInfoService>((ref) {
  return DeviceInfoService._internal();
});

/// Collects and caches device hardware and OS information.
///
/// Uses [device_info_plus] plugin to read Android device info.
/// Results are cached after first collection for efficiency.
class DeviceInfoService {
  DeviceInfoService._internal() : _plugin = DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;

  // In-memory cache — populated on first [getDeviceInfo] call.
  DeviceInfoModel? _cachedDeviceInfo;

  // ==========================================================================
  // GET DEVICE INFO (primary method)
  // ==========================================================================

  /// Returns complete device information as a [DeviceInfoModel].
  ///
  /// On first call: collects data from the device_info_plus plugin.
  /// On subsequent calls: returns the cached result immediately.
  ///
  /// Never throws — returns [DeviceInfoModel.unknown()] on any error.
  /// This ensures API calls always have device fields, even if collection fails.
  ///
  /// Example:
  /// ```dart
  /// final deviceInfo = await deviceInfoService.getDeviceInfo();
  /// print(deviceInfo.deviceName); // 'Samsung SM-A536B'
  /// print(deviceInfo.osVersion);  // '13'
  /// ```
  Future<DeviceInfoModel> getDeviceInfo() async {
    // Return cached value if available.
    if (_cachedDeviceInfo != null) {
      _debugLog('getDeviceInfo → returning cached result');
      return _cachedDeviceInfo!;
    }

    _debugLog('getDeviceInfo → collecting from plugin');

    try {
      final DeviceInfoModel info;

      if (Platform.isAndroid) {
        info = await _collectAndroidInfo();
      } else if (Platform.isIOS) {
        info = await _collectIosInfo();
      } else {
        // Unsupported platform — return unknown fallback.
        _debugLog('getDeviceInfo → unsupported platform, using fallback');
        info = DeviceInfoModel.unknown();
      }

      _cachedDeviceInfo = info;
      _debugLog('getDeviceInfo → collected: $info');
      return info;
    } catch (e) {
      _debugLog('getDeviceInfo → ERROR: $e, using fallback');
      final fallback = DeviceInfoModel.unknown();
      _cachedDeviceInfo = fallback;
      return fallback;
    }
  }

  // ==========================================================================
  // ANDROID COLLECTION
  // ==========================================================================

  /// Collects device info from AndroidDeviceInfo.
  ///
  /// Fields collected:
  /// - brand: Manufacturer name (e.g., 'samsung', capitalized to 'Samsung')
  /// - model: Device model code (e.g., 'SM-A536B')
  /// - version.release: OS version string (e.g., '13')
  /// - isPhysicalDevice: Whether running on real hardware (not emulator)
  Future<DeviceInfoModel> _collectAndroidInfo() async {
    final AndroidDeviceInfo androidInfo = await _plugin.androidInfo;

    final String brand = _capitalizeBrand(androidInfo.brand);
    final String model = androidInfo.model;
    final String osVersion = androidInfo.version.release;
    final bool isPhysicalDevice = androidInfo.isPhysicalDevice;

    // Build a composite device name: Brand + Model
    // This is the name displayed in the backend admin panel.
    final String deviceName = '$brand $model';

    // Determine device type (phone vs tablet).
    // Physical size check: use displayMetrics if available.
    final String deviceType = _determineDeviceType(
      isPhysicalDevice: isPhysicalDevice,
    );

    return DeviceInfoModel(
      deviceName: deviceName,
      deviceType: deviceType,
      deviceBrand: brand,
      deviceModel: model,
      operatingSystem: AppConstants.osAndroid,
      osVersion: osVersion,
      // appVersion is not set here — DeviceInfoService doesn't know app version.
      // It's merged in when building the API payload. Set to fallback for now.
      // The actual version is injected by the repository/provider that
      // constructs the full request body using AppInfoService.
      appVersion: AppConstants.fallbackVersion,
    );
  }

  // ==========================================================================
  // iOS COLLECTION (stub for future iOS support)
  // ==========================================================================

  /// Collects device info from IosDeviceInfo.
  ///
  /// Currently returns a structured fallback with iOS OS name.
  /// Implement fully when iOS platform support is added.
  Future<DeviceInfoModel> _collectIosInfo() async {
    // TODO: Implement full iOS collection when iOS support is needed:
    // final IosDeviceInfo iosInfo = await _plugin.iosInfo;
    // return DeviceInfoModel(
    //   deviceName: iosInfo.name,
    //   deviceType: _isIpad() ? AppConstants.deviceTypeTablet : AppConstants.deviceTypePhone,
    //   deviceBrand: 'Apple',
    //   deviceModel: iosInfo.model,
    //   operatingSystem: 'iOS',
    //   osVersion: iosInfo.systemVersion,
    //   appVersion: AppConstants.fallbackVersion,
    // );

    final IosDeviceInfo iosInfo = await _plugin.iosInfo;

    return DeviceInfoModel(
      deviceName: iosInfo.name,
      deviceType: iosInfo.model.toLowerCase().contains('ipad')
          ? AppConstants.deviceTypeTablet
          : AppConstants.deviceTypePhone,
      deviceBrand: 'Apple',
      deviceModel: iosInfo.model,
      operatingSystem: 'iOS',
      osVersion: iosInfo.systemVersion,
      appVersion: AppConstants.fallbackVersion,
    );
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  /// Determines device type (phone vs tablet).
  ///
  /// Heuristic: emulators are treated as phones.
  /// Physical device classification could use screen size in dp
  /// but requires MediaQuery context which isn't available in a service.
  ///
  /// A more accurate approach is to check at the UI layer:
  /// ```dart
  /// final shortestSide = MediaQuery.of(context).size.shortestSide;
  /// final isTablet = shortestSide >= 600;
  /// ```
  ///
  /// For the API payload, "phone" is the safe default.
  String _determineDeviceType({required bool isPhysicalDevice}) {
    // For physical devices, default to phone.
    // In a future enhancement, this can read from SharedPreferences
    // where the user has set their device type manually.
    return AppConstants.deviceTypePhone;
  }

  /// Capitalizes the first letter of the brand name.
  ///
  /// Android brand values are lowercase (e.g., 'samsung', 'google').
  /// We capitalize for display: 'Samsung', 'Google'.
  String _capitalizeBrand(String brand) {
    if (brand.isEmpty) return 'Unknown';
    final trimmed = brand.trim();
    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }

  /// Invalidates the device info cache.
  ///
  /// Called if the user changes device settings that affect the device name.
  /// Forces the next [getDeviceInfo] call to re-collect from the plugin.
  @visibleForTesting
  void invalidateCache() {
    _cachedDeviceInfo = null;
    _debugLog('cache invalidated');
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[DeviceInfoService] $message');
    }
  }
}