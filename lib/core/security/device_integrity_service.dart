import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceIntegrityServiceProvider = Provider<DeviceIntegrityService>((ref) {
  return DeviceIntegrityService._();
});

/// Detects compromised devices (root/jailbreak, developer mode).
class DeviceIntegrityService {
  DeviceIntegrityService._();

  /// Set to `true` before production. Disabled for rooted test devices.
  static const bool enableIntegrityCheck = false;

  /// Returns true when the device appears rooted/jailbroken or in dev mode.
  Future<bool> isDeviceCompromised() async {
    if (!enableIntegrityCheck || kDebugMode) return false;

    // Re-add flutter_jailbreak_detection to pubspec.yaml, then restore:
    // final jailbroken = await FlutterJailbreakDetection.jailbroken;
    // final devMode = await FlutterJailbreakDetection.developerMode;
    // return jailbroken || devMode;
    return false;
  }
}
