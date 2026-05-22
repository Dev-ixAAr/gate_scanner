// ============================================================================
// App Info Service — Package and version information
//
// Reads app version and build information from pubspec.yaml at runtime
// using the package_info_plus plugin.
//
// This information is:
// 1. Sent with API requests as the 'app_version' field
// 2. Displayed on the settings screen under device info
// 3. Used for update prompts if the backend signals a newer version
//
// CACHING:
// Package info does not change during app runtime.
// Results are cached after the first read.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/app_constants.dart';

/// Riverpod provider for [AppInfoService].
///
/// Access pattern:
/// ```dart
/// final appInfoService = ref.read(appInfoServiceProvider);
/// final version = await appInfoService.getAppVersion();
/// ```
final appInfoServiceProvider = Provider<AppInfoService>((ref) {
  return AppInfoService._internal();
});

/// Reads and caches app package information from pubspec.yaml.
///
/// Uses [package_info_plus] to read the app version and build number
/// at runtime. These values come from the `version` field in pubspec.yaml:
///
/// ```yaml
/// version: 1.2.3+45   # → appVersion='1.2.3', buildNumber='45'
/// ```
class AppInfoService {
  AppInfoService._internal();

  // In-memory cache.
  PackageInfo? _cachedPackageInfo;

  // ==========================================================================
  // GET APP VERSION
  // ==========================================================================

  /// Returns the app version string (major.minor.patch).
  ///
  /// Source: pubspec.yaml `version` field before the '+'.
  ///
  /// Returns [AppConstants.fallbackVersion] if the plugin fails.
  ///
  /// Example: '1.0.0'
  Future<String> getAppVersion() async {
    final info = await _getPackageInfo();
    return info?.version ?? AppConstants.fallbackVersion;
  }

  // ==========================================================================
  // GET BUILD NUMBER
  // ==========================================================================

  /// Returns the build number string.
  ///
  /// Source: pubspec.yaml `version` field after the '+'.
  ///
  /// Returns [AppConstants.fallbackBuildNumber] if the plugin fails.
  ///
  /// Example: '42'
  Future<String> getBuildNumber() async {
    final info = await _getPackageInfo();
    return info?.buildNumber ?? AppConstants.fallbackBuildNumber;
  }

  // ==========================================================================
  // GET VERSION WITH BUILD
  // ==========================================================================

  /// Returns a display string combining version and build number.
  ///
  /// Format: 'v{version} (build {buildNumber})'
  ///
  /// Used on the settings screen.
  ///
  /// Example: 'v1.0.0 (build 42)'
  Future<String> getVersionDisplay() async {
    final version = await getAppVersion();
    final build = await getBuildNumber();
    return 'v$version (build $build)';
  }

  // ==========================================================================
  // GET PACKAGE NAME
  // ==========================================================================

  /// Returns the app package name.
  ///
  /// Source: android/app/build.gradle applicationId.
  ///
  /// Returns fallback if the plugin fails.
  ///
  /// Example: 'com.yourcompany.gate_scanner'
  Future<String> getPackageName() async {
    final info = await _getPackageInfo();
    return info?.packageName ?? 'com.yourcompany.gate_scanner';
  }

  // ==========================================================================
  // GET APP NAME
  // ==========================================================================

  /// Returns the app name as configured in the build system.
  ///
  /// Falls back to [AppConstants.appName] if the plugin fails.
  ///
  /// Example: 'Gate Scanner'
  Future<String> getAppName() async {
    final info = await _getPackageInfo();
    return info?.appName ?? AppConstants.appName;
  }

  // ==========================================================================
  // PRIVATE — PACKAGE INFO LOADER
  // ==========================================================================

  /// Loads [PackageInfo] from the plugin, with caching.
  ///
  /// Returns null if the plugin fails (caller uses fallback values).
  Future<PackageInfo?> _getPackageInfo() async {
    if (_cachedPackageInfo != null) {
      return _cachedPackageInfo;
    }

    try {
      final info = await PackageInfo.fromPlatform();
      _cachedPackageInfo = info;
      _debugLog(
        'loaded → name: ${info.appName}, '
        'version: ${info.version}, '
        'build: ${info.buildNumber}',
      );
      return info;
    } catch (e) {
      _debugLog('ERROR loading package info: $e');
      return null;
    }
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[AppInfoService] $message');
    }
  }
}