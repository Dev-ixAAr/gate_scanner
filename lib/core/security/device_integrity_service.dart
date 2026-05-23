import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceIntegrityServiceProvider = Provider<DeviceIntegrityService>((ref) {
  return DeviceIntegrityService._();
});

/// Detects compromised devices (root/jailbreak, developer mode).
class DeviceIntegrityService {
  DeviceIntegrityService._();

  bool? _cachedCompromised;

  /// Returns true when the device appears rooted/jailbroken or in dev mode.
  Future<bool> isDeviceCompromised() async {
    if (kDebugMode) return false;
    if (_cachedCompromised != null) return _cachedCompromised!;

    try {
      final bool jailbroken = await FlutterJailbreakDetection.jailbroken;
      final bool devMode = await FlutterJailbreakDetection.developerMode;
      _cachedCompromised = jailbroken || devMode;
      return _cachedCompromised!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeviceIntegrityService] check failed: $e');
      }
      _cachedCompromised = false;
      return false;
    }
  }
}
